# LavaJÁ — App do Lavador

App Flutter para o lavador (prestador de serviço) da plataforma LavaJÁ. Recebe notificações em tempo real via WebSocket, aceita/recusa solicitações e gerencia o ciclo de lavagem.

---

## Pré-requisitos

- Flutter SDK 3.x / Dart 2.16+
- Backend rodando em `localhost:3000` (ver `backend/README.md`)
- Emulador Android ou dispositivo físico

---

## Como rodar

```bash
# 1. Instalar dependências
flutter pub get

# 2. Rodar no emulador (Android)
flutter run
```

> **Emulador Android:** em `lib/core/constants/app_config.dart`, o host padrão é `'localhost'`.
> Para emulador Android, troque para `'10.0.2.2'`.
> Para dispositivo físico via USB, rode `adb reverse tcp:3000 tcp:3000` e mantenha `'localhost'`.

---

## Arquitetura

```
lib/
├── main.dart / app.dart           ← entry point
├── core/
│   ├── constants/                 ← AppColors (teal), AppConfig (host/port)
│   ├── network/api_client.dart    ← HTTP com header x-usuario-id
│   ├── storage/local_storage.dart ← SharedPreferences
│   └── formatters/date_formatter.dart
├── models/
│   ├── solicitacao.dart           ← Solicitacao, StatusSolicitacao, TipoServico
│   └── usuario.dart
├── services/
│   ├── auth_service.dart          ← cadastro/login como tipo='lavador'
│   ├── solicitacao_service.dart   ← aceitar/recusar/iniciar/concluir
│   └── websocket_service.dart     ← registra como tipo='lavador'
├── screens/
│   ├── login_screen.dart          ← tela de boas-vindas
│   ├── entrar_screen.dart         ← login por e-mail e senha
│   ├── cadastro_screen.dart       ← cadastro de lavador
│   ├── main_screen.dart           ← 4 tabs com bottom nav
│   ├── pendentes_tab.dart         ← lista pendentes + push WS
│   ├── andamento_tab.dart         ← aceitas + em execução
│   ├── historico_tab.dart         ← concluídas/recusadas
│   ├── perfil_tab.dart            ← nome, e-mail e logout
│   └── detalhes_solicitacao_screen.dart ← ações por status
└── widgets/
    ├── solicitacao_card.dart
    ├── status_tag.dart
    └── timeline_item.dart
```

---

## Fluxo do lavador

1. Cliente cria solicitação → backend publica no RabbitMQ (`solicitacao.criada`)
2. Backend consome do RabbitMQ e envia via WebSocket para todos os lavadores conectados
3. App do lavador recebe o evento e recarrega a lista de pendentes automaticamente
4. Lavador abre os detalhes → aceita ou recusa
5. Backend publica `solicitacao.aceita/recusada` → cliente é notificado
6. Lavador inicia a lavagem → `em_execucao` → conclui → `concluida`

*Disciplina: LDAMD — PUC Minas · 1º Semestre 2026*
*Aluna: Gabriela Alvarenga Cardoso*
