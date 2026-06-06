const pool = require('../db');

const obtenerMascotas = async (req, res) => {
    try {
        const idUsuario = req.query.user;
        let query = 'SELECT * FROM mascota';
        const params = [];
        if (idUsuario) {
            query += ' WHERE id_usuario = $1';
            params.push(idUsuario);
        }
        const { rows } = await pool.query(query, params);
        res.json(rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al obtener mascotas' });
    }
};

const agregarMascota = async (req, res) => {
    try {
        const { nombre, tipo, tipo_otro, edad, id_usuario } = req.body;
        const { rows } = await pool.query(
            'INSERT INTO mascota (nombre, tipo, tipo_otro, edad, id_usuario) VALUES ($1, $2, $3, $4, $5) RETURNING *',
            [nombre, tipo, tipo_otro || null, edad || null, id_usuario]
        );
        res.status(201).json(rows[0]);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al agregar mascota' });
    }
};

const eliminarMascota = async (req, res) => {
    try {
        const { id } = req.params;
        await pool.query('DELETE FROM mascota WHERE id_mascota = $1', [id]);
        res.json({ mensaje: 'Mascota eliminada' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al eliminar mascota' });
    }
};

const actualizarMascota = async (req, res) => {
    try {
        const { id } = req.params;
        const { nombre, tipo, tipo_otro, edad } = req.body;
        const { rowCount } = await pool.query(
            'UPDATE mascota SET nombre = $1, tipo = $2, tipo_otro = $3, edad = $4 WHERE id_mascota = $5',
            [nombre, tipo, tipo_otro || null, edad || null, id]
        );
        if (rowCount === 0) {
            return res.status(404).json({ error: 'Mascota no encontrada' });
        }
        const { rows } = await pool.query('SELECT * FROM mascota WHERE id_mascota = $1', [id]);
        res.json(rows[0]);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al actualizar mascota' });
    }
};

module.exports = { obtenerMascotas, agregarMascota, eliminarMascota, actualizarMascota };