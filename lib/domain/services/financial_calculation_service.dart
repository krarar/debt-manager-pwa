import '../entities/customer.dart';
import '../entities/installment.dart';
import '../entities/installment_plan.dart';
import '../entities/payment.dart';
import '../entities/product.dart';
import '../entities/sale.dart';

/// The single source of truth for the figures shown by the dashboard and
/// reports. Amounts are integer Iraqi dinars to avoid rounding errors.
class FinancialSummary {
  const FinancialSummary({
    required this.totalDebtIQD,
    required this.totalPaidIQD,
    required this.totalRemainingIQD,
    required this.todayDueIQD,
    required this.overdueIQD,
    required this.customerCount,
    required this.activePlans,
    required this.completedPlans,
    required this.dueTodayCount,
    required this.overdueCount,
    this.totalSalesIQD = 0,
    this.salesTodayIQD = 0,
    this.lowStockCount = 0,
  });

  final int totalDebtIQD;
  final int totalPaidIQD;
  final int totalRemainingIQD;
  final int todayDueIQD;
  final int overdueIQD;
  final int customerCount;
  final int activePlans;
  final int completedPlans;
  final int dueTodayCount;
  final int overdueCount;
  final int totalSalesIQD;
  final int salesTodayIQD;
  final int lowStockCount;
}

class FinancialCalculationService {
  const FinancialCalculationService();

  FinancialSummary summarize({
    required Iterable<Customer> customers,
    required Iterable<InstallmentPlan> plans,
    required Iterable<Installment> installments,
    required Iterable<Payment> payments,
    Iterable<Sale> sales = const [],
    Iterable<Product> products = const [],
    DateTime? now,
  }) {
    final date = now ?? DateTime.now();
    final debt = plans.fold<int>(0, (sum, plan) => sum + plan.totalAmountIQD);
    final paid = payments.fold<int>(
      0,
      (sum, payment) => sum + payment.amountIQD,
    );
    final today = installments.where(
      (item) => _sameDay(item.dueDate, date) && item.remainingIQD > 0,
    );
    final overdue = installments.where(
      (item) =>
          item.statusAt(date) == InstallmentStatus.overdue &&
          item.remainingIQD > 0,
    );
    final allSales = sales.toList(growable: false);
    return FinancialSummary(
      totalDebtIQD: debt,
      totalPaidIQD: paid,
      totalRemainingIQD: installments.fold(
        0,
        (sum, item) => sum + item.remainingIQD.clamp(0, item.amountIQD).toInt(),
      ),
      todayDueIQD: today.fold(
        0,
        (sum, item) => sum + item.remainingIQD.clamp(0, item.amountIQD),
      ),
      overdueIQD: overdue.fold(
        0,
        (sum, item) => sum + item.remainingIQD.clamp(0, item.amountIQD),
      ),
      customerCount: customers.length,
      activePlans: plans
          .where((plan) => plan.status == PlanStatus.active)
          .length,
      completedPlans: plans
          .where((plan) => plan.status == PlanStatus.completed)
          .length,
      dueTodayCount: today.length,
      overdueCount: overdue.length,
      totalSalesIQD: allSales.fold<int>(0, (sum, sale) => sum + sale.totalIQD),
      salesTodayIQD: allSales
          .where((sale) => _sameDay(sale.createdAt, date))
          .fold<int>(0, (sum, sale) => sum + sale.totalIQD),
      lowStockCount: products
          .where((product) => product.stockQuantity <= product.minimumStock)
          .length,
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
