const bcrypt = require('bcrypt');
const pool = require('./db');

async function migrar() {
    try {
        const { rows: users } = await pool.query('SELECT id_usuario, contraseña FROM usuario');
        for (const user of users) {
            // Si la contraseña NO empieza con $2b$ (hash bcrypt), la hasheamos
            if (!user.contraseña.startsWith('$2b$')) {
                const hashed = await bcrypt.hash(user.contraseña, 10);
                await pool.query('UPDATE usuario SET contraseña = $1 WHERE id_usuario = $2', [hashed, user.id_usuario]);
                console.log(`Usuario ${user.id_usuario} migrado`);
            }
        }
        console.log(' Migración completada');
    } catch (error) {
        console.error('Error en migración:', error);
    } finally {
        process.exit();
    }
}

migrar();