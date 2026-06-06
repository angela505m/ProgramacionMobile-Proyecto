const admin = require('firebase-admin');
const serviceAccount = require('../config/petcare-app-c5dfc-firebase-adminsdk-fbsvc-97ae41124d.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});
async function sendPushNotification(deviceToken, title, body) {
  if (!deviceToken) {
    console.log('No hay token de dispositivo');
    return;
  }
  const message = {
    notification: { title, body },
    token: deviceToken,
    android: { priority: 'high' },
    apns: { payload: { aps: { sound: 'default' } } },
  };
  try {
    const response = await admin.messaging().send(message);
    console.log('Notificación push enviada:', response);
  } catch (error) {
    console.error('Error al enviar notificación push:', error);
  }
}

module.exports = { sendPushNotification };