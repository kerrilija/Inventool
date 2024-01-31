class SqlHistory {
  final int id;
  final String query;
  final String queryType;
  final DateTime timestamp;

  SqlHistory(
      {required this.id,
      required this.query,
      required this.queryType,
      required this.timestamp});

  factory SqlHistory.fromJson(Map<String, dynamic> json) {
    return SqlHistory(
      id: json['id'],
      query: json['query'],
      queryType: json['query_type'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
