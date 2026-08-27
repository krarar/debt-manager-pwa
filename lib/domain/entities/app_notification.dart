enum NotificationType {
  dueToday,
  overdue,
  paymentRecorded,
  paymentReceived,
  planCompleted,
  backupSuccess,
  backupFailed,
  system,
}

extension NotificationTypeLabel on NotificationType {
  String get key => name;
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.relatedId,
    required this.createdAt,
    this.amountIQD,
    this.isRead = false,
  });

  final String id;
  final NotificationType type;
  final String relatedId;
  final DateTime createdAt;
  final int? amountIQD;
  final bool isRead;

  AppNotification copyWith({bool? isRead}) => AppNotification(
    id: id,
    type: type,
    relatedId: relatedId,
    createdAt: createdAt,
    amountIQD: amountIQD,
    isRead: isRead ?? this.isRead,
  );
}
