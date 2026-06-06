const pool = require('../db');

const registrarUbicacion = async (req, res) => {
    try {
        const { id_paseo, latitud, longitud, fecha_hora } = req.body;
        const { rows } = await pool.query(
            'INSERT INTO ubicacion (id_paseo, latitud, longitud, fecha_hora) VALUES ($1, $2, $3, $4) RETURNING id_ubicacion',
            [id_paseo, latitud, longitud, fecha_hora]
        );
        res.status(201).json({ id_ubicacion: rows[0].id_ubicacion });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al registrar ubicación' });
    }
};

module.exports = { registrarUbicacion };