/**
 * Stress test — LavaJÁ
 * Simula N clientes e M lavadores simultâneos, conecta WebSockets
 * e dispara o fluxo completo: criar solicitação → aceitar → executar → concluir
 *
 * Uso:
 *   node scripts/stress_test.js              → 3 clientes, 2 lavadores (padrão)
 *   node scripts/stress_test.js 5 3          → 5 clientes, 3 lavadores
 */

const http = require('http');
const WebSocket = require('ws');

const BASE_URL = 'http://localhost:3000';
const WS_URL   = 'ws://localhost:3000';

const N_CLIENTES  = parseInt(process.argv[2]) || 3;
const N_LAVADORES = parseInt(process.argv[3]) || 2;
const PAUSA_MS    = parseInt(process.argv[4]) || 1200; // pausa entre cada etapa

// ─── Utilitários ──────────────────────────────────────────────────────────────

function request(method, path, body = null, headers = {}) {
  return new Promise((resolve, reject) => {
    const data = body ? JSON.stringify(body) : null;
    const options = {
      hostname: 'localhost',
      port: 3000,
      path,
      method,
      headers: {
        'Content-Type': 'application/json',
        ...(data ? { 'Content-Length': Buffer.byteLength(data) } : {}),
        ...headers,
      },
    };

    const req = http.request(options, (res) => {
      let raw = '';
      res.on('data', (chunk) => raw += chunk);
      res.on('end', () => {
        try { resolve({ status: res.statusCode, body: JSON.parse(raw) }); }
        catch { resolve({ status: res.statusCode, body: raw }); }
      });
    });

    req.on('error', reject);
    if (data) req.write(data);
    req.end();
  });
}

function log(tag, msg, color = '\x1b[0m') {
  const ts = new Date().toISOString().substring(11, 23);
  console.log(`${color}[${ts}] [${tag}] ${msg}\x1b[0m`);
}

const COR = {
  cliente:  '\x1b[36m',  // ciano
  lavador:  '\x1b[33m',  // amarelo
  evento:   '\x1b[32m',  // verde
  erro:     '\x1b[31m',  // vermelho
  info:     '\x1b[90m',  // cinza
  titulo:   '\x1b[35m',  // magenta
};

// ─── Contadores globais ────────────────────────────────────────────────────────

const stats = {
  eventosPublicados: 0,
  eventosRecebidosWS: 0,
  solicitacoesCriadas: 0,
  solicitacoesConcluidas: 0,
  erros: 0,
};

// ─── Conectar WebSocket para um usuário ───────────────────────────────────────

function conectarWS(usuario) {
  return new Promise((resolve) => {
    const ws = new WebSocket(WS_URL);

    ws.on('open', () => {
      ws.send(JSON.stringify({ tipo: usuario.tipo, usuario_id: usuario.id }));
      log(`WS-${usuario.tipo.toUpperCase()}`, `${usuario.nome} conectado`, COR.info);
      resolve(ws);
    });

    ws.on('message', (raw) => {
      const msg = JSON.parse(raw.toString());
      if (msg.evento === 'conectado') return;
      stats.eventosRecebidosWS++;
      const cor = usuario.tipo === 'cliente' ? COR.cliente : COR.lavador;
      log(`WS-${usuario.nome}`, `← ${msg.evento} | sol: ${msg.dados?.id?.substring(0, 8)}...`, cor);
    });

    ws.on('error', (e) => log('WS-ERRO', e.message, COR.erro));
  });
}

// ─── Fluxo de um par cliente + lavador ────────────────────────────────────────

function separador(label) {
  const linha = '─'.repeat(42);
  console.log(`\n\x1b[90m${linha}\x1b[0m`);
  if (label) console.log(`\x1b[33m  ▶ ${label}\x1b[0m`);
}

async function executarFluxo(cliente, veiculo, lavador, wsCliente, wsLavador, indice) {
  const prefixo = `Fluxo-${indice + 1}`;

  try {
    separador(`${cliente.nome} → ${lavador.nome}`);

    // 1. Criar solicitação
    const tiposServico = ['simples', 'completa', 'polimento'];
    const tipo = tiposServico[indice % tiposServico.length];

    log(prefixo, `POST /api/solicitacoes  [tipo: ${tipo}]`, COR.info);
    const { body: sol } = await request('POST', '/api/solicitacoes', {
      cliente_id:   cliente.id,
      veiculo_id:   veiculo.id,
      endereco:     `Rua Teste ${indice + 1}, ${(indice + 1) * 100} - BH`,
      tipo_servico: tipo,
    }, { 'x-usuario-id': cliente.id });

    if (!sol.id) throw new Error(`Falha ao criar solicitação: ${JSON.stringify(sol)}`);
    stats.solicitacoesCriadas++;
    log(prefixo, `✔ Solicitação criada  id: ${sol.id.substring(0, 8)}...  status: ${sol.status}`, COR.evento);
    log(prefixo, `  ↪ RabbitMQ deve publicar: solicitacao.criada`, COR.info);

    await delay(PAUSA_MS);

    // 2. Aceitar
    log(prefixo, `PATCH /status → aceita  (lavador: ${lavador.nome})`, COR.info);
    await request('PATCH', `/api/solicitacoes/${sol.id}/status`, {
      status: 'aceita', lavador_id: lavador.id,
    }, { 'x-usuario-id': lavador.id });
    log(prefixo, `✔ Status: pendente → aceita`, COR.evento);
    log(prefixo, `  ↪ RabbitMQ deve publicar: solicitacao.aceita`, COR.info);

    await delay(PAUSA_MS);

    // 3. Em execução
    log(prefixo, `PATCH /status → em_execucao`, COR.info);
    await request('PATCH', `/api/solicitacoes/${sol.id}/status`, {
      status: 'em_execucao',
    }, { 'x-usuario-id': lavador.id });
    log(prefixo, `✔ Status: aceita → em_execucao`, COR.evento);
    log(prefixo, `  ↪ RabbitMQ deve publicar: solicitacao.em_execucao`, COR.info);

    await delay(PAUSA_MS);

    // 4. Concluída
    log(prefixo, `PATCH /status → concluida`, COR.info);
    await request('PATCH', `/api/solicitacoes/${sol.id}/status`, {
      status: 'concluida',
    }, { 'x-usuario-id': lavador.id });
    stats.solicitacoesConcluidas++;
    log(prefixo, `✔ Status: em_execucao → concluida`, COR.evento);
    log(prefixo, `  ↪ RabbitMQ deve publicar: solicitacao.concluida`, COR.info);

  } catch (err) {
    stats.erros++;
    log(prefixo, `✘ Erro: ${err.message}`, COR.erro);
  }
}

function delay(ms) {
  return new Promise(r => setTimeout(r, ms));
}

// ─── Main ─────────────────────────────────────────────────────────────────────

async function main() {
  console.log('\x1b[35m');
  console.log('╔════════════════════════════════════════╗');
  console.log(`║   LavaJÁ — Stress Test RabbitMQ        ║`);
  console.log(`║   ${N_CLIENTES} clientes × ${N_LAVADORES} lavadores               ║`);
  console.log('╚════════════════════════════════════════╝\x1b[0m\n');

  // ── 1. Criar lavadores ──────────────────────────────────────────────────────
  log('SETUP', `Criando ${N_LAVADORES} lavadores...`, COR.titulo);
  const lavadores = await Promise.all(
    Array.from({ length: N_LAVADORES }, (_, i) =>
      request('POST', '/api/usuarios', {
        nome:     `Lavador ${i + 1}`,
        email:    `lavador${i + 1}_${Date.now()}@test.com`,
        telefone: `319999${String(i).padStart(5, '0')}`,
        tipo:     'lavador',
      }).then(r => { log('SETUP', `  lavador criado: ${r.body.nome}`, COR.lavador); return r.body; })
    )
  );

  // ── 2. Criar clientes e veículos ───────────────────────────────────────────
  log('SETUP', `Criando ${N_CLIENTES} clientes e veículos...`, COR.titulo);
  const clientes = await Promise.all(
    Array.from({ length: N_CLIENTES }, async (_, i) => {
      const { body: cliente } = await request('POST', '/api/usuarios', {
        nome:     `Cliente ${i + 1}`,
        email:    `cliente${i + 1}_${Date.now()}@test.com`,
        telefone: `318888${String(i).padStart(5, '0')}`,
        tipo:     'cliente',
      });
      log('SETUP', `  cliente criado: ${cliente.nome}`, COR.cliente);

      // sufixo único por execução para não colidir com placas de runs anteriores
      const sufixo = Date.now().toString().slice(-3);
      const placa  = `T${sufixo}${String(i).padStart(2,'0')}A`;

      const resV = await request('POST', '/api/veiculos', {
        usuario_id: cliente.id,
        placa,
        modelo: ['Civic', 'Uno', 'Gol', 'HB20', 'Argo'][i % 5],
        cor:    ['Prata', 'Branco', 'Preto', 'Vermelho', 'Azul'][i % 5],
      }, { 'x-usuario-id': cliente.id });

      if (!resV.body.id) throw new Error(`Veículo: ${JSON.stringify(resV.body)}`);
      log('SETUP', `  veículo criado: ${placa}`, COR.info);

      return { cliente, veiculo: resV.body };
    })
  );

  // ── 3. Conectar WebSockets ─────────────────────────────────────────────────
  log('SETUP', 'Conectando WebSockets...', COR.titulo);
  const wsLavadores = await Promise.all(lavadores.map(conectarWS));
  const wsClientes  = await Promise.all(clientes.map(({ cliente }) => conectarWS(cliente)));

  await delay(500);

  // ── 4. Disparar fluxos simultâneos ────────────────────────────────────────
  console.log('');
  log('START', `Disparando ${N_CLIENTES} fluxos simultâneos...\n`, COR.titulo);
  const inicio = Date.now();

  await Promise.all(
    clientes.map(({ cliente, veiculo }, i) => {
      const lavador   = lavadores[i % lavadores.length];
      const wsCliente = wsClientes[i];
      const wsLavador = wsLavadores[i % wsLavadores.length];
      return executarFluxo(cliente, veiculo, lavador, wsCliente, wsLavador, i);
    })
  );

  const duracao = ((Date.now() - inicio) / 1000).toFixed(2);

  // ── 5. Aguardar eventos WebSocket chegarem ─────────────────────────────────
  await delay(1000);

  // ── 6. Fechar WebSockets ───────────────────────────────────────────────────
  [...wsLavadores, ...wsClientes].forEach(ws => ws.close());

  // ── 7. Relatório final ─────────────────────────────────────────────────────
  console.log('\n\x1b[35m');
  console.log('╔════════════════════════════════════════╗');
  console.log('║           RESULTADO DO TESTE           ║');
  console.log('╠════════════════════════════════════════╣');
  console.log(`║  Duração total:        ${String(duracao + 's').padEnd(16)}║`);
  console.log(`║  Solicitações criadas: ${String(stats.solicitacoesCriadas).padEnd(16)}║`);
  console.log(`║  Solicitações concluídas: ${String(stats.solicitacoesConcluidas).padEnd(13)}║`);
  console.log(`║  Eventos WS recebidos: ${String(stats.eventosRecebidosWS).padEnd(16)}║`);
  console.log(`║  Erros:                ${String(stats.erros).padEnd(16)}║`);
  console.log('╚════════════════════════════════════════╝\x1b[0m\n');

  process.exit(stats.erros > 0 ? 1 : 0);
}

main().catch(err => {
  log('FATAL', err.message, COR.erro);
  process.exit(1);
});
