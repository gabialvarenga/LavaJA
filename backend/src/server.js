require('dotenv').config();
const http = require('http');
const { migrate } = require('./config/migrate');
const { connect } = require('./config/rabbitmq');
const wsGateway = require('./config/websocket');
const app = require('./app');
const { log } = require('./config/logger');

const PORT = process.env.PORT || 3000;

async function start() {
  await migrate();
  await connect();

  // Cria servidor HTTP compartilhado entre Express e WebSocket
  const httpServer = http.createServer(app);

  // Inicia WebSocket Gateway (consome RabbitMQ e repassa aos apps)
  await wsGateway.iniciar(httpServer);

  httpServer.listen(PORT, () => {
    log('SERVER', `LavaJA Backend rodando em http://localhost:${PORT}`);
    log('WS',     `WebSocket disponivel em  ws://localhost:${PORT}`);
    log('REST',   `Endpoints REST em        http://localhost:${PORT}/api`);
  });
}

start().catch(e => { console.error(e); process.exit(1); });
