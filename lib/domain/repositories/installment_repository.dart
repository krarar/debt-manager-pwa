import '../entities/installment.dart';

/// Compatibility boundary for consumers of the original stage-one API.
abstract interface class InstallmentRepository {
  Future<List<Installment>> upcoming();
}
