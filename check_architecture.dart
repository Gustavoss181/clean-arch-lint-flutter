/// Validador de Arquitetura — Clean Architecture (Flutter)
///
/// Execute na raiz do projeto:
///   dart run check_architecture.dart
///
/// Regras validadas:
///   1. domain  → não pode importar data nem presentation
///   2. data    → não pode importar presentation
///   3. presentation → não pode importar data diretamente
///   4. Uma feature não pode importar outra feature diretamente
///      (deve usar shared/ ou core/)

import 'dart:io';

// ─── Configuração ────────────────────────────────────────────────────────────

const String libRoot = 'lib';

/// Regras de dependência proibidas.
/// Cada entrada: { camada de origem → lista de camadas que ela NÃO pode importar }
const Map<String, List<String>> forbiddenDeps = {
  'domain': ['data', 'presentation'],
  'data': ['presentation'],
  'presentation': ['data'],
};

// ─── Modelo ──────────────────────────────────────────────────────────────────

class Violation {
  final String file;
  final int line;
  final String importPath;
  final String rule;

  Violation({
    required this.file,
    required this.line,
    required this.importPath,
    required this.rule,
  });

  @override
  String toString() =>
      '  [$line] $importPath\n'
      '         Regra: $rule';
}

// ─── Lógica principal ─────────────────────────────────────────────────────────

void main() {
  final libDir = Directory(libRoot);

  if (!libDir.existsSync()) {
    stderr.writeln('❌  Diretório "$libRoot" não encontrado. '
        'Execute na raiz do projeto Flutter.');
    exit(1);
  }

  final dartFiles = libDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  final List<Violation> violations = [];

  for (final file in dartFiles) {
    final relativePath = _normalize(file.path);
    final lines = file.readAsLinesSync();

    for (var i = 0; i < lines.length; i++) {
      final raw = lines[i].trim();
      if (!raw.startsWith("import '") && !raw.startsWith('import "')) {
        continue;
      }

      final importPath = _extractImportPath(raw);
      if (importPath == null) continue;

      // ── Regra 1-3: dependências entre camadas ──
      final originLayer = _layerOf(relativePath);
      if (originLayer != null) {
        final forbidden = forbiddenDeps[originLayer] ?? [];
        for (final forbiddenLayer in forbidden) {
          if (_importReachesLayer(importPath, forbiddenLayer)) {
            violations.add(Violation(
              file: relativePath,
              line: i + 1,
              importPath: importPath,
              rule:
                  '"$originLayer" não pode depender de "$forbiddenLayer"',
            ));
          }
        }
      }

      // ── Regra 4: cross-feature imports ──
      final originFeature = _featureOf(relativePath);
      final importFeature = _featureOfImport(importPath);

      if (originFeature != null &&
          importFeature != null &&
          originFeature != importFeature) {
        violations.add(Violation(
          file: relativePath,
          line: i + 1,
          importPath: importPath,
          rule: 'feature "$originFeature" não pode importar '
              'feature "$importFeature" diretamente. '
              'Use shared/ ou core/',
        ));
      }
    }
  }

  // ─── Relatório ────────────────────────────────────────────────────────────
  _printReport(violations, dartFiles.length);
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

String _normalize(String path) =>
    path.replaceAll(r'\', '/').replaceAll('//', '/');

String? _extractImportPath(String line) {
  final match = RegExp(r'''import\s+['"]([^'"]+)['"]''').firstMatch(line);
  return match?.group(1);
}

/// Retorna a camada Clean Architecture do arquivo, se ele estiver dentro
/// de features/.
String? _layerOf(String path) {
  final re = RegExp(r'features/[^/]+/(domain|data|presentation)/');
  final m = re.firstMatch(path);
  return m?.group(1);
}

/// Verifica se um import aponta para uma camada específica dentro de features/.
bool _importReachesLayer(String importPath, String layer) {
  // Imports relativos: ../data/... ou ../../data/...
  if (importPath.startsWith('.')) {
    return importPath.contains('/$layer/') || importPath.contains('\\$layer\\');
  }
  // Imports de package: package:app/features/xxx/data/...
  return importPath.contains('/features/') &&
      (importPath.contains('/$layer/') || importPath.endsWith('/$layer'));
}

/// Retorna o nome da feature do arquivo (ex: "auth"), ou null se não for
/// uma feature.
String? _featureOf(String path) {
  final re = RegExp(r'features/([^/]+)/');
  final m = re.firstMatch(path);
  return m?.group(1);
}

/// Retorna a feature referenciada por um import de package, se houver.
String? _featureOfImport(String importPath) {
  if (importPath.startsWith('.')) return null; // relativo: ignora
  final re = RegExp(r'features/([^/]+)/');
  final m = re.firstMatch(importPath);
  return m?.group(1);
}

void _printReport(List<Violation> violations, int totalFiles) {
  final sep = '─' * 70;

  print('\n$sep');
  print(' 🏗   Validação de Arquitetura — Clean Architecture');
  print(sep);
  print(' Arquivos analisados: $totalFiles');

  if (violations.isEmpty) {
    print('\n ✅  Nenhuma violação encontrada. Arquitetura íntegra!\n');
    print(sep);
    return;
  }

  // Agrupa por arquivo
  final byFile = <String, List<Violation>>{};
  for (final v in violations) {
    byFile.putIfAbsent(v.file, () => []).add(v);
  }

  print(' ❌  ${violations.length} violação(ões) em ${byFile.length} arquivo(s)\n');

  var fileIdx = 1;
  for (final entry in byFile.entries) {
    print(' ${fileIdx++}. ${entry.key}');
    for (final v in entry.value) {
      print(v);
    }
    print('');
  }

  print(sep);
  print(' Corrija as violações acima para manter a integridade arquitetural.');
  print('$sep\n');

  // Sai com código de erro para facilitar uso em CI
  exit(1);
}
