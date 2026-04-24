import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../arch_utils.dart';

/// Garante que nenhum arquivo da camada `domain` importe algo da camada `data`.
///
/// Na Clean Architecture, `domain` é o núcleo puro da aplicação e não pode
/// conhecer detalhes de infraestrutura. DTOs, datasources e implementações
/// de repositório pertencem a `data` e jamais devem vazar para o domínio.
///
/// ✅ Permitido
/// ```dart
/// // features/auth/domain/usecases/login_usecase.dart
/// import '../repositories/auth_repository.dart'; // contrato do domínio
/// import '../entities/user_entity.dart';
/// ```
///
/// ❌ Violação
/// ```dart
/// // features/auth/domain/usecases/login_usecase.dart
/// import '../../data/datasources/remote/auth_remote_datasource.dart';
/// import '../../data/dtos/login_response_dto.dart';
/// ```
class DomainMustNotImportData extends DartLintRule {
  const DomainMustNotImportData() : super(code: _code);

  static const _code = LintCode(
    name: 'domain_must_not_import_data',
    problemMessage: 'A camada "domain" não pode importar da camada "data".\n'
        'O domínio deve depender apenas de abstrações definidas em domain/.',
    correctionMessage:
        'Remova o import. Se precisar de um contrato, declare-o em '
        'domain/repositories/ ou domain/datasources/ como interface.',
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
      // O caminho absoluto do arquivo que está sendo analisado agora
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
      if (layerOf(importedFileAbsolutePath) == ArchLayer.data) {
        reporter.atNode(node, _code);
      }
    });
  }
}
