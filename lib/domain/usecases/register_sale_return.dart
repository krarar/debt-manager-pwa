import '../entities/sale_return.dart';
import '../repositories/qisti_repository.dart';

class RegisterSaleReturn {
  const RegisterSaleReturn(this.repository);
  final QistiRepository repository;

  Future<void> call(SaleReturn saleReturn) =>
      repository.registerReturn(saleReturn);
}
