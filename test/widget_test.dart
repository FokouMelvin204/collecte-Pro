import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:collecte_pro/core/constants/app_strings.dart';
import 'package:collecte_pro/features/admin/providers/admin_provider.dart';
import 'package:collecte_pro/features/agent/providers/agent_provider.dart';
import 'package:collecte_pro/features/auth/providers/auth_provider.dart';
import 'package:collecte_pro/features/client/providers/client_provider.dart';
import 'package:collecte_pro/main.dart';

void main() {
  testWidgets('Collecte Pro affiche l’écran de connexion après vérification de session', (WidgetTester tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => AgentProvider()),
          ChangeNotifierProvider(create: (_) => ClientProvider()),
          ChangeNotifierProvider(create: (_) => AdminProvider()),
        ],
        child: const CollecteProApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text(AppStrings.appName), findsOneWidget);
  });
}
