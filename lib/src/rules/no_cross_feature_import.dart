import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../arch_utils.dart';

/// Garante que features não importem umas das outras diretamente.
///
/// O acoplamento direto entre features cria dependências circulares latentes
/// e dificulta refatorações. Código compartilhado deve viver em `shared/`
/// ou `core/`, nunca diretamente numa feature.
///
/// ✅ Permitido
/// ```dart
/// // features/orders/presentation/screens/order_screen.dart
/// import 'package:app/shared/widgets/custom_app_bar.dart';
/// import 'package:app/core/routing/app_router.dart';
/// import '../domain/usecases/place_order_usecase.dart'; // mesma feature
/// ```
///
/// ❌ Violação
/// ```dart
/// // features/orders/presentation/screens/order_screen.dart
/// import 'package:app/features/auth/domain/entities/user_entity.dart';
/// //                         ^^^^ outra feature
/// ```
///
/// 💡 Solução recomendada
/// Mova `user_entity.dart` para `shared/` se ela for realmente compartilhada,
/// ou passe o dado necessário como parâmetro para a feature `orders`.
class NoCrossFeatureImport extends DartLintRule {
  const NoCrossFeatureImport() : super(code: _code);

  static const _code = LintCode(
    name: 'no_cross_feature_import',
    problemMessage:
        'A feature "{0}" não pode importar diretamente da feature "{1}".\n'
        'Features devem ser independentes entre si.',
    correctionMessage:
        'Mova o código compartilhado para shared/ ou core/, '
        'ou passe os dados necessários via parâmetros / injeção de dependência.',
    errorSeverity: DiagnosticSeverity.WARNING,
    url: 'https://github.com/seu-org/seu-projeto/blob/main/architecture.md',
  );

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addImportDirective((ImportDirective node) {
      final currentFile = resolver.path;

      final originFeature = featureOf(currentFile);
      if (originFeature == null) return; // arquivo fora de features/

      final importedFileAbsolutePath =
          node.libraryImport?.importedLibrary?.identifier;
      if (importedFileAbsolutePath == null) return;

      final importedFeature = featureOf(importedFileAbsolutePath);
      if (importedFeature == null) return; // import para fora de features/

      if (originFeature != importedFeature) {
        reporter.atNode(
          node,
          _code,
          arguments: [originFeature, importedFeature],
        );
      }
    });
  }
}
