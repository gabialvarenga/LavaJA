const amqp = require('amqplib');
require('dotenv').config();
const { log, warn, err } = require('./logger');

const RABBITMQ_URL = process.env.RABBITMQ_URL || 'amqp://localhost';

const EXCHANGES = {
  SOLICITACOES: 'lavaja.solicitacoes',
};

const ROUTING_KEYS = {
  CRIADA:       'solicitacao.criada',
  ACEITA:       'solicitacao.aceita',
  RECUSADA:     'solicitacao.recusada',
  EM_EXECUCAO:  'solicitacao.em_execucao',
  CONCLUIDA:    'solicitacao.concluida',
  CANCELADA:    'solicitacao.cancelada',
  STATUS_ATUALIZADO: 'solicitacao.status_atualizado',
};

let connection = null;
let channel = null;

async function connect() {
  try {
    connection = await amqp.connect(RABBITMQ_URL);
    channel = await connection.createChannel();
    await channel.assertExchange(EXCHANGES.SOLICITACOES, 'topic', { durable: true });
    log('MOM', 'RabbitMQ conectado');
  } catch (err) {
    warn('MOM', `RabbitMQ indisponivel — modo offline: ${err.message}`);
  }
}

async function publish(routingKey, payload) {
  if (!channel) return;
  try {
    const msg = Buffer.from(JSON.stringify({ ...payload, timestamp: new Date().toISOString() }));
    channel.publish(EXCHANGES.SOLICITACOES, routingKey, msg, { persistent: true });
    log('PRODUCER', `[${routingKey}] ${payload.id || ''}`);
  } catch (err) {
    err('PRODUCER', `Erro ao publicar evento: ${err.message}`);
  }
}

module.exports = { connect, publish, EXCHANGES, ROUTING_KEYS };
