const { WebSocketServer } = require('ws');
const amqp = require('amqplib');
require('dotenv').config();
const { log, warn, err: logErr } = require('./logger');

const RABBITMQ_URL = process.env.RABBITMQ_URL || 'amqp://localhost';
const EXCHANGE     = 'lavaja.solicitacoes';

const clientes = new Map();

let wss = null;

/**
 * Inicializa o servidor WebSocket e o consumer do RabbitMQ.
 * @param {http.Server} httpServer — o mesmo servidor HTTP do Express
 */
async function iniciar(httpServer) {

  wss = new WebSocketServer({ server: httpServer });

  wss.on('connection', (ws) => {
    let usuario_id = null;
    let tipo = null;

    ws.on('message', (raw) => {
      try {
        const msg = JSON.parse(raw);
        if (msg.tipo && msg.usuario_id) {
          usuario_id = msg.usuario_id;
          tipo = msg.tipo;
          clientes.set(usuario_id, { ws, tipo });
          log('WS', `conectado: ${tipo} [${usuario_id}]`);
          ws.send(JSON.stringify({ evento: 'conectado', mensagem: 'WebSocket ativo' }));
        }
      } catch (_) {}
    });

    ws.on('close', () => {
      if (usuario_id) {
        clientes.delete(usuario_id);
        log('WS', `desconectado: ${tipo} [${usuario_id}]`);
      }
    });
  });

  log('WS', 'Gateway iniciado');

  try {
    const conn    = await amqp.connect(RABBITMQ_URL);
    const channel = await conn.createChannel();

    await channel.assertExchange(EXCHANGE, 'topic', { durable: true });

    const { queue } = await channel.assertQueue('', { exclusive: true });

    await channel.bindQueue(queue, EXCHANGE, '#');

    channel.consume(queue, (msg) => {
      if (!msg) return;
      try {
        const evento    = msg.fields.routingKey;
        const payload   = JSON.parse(msg.content.toString());

        log('CONSUMER', `Evento recebido: [${evento}] ${payload.id || ''}`);

        const pacote = JSON.stringify({ evento, dados: payload });

        if (evento === 'solicitacao.criada') {
          enviarParaTipo('lavador', pacote);
        } else {
          if (payload.cliente_id) enviarParaUsuario(payload.cliente_id, pacote);
          if (payload.lavador_id) enviarParaUsuario(payload.lavador_id, pacote);
        }

        channel.ack(msg);
      } catch (err) {
        logErr('CONSUMER', `Erro ao processar mensagem: ${err.message}`);
        channel.nack(msg, false, false);
      }
    });

    log('CONSUMER', 'RabbitMQ → WebSocket Gateway ativo');
  } catch (err) {
    warn('MOM', `RabbitMQ indisponivel — WebSocket gateway em modo offline: ${err.message}`);
  }
}

function enviarParaUsuario(usuario_id, pacote) {
  const cliente = clientes.get(usuario_id);
  if (cliente && cliente.ws.readyState === 1) {
    cliente.ws.send(pacote);
    log('WS', `→ usuario [${usuario_id}]`);
  }
}

function enviarParaTipo(tipo, pacote) {
  let enviados = 0;
  clientes.forEach((cliente) => {
    if (cliente.tipo === tipo && cliente.ws.readyState === 1) {
      cliente.ws.send(pacote);
      enviados++;
    }
  });
  log('WS', `broadcast → ${enviados} ${tipo}(s) conectado(s)`);
}

module.exports = { iniciar };
