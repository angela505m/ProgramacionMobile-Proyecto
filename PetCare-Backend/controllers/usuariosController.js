const bcrypt = require('bcrypt');
const pool = require('../db');
const saltRounds = 10;

const registrar = async (req, res) => {
    try {
        const { nombre, email, password } = req.body;
        const hashedPassword = await bcrypt.hash(password, saltRounds);

        // Verificar si ya existe
        const { rows: existRows } = await pool.query(
            'SELECT id_usuario FROM usuario WHERE email = $1',
            [email]
        );
        if (existRows.length > 0) {
            return res.status(400).json({ error: 'El email ya está registrado' });
        }

        const { rows } = await pool.query(
            'INSERT INTO usuario (nombre, email, contraseña, es_premium) VALUES ($1, $2, $3, false) RETURNING id_usuario, nombre, email, es_premium',
            [nombre, email, hashedPassword]
        );
        res.status(201).json(rows[0]);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al crear usuario' });
    }
};

const login = async (req, res) => {
    try {
        const { email, password } = req.body;
        const { rows } = await pool.query(
            'SELECT id_usuario, nombre, email, contraseña, es_premium FROM usuario WHERE email = $1',
            [email]
        );
        if (rows.length === 0) {
            return res.status(401).json({ error: 'Email o contraseña incorrectos' });
        }
        const usuario = rows[0];
        const match = await bcrypt.compare(password, usuario.contraseña);
        if (!match) {
            return res.status(401).json({ error: 'Email o contraseña incorrectos' });
        }
        res.json({
            id_usuario: usuario.id_usuario,
            nombre: usuario.nombre,
            email: usuario.email,
            es_premium: usuario.es_premium
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error en el servidor' });
    }
};

const eliminarUsuario = async (req, res) => {
    try {
        const { id } = req.params;
        const { rowCount } = await pool.query('DELETE FROM usuario WHERE id_usuario = $1', [id]);
        if (rowCount === 0) {
            return res.status(404).json({ error: 'Usuario no encontrado' });
        }
        res.json({ mensaje: 'Usuario eliminado correctamente' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al eliminar usuario' });
    }
};

const actualizarUsuario = async (req, res) => {
    try {
        const { id } = req.params;
        const { nombre, email } = req.body;
        // Verificar email no repetido
        const { rows: existing } = await pool.query(
            'SELECT id_usuario FROM usuario WHERE email = $1 AND id_usuario != $2',
            [email, id]
        );
        if (existing.length > 0) {
            return res.status(400).json({ error: 'El email ya está registrado por otro usuario' });
        }
        const { rowCount } = await pool.query(
            'UPDATE usuario SET nombre = $1, email = $2 WHERE id_usuario = $3',
            [nombre, email, id]
        );
        if (rowCount === 0) {
            return res.status(404).json({ error: 'Usuario no encontrado' });
        }
        res.json({ mensaje: 'Usuario actualizado correctamente', nombre, email });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al actualizar usuario' });
    }
};

module.exports = { login, registrar, eliminarUsuario, actualizarUsuario };