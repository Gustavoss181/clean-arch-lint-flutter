// ignore_for_file: prefer_single_quotes
import 'package:custom_lint_core/custom_lint_core.dart';
import 'package:test/test.dart';

import 'package:arch_lint/src/rules/domain_must_not_import_data.dart';

/// Testa a regra [DomainMustNotImportData] com o helper do custom_lint_core.
///
/// O testLint() compila o código em memória e roda o lint nele, retornando
/// os erros encontrados — sem precisar de um projeto Flutter real.
void main() {
  group('DomainMustNotImportData', () {
    final rule = DomainMustNotImportData();

    // ── Casos que DEVEM gerar erro ──────────────────────────────────────────

    test('detecta import relativo de data dentro de domain', () async {
      final result = await testLint(
        rule,
        // Simula: lib/features/auth/domain/usecases/login_usecase.dart
        path: 'lib/features/auth/domain/usecases/login_usecase.dart',
        code: '''
import '../../data/datasources/remote/auth_remote_datasource.dart';

class LoginUsecase {}
''',
      );

      expect(result, hasLength(1));
      expect(result.first.errorCode.name, 'domain_must_not_import_data');
    });

    test('detecta import de package de data dentro de domain', () async {
      final result = await testLint(
        rule,
        path: 'lib/features/auth/domain/usecases/login_usecase.dart',
        code: '''
import 'package:myapp/features/auth/data/dtos/login_response_dto.dart';

class LoginUsecase {}
''',
      );

      expect(result, hasLength(1));
    });

    test('detecta múltiplos imports proibidos', () async {
      final result = await testLint(
        rule,
        path: 'lib/features/auth/domain/usecases/login_usecase.dart',
        code: '''
import '../../data/datasources/remote/auth_remote_datasource.dart';
import '../../data/dtos/login_request_dto.dart';

class LoginUsecase {}
''',
      );

      expect(result, hasLength(2));
    });

    // ── Casos que NÃO devem gerar erro ──────────────────────────────────────

    test('permite import dentro do proprio domain', () async {
      final result = await testLint(
        rule,
        path: 'lib/features/auth/domain/usecases/login_usecase.dart',
        code: '''
import '../repositories/auth_repository.dart';
import '../entities/user_entity.dart';

class LoginUsecase {}
''',
      );

      expect(result, isEmpty);
    });

    test('permite import de core/', () async {
      final result = await testLint(
        rule,
        path: 'lib/features/auth/domain/usecases/login_usecase.dart',
        code: '''
import 'package:myapp/core/errors/failures.dart';

class LoginUsecase {}
''',
      );

      expect(result, isEmpty);
    });

    test('ignora arquivos fora de domain/', () async {
      // Um arquivo em data/ importando data/ é permitido
      final result = await testLint(
        rule,
        path: 'lib/features/auth/data/repositories/auth_repository_impl.dart',
        code: '''
import '../datasources/remote/auth_remote_datasource.dart';

class AuthRepositoryImpl {}
''',
      );

      expect(result, isEmpty);
    });

    test('ignora pacotes externos (dart:, flutter:, package: terceiros)', () async {
      final result = await testLint(
        rule,
        path: 'lib/features/auth/domain/usecases/login_usecase.dart',
        code: '''
import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class LoginUsecase {}
''',
      );

      expect(result, isEmpty);
    });
  });
}
