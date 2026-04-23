<!-- Instruções sucintas para agentes AI que vão editar este repositório -->
# Copilot / Agentes — Instruções específicas do repositório PheliFlaApp

Propósito rápido
- Este repositório contém um aplicativo Flutter (mobile) + painel gerencial (web) que se comunicam via Firebase Firestore. Há também Cloud Functions em `functions/` para notificações.

Arquitetura (big picture)
- App Flutter: código em `lib/` (telas em `lib/screens/`, modelos em `lib/models/`, integrações em `lib/services/`). Entrada em `lib/main.dart`.
- Painel Web: projeto separado (não detalhado aqui) e deploy feito via Firebase Hosting (ver `README.md`).
- Backend: Firebase (Auth, Firestore, Cloud Messaging). Cloud Functions em `functions/` (ex.: `functions/index.js` envia notificações ao criar mensagens em `salas/{salaId}/mensagens/{mensagemId}`).

Padrões e convenções específicos
- Firestore: coleções chave são `produtos`, `categorias`, `usuarios`, `salas` e subcoleção `salas/{salaId}/mensagens`.
- Nomes e texto em português — preserve terminologia (ex.: `nomeUsuario`, `sala`, `limite`, `usuarios`).
- UI: usa `StreamBuilder` para dados em tempo real (ver `lib/screens/room_selection_screen.dart`).
- Separação: regras de negócio / integrações Firebase ficam em `lib/services/` quando existir; telas usam essas camadas.
- Arquivos de configuração do Firebase (`google-services.json`, `@google-services.json`) estão em `android/app/` e em `app/` — não remova sem checar variáveis de ambiente.

Fluxos de desenvolvedor importantes
- Instalação dependências Flutter:
  - `flutter pub get`
- Rodar app em debug (PowerShell, Windows):
  - `flutter run -d <deviceId>`
- Rodar testes unitários/widget:
  - `flutter test`
- Build para release (Android):
  - `flutter build apk --release`
- Funções Firebase (desenvolvimento):
  - `cd functions; npm install` (se ainda não instalado)
  - `npm run serve` (inicia emulador local de functions)
  - `npm run deploy` (faz deploy apenas das functions)
- Deploy completo (hosting + functions): use `firebase deploy` conforme `README.md`.

Integrações e pontos críticos
- FCM: tokens são lidos da coleção `usuarios` (campo `fcmToken`) — Cloud Function `enviarNotificacaoNovaMensagem` filtra por `notificacoesAtivadas`.
- Auth: `FirebaseAuth.instance.currentUser` é usado em telas (ex.: `room_selection_screen.dart` obtém `displayName`, `photoURL`, `uid`).
- Firestore updates: quando um usuário entra em uma `sala`, o app usa `FieldValue.arrayUnion([uid])` para atualizar `usuarios`.

Regras para agentes AI ao editar este repositório
- Faça mudanças pequenas e focadas; evite refatorações globais sem pedir aprovação.
- Ao editar Dart/Flutter:
  - Use `apply_patch` para mudanças de arquivos e siga o estilo existente (não reformatar arquivos não relacionados).
  - Rode `flutter test` localmente se alterar lógica que afeta testes.
- Ao alterar Firebase/Cloud Functions:
  - Confirme a engine em `functions/package.json` (atualmente Node 22) e instale dependências antes de executar.
- Não commite credenciais sensíveis. Se encontrar `google-services.json` ou chaves, confirme se estão placeholders ou secretos.

Exemplos rápidos (códigos referências)
- Para ver como `nomeUsuario` é passado: `lib/screens/room_selection_screen.dart` usa `ModalRoute.of(context)!.settings.arguments as String`.
- Para envio de notificações: `functions/index.js` observa `salas/{salaId}/mensagens/{mensagemId}`.

Onde olhar primeiro
- `lib/main.dart` — inicialização do app.
- `lib/screens/` — telas e navegação.
- `lib/services/` — integrações com Firebase (quando presentes).
- `functions/` — lógica server-side para notificações.
- `pubspec.yaml` — dependências Flutter.

Seções que podem necessitar de confirmação manual
- Fluxo de build para painel Web (React) não está no monorepo aqui; consulte `README.md` quando mexer no painel.

Se precisar de mais contexto, diga quais áreas quer que eu detalhe (ex.: fluxo de login, estrutura das coleções Firestore, testes). 
