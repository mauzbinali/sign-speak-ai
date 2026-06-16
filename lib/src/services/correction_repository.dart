import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/sign_models.dart';

class CorrectionRepository {
  static const _correctionsKey = 'sign_speak_local_corrections';

  Future<List<SignCorrectionEntry>> load() async {
    final preferences = await SharedPreferences.getInstance();
    final rawCorrections =
        preferences.getStringList(_correctionsKey) ?? const [];
    return rawCorrections
        .map((raw) {
          try {
            return SignCorrectionEntry.fromJson(
              jsonDecode(raw) as Map<String, dynamic>,
            );
          } catch (_) {
            return null;
          }
        })
        .whereType<SignCorrectionEntry>()
        .where((entry) => entry.poseFeatures.length == 63)
        .toList();
  }

  Future<void> save(List<SignCorrectionEntry> corrections) async {
    final preferences = await SharedPreferences.getInstance();
    final serialized = corrections
        .map((entry) => jsonEncode(entry.toJson()))
        .toList(growable: false);
    await preferences.setStringList(_correctionsKey, serialized);
  }

  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_correctionsKey);
  }
}
