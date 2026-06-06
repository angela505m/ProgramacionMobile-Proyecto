const pool = require('./db');
require('dotenv').config();
const express = require('express');
const cors = require('cors');
const http = require('http');
const socketIo = require('socket.io');
const schedule = require('node-schedule');

async function testDB() {
    try {
        const { rows } = await pool.query('SELECT 1');
        console.log('Conexión a PostgreSQL exitosa');
    } catch (error) {
        console.error('Error de conexión a PostgreSQL:', error.message);
        process.exit(1);
    }
}
testDB();

const app = express();
app.use(cors());
app.use(express.json());

const server = http.createServer(app);
const io = socketIo(server, { cors: { origin: "*" } });

const userSockets = new Map();

io.on('connection', (socket) => {
    console.log('Cliente conectado:', socket.id);
    socket.on('register', (userId) => {
        userSockets.set(userId, socket.id);
        console.log(`Usuario ${userId} registrado`);
    });
    socket.on('disconnect', () => {
        for (let [userId, sockId] of userSockets.entries()) {
            if (sockId === socket.id) {
                userSockets.delete(userId);
                break;
            }
        }
        console.log('Cliente desconectado:', socket.id);
    });
});

function scheduleReminder(reminder) {
    const { id_recordatorio, id_usuario, tipo, hora } = reminder;
    const [hour, minute] = hora.split(':');
    const rule = new schedule.RecurrenceRule();
    rule.hour = parseInt(hour);
    rule.minute = parseInt(minute);
    const job = schedule.scheduleJob(rule, () => {
        const socketId = userSockets.get(id_usuario);
        if (socketId) {
            io.to(socketId).emit('reminder', {
                id: id_recordatorio,
                tipo: tipo,
                title: `Recordatorio de ${tipo}`,
                body: `Es hora de ${tipo} para tu mascota`
            });
            console.log(`Notificación enviada a usuario ${id_usuario}`);
        }
    });
    if (!global.reminderJobs) global.reminderJobs = new Map();
    global.reminderJobs.set(id_recordatorio, job);
}

// Exportar para controladores
module.exports = { io, userSockets, scheduleReminder };

// Rutas
const mascotasRoutes = require('./routes/mascotas');
const usuariosRoutes = require('./routes/usuarios');
const recordatoriosRoutes = require('./routes/recordatorios');
const paseosRoutes = require('./routes/paseos');
const ubicacionesRoutes = require('./routes/ubicaciones');

app.use('/mascotas', mascotasRoutes);
app.use('/usuarios', usuariosRoutes);
app.use('/recordatorios', recordatoriosRoutes);
app.use('/paseos', paseosRoutes);
app.use('/ubicaciones', ubicacionesRoutes);

module.exports = app;