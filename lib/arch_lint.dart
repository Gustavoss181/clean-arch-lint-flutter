/// Pacote de lint para validar a Clean Architecture do projeto.
///
/// Registra todas as regras customizadas no servidor de análise do Dart.
/// O custom_lint descobre este plugin via `pubspec.yaml` do projeto raiz.
library arch_lint;

import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'src/rules/domain_must_not_import_data.dart';
import 'src/rules/domain_must_not_import_presentation.dart';
import 'src/rules/no_cross_feature_import.dart';
import 'src/rules/presentation_must_not_import_data.dart';

/// Ponto de entrada obrigatório reconhecido pelo custom_lint_builder.
PluginBase createPlugin() => _ArchLintPlugin();

class _ArchLintPlugin extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
        DomainMustNotImportData(),
        DomainMustNotImportPresentation(),
        PresentationMustNotImportData(),
        NoCrossFeatureImport(),
      ];
}
