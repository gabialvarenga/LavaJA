const express = require('express');
const router  = express.Router();

const usuarios     = require('../controllers/usuariosController');
const veiculos     = require('../controllers/veiculosController');
const solicitacoes = require('../controllers/solicitacoesController');

const { autenticar, apenasCliente, apenasLavador, apenasProprioOuLavador } = require('../middlewares/auth');
const { donoSolicitacao } = require('../middlewares/roleGuard');

router.post ('/usuarios',       usuarios.criar);
router.post ('/usuarios/login', usuarios.login);   // público — auth simplificada sem senha
router.get  ('/usuarios',     autenticar, apenasLavador, usuarios.listar);
router.get  ('/usuarios/:id', autenticar, apenasProprioOuLavador, usuarios.buscarPorId);

router.post  ('/veiculos',     autenticar, apenasCliente, veiculos.criar);
router.get   ('/veiculos',     autenticar, apenasCliente, veiculos.listar);
router.get   ('/veiculos/:id', autenticar, veiculos.buscarPorId);
router.patch ('/veiculos/:id', autenticar, apenasCliente, veiculos.atualizar);

router.post ('/solicitacoes',               autenticar, apenasCliente,    solicitacoes.criar);
router.get  ('/solicitacoes',               autenticar,                   solicitacoes.listar);
router.get  ('/solicitacoes/:id',           autenticar, donoSolicitacao,  solicitacoes.buscarPorId);
router.patch('/solicitacoes/:id/status',    autenticar, donoSolicitacao,  solicitacoes.atualizarStatus);
router.get  ('/solicitacoes/:id/historico', autenticar, donoSolicitacao,  solicitacoes.historico);

module.exports = router;
