class Game {
  final String id;
  final String adversario;
  final String competicao;
  final String data;
  final String hora;
  final String local;
  final String etapa;
  final String escudotime;
  final String escudoAdversario;
  final bool concluido;
  final int golsFlamengo;
  final int golsAdversario;

  Game({
    required this.id,
    required this.adversario,
    required this.competicao,
    required this.data,
    required this.hora,
    required this.local,
    required this.etapa,
    required this.escudotime,
    required this.escudoAdversario,
    required this.concluido,
    required this.golsFlamengo,
    required this.golsAdversario,
  });

  factory Game.fromFirestore(Map<String, dynamic> json, String id) {
  // Função auxiliar para garantir que o valor vire um inteiro
  int toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  return Game(
    id: id,
    adversario: json['adversario'] ?? '',
    competicao: json['competicao'] ?? '',
    data: json['data'] ?? '',
    hora: json['hora'] ?? '',
    local: json['local'] ?? '',
    etapa: json['etapa'] ?? '',
    escudotime: json['escudotime'] ?? '',
    escudoAdversario: json['escudo_adversario'] ?? '',
    concluido: json['concluido'] ?? false,
    // Usando a conversão segura para os gols
    golsFlamengo: toInt(json['gols_flamengo']),
    golsAdversario: toInt(json['gols_adversario']),
  );
}
}
