import '../entities/payment.dart';
import '../repositories/qisti_repository.dart';

final class RegisterPayment {
  const RegisterPayment(this.repository);
  final QistiRepository repository;
  Future<void> call(Payment payment) => repository.registerPayment(payment);
}
