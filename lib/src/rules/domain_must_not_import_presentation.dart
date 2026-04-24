import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../arch_utils.dart';

/// Garante que nenhum arquivo da camada `domain` importe algo de `presentation`.
///
/// O domínio não deve ter qualquer conhecimento da UI — nem widgets, nem
/// Cubits, nem Blocs. Essa separação é o que permite testar o domínio
/// isoladamente e reutilizá-lo em diferentes plataformas (mobile, web, etc).
///
/// ✅ Permitido
/// ```dart
/// // features/auth/domain/usecases/login_usecase.dart
/// import '../repositories/auth_repository.dart';
/// ```
///
/// ❌ Violação
/// ```dart
/// // features/auth/domain/usecases/login_usecase.dart
/// import '../../presentation/cubits/auth_cubit.dart';
/// ```
class DomainMustNotImportPresentation extends DartLintRule {
  const DomainMustNotImportPresentation() : super(code: _code);

  static const _code = LintCode(
    name: 'domain_must_not_import_presentation',
    problemMessage:
        'A camada "domain" não pode importar da camada "presentation".\n'
        'O domínio é puro Dart e não pode conhecer detalhes de UI.',
    correctionMessage:
        'Remova o import. Se precisar de um callback ou contrato de UI, '
        'modele-o como uma interface em domain/ (ex: NavigationPort).',
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

      // Só nos interessa arquivos dentro de domain/
      if (layerOf(currentFile) != ArchLayer.domain) return;

      // NOVO: Pede ao analyzer o elemento resolvido desse import.
      // Isso devolve o caminho absoluto do arquivo no sistema, resolvendo ../../ etc.
      // final importedFileAbsolutePath =
      //     node.element?.importedLibrary?.source.fullName;
      final importedFileAbsolutePath =
          node.libraryImport?.importedLibrary?.identifier;

      // Pode ser null se o arquivo não existir ou for uma biblioteca core (ex: dart:core)
      if (importedFileAbsolutePath == null) return;

      // NOVO: Verifica se o arquivo IMPORTADO pertence à camada data
      if (layerOf(importedFileAbsolutePath) == ArchLayer.presentation) {
        reporter.atNode(node, _code);
      }
    });
  }
}
