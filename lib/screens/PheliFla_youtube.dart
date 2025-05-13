import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class PheliFlaYoutube extends StatefulWidget {
  const PheliFlaYoutube({super.key});

  @override
  State<PheliFlaYoutube> createState() => _PheliFlaYoutubeState();
}

class _PheliFlaYoutubeState extends State<PheliFlaYoutube> {
  List<Map<String, dynamic>> _videos = [];

  final String apiKey = 'AIzaSyDLwWuCwjldALp5MZawMbhdhzC87V1ExpY';
  final String channelId = 'UCPs-fbgJUcvNu4fefuhbEdg';

  @override
  void initState() {
    super.initState();
    buscarVideosDoYoutube();
  }

  Future<void> buscarVideosDoYoutube() async {
    final url = Uri.parse(
      'https://www.googleapis.com/youtube/v3/search'
      '?part=snippet'
      '&channelId=$channelId'
      '&maxResults=10'
      '&order=date'
      '&type=video'
      '&key=$apiKey',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List;

        final videos =
            items.map((item) {
              final snippet = item['snippet'];
              final videoId = item['id']['videoId'];

              return {
                'titulo': snippet['title'],
                'imagem': snippet['thumbnails']['high']['url'],
                'link': 'https://www.youtube.com/watch?v=$videoId',
              };
            }).toList();

        setState(() {
          _videos = videos;
        });
      } else {
        print('Erro na API do YouTube: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro ao buscar vídeos do YouTube: $e');
    }
  }

  Future<void> _abrirLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      print('Não foi possível abrir o link: $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _videos.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _videos.length,
                itemBuilder: (context, index) {
                  final video = _videos[index];
                  return InkWell(
                    onTap: () => _abrirLink(video['link']!),
                    borderRadius: BorderRadius.circular(16),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      margin: const EdgeInsets.only(bottom: 16),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Image.network(
                            video['imagem']!,
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) =>
                                    const SizedBox(),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              video['titulo']!,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
