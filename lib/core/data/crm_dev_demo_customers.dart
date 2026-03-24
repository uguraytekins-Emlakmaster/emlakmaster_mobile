import 'package:emlakmaster_mobile/shared/models/customer_models.dart';

/// Yalnızca [isDevMode] ve Firestore listesi boşken gösterilen örnek satırlar (üretimde kullanılmaz).
final List<CustomerEntity> crmDevDemoCustomers = [
  CustomerEntity(
    id: '__dev_demo_customer_1',
    fullName: 'Demo · Ayşe Yılmaz',
    primaryPhone: '+90 555 000 0001',
    email: 'demo.musteri@example.com',
    createdAt: DateTime(2026, 1, 10),
    updatedAt: DateTime(2026, 1, 15),
  ),
  CustomerEntity(
    id: '__dev_demo_customer_2',
    fullName: 'Demo · Mehmet Kaya',
    primaryPhone: '+90 555 000 0002',
    createdAt: DateTime(2026, 2),
    updatedAt: DateTime(2026, 2, 5),
  ),
];
