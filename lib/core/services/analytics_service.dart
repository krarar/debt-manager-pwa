abstract interface class AnalyticsService {
  Future<void> track(String event, {Map<String, Object?> parameters});
}

final class NoOpAnalyticsService implements AnalyticsService {
  const NoOpAnalyticsService();

  @override
  Future<void> track(
    String event, {
    Map<String, Object?> parameters = const {},
  }) async {}
}
