const { initDb } = require('../src/config/database');

const FORCE = process.argv.includes('--force');

async function main() {
  if (!FORCE) {
    console.log('⚠️  Isso vai apagar TODOS os dados do banco (usuarios, veiculos, solicitacoes, historico).');
    console.log('   Rode com --force para confirmar:\n');
    console.log('   node scripts/clear_db.js --force\n');
    process.exit(0);
  }

  const db = await initDb();

  // Ordem importa por causa das FKs
  const tabelas = ['historico_status', 'solicitacoes', 'veiculos', 'usuarios'];

  for (const tabela of tabelas) {
    db.exec(`DELETE FROM ${tabela}`);
    console.log(`🗑️  ${tabela} limpa`);
  }

  console.log('\n✅ Banco zerado. Estrutura mantida.\n');
  process.exit(0);
}

main().catch(err => {
  console.error('Erro:', err.message);
  process.exit(1);
});
