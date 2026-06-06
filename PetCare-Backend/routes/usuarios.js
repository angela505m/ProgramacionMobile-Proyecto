const express = require('express');
const router = express.Router();
const { login, registrar, eliminarUsuario, actualizarUsuario } = require('../controllers/usuariosController');
const pool = require('../db');

router.post('/login', login);
router.post('/registrar', registrar);
router.delete('/:id', eliminarUsuario);
router.put('/:id', actualizarUsuario);

router.post('/:id/fcm-token', async (req, res) => {
  const { id } = req.params;
  const { fcm_token } = req.body;
  try {
    await pool.query('UPDATE usuario SET fcm_token = $1 WHERE id_usuario = $2', [fcm_token, id]);
    res.json({ mensaje: 'Token FCM guardado' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Error al guardar token FCM' });
  }
});

router.put('/:id/premium', async (req, res) => {
  const { id } = req.params;
  try {
    await pool.query('UPDATE usuario SET es_premium = true WHERE id_usuario = $1', [id]);
    const { rows } = await pool.query(
      'SELECT id_usuario, nombre, email, es_premium FROM usuario WHERE id_usuario = $1',
      [id]
    );
    res.json(rows[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;