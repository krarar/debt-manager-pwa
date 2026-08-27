import '../models/installment_model.dart';

abstract interface class InstallmentDataSource {
  Future<List<InstallmentModel>> upcoming();
}

final class MockInstallmentDataSource implements InstallmentDataSource {
  @override
  Future<List<InstallmentModel>> upcoming() async => const [];
}
