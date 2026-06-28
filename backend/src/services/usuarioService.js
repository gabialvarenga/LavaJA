/**
 * Service — UsuarioService
 * Regras de negócio relacionadas a usuários.
 */
const crypto = require('crypto');
const usuarioRepo = require('../repositories/usuarioRepository');
const { TIPOS } = require('../models/Usuario');

function semSenha(usuario) {
  if (!usuario) return null;
  const { senha_hash, ...resto } = usuario;
  return resto;
}

function hashSenha(senha) {
  const salt = crypto.randomBytes(16).toString('hex');
  const hash = crypto.scryptSync(senha, salt, 64).toString('hex');
  return `${salt}:${hash}`;
}

function verificarSenha(senha, senhaHash) {
  const [salt, hash] = senhaHash.split(':');
  const hashVerif = crypto.scryptSync(senha, salt, 64).toString('hex');
  return hash === hashVerif;
}

function criar({ nome, email, telefone, tipo, senha }) {
  if (!nome || !email || !tipo || !senha) throw { status: 400, erro: 'Campos obrigatórios: nome, email, tipo, senha' };
  if (senha.length < 6) throw { status: 400, erro: 'A senha deve ter no mínimo 6 caracteres' };
  if (!TIPOS.includes(tipo)) throw { status: 400, erro: `Tipo deve ser: ${TIPOS.join(' ou ')}` };

  const existente = usuarioRepo.buscarPorEmail(email);
  if (existente) throw { status: 409, erro: 'E-mail já cadastrado' };

  const senha_hash = hashSenha(senha);
  return semSenha(usuarioRepo.criar({ nome, email, telefone, tipo, senha_hash }));
}

function buscarPorId(id) {
  const usuario = usuarioRepo.buscarPorId(id);
  if (!usuario) throw { status: 404, erro: 'Usuário não encontrado' };
  return semSenha(usuario);
}

function listar({ tipo, nome } = {}) {
  return usuarioRepo.listar({ tipo, nome }).map(semSenha);
}

function login(email, senha) {
  if (!email || !senha) throw { status: 400, erro: 'Campos obrigatórios: email, senha' };
  const usuario = usuarioRepo.buscarPorEmail(email);
  if (!usuario || !usuario.senha_hash || !verificarSenha(senha, usuario.senha_hash)) {
    throw { status: 401, erro: 'E-mail ou senha incorretos' };
  }
  return semSenha(usuario);
}

module.exports = { criar, buscarPorId, listar, login };
