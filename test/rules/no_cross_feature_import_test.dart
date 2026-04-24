// ignore_for_file: prefer_single_quotes
import 'package:custom_lint_core/custom_lint_core.dart';
import 'package:test/test.dart';

import 'package:arch_lint/src/rules/no_cross_feature_import.dart';

void main() {
  group('NoCrossFeatureImport', () {
    final rule = NoCrossFeatureImport();

    // ── Casos que DEVEM gerar aviso ─────────────────────────────────────────

    test('detecta import de outra feature via package:', () async {
      final result = await testLint(
        rule,
        path: 'lib/features/orders/presentation/screens/order_screen.dart',
        code: '''
import 'package:myapp/features/auth/domain/entities/user_entity.dart';

class OrderScreen {}
''',
      );

      expect(result, hasLength(1));
      expect(result.first.errorCode.name, 'no_cross_feature_import');
      // Verifica que a mensagem menciona as duas features
      expect(result.first.message, contains('orders'));
      expect(result.first.message, contains('auth'));
    });

    test('detecta cross-feature em camada domain', () async {
      final result = await testLint(
        rule,
        path: 'lib/features/orders/domain/usecases/place_order_usecase.dart',
        code: '''
import 'package:myapp/features/products/domain/entities/product_entity.dart';

class PlaceOrderUsecase {}
''',
      );

      expect(result, hasLength(1));
    });

    // ── Casos que NÃO devem gerar aviso ─────────────────────────────────────

    test('permite import dentro da mesma feature', () async {
      final result = await testLint(
        rule,
        path: 'lib/features/auth/presentation/screens/login_screen.dart',
        code: '''
import 'package:myapp/features/auth/domain/usecases/login_usecase.dart';
import '../cubits/auth_cubit.dart';

class LoginScreen {}
''',
      );

      expect(result, isEmpty);
    });

    test('permite import de shared/', () async {
      final result = await testLint(
        rule,
        path: 'lib/features/orders/presentation/screens/order_screen.dart',
        code: '''
import 'package:myapp/shared/widgets/custom_app_bar.dart';
import 'package:myapp/shared/design/tokens/colors.dart';

class OrderScreen {}
''',
      );

      expect(result, isEmpty);
    });

    test('permite import de core/', () async {
      final result = await testLint(
        rule,
        path: 'lib/features/orders/domain/usecases/place_order_usecase.dart',
        code: '''
import 'package:myapp/core/errors/failures.dart';

class PlaceOrderUsecase {}
''',
      );

      expect(result, isEmpty);
    });

    test('permite imports externos (pacotes pub.dev)', () async {
      final result = await testLint(
        rule,
        path: 'lib/features/auth/presentation/cubits/auth_cubit.dart',
        code: '''
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';

class AuthCubit {}
''',
      );

      expect(result, isEmpty);
    });

    test('ignora arquivos fora de features/', () async {
      final result = await testLint(
        rule,
        path: 'lib/shared/widgets/custom_app_bar.dart',
        code: '''
import 'package:myapp/features/auth/domain/entities/user_entity.dart';

class CustomAppBar {}
''',
      );

      // shared/ pode importar de features (é um aviso de design, não desta regra)
      expect(result, isEmpty);
    });
  });
}
