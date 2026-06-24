import 'package:hive_flutter/hive_flutter.dart';

class HiveStorage {
  static const String transactionsBoxName = 'transactions';
  static const String goalsBoxName = 'goals';
  static const String debtsBoxName = 'debts';
  static const String equbsBoxName = 'equbs';
  static const String profileBoxName = 'profile';

  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Open boxes to make sure they are ready for use
    await Hive.openBox(transactionsBoxName);
    await Hive.openBox(goalsBoxName);
    await Hive.openBox(debtsBoxName);
    await Hive.openBox(equbsBoxName);
    await Hive.openBox(profileBoxName);
  }

  // Generic methods to read and write from Hive boxes
  static List<Map<String, dynamic>> getList(String boxName) {
    final box = Hive.box(boxName);
    final list = box.get('data', defaultValue: []);
    if (list is List) {
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  static Future<void> saveList(String boxName, List<Map<String, dynamic>> list) async {
    final box = Hive.box(boxName);
    await box.put('data', list);
  }

  static Map<String, dynamic>? getMap(String boxName, String key) {
    final box = Hive.box(boxName);
    final data = box.get(key);
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }

  static Future<void> saveMap(String boxName, String key, Map<String, dynamic> data) async {
    final box = Hive.box(boxName);
    await box.put(key, data);
  }

  static Future<void> clearAll() async {
    await Hive.box(transactionsBoxName).clear();
    await Hive.box(goalsBoxName).clear();
    await Hive.box(debtsBoxName).clear();
    await Hive.box(equbsBoxName).clear();
    await Hive.box(profileBoxName).clear();
  }
}
