import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class NewsCard extends StatelessWidget {
  final String titulo;
  final String link;
  final String? imagem;

  const NewsCard({
    Key? key,
    required this.titulo,
    required this.link,
    this.imagem,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final uri = Uri.parse(link);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.only(bottom: 16),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            (imagem != null && imagem!.isNotEmpty)
                ? Image.network(
                  imagem!,
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset(
                      'assets/imagens/imagem_padrao.png',
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                    );
                  },
                )
                : Image.asset(
                  'assets/images/imagem_padrao.png',
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                titulo,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
