import '../entities/customer.dart';
import '../entities/installment.dart';
import '../entities/installment_plan.dart';
import '../entities/payment.dart';
import '../entities/receipt.dart';
import '../entities/app_notification.dart';
import '../entities/search_result.dart';
import '../entities/category.dart';
import '../entities/product.dart';
import '../entities/inventory_movement.dart';
import '../entities/sale.dart';
import '../entities/sale_item.dart';
import '../entities/sale_return.dart';

abstract interface class QistiRepository {
  Future<List<Customer>> customers({String query = ''});
  Future<Customer?> customer(String id);
  Future<void> saveCustomer(Customer customer);
  Future<void> deleteCustomer(String id);
  Future<List<InstallmentPlan>> plans({String? customerId});
  Future<InstallmentPlan?> plan(String id);
  Future<void> createPlan(InstallmentPlan plan);
  Future<void> updatePlan(InstallmentPlan plan);
  Future<void> deletePlan(String id);
  Future<List<Installment>> installments({String? planId});
  Future<List<Payment>> payments({String? planId});
  Future<List<Receipt>> receipts({String? paymentId});
  Future<Receipt?> receipt(String id);
  Future<List<SearchResult>> search(String query);
  Future<List<AppNotification>> notifications({bool unreadOnly = false});
  Future<void> saveNotification(AppNotification notification);
  Future<void> markNotificationRead(String id);
  Future<void> markAllNotificationsRead();
  Future<void> registerPayment(Payment payment);
  Future<Receipt> registerPaymentAtomic(Payment payment);
  Future<List<Category>> categories();
  Future<Category?> category(String id);
  Future<void> saveCategory(Category category);
  Future<void> deleteCategory(String id);
  Future<List<Product>> products({String query = '', String? categoryId});
  Future<Product?> product(String id);
  Future<void> saveProduct(Product product);
  Future<void> deleteProduct(String id);
  Future<List<InventoryMovement>> inventoryMovements({String? productId});
  Future<void> recordInventoryMovement(InventoryMovement movement);
  Future<List<Sale>> sales();
  Future<Sale?> sale(String id);
  Future<List<SaleItem>> saleItems(String saleId);
  Future<Sale> createSale(
    Sale sale,
    List<SaleItem> items, {
    int installmentCount = 1,
    RecurringPeriod recurringPeriod = RecurringPeriod.monthly,
    DateTime? installmentStartDate,
  });
  Future<List<SaleReturn>> returns({String? saleId});
  Future<void> registerReturn(SaleReturn saleReturn);
}
