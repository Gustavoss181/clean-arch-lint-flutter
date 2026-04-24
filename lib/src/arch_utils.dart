/// Utilitários para inspecionar a posição de um arquivo
/// dentro da estrutura de Clean Architecture por features.
library;

// ─── Camadas reconhecidas ─────────────────────────────────────────────────────

/// Camadas da Clean Architecture mapeadas na estrutura de pastas.
enum ArchLayer { domain, data, presentation }

// ─── Análise de paths ─────────────────────────────────────────────────────────

// Expressão regular aprimorada para garantir que a camada seja uma pasta exata
// Ex: features/auth/domain/ -> match
// Ex: features/auth/domain_models/ -> no match
final _layerPattern = RegExp(
  r'features/([^/]+)/(domain|data|presentation)(/|$)',
);

// Pega o nome da feature imediatamente após a pasta features/
final _featurePattern = RegExp(
  r'features/([^/]+)(/|$)',
);

/// Retorna a [ArchLayer] de um caminho de arquivo ABSOLUTO, ou null se o arquivo
/// não pertencer à estrutura features/<feature>/<layer>/.
ArchLayer? layerOf(String filePath) {
  final match = _layerPattern.firstMatch(_normalize(filePath));
  if (match == null) return null;
  return _parseLayer(match.group(2)!);
}

/// Retorna o nome da feature de um caminho de arquivo ABSOLUTO, ou null.
String? featureOf(String filePath) {
  final match = _featurePattern.firstMatch(_normalize(filePath));
  return match?.group(1);
}

// ─── Helpers privados ─────────────────────────────────────────────────────────

/// Normaliza as barras do caminho para funcionar no Windows, Mac e Linux
String _normalize(String path) => path.replaceAll(r'\', '/');

ArchLayer _parseLayer(String name) => switch (name) {
      'domain' => ArchLayer.domain,
      'data' => ArchLayer.data,
      'presentation' => ArchLayer.presentation,
      _ => throw ArgumentError('Camada desconhecida: $name'),
    };
