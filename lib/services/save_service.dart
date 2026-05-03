import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/save_data.dart';

class SaveService {
  static const _key = 'roll_cliker_save_v1';

  Future<SaveData> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return SaveData();
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return SaveData.fromJson(json);
    } catch (_) {
      return SaveData();
    }
  }

  Future<void> save(SaveData data) async {
    final prefs = await SharedPreferences.getInstance();
    data.lastSavedAt = DateTime.now();
    await prefs.setString(_key, jsonEncode(data.toJson()));
  }

  Future<void> wipe() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
