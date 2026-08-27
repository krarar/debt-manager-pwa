import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/qisti_repository.dart';

abstract interface class NotificationService {
  Future<void> initialize();
  Future<void> schedule(String title, String body, DateTime at);
}

/// Coordinates persisted in-app notifications and guarantees idempotent
/// publication by notification id.
final class NotificationCenter {
  const NotificationCenter(this.repository);
  final QistiRepository repository;

  Future<AppNotification> publish(AppNotification notification) async {
    final existing = (await repository.notifications()).where(
      (item) => item.id == notification.id,
    );
    if (existing.isNotEmpty) return existing.first;
    await repository.saveNotification(notification);
    return notification;
  }
}

final class NoOpNotificationService implements NotificationService {
  const NoOpNotificationService();

  @override
  Future<void> initialize() async {}

  @override
  Future<void> schedule(String title, String body, DateTime at) async {}
}
