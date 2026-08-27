import '../entities/installment.dart';
import '../repositories/qisti_repository.dart';

final class GetUpcomingInstallments {
  const GetUpcomingInstallments(this.repository);
  final QistiRepository repository;
  Future<List<Installment>> call() async => (await repository.installments())
      .where((i) => i.status != InstallmentStatus.paid)
      .toList();
}
