const { initDb } = require('../src/config/database');
const { log, warn } = require('../src/config/logger');

const FORCE = process.argv.includes('--force');

async function main() {
  if (!FORCE) {
    warn('DB', 'Isso vai apagar TODOS os dados do banco (usuarios, veiculos, solicitacoes, historico).');
    warn('DB', 'Rode com --force para confirmar: node scripts/clear_db.js --force');
    process.exit(0);
  }

  const db = await initDb();

  // Ordem importa por causa das FKs
  const tabelas = ['historico_status', 'solicitacoes', 'veiculos', 'usuarios'];

  for (const tabela of tabelas) {
    db.exec(`DELETE FROM ${tabela}`);
    log('DB', `${tabela} limpa`);
  }

  log('DB', 'Banco zerado. Estrutura mantida.');
  process.exit(0);
}

main().catch(err => {
  console.error('Erro:', err.message);
  process.exit(1);
});
