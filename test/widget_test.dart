import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sign_speak_ai/src/app/sign_speak_app.dart';
import 'package:sign_speak_ai/src/services/sign_ai_service.dart';
import 'package:sign_speak_ai/src/state/sign_speak_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('Sign Speak AI dashboard smoke test', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          signAiServiceProvider.overrideWithValue(_InstantAiService()),
        ],
        child: const SignSpeakApp(),
      ),
    );

    expect(find.text('Sign Speak AI'), findsOneWidget);
    expect(find.text('Start Real-Time Translation'), findsOneWidget);
    expect(find.text('Practice With AI'), findsOneWidget);
  });
}

class _InstantAiService extends SignAiService {
  @override
  Future<void> loadModel() async {}
}
