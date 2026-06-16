import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/sign_models.dart';

class HistoryRepository {
  static const _historyKey = 'sign_speak_translation_history';

  Future<List<TranslationHistoryEntry>> load() async {
    final preferences = await SharedPreferences.getInstance();
    final rawHistory = preferences.getStringList(_historyKey) ?? const [];
    return rawHistory
        .map((raw) {
          try {
            return TranslationHistoryEntry.fromJson(
              jsonDecode(raw) as Map<String, dynamic>,
            );
          } catch (_) {
            return null;
          }
        })
        .whereType<TranslationHistoryEntry>()
        .toList();
  }

  Future<void> save(List<TranslationHistoryEntry> history) async {
    final preferences = await SharedPreferences.getInstance();
    final serialized = history
        .map((entry) => jsonEncode(entry.toJson()))
        .toList(growable: false);
    await preferences.setStringList(_historyKey, serialized);
  }

  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_historyKey);
  }
}
