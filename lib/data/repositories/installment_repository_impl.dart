import '../../domain/entities/installment.dart';
import '../../domain/repositories/installment_repository.dart';
import '../datasources/installment_datasource.dart';

final class InstallmentRepositoryImpl implements InstallmentRepository {
  const InstallmentRepositoryImpl(this.dataSource);
  final InstallmentDataSource dataSource;
  @override
  Future<List<Installment>> upcoming() async =>
      (await dataSource.upcoming()).map((model) => model.toEntity()).toList();
}
