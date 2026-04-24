import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../arch_utils.dart';

/// Garante que nenhum arquivo de `presentation` importe diretamente de `data`.
///
/// Screens e widgets não devem conhecer datasources, DTOs ou implementações
/// de repositório. O acesso a dados deve fluir exclusivamente por usecases
/// da camada `domain`, orquestrados por Cubits/Blocs na `presentation`.
///
/// ✅ Permitido
/// ```dart
/// // features/auth/presentation/cubits/auth_cubit.dart
/// import '../../domain/usecases/login_usecase.dart';
/// import '../../domain/entities/user_entity.dart';
/// ```
///
/// ❌ Violação
/// ```dart
/// // features/auth/presentation/screens/login_screen.dart
/// import '../../data/datasources/remote/auth_remote_datasource.dart';
/// ```
class PresentationMustNotImportData extends DartLintRule {
  const PresentationMustNotImportData() : super(code: _code);

  static const _code = LintCode(
    name: 'presentation_must_not_import_data',
    problemMessage:
        'A camada "presentation" não pode importar da camada "data".\n'
        'Acesse dados exclusivamente por usecases do "domain".',
    correctionMessage:
        'Remova o import. Injete o usecase correspondente no Cubit/Bloc '
        'e acesse os dados através dele.',
    errorSeverity: DiagnosticSeverity.ERROR,
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

      if (layerOf(currentFile) != ArchLayer.presentation) return;

      final importedFileAbsolutePath =
          node.libraryImport?.importedLibrary?.identifier;
      if (importedFileAbsolutePath == null) return;

      if (layerOf(importedFileAbsolutePath) == ArchLayer.data) {
        reporter.atNode(node, _code);
      }
    });
  }
}
