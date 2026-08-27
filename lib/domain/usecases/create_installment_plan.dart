import '../entities/installment_plan.dart';
import '../repositories/qisti_repository.dart';

final class CreateInstallmentPlan {
  const CreateInstallmentPlan(this.repository);
  final QistiRepository repository;
  Future<void> call(InstallmentPlan plan) => repository.createPlan(plan);
}
