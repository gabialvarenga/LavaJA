# Relatório Técnico Final — LavaJÁ

**Disciplina:** Laboratório de Desenvolvimento de Aplicações Móveis e Distribuídas  
**Curso:** Engenharia de Software — PUC Minas  
**Aluna:** Gabriela Alvarenga Cardoso  
**Semestre:** 1º Semestre 2026  

---

## 1. Introdução

O LavaJÁ é uma plataforma de solicitação e acompanhamento de lavagem de veículos, conectando clientes (donos de veículos) a lavadores autônomos que operam em bancas de rua e estacionamentos. O sistema permite que o cliente abra uma solicitação de lavagem, e o lavador receba, aceite e execute o serviço — tudo com comunicação assíncrona em tempo real.

O projeto foi desenvolvido como Projeto Integrador da disciplina LDAMD ao longo de quatro sprints, aplicando os conceitos de Arquitetura Orientada a Eventos (EDA), Middleware Orientado a Mensagens (MOM), serviços REST e desenvolvimento mobile com Flutter.

---

## 2. Arquitetura do Sistema

### 2.1 Visão Geral

A arquitetura adota os princípios de Event-Driven Architecture (EDA), com separação clara de responsabilidades entre os componentes:

```
┌─────────────────┐         HTTP REST         ┌──────────────────────┐
│  Flutter Cliente │ ◄───────────────────────► │                      │
│  (app cliente)   │                           │  Backend Node.js     │
└─────────────────┘         WebSocket          │  (Express + SQLite)  │
                    ◄───────────────────────── │                      │
                                               │    ┌──────────────┐  │
┌─────────────────┐         HTTP REST          │    │  RabbitMQ    │  │
│  Flutter Lavador │ ◄───────────────────────► │    │  (AMQP)      │  │
│  (app prestador) │                           │    └──────────────┘  │
└─────────────────┘         WebSocket          └──────────────────────┘
                    ◄─────────────────────────
```

**Componentes:**

- **Apps Flutter:** dois aplicativos nativos (cliente e lavador). Comunicam-se com o backend via HTTP REST e recebem notificações assíncronas via WebSocket.
- **Backend (Node.js/Express):** camada central organizada em Clean Architecture. Expõe endpoints REST, persiste dados no SQLite, publica e consome eventos no RabbitMQ.
- **RabbitMQ:** broker de mensagens. Recebe eventos do backend (produtor) e os distribui via exchange `lavaja.solicitacoes` do tipo `topic`.
- **WebSocket Gateway:** o backend actua como gateway — consome eventos do RabbitMQ e os entrega aos apps conectados. Os apps não se conectam diretamente ao broker.
- **SQLite:** persistência relacional. Armazena usuários, veículos, solicitações e histórico de transições de status.

### 2.2 Fluxo de Ponta a Ponta

O fluxo central do sistema ilustra como os componentes se integram:

1. **Cliente** cria solicitação → POST `/api/solicitacoes`
2. **Backend** persiste no SQLite e publica `solicitacao.criada` no RabbitMQ (routing key `solicitacao.criada`)
3. **Gateway WebSocket** consome o evento e faz broadcast para todos os lavadores conectados (tipo `lavador`)
4. **App do lavador** recebe o evento WebSocket → recarrega a lista de pendentes automaticamente
5. **Lavador** aceita → PATCH `/api/solicitacoes/:id/status` com `{status:'aceita', lavador_id}`
6. **Backend** persiste e publica `solicitacao.aceita` no RabbitMQ
7. **Gateway** entrega o evento diretamente ao cliente dono da solicitação (por `cliente_id`)
8. **App do cliente** recebe a notificação e atualiza o status em tempo real
9. Fluxo continua: lavador inicia (`em_execucao`) → conclui (`concluida`) → cliente notificado a cada etapa

---

## 3. Backend REST e Middleware Orientado a Mensagens

### 3.1 API REST

O backend expõe uma API RESTful implementada com Express.js, organizada segundo os princípios da Clean Architecture:

| Camada | Responsabilidade |
|--------|-----------------|
| Routes | Mapeamento de URLs e middlewares |
| Controllers | Interface HTTP — recebe requisição, chama service, devolve resposta |
| Services | Lógica de negócio, validações de domínio, publicação de eventos |
| Repositories | Único ponto de acesso ao banco — isolamento do SQLite |
| Models | Regras de domínio (estados válidos, transições permitidas) |

**Autenticação:** o cadastro exige e-mail, nome e senha (mínimo 6 caracteres). A senha é armazenada como hash derivado com `crypto.scryptSync` (salt aleatório de 16 bytes + 64 bytes de hash), nunca em texto puro. O login valida e-mail e senha; em caso de sucesso, o backend retorna o UUID do usuário. As requisições subsequentes enviam esse UUID no header `x-usuario-id`, que o middleware `autenticar` valida no banco e injeta como `req.usuario` em toda a cadeia de middlewares.

**Endpoints principais:**

| Método | Rota | Acesso |
|--------|------|--------|
| POST | `/api/usuarios` | público |
| POST | `/api/usuarios/login` | público |
| GET/POST | `/api/veiculos` | cliente |
| POST | `/api/solicitacoes` | cliente |
| GET | `/api/solicitacoes` | cliente (filtra por id) ou lavador (todos) |
| GET | `/api/solicitacoes/:id` | cliente dono ou lavador |
| PATCH | `/api/solicitacoes/:id/status` | cliente (cancelar) ou lavador (aceitar, iniciar, concluir) |
| GET | `/api/solicitacoes/:id/historico` | cliente dono ou lavador |

### 3.2 Middleware Orientado a Mensagens (RabbitMQ)

**Decisão:** RabbitMQ com exchange do tipo `topic` foi escolhido pela expressividade dos routing keys e pela facilidade de adicionar consumidores sem alterar os produtores — um dos princípios do padrão Publish/Subscribe descrito em Hohpe e Woolf (2003).

**Exchange:** `lavaja.solicitacoes` (tipo `topic`, durable)

**Eventos publicados:**

| Routing Key | Produtor | Consumidor | Payload |
|-------------|----------|------------|---------|
| `solicitacao.criada` | Backend ao criar | Gateway WS → lavadores | `{id, cliente_id, cliente_nome, veiculo, endereco, tipo_servico, status}` |
| `solicitacao.aceita` | Backend ao aceitar | Gateway WS → cliente | `{id, cliente_id, lavador_id, status_anterior, status_novo}` |
| `solicitacao.recusada` | Backend ao recusar | Gateway WS → cliente | `{id, cliente_id, lavador_id, ...}` |
| `solicitacao.em_execucao` | Backend ao iniciar | Gateway WS → cliente e lavador | `{id, cliente_id, lavador_id, ...}` |
| `solicitacao.concluida` | Backend ao concluir | Gateway WS → cliente e lavador | `{id, cliente_id, lavador_id, ...}` |
| `solicitacao.cancelada` | Backend ao cancelar | Gateway WS → cliente | `{id, cliente_id, lavador_id, ...}` |

**Consumidor (Gateway WebSocket):** ao iniciar, o backend cria uma fila exclusiva, temporária (`exclusive: true`) e a vincula ao exchange com binding key `#` (recebe todos os eventos). Ao processar cada mensagem, decide o destino:
- `solicitacao.criada` → broadcast para todos os WebSockets de tipo `lavador`
- Demais eventos → entrega direta para `cliente_id` e/ou `lavador_id` via mapa de conexões em memória

**Modo offline:** se o RabbitMQ não estiver disponível, o servidor inicia normalmente sem o gateway. As operações REST funcionam; apenas as notificações em tempo real ficam indisponíveis.

---

## 4. Aplicativo Flutter — Cliente

### 4.1 Arquitetura

O app do cliente segue Clean Architecture com quatro camadas:

- **Core:** constantes (cores, configuração de host), rede (`ApiClient` com timeout e tratamento de erros), armazenamento local (`SharedPreferences`) e formatadores de data.
- **Models:** `Solicitacao`, `StatusSolicitacao` (enum com 6 estados), `TipoServico`, `HistoricoStatus`, `Usuario`.
- **Services:** `AuthService` (cadastro/login), `SolicitacaoService` (CRUD e cancelamento), `WebSocketService` (ChangeNotifier — Provider).
- **Screens/Widgets:** telas de autenticação, `MainScreen` com 4 tabs (início, histórico, veículos, perfil) e widgets reutilizáveis (`SolicitacaoCard`, `StatusTag`, `TimelineItem`).

### 4.2 Atualização Assíncrona

O `WebSocketService` é um `ChangeNotifier` disponibilizado globalmente via `Provider`. Ao receber uma mensagem do servidor, notifica todos os widgets que fazem `context.watch<WebSocketService>()`. Cada tela verifica o evento recebido em `didChangeDependencies()` e recarrega os dados necessários — eliminando polling periódico e garantindo atualização imediata sem ação do usuário.

---

## 5. Aplicativo Flutter — Lavador

### 5.1 Diferenças em Relação ao App do Cliente

O app do lavador (`flutter_lavador`) compartilha a mesma arquitetura do app do cliente, com as seguintes diferenças:

- **Identidade visual:** cor primária teal (#085041) versus azul (#185FA5) do cliente — distinção visual imediata entre os dois apps durante demonstrações.
- **Tipo de registro:** `AuthService` envia `tipo: 'lavador'` ao cadastrar; `EntrarScreen` valida que o usuário logado é do tipo `lavador`.
- **WebSocket:** registra-se com `{tipo: 'lavador', usuario_id}` — o gateway roteia `solicitacao.criada` para este tipo de conexão.
- **Serviço:** `SolicitacaoService` expõe `aceitar`, `recusar`, `iniciar` e `concluir` em vez de `criar` e `cancelar`.
- **Navegação:** 4 tabs — Pendentes, Em Andamento, Histórico e Perfil — mesma quantidade do app cliente.

### 5.2 Telas

| Tela | Função |
|------|--------|
| `PendentesTab` | Lista solicitações com status `pendente`. Recarrega automaticamente ao receber `solicitacao.criada` via WebSocket. |
| `AndamentoTab` | Lista solicitações com status `aceita` ou `em_execucao` vinculadas ao lavador. |
| `HistoricoTab` | Lista solicitações finalizadas (`concluida`, `recusada`, `cancelada`) com filtros. |
| `DetalhesSolicitacaoScreen` | Exibe dados completos. Botões condicionais: pendente → Aceitar/Recusar; aceita → Iniciar; em execução → Concluir. |
| `PerfilTab` | Exibe nome, e-mail e tipo de conta do lavador logado. Botão de logout desconecta o WebSocket e redireciona para a tela de login. |

---

## 6. Dificuldades e Soluções

### 6.1 Fuso Horário

O SQLite grava timestamps em UTC (`datetime('now')`), mas os dispositivos Android mostram a hora local. A solução foi criar o `DateFormatter`, que normaliza o timestamp como UTC antes de converter para o fuso do dispositivo com `DateTime.toLocal()`.

### 6.2 Modo Offline do RabbitMQ

Durante o desenvolvimento, o RabbitMQ nem sempre estava disponível. O servidor foi configurado para inicializar o gateway WebSocket em modo `try/catch` — se a conexão com o broker falhar, um warning é logado e o sistema opera sem notificações em tempo real. A API REST continua funcional.

### 6.3 Roteamento de Eventos WebSocket

O desafio de entregar eventos para o destinatário certo (não fazer broadcast para todos) foi resolvido com um `Map<usuario_id, {ws, tipo}>` em memória no servidor. Eventos de mudança de status carregam `cliente_id` e `lavador_id` no payload, permitindo entrega direta.

### 6.4 Transições de Status

O backend implementa uma máquina de estados no modelo `Solicitacao` com validação de transições permitidas. Isso evita que o cliente cancele uma solicitação já em execução, ou que o lavador inicie uma solicitação não aceita. A função `transicaoValida(statusAtual, statusNovo)` é consultada antes de qualquer atualização.

---

## 7. Reflexão sobre Padrões

### Event-Driven Architecture (EDA)

A adoção de EDA foi o principal diferencial arquitetural do projeto. Em vez de o app do lavador fazer polling periódico para verificar novas solicitações, o backend publica eventos sempre que há mudança de estado. Isso reduz carga no servidor, elimina latência de descoberta e simplifica o código dos apps — que apenas reagem a eventos. Richardson (2018) descreve esse modelo como fundamental para sistemas distribuídos com baixo acoplamento.

### Publish/Subscribe via RabbitMQ

O padrão Publish/Subscribe, descrito em Hohpe e Woolf (2003), foi implementado com exchange do tipo `topic`. A vantagem sobre filas ponto-a-ponto é a possibilidade de adicionar consumidores futuros (ex.: serviço de notificação push, analytics) sem alterar os produtores. O routing key por evento (`solicitacao.criada`, `solicitacao.aceita`) permite que cada consumidor se inscreva apenas nos eventos de seu interesse.

### Clean Architecture

A separação em camadas (models → repositories → services → controllers/screens) manteve o código coeso e testável. O `SolicitacaoRepository` é o único ponto de acesso ao banco; qualquer mudança de banco de dados (ex.: migrar de SQLite para PostgreSQL) afeta apenas essa camada. Martin (2019) define esse isolamento como o objetivo central da arquitetura limpa.

### REST

A API segue os princípios REST com recursos bem definidos (`/solicitacoes`, `/usuarios`, `/veiculos`), uso semântico dos verbos HTTP (POST para criar, PATCH para atualizar estado parcialmente, GET para consultar) e códigos de status HTTP adequados (201 Created, 422 Unprocessable Entity para transições inválidas). Coulouris et al. (2011) descreve REST como o paradigma dominante para sistemas distribuídos baseados em HTTP pela sua statelessness e interoperabilidade.

---

## 8. Referências Bibliográficas

HOHPE, Gregor; WOOLF, Bobby. **Enterprise Integration Patterns: designing, building, and deploying messaging solutions**. Boston: Addison-Wesley, 2003.

MARTIN, Robert C. **Arquitetura limpa: o guia do artesão para estrutura e design de software**. Rio de Janeiro: Alta Books, 2019.

RICHARDSON, Chris. **Microservices patterns: with examples in Java**. Shelter Island: Manning, 2018.

COULOURIS, George et al. **Distributed Systems: concepts and design**. 5th ed. Boston: Addison-Wesley, 2011.

BAILEY, Thomas. **Flutter for beginners**. 3rd ed. Birmingham: Packt, 2023.
