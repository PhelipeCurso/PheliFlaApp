🚀 Visão Geral

O projeto é composto por duas partes principais:

Aplicativo Mobile (Flutter): voltado ao usuário final, com chat, loja de produtos e notícias.

Painel Gerencial (React + Firebase): sistema administrativo para gestão de produtos e categorias, com autenticação via Google.

Ambas as partes se comunicam via Firebase Firestore, garantindo dados em tempo real e sincronizados.

📱 Aplicativo Mobile (Flutter)

Funcionalidades

- Tela de Login com Google/Firebase
- Tela de seleção de salas (Homens, Mulheres, Todos)
- Chat em tempo real
- Loja integrada com produtos cadastrados no painel
- Filtros por categoria, gênero e tipo (adulto/infantil)
- Lista de notícias por scraping ou API
- Temas claro/escuro
  

Upload e exibição de foto de perfil

# Estrutura de Pastas (resumo)
lib/
  screens/            // Telas do app
  models/             // Modelo Product
  services/           // Serviços Firebase
  main.dart           // Entrada principal

### Integração Firebase

- Autenticação (Firebase Auth)
- Firestore (coleções: produtos, categorias, usuarios)
- Push Notification (opcional)

📅 Painel Gerencial (React + Firebase)

- Funcionalidades
- Autenticação via Google restrita a e-mails autorizados
- Cadastro e edição de produtos
- Cadastro e edição de categorias
- Listagem de produtos e categorias com ações
- Menu lateral com navegação entre telas
- Layout responsivo com Tailwind CSS ou CSS customizado
### Tecnologias

React 19
- Firebase Auth + Firestore
- react-router-dom
- Lucide Icons (botões modernos)
- Deploy com Firebase Hosting

### Firebase Firestore - Estrutura de Dados
```json
categorias: [
  {
    id: "camisas",
    nome: "Camisas",
    icone: "shirt"
  }
]

produtos: [
  {
    nome: "Camisa Rubro-Negra",
    imagem: "https://...",
    url: "https://...",
    categoria: "Camisas",
    genero: "Masculino",
    tipo: "Adulto",
    criadoEm: timestamp
  }
]

admins: [
  {
    id: "admin@email.com"  // Verificação de acesso ao painel
  }
]
```

### ✨ Funcionalidades
- Filtros inteligentes no app e painel
- Grid responsivo de produtos na loja (Flutter)
- Armazenamento de sessão no LocalStorage (manter login mesmo com refresh)
- Login com conta Google
- Listagem de produtos em tempo real
- Filtros por categoria, gênero e tipo
- Exibição de imagens com fallback
- Abertura de links de compra em apps externos
- Layout moderno em **grid responsivo**

### 🗃️ Estrutura dos Dados no Firestore

```json
{
  "nome": "string",
  "url": "string",
  "imagem": "string",
  "categoria": "string",
  "genero": "string",
  "tipo": "string",
  "criadoEm": "timestamp"
}
```
### ✉️ Futuras melhorias
- Edição e exclusão no app Flutter (modo admin)
- Gerenciamento de usuários no painel
- Suporte a cupons de desconto ou promoções
- Upload de imagem via painel

### 💾 Deploy

-Painel Web
```json
npm run build
firebase deploy
```
### App Flutter
- Distribuição manual (APK) ou via Play Store/TestFlight
