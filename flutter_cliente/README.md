# LavaJÁ — App Cliente (Flutter)

Aplicativo móvel para o cliente do serviço de lavagem de carros a domicílio **LavaJÁ**.  
Desenvolvido em Flutter como parte da Sprint 3 da disciplina LDAMD — PUC Minas.

---

## Arquitetura do App (Clean Architecture)

```
┌─────────────────────────────────────────────────────────────┐
│                        SCREENS                              │
│                                                             │
│  LoginScreen  CadastroScreen  EntrarScreen  MainScreen      │
│  HomeTab  HistoricoTab  VeiculosTab  PerfilTab              │
│  NovaSolicitacaoScreen  DetalhesSolicitacaoScreen           │
│                                                             │
│  Responsabilidade: estado visual, navegação, eventos de UI  │
└───────────────────────────┬─────────────────────────────────┘
                            │ chama / consome
┌───────────────────────────▼─────────────────────────────────┐
│                        SERVICES                             │
│                                                             │
│  AuthService      → registro e login de usuários            │
│  VeiculoService   → CRUD de veículos do cliente             │
│  SolicitacaoService → criar, listar, cancelar solicitações  │
│  WebSocketService → conexão em tempo real com o backend     │
│                   (ChangeNotifier — estado reativo via      │
│                    Provider)                                │
│                                                             │
│  Responsabilidade: regras de negócio do cliente,            │
│  chamadas ao ApiClient, transformação de dados              │
└──────────┬────────────────────────────────────┬─────────────┘
           │ usa                                │ usa
┌──────────▼────────────┐          ┌────────────▼─────────────┐
│        MODELS         │          │          CORE             │
│                       │          │                           │
│  Solicitacao          │          │  network/                 │
│  HistoricoStatus      │          │    ApiClient              │
│  TipoServico (enum)   │          │    (HTTP + timeout)       │
│  StatusSolicitacao    │          │                           │
│  Veiculo              │          │  storage/                 │
│  Usuario              │          │    LocalStorage           │
│                       │          │    (SharedPreferences)    │
│  Responsabilidade:    │          │                           │
│  estrutura de dados   │          │  formatters/              │
│  + parsing de JSON    │          │    PlacaFormatter         │
│                       │          │                           │
└───────────────────────┘          │  constants/               │
                                   │    AppColors              │
                                   │                           │
                                   │  Responsabilidade:        │
                                   │  infraestrutura agnóstica │
                                   │  (não conhece negócio)    │
                                   └───────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                        WIDGETS                              │
│                                                             │
│  StatusTag    → chip colorido por status da solicitação     │
│  TimelineItem → item do histórico de status                 │
│  SolicitacaoCard → card resumido da solicitação             │
│                                                             │
│  Responsabilidade: componentes visuais reutilizáveis,       │
│  sem lógica de negócio                                      │
└─────────────────────────────────────────────────────────────┘
```

---

## Fluxo de Atualização Assíncrona (RabbitMQ → WebSocket → Flutter)

```
Backend (Node.js)
  │
  ├─ SolicitacaoService.atualizarStatus()
  │       │
  │       └─► RabbitMQ Exchange (topic: lavaja.solicitacoes)
  │                   │
  │                   └─► Fila exclusiva (binding: #)
  │                               │
  │                   websocket.js consome e roteia
  │                               │
  │              ┌────────────────┴────────────────┐
  │              │ se "solicitacao.criada"          │ demais eventos
  │              ▼                                  ▼
  │     broadcast → lavadores           cliente_id + lavador_id
  │                                     (WebSocket direto)
  │
Flutter (WebSocketService)
  ├─ Recebe evento JSON: { evento, dados }
  ├─ Atualiza _ultimoEvento e chama notifyListeners()
  │
  ├─ HomeTab (context.watch) → recarrega lista de solicitações ativas
  └─ DetalhesSolicitacaoScreen → atualiza status e timeline em tempo real
```

---

## Estrutura de Pastas

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/app_colors.dart
│   ├── formatters/placa_formatter.dart
│   ├── network/api_client.dart
│   └── storage/local_storage.dart
├── models/
│   ├── solicitacao.dart
│   ├── usuario.dart
│   └── veiculo.dart
├── screens/
│   ├── login_screen.dart
│   ├── cadastro_screen.dart
│   ├── entrar_screen.dart
│   ├── main_screen.dart
│   ├── home_tab.dart
│   ├── historico_tab.dart
│   ├── veiculos_tab.dart
│   ├── perfil_tab.dart
│   ├── nova_solicitacao_screen.dart
│   └── detalhes_solicitacao_screen.dart
├── services/
│   ├── auth_service.dart
│   ├── solicitacao_service.dart
│   ├── veiculo_service.dart
│   └── websocket_service.dart
└── widgets/
    ├── solicitacao_card.dart
    ├── status_tag.dart
    └── timeline_item.dart
```

---

## Tecnologias

| Camada | Tecnologia |
|---|---|
| UI | Flutter 2.10.5 / Dart 2.16.2 |
| HTTP | `http: 0.13.4` |
| WebSocket | `web_socket_channel: ^2.3.0` |
| Estado reativo | `provider: ^6.0.5` (ChangeNotifier) |
| Persistência local | `shared_preferences: ^2.0.15` |

---

## Configuração do servidor

O endereço do backend fica em **um único lugar**: [`lib/core/constants/app_config.dart`](lib/core/constants/app_config.dart).
Basta editar o campo `host` (só o IP/nome, **sem** `http://` e **sem** a porta) — o REST e o WebSocket derivam dele automaticamente.

```dart
static const String host = 'localhost'; // <- único campo a trocar
```

## Como executar

> ⚠️ Após trocar o `host`, faça **hot restart** (tecla `R` maiúsculo) ou pare e rode de novo.
> Hot reload (`r`) **não** atualiza constantes.

### Opção A — Emulador Android com `adb reverse` (recomendado)

Cria um túnel do `localhost` do emulador para o `localhost` da máquina. Funciona mesmo com o
Firewall do Windows bloqueando conexões externas ao `node.exe`.

```bash
# 1. Backend rodando na máquina (porta 3000) + RabbitMQ (Docker) ativo
# 2. Cria o túnel (refazer sempre que o emulador for reiniciado)
adb reverse tcp:3000 tcp:3000
# 3. app_config.dart  ->  host = 'localhost'
flutter run
```

### Opção B — Emulador Android sem túnel

O emulador acessa o `localhost` da máquina pelo IP especial `10.0.2.2`.
Requer que o Firewall do Windows libere o `node.exe` para conexões de entrada.

```dart
// app_config.dart
static const String host = '10.0.2.2';
```

### Opção C — Dispositivo físico na mesma rede WiFi

```dart
// app_config.dart  ->  host = IP da máquina na rede (ex: ipconfig)
static const String host = '192.168.0.193';
```
