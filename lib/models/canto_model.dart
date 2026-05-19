// lib/models/canto_model.dart
class CantoModel {
  final String id;
  final String titulo;
  final String letra;
  final String categoria;
  final String audioUrl;

  CantoModel({
    required this.id,
    required this.titulo,
    required this.letra,
    required this.categoria,
    required this.audioUrl,
  });

  factory CantoModel.fromFirestore(String id, Map<String, dynamic> data) {
    return CantoModel(
      id: id,
      titulo: data['titulo'] ?? '',
      letra: data['letra'] ?? '',
      categoria: data['categoria'] ?? 'arquibancada',
      audioUrl: data['audioUrl'] ?? '',
    );
  }
}