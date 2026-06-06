const pool = require('../db');
const schedule = require('node-schedule');
const { sendPushNotification } = require('../services/fcm');

const jobs = new Map();

const obtenerRecordatoriosPorMascota = async (req, res) => {
    try {
        const idMascota = req.query.mascota;
        if (!idMascota) return res.status(400).json({ error: 'Se requiere id de mascota' });
        const { rows } = await pool.query('SELECT * FROM recordatorio WHERE id_mascota = $1', [idMascota]);
        res.json(rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al obtener recordatorios' });
    }
};

function schedulePush(recordatorio, token, tipo) {
    const [hour, minute] = recordatorio.hora.split(':');
    const now = new Date();
    let scheduledDate = new Date(now.getFullYear(), now.getMonth(), now.getDate(), hour, minute);
    if (scheduledDate <= now) {
        scheduledDate.setDate(scheduledDate.getDate() + 1);
    }
    const job = schedule.scheduleJob(scheduledDate, async () => {
        await sendPushNotification(token, `Recordatorio de ${tipo}`, `Es hora de ${tipo} para tu mascota`);
    });
    jobs.set(recordatorio.id_recordatorio, job);
}

const agregarRecordatorio = async (req, res) => {
    try {
        const { id_mascota, tipo, hora, dias, activo } = req.body;
        // Obtener id_usuario y token
        const { rows: mascotaRows } = await pool.query('SELECT id_usuario FROM mascota WHERE id_mascota = $1', [id_mascota]);
        if (mascotaRows.length === 0) return res.status(404).json({ error: 'Mascota no encontrada' });
        const id_usuario = mascotaRows[0].id_usuario;
        const { rows: usuarioRows } = await pool.query('SELECT fcm_token FROM usuario WHERE id_usuario = $1', [id_usuario]);
        const fcmToken = usuarioRows[0]?.fcm_token;

        const { rows } = await pool.query(
            'INSERT INTO recordatorio (id_mascota, tipo, hora, dias, activo) VALUES ($1, $2, $3, $4, $5) RETURNING *',
            [id_mascota, tipo, hora, dias || '', activo !== undefined ? activo : true]
        );
        const nuevo = rows[0];
        if (activo !== false && fcmToken) {
            schedulePush(nuevo, fcmToken, tipo);
        }
        res.status(201).json(nuevo);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al agregar recordatorio' });
    }
};

const actualizarRecordatorio = async (req, res) => {
    try {
        const { id } = req.params;
        const { tipo, hora, dias, activo } = req.body;
        let query = 'UPDATE recordatorio SET ';
        const params = [];
        let idx = 1;
        if (tipo !== undefined) { query += `tipo = $${idx}, `; params.push(tipo); idx++; }
        if (hora !== undefined) { query += `hora = $${idx}, `; params.push(hora); idx++; }
        if (dias !== undefined) { query += `dias = $${idx}, `; params.push(dias); idx++; }
        if (activo !== undefined) { query += `activo = $${idx}, `; params.push(activo); idx++; }
        query = query.slice(0, -2) + ` WHERE id_recordatorio = $${idx}`;
        params.push(id);
        await pool.query(query, params);

        const { rows } = await pool.query('SELECT * FROM recordatorio WHERE id_recordatorio = $1', [id]);
        if (jobs.has(parseInt(id))) {
            jobs.get(parseInt(id)).cancel();
            jobs.delete(parseInt(id));
        }
        if (rows[0].activo) {
            const { rows: mascotaRows } = await pool.query('SELECT id_usuario FROM mascota WHERE id_mascota = $1', [rows[0].id_mascota]);
            const { rows: usuarioRows } = await pool.query('SELECT fcm_token FROM usuario WHERE id_usuario = $1', [mascotaRows[0].id_usuario]);
            if (usuarioRows[0]?.fcm_token) {
                schedulePush(rows[0], usuarioRows[0].fcm_token, rows[0].tipo);
            }
        }
        res.json(rows[0]);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al actualizar recordatorio' });
    }
};

const eliminarRecordatorio = async (req, res) => {
    try {
        const { id } = req.params;
        if (jobs.has(parseInt(id))) {
            jobs.get(parseInt(id)).cancel();
            jobs.delete(parseInt(id));
        }
        await pool.query('DELETE FROM recordatorio WHERE id_recordatorio = $1', [id]);
        res.json({ mensaje: 'Recordatorio eliminado' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al eliminar recordatorio' });
    }
};

module.exports = { obtenerRecordatoriosPorMascota, agregarRecordatorio, actualizarRecordatorio, eliminarRecordatorio };