// Web-compatible fallback for IsarService
// Since Isar doesn't support web, we'll use a simple in-memory storage

class IsarService {
  static IsarService? _instance;
  static IsarService get instance => _instance ??= IsarService._internal();
  IsarService._internal();

  // Mock database for web compatibility
  Future<MockIsar> get database async {
    return MockIsar();
  }

  Future<bool> get isOnline async {
    // Always assume online for web
    return true;
  }

  Future<List<T>> getAll<T>(MockCollection<T> collection) async {
    return collection.getAll();
  }

  Future<T> create<T>(
    T entity, {
    required String tableName,
    required String Function(T) getId,
    required Map<String, dynamic> Function(T) toJson,
  }) async {
    // For web, just return the entity (would sync directly to Supabase)
    return entity;
  }

  Future<T> update<T>(
    T entity, {
    required String tableName,
    required String Function(T) getId,
    required Map<String, dynamic> Function(T) toJson,
  }) async {
    // For web, just return the entity (would sync directly to Supabase)
    return entity;
  }

  Future<void> delete<T>(
    String id, {
    required String tableName,
    required MockCollection<T> collection,
  }) async {
    // For web, would delete directly from Supabase
  }
}

// Mock classes for web compatibility
class MockIsar {
  final isarUserProfiles = MockCollection<dynamic>();
  final isarSimCardRecords = MockCollection<dynamic>();
  final isarFinancialAccountRecords = MockCollection<dynamic>();
  final isarTransactionRecords = MockCollection<dynamic>();
  final isarFriendRecords = MockCollection<dynamic>();
  final isarLoanDebtItems = MockCollection<dynamic>();
  final isarLoanDebtPayments = MockCollection<dynamic>();
  final isarSyncQueues = MockCollection<dynamic>();

  Future<void> writeTxn(Future<void> Function() callback) async {
    await callback();
  }
}

class MockCollection<T> {
  final List<T> _items = [];

  List<T> getAll() => _items;

  MockQueryBuilder<T> where() => MockQueryBuilder<T>(_items);

  Future<void> put(T item) async {
    _items.add(item);
  }
}

class MockQueryBuilder<T> {
  final List<T> _items;
  MockQueryBuilder(this._items);

  MockQueryBuilder<T> recordIdEqualTo(String id) => this;
  MockQueryBuilder<T> userIdEqualTo(String id) => this;
  MockQueryBuilder<T> phoneNumberEqualTo(String phone) => this;
  MockQueryBuilder<T> linkedSimIdEqualTo(String id) => this;
  MockQueryBuilder<T> and() => this;

  Future<T?> findFirst() async => _items.isNotEmpty ? _items.first : null;
  Future<List<T>> findAll() async => _items;
}