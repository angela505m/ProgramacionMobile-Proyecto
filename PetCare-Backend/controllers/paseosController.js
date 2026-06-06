const pool = require('../db');

const iniciarPaseo = async (req, res) => {
    try {
        const { id_mascota, fecha, hora_inicio } = req.body;
        const { rows } = await pool.query(
            'INSERT INTO paseo (id_mascota, fecha, hora_inicio) VALUES ($1, $2, $3) RETURNING *',
            [id_mascota, fecha, hora_inicio]
        );
        res.status(201).json(rows[0]);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al iniciar paseo' });
    }
};

const finalizarPaseo = async (req, res) => {
    try {
        const { id } = req.params;
        const { hora_fin, duracion } = req.body;
        await pool.query(
            'UPDATE paseo SET hora_fin = $1, duracion = $2 WHERE id_paseo = $3',
            [hora_fin, duracion, id]
        );
        res.json({ mensaje: 'Paseo finalizado' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al finalizar paseo' });
    }
};

module.exports = { iniciarPaseo, finalizarPaseo };