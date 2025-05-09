class Game {
  final String league;
  final String homeTeam;
  final String awayTeam;
  final String homeBadge;
  final String awayBadge;
  final String date;
  final String time;
  final String venue;
  final int? homeScore;
  final int? awayScore;

  Game({
    required this.league,
    required this.homeTeam,
    required this.awayTeam,
    required this.homeBadge,
    required this.awayBadge,
    required this.date,
    required this.time,
    required this.venue,
    this.homeScore,
    this.awayScore,
  });

  factory Game.fromJson(Map<String, dynamic> json) {
    int? parseScore(dynamic value) {
      if (value is int) return value;
      if (value is String && value.isNotEmpty) return int.tryParse(value);
      return null;
    }

    return Game(
      league: json['strLeague'] ?? '',
      homeTeam: json['strHomeTeam'] ?? '',
      awayTeam: json['strAwayTeam'] ?? '',
      homeBadge: json['strHomeTeamBadge'] ?? '',
      awayBadge: json['strAwayTeamBadge'] ?? '',
      date: json['dateEvent'] ?? '',
      time: json['strTime'] ?? '',
      venue: json['strVenue'] ?? '',
      homeScore: parseScore(json['intHomeScore']),
      awayScore: parseScore(json['intAwayScore']),
    );
  }

  factory Game.fromApiFootballJson(Map<String, dynamic> json) {
    final fixture = json['fixture'] ?? {};
    final teams = json['teams'] ?? {};
    final goals = json['goals'] ?? {};
    final league = json['league'] ?? {};
    final venue = fixture['venue'] ?? {};

    String date = '';
    String time = '';

    try {
      final utcDateTime = DateTime.parse(fixture['date']).toUtc();
      // Brazil Time = UTC -3
      final brazilTime = utcDateTime.subtract(const Duration(hours: 3));
      date = brazilTime.toIso8601String().split('T')[0];
      time =
          '${brazilTime.hour.toString().padLeft(2, '0')}:${brazilTime.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      // fallback to empty if parse fails
    }

    return Game(
      league: league['name'] ?? '',
      homeTeam: teams['home']?['name'] ?? '',
      awayTeam: teams['away']?['name'] ?? '',
      homeBadge: teams['home']?['logo'] ?? '',
      awayBadge: teams['away']?['logo'] ?? '',
      date: date,
      time: time,
      venue: venue['name'] ?? '',
      homeScore: goals['home'] is int ? goals['home'] : null,
      awayScore: goals['away'] is int ? goals['away'] : null,
    );
  }
}
