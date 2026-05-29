# Testes de Bancada - LavaJA

## 1. Cadastro e Sessão

| ID | Ação | Resultado esperado |
|---|---|---|
| 1.1 | Abrir o app pela primeira vez | Tela de login aparece |
| 1.2 | Tocar em "Criar conta" | Vai para a tela de cadastro |
| 1.3 | Preencher nome, e-mail e telefone → "Cadastrar" | Vai direto para a Home |
| 1.4 | Fechar e reabrir o app | Pula o login, vai direto para a Home (sessão salva) |

## 2. Veículos (aba Veículos)

| ID | Ação | Resultado esperado |
|---|---|---|
| 2.1 | Tocar na aba "veículos" | Lista vazia |
| 2.2 | Tocar no + → preencher modelo, placa, cor → "Salvar" | Veículo aparece na lista |
| 2.3 | Tentar cadastrar a mesma placa novamente | Erro exibido ("placa já existe") |

## 3. Nova Solicitação (Fluxo Principal)

| ID | Ação | Resultado esperado |
|---|---|---|
| 3.1 | Na Home → "Nova solicitação" | Tela de criação abre |
| 3.2 | Selecionar veículo no dropdown | Dropdown mostra o veículo cadastrado no passo 2.2 |
| 3.3 | Selecionar tipo: Simples / Completa / Polimento | Pill muda de cor, descrição atualiza |
| 3.4 | Preencher endereço → "Solicitar lavagem" | Volta para a Home, solicitação aparece com status pendente |
| 3.5 | Tentar criar sem endereço | Mensagem de erro inline |

## 4. Detalhes da Solicitação

| ID | Ação | Resultado esperado |
|---|---|---|
| 4.1 | Tocar na solicitação pendente na Home | Abre tela de Detalhes |
| 4.2 | Verificar timeline | Mostra o passo "pendente" ativo |
| 4.3 | Botão "Cancelar" aparece? | Sim (status é pendente) |
| 4.4 | Tocar "Cancelar" → confirmar | Status muda para cancelada, botão some |

## 5. WebSocket — Tempo Real

> **Pré-requisito:** Precisa de um lavador ativo. Abra o Postman ou use o script para simular.

### Setup da API

**Crie um lavador via API:**
```
POST http://localhost:3000/api/usuarios
{ "nome": "Carlos", "email": "carlos@lava.com", "telefone": "31999990002", "tipo": "lavador" }
```

**Copie o ID retornado e aceite a solicitação:**
```
PATCH http://localhost:3000/api/solicitacoes/<id_solicitacao>/status
Headers: x-usuario-id: <id_do_lavador>
Body: { "status": "aceita", "lavador_id": "<id_do_lavador>" }
```

### Testes

| ID | Ação | Resultado esperado |
|---|---|---|
| 5.1 | Com o app aberto na Home, lavador aceita via Postman | Banner azul aparece na Home sem refresh manual |
| 5.2 | Abrir detalhes da solicitação aceita | Timeline mostra "aceita" como passo atual |
| 5.3 | Lavador muda para em_execucao via Postman | Banner atualiza, timeline avança |
| 5.4 | Lavador muda para concluida | Banner "Lavagem concluída!", botão cancelar some |

## 6. Histórico e Filtros

| ID | Ação | Resultado esperado |
|---|---|---|
| 6.1 | Aba "histórico" | Lista todas as solicitações |
| 6.2 | Filtro "Ativas" | Só pendente/aceita/em_execucao |
| 6.3 | Filtro "Concluídas" | Só as concluídas |
| 6.4 | Pull-to-refresh (puxar para baixo) | Lista recarrega |

## 7. Perfil e Logout

| ID | Ação | Resultado esperado |
|---|---|---|
| 7.1 | Aba "perfil" | Nome e e-mail do usuário cadastrado |
| 7.2 | "Sair da conta" → confirmar | Volta para a tela de login |
| 7.3 | Reabrir o app | Pede cadastro novamente |

## Casos de Erro

- **Backend desligado:** Abrir a Home → exibe mensagem de erro com botão "Tentar"
- **Sem veículos:** Ir em "Nova solicitação" → exibe link "Cadastrar veículo"
- **E-mail duplicado no cadastro:** Backend retorna erro → exibido em vermelho na tela