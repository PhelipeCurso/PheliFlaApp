const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.enviarNotificacaoNovaMensagem = functions.firestore
  .document("salas/{salaId}/mensagens/{mensagemId}")
  .onCreate(async (snap, context) => {
    const novaMensagem = snap.data();
    const texto = novaMensagem.texto;
    const nome = novaMensagem.nome;
    
    const usuariosSnapshot = await admin.firestore().collection("usuarios").get();

    const tokens = [];

    usuariosSnapshot.forEach(doc => {
      const data = doc.data();
      if (data.notificacoesAtivadas && data.fcmToken && data.uid !== novaMensagem.uid) {
        tokens.push(data.fcmToken);
      }
    });

    const payload = {
      notification: {
        title: `Nova mensagem de ${nome}`,
        body: texto.length > 40 ? texto.substring(0, 40) + '...' : texto,
      }
    };

    if (tokens.length > 0) {
      await admin.messaging().sendToDevice(tokens, payload);
    }

    return null;
  });
