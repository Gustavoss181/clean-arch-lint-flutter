# arch_lint

Regras de lint customizadas para validar a [Clean Architecture](../architecture.md) do projeto.

Funciona com o [`custom_lint`](https://pub.dev/packages/custom_lint), rodando integrado
ao `dart analyze` e ao servidor de análise dos IDEs (VS Code, IntelliJ / Android Studio).

---

## Regras disponíveis

| Regra | Severidade | Descrição |
|---|---|---|
| `domain_must_not_import_data` | ERROR | `domain/` não pode importar de `data/` |
| `domain_must_not_import_presentation` | ERROR | `domain/` não pode importar de `presentation/` |
| `presentation_must_not_import_data` | ERROR | `presentation/` não pode importar de `data/` diretamente |
| `no_cross_feature_import` | WARNING | Uma feature não pode importar outra feature diretamente |

---

## Instalação

### 1. Referencie o pacote no `pubspec.yaml` do projeto

```yaml
# pubspec.yaml (projeto raiz)
dev_dependencies:
  custom_lint: ^0.6.0
  arch_lint:
    path: packages/arch_lint   # ou via git/pub
```

### 2. Ative o plugin no `analysis_options.yaml`

```yaml
# analysis_options.yaml (projeto raiz)
analyzer:
  plugins:
    - custom_lint

custom_lint:
  rules:
    - domain_must_not_import_data: true
    - domain_must_not_import_presentation: true
    - presentation_must_not_import_data: true
    - no_cross_feature_import: true
```

### 3. Execute a análise

```bash
# Análise normal (com lint integrado)
dart run custom_lint

# Ou via flutter
flutter analyze
```

---

## Uso no CI/CD

Adicione ao seu pipeline (GitHub Actions, Bitrise, Codemagic, etc.):

```yaml
# .github/workflows/ci.yml
- name: Arch lint
  run: dart run custom_lint --fatal-warnings
```

O `--fatal-warnings` garante que WARNINGs (como `no_cross_feature_import`)
também quebrem o pipeline.

---

## Adicionando novas regras

1. Crie um arquivo em `lib/src/rules/minha_regra.dart` estendendo `DartLintRule`
2. Registre a classe em `lib/arch_lint.dart` dentro do `getLintRules()`
3. Escreva os testes em `test/rules/minha_regra_test.dart`
4. Execute `dart test` para validar

---

## Rodando os testes do pacote

```bash
cd packages/arch_lint
dart test
```
