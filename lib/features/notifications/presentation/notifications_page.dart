import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/localization/app_localizations_extension.dart';
import '../../../domain/entities/app_notification.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.notifications,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    await ref
                        .read(repositoryProvider)
                        .markAllNotificationsRead();
                    ref.invalidate(notificationsProvider);
                    ref.invalidate(unreadNotificationsProvider);
                  },
                  child: Text(context.l10n.markAllRead),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: notifications.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text(error.toString())),
                data: (items) => items.isEmpty
                    ? Center(child: Text(context.l10n.noNotifications))
                    : ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, index) {
                          final item = items[index];
                          return Card(
                            color: item.isRead
                                ? null
                                : Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer,
                            child: ListTile(
                              leading: Icon(_icon(item.type)),
                              title: Text(_title(context, item.type)),
                              subtitle: Text(
                                item.amountIQD == null
                                    ? item.createdAt
                                          .toLocal()
                                          .toString()
                                          .split(' ')
                                          .first
                                    : '${item.amountIQD} ${context.l10n.currency}',
                              ),
                              trailing: item.isRead
                                  ? null
                                  : IconButton(
                                      tooltip: context.l10n.markRead,
                                      icon: const Icon(Icons.done),
                                      onPressed: () async {
                                        await ref
                                            .read(repositoryProvider)
                                            .markNotificationRead(item.id);
                                        ref.invalidate(notificationsProvider);
                                        ref.invalidate(
                                          unreadNotificationsProvider,
                                        );
                                      },
                                    ),
                              onTap: () async {
                                await ref
                                    .read(repositoryProvider)
                                    .markNotificationRead(item.id);
                                ref.invalidate(notificationsProvider);
                                ref.invalidate(unreadNotificationsProvider);
                                if (context.mounted) {
                                  context.push(_route(item.type));
                                }
                              },
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _icon(NotificationType type) => switch (type) {
    NotificationType.dueToday => Icons.today_outlined,
    NotificationType.overdue => Icons.warning_amber_outlined,
    NotificationType.paymentRecorded => Icons.payments_outlined,
    NotificationType.paymentReceived => Icons.payments_outlined,
    NotificationType.planCompleted => Icons.task_alt_outlined,
    NotificationType.backupSuccess => Icons.cloud_done_outlined,
    NotificationType.backupFailed => Icons.error_outline,
    NotificationType.system => Icons.info_outline,
  };

  String _title(BuildContext context, NotificationType type) => switch (type) {
    NotificationType.dueToday => context.l10n.dueInstallmentNotification,
    NotificationType.overdue => context.l10n.overdueInstallmentNotification,
    NotificationType.paymentRecorded =>
      context.l10n.paymentRecordedNotification,
    NotificationType.paymentReceived =>
      context.l10n.paymentRecordedNotification,
    NotificationType.planCompleted => context.l10n.planCompletedNotification,
    NotificationType.backupSuccess => context.l10n.backupSaved,
    NotificationType.backupFailed => context.l10n.backupFailed,
    NotificationType.system => context.l10n.systemNotification,
  };

  String _route(NotificationType type) =>
      type == NotificationType.paymentRecorded ||
          type == NotificationType.paymentReceived
      ? '/payments'
      : type == NotificationType.backupSuccess ||
            type == NotificationType.backupFailed
      ? '/backup'
      : '/installments';
}
