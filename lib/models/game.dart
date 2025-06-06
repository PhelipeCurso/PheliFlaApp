class Game {
  final int id;
  final String data;
  final String hora;
  final String local;
  final String adversario;
  final String competicao;
  final String placar;
  final String etapa;
  final String escudoAdversario;
  final String escudotime;

  Game({
    required this.id,
    required this.data,
    required this.hora,
    required this.local,
    required this.adversario,
    required this.competicao,
    required this.placar,
    required this.etapa,
    required this.escudoAdversario,
    required this.escudotime,
  });

  factory Game.fromJson(Map<String, dynamic> json) {
    final bool concluido = json['concluido'] == true;
    final int? golsFlamengo = json['gols_flamengo'];
    final int? golsAdversario = json['gols_adversario'];

    // Gera placar se o jogo estiver concluído
    final String placar =
        (concluido && golsFlamengo != null && golsAdversario != null)
            ? '$golsFlamengo x $golsAdversario'
            : 'A definir';

    // Usa etapa se existir, senão define uma padrão
    final String etapa = json['etapa']?.toString() ?? 'Fase única';

    return Game(
      id: json['id'],
      data: json['data'],
      hora: json['hora']?.toString() ?? '',
      local: json['local'],
      adversario: json['adversario'],
      competicao: json['competicao'],
      placar: placar,
      etapa: etapa,
      escudoAdversario: json['escudo_adversario'] ?? '',
      escudotime: json['escudo_time'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'data': data,
      'hora': hora,
      'local': local,
      'adversario': adversario,
      'competicao': competicao,
      'placar': placar,
      'etapa': etapa,
    };
  }
}
