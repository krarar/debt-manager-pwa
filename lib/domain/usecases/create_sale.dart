import '../entities/installment_plan.dart';
import '../entities/sale.dart';
import '../entities/sale_item.dart';
import '../repositories/qisti_repository.dart';

class CreateSale {
  const CreateSale(this.repository);
  final QistiRepository repository;

  Future<Sale> call(
    Sale sale,
    List<SaleItem> items, {
    int installmentCount = 1,
    RecurringPeriod recurringPeriod = RecurringPeriod.monthly,
    DateTime? installmentStartDate,
  }) => repository.createSale(
    sale,
    items,
    installmentCount: installmentCount,
    recurringPeriod: recurringPeriod,
    installmentStartDate: installmentStartDate,
  );
}
