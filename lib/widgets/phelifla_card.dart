import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class PheliFlaCard extends StatelessWidget {
  final String titulo;
  final String imagem;
  final VoidCallback onTap;

  const PheliFlaCard({
    Key? key,
    required this.titulo,
    required this.imagem,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imagem.isNotEmpty)
              CachedNetworkImage(
                imageUrl: imagem,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder:
                    (context, url) => Container(color: Colors.grey[200]),
                errorWidget:
                    (context, url, error) => const Icon(Icons.broken_image),
              )
            else
              Container(
                height: 180,
                width: double.infinity,
                color: Colors.grey[200],
                child: const Icon(
                  Icons.image_not_supported,
                  size: 48,
                  color: Colors.black26,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                titulo,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
