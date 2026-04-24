import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/game.dart'; // Certifique-se de que o caminho para o seu modelo está correto

class GamesService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Busca os jogos filtrados por uma competição específica (ex: 'brasileirao')
  Stream<List<Game>> getGamesByCompetition(String competicao) {
    return _db
        .collection('jogos')
        .where('competicao', isEqualTo: competicao)
        .orderBy('data', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Game.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  /// Busca todos os jogos cadastrados no banco de dados, independente da competição
  Stream<List<Game>> getAllGames() {
    return _db
        .collection('jogos')
        .orderBy('data', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Game.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  /// Busca apenas os jogos que já foram concluídos (para uma aba de "Resultados")
  Stream<List<Game>> getCompletedGames() {
    return _db
        .collection('jogos')
        .where('concluido', isEqualTo: true)
        .orderBy('data', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Game.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  /// Busca apenas os jogos futuros (para uma aba de "Calendário" ou "Próximos Jogos")
  Stream<List<Game>> getUpcomingGames() {
    return _db
        .collection('jogos')
        .where('concluido', isEqualTo: false)
        .orderBy('data', descending: false) // Ordem crescente para mostrar o mais próximo primeiro
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Game.fromFirestore(doc.data(), doc.id))
            .toList());
  }
}