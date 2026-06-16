import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sobre o Aplicativo"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Center(
            child: Column(
              children: [
                Icon(Icons.newspaper, size: 64, color: Colors.red), // Use as cores do seu app
                SizedBox(height: 12),
                Text(
                  "PheliFla",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  "Informativo Independente",
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          // ── SEÇÃO OBRIGATÓRIA: CONTATO DO DESENVOLVEDOR ──
          const Text(
            "Informações de Contato",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
          ),
          const SizedBox(height: 8),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.email),
                    title: Text("E-mail de Suporte"),
                    subtitle: Text("suporte.phelifla@gmail.com"), // ⚠️ COLOQUE SEU E-MAIL DO GOOGLE PLAY CONSOLE HERE
                  ),
                  ListTile(
                    leading: Icon(Icons.person),
                    title: Text("Desenvolvedor Responsável"),
                    subtitle: Text("PheliFla Dev Team"),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── SEÇÃO OBRIGATÓRIA PARA APPS DE NOTÍCIAS ──
          const Text(
            "Declaração de Conteúdo e Fontes",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
          ),
          const SizedBox(height: 8),
          Text(
            "O PheliFla é um aplicativo agregador de conteúdo de caráter estritamente informativo e independente sobre o Clube de Regatas do Flamengo.\n\n"
            "Esclarecemos que este aplicativo não possui vínculo oficial, associação, patrocínio ou autorização direta do Clube de Regatas do Flamengo ou de seus órgãos de imprensa.\n\n"
            "Todas as notícias, artigos e mídias exibidos são obtidos a partir de fontes de dados públicas e feeds de notícias abertos na internet. Os créditos e a autoria intelectual pertencem aos seus respectivos veículos e autores originais.",
            style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.grey),
            textAlign: TextAlign.justify,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}