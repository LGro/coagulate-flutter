import 'package:veilid/veilid.dart';
import 'veilid_init.dart';

Future<T> tableScope<T>(
    String name, Future<T> Function(VeilidTableDB tdb) callback,
    {int columnCount = 1}) async {
  final veilid = await eventualVeilid.future;
  VeilidTableDB tableDB = await veilid.openTableDB(name, columnCount);
  try {
    return await callback(tableDB);
  } finally {
    tableDB.close();
  }
}

Future<T> transactionScope<T>(
  VeilidTableDB tdb,
  Future<T> Function(VeilidTableDBTransaction tdbt) callback,
) async {
  VeilidTableDBTransaction tdbt = tdb.transact();
  try {
    final ret = await callback(tdbt);
    if (!tdbt.isDone()) {
      await tdbt.commit();
    }
    return ret;
  } finally {
    if (!tdbt.isDone()) {
      await tdbt.rollback();
    }
  }
}

abstract mixin class AsyncTableDBBacked<T> {
  String tableName();
  String tableKeyName();
  T valueFromJson(Object? obj);
  Object? valueToJson(T val);

  /// Load things from storage
  Future<T> load() async {
    final obj = await tableScope(tableName(), (tdb) async {
      final objJson = await tdb.loadStringJson(0, tableKeyName());
      return valueFromJson(objJson);
    });
    return obj;
  }

  /// Store things to storage
  Future<void> store(T obj) async {
    await tableScope(tableName(), (tdb) async {
      await tdb.storeStringJson(0, tableKeyName(), valueToJson(obj));
    });
  }
}
