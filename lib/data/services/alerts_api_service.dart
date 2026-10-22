/// Head-office JSON feed.
///
/// Unused this week. The UI talks to [AlertRepository]; swap
/// [InMemoryAlertRepository] for a network-backed implementation later.
class AlertsApiService {
  AlertsApiService({
    this.baseUrl = 'https://head-office.nour.example/v1/stock-alerts',
  });

  final String baseUrl;

  Future<List<Map<String, Object?>>> fetchFeed() {
    throw UnimplementedError(
      'Wire this to the head-office feed when the HTTP client is added.',
    );
  }
}
