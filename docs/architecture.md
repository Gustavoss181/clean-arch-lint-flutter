# Arquitetura — Especificação Formal (Clean Architecture + Features)

> **Propósito deste documento.** Esta é a fonte da verdade da arquitetura dos
> projetos Flutter do time. Ele serve a dois públicos ao mesmo tempo:
> a pessoa desenvolvedora (o "porquê" de cada regra) e o pacote de lint
> (`arch_lint`), que traduz cada regra **normativa** em verificação automática.
>
> Sempre que uma regra puder ser expressa como lint, ela está marcada com
> **`[lint: nome_da_regra]`**. Regras ainda não automatizadas estão marcadas
> com **`[manual]`** — são candidatas naturais a virar lint no futuro.
>
> Decisões que dependem de escolha do time (e que eu, ao formalizar, **não**
> podia cravar sozinho) estão marcadas com **`⚠️ DECISÃO PENDENTE`**.

---

## 1. Vocabulário e princípio único

A arquitetura tem **um** princípio do qual quase tudo deriva:

> **A dependência só aponta para dentro.** `presentation` → `domain` ← `data`.
> O `domain` é o centro e não conhece ninguém; `data` e `presentation` o
> conhecem, mas nunca um ao outro.

Se você memorizar só isso, acerta a maioria das decisões. As regras abaixo são
consequências desse princípio, não acréscimos a ele.

As três camadas:

| Camada | Natureza | Conhece | É conhecida por |
|---|---|---|---|
| **domain** | Dart puro, sem Flutter | ninguém | `data`, `presentation` |
| **data** | Infra (Dio, Drift, storage) | `domain` | ninguém |
| **presentation** | UI (Flutter, Bloc/Cubit) | `domain` | ninguém |

---

## 2. Estrutura de diretórios

O projeto tem quatro regiões de topo: `core/`, `shared/`, `features/` e os
arquivos de bootstrap na raiz de `lib/`.

```text
lib/
├── main.dart          # entrypoint
├── bootstrap.dart     # inicialização de serviços globais, observers
├── app.dart           # MaterialApp e configuração base
├── locator.dart       # injeção de dependência raiz (get_it/injectable)
│
├── core/              # fundacional, agnóstico de qualquer feature
├── shared/            # reutilizável entre features (inclui UI compartilhada)
└── features/          # funcionalidades de negócio
```

### 2.1 `core/` — fundação agnóstica

`core` não conhece nenhuma feature e não contém regra de negócio. É
infraestrutura transversal: configuração, rede, roteamento, serviços de baixo
nível, armazenamento, utilitários.

```text
core/
├── config/          # configuração de ambiente/app
├── errors/          # Exception e Failure base
├── network/         # Dio, DTOs de rede transversais, interceptors
│   ├── dtos/
│   └── interceptors/
├── pagination/      # contratos e helpers de paginação
├── routing/         # AppRouter, rotas base, redirect guard
├── services/        # serviços de baixo nível
│   ├── auth/        # ⚠️ ver §5.2
│   ├── location/
│   ├── session/     # session_service (ciclo de vida da sessão)
│   ├── snackbar/
│   └── sync/        # orquestração de sincronização
├── storage/         # shared_preferences, secure storage, Drift base
│   └── services/
└── utils/           # validators, error handlers, helpers puros
```

### 2.2 `shared/` — reutilizável entre features

`shared` guarda o que mais de uma feature usa. Diferente de `core`, `shared`
**pode** conter UI e até sub-features completas.

```text
shared/
├── data/            # tabelas, converters, extensions de dados compartilhados
│   ├── converters/
│   ├── extensions/
│   └── tables/
├── domain/          # enums e contratos de domínio compartilhados
│   └── enums/
├── design/          # design system: tema, tokens, mappers de estilo
│   ├── extensions/
│   ├── mappers/
│   ├── theme/
│   └── tokens/
├── presentation/    # UI compartilhada (widgets, screens, formatters)
│   ├── formatters/
│   ├── providers/
│   ├── screens/
│   └── widgets/
└── features/        # sub-features compartilhadas (ex.: map) — ver §5.1
    └── map/
        ├── data/
        ├── domain/
        └── presentation/
```

> **Nota de design.** `shared/features/<x>/` é uma decisão deliberada: quando
> uma feature (ex.: mapa) é usada por várias outras, ela vira uma feature
> compartilhada com suas próprias três camadas. Isso é legítimo, mas tem custo:
> a regra de "não importar cross-feature" precisa abrir exceção para
> `shared/features/` (ver §5.1). Use com parcimônia — cada feature promovida a
> `shared` é uma que todas as outras passam a poder acoplar.

### 2.3 `features/<feature>/` — funcionalidade de negócio

Toda feature segue a mesma tríade. Filhas dentro de cada camada são livres
(ex.: `usecases/params/`, `widgets/register/`), desde que a **raiz** da feature
contenha apenas as três camadas mais os arquivos de composição.

```text
features/<feature>/
├── data/
│   ├── datasources/
│   │   ├── local/           # Drift, prefs, secure storage
│   │   │   ├── converters/
│   │   │   └── tables/
│   │   └── remote/          # Dio → APIs externas
│   │       ├── dtos/
│   │       └── extensions/
│   ├── mappers/             # DTO/Companion ↔ Entity
│   └── repositories/        # *RepositoryImpl
│
├── domain/
│   ├── entities/            # *Entity
│   ├── enums/
│   ├── failures/            # Failures da feature
│   ├── repositories/        # contratos *Repository (abstratos)
│   └── usecases/            # *UseCase
│       └── params/          # objetos de parâmetro dos usecases
│
├── presentation/
│   ├── cubits/              # e/ou blocs/
│   ├── enums/
│   ├── extensions/
│   ├── formatters/
│   ├── screens/
│   ├── widgets/
│   └── routes.dart          # GoRouter da feature
│
└── <feature>_injections.dart  # DI da feature
```

**`[lint: feature_root_only_layers]`** `[manual]` — A raiz de uma feature só
pode conter as pastas `data/`, `domain/`, `presentation/` e arquivos soltos de
composição (`*_injections.dart`, `routes.dart`). Qualquer outra **pasta** na
raiz da feature é violação.

> ⚠️ **DECISÃO PENDENTE (P1).** O `<feature>_injections.dart` fica na raiz da
> feature (como no projeto de referência) ou dentro de uma pasta? E `routes.dart`
> fica na raiz ou em `presentation/`? As duas árvores divergem. Escolha um e a
> regra `feature_root_only_layers` passa a permitir exatamente esse conjunto.

---

## 3. Regras de dependência entre camadas

Estas são as regras que o pacote já cobre (ou quase). Todas derivam do princípio
do §1.

**`[lint: domain_must_not_import_data]`** — `domain` não importa `data`.
O domínio depende apenas de abstrações declaradas nele mesmo
(`domain/repositories/`). DTOs, datasources e `*RepositoryImpl` jamais vazam
para o domínio. **Severidade: ERROR.**

**`[lint: domain_must_not_import_presentation]`** — `domain` não importa
`presentation`. O domínio não conhece Flutter, widget, Cubit ou Bloc. Se
precisar de um contrato de UI (ex.: navegação), modele-o como interface no
`domain` (porta) e implemente na `presentation` (adaptador). **Severidade: ERROR.**

**`[lint: presentation_must_not_import_data]`** — `presentation` não importa
`data`. Telas e Cubits acessam dados **somente** por usecases do `domain`.
Nunca um datasource ou `RepositoryImpl` direto. **Severidade: ERROR.**

**`[lint: data_must_not_import_presentation]`** `[manual]` — `data` não importa
`presentation`. Simétrica à anterior; fecha o triângulo. **Ainda não existe
como regra** (as 4 atuais não cobrem este sentido). **Severidade sugerida: ERROR.**

> **Por que as três de camada são ERROR e não WARNING.** Cruzar uma fronteira de
> camada não é "cheiro", é quebra do invariante que torna o domínio testável e
> portável. Um ERROR barra o merge; é isso que queremos aqui. (Contraste com a
> regra de cross-feature abaixo — ver §5.1 ⚠️.)

---

## 4. Contratos de implementação (padrões de código)

Regras sobre *como* o código dentro de cada camada é escrito. Hoje são `[manual]`;
são o backlog natural de automação.

### 4.1 Repositórios e tratamento de erro

- **`[manual]`** `*RepositoryImpl` deve estender `SafeCall`, que mapeia
  `Exception` → `Failure`. Nenhuma exceção "vaza crua" de um repositório.
- **`[manual]`** Todo método público de repositório retorna
  `Either<Failure, T>` (fpdart). Para operações sem retorno, `Either<Failure, Unit>`
  — nunca `void`, nunca `Future<void>`.
- **`[manual]`** Contratos (`domain/repositories/*Repository`) retornam já os
  `Failure` mapeados — a interface não expõe exceções.

### 4.2 Usecases

- **`[lint: usecase_must_have_single_public_method]`** `[manual]` — Um `*UseCase`
  tem exatamente **um** método público, nomeado `call()`. Parâmetros complexos
  vão para um objeto em `usecases/params/`.

### 4.3 Mapeamento

- **`[manual]`** A conversão DTO ↔ Entity e Companion(Drift) ↔ Entity acontece
  **exclusivamente** em `data/mappers/`. Entities não conhecem DTOs; DTOs não
  conhecem Entities fora do mapper.

---

## 5. Regras entre features

### 5.1 Isolamento de features

**`[lint: no_cross_feature_import]`** — Uma feature não importa livremente de
outra. Mas o isolamento **não é absoluto** — e é aqui que a regra atual diverge
da intenção:

- **Permitido:** importar de `shared/` e `core/`.
- **Permitido:** importar de `shared/features/<x>/` (sub-features
  compartilhadas, ex.: `map`).
- **Permitido (com cautela):** importar **apenas** `domain/entities/` e
  `domain/usecases/` de outra feature — o "contrato público" de uma feature.
  Casos legítimos: `AppShell`, `Dashboard`, telas agregadoras.
- **Proibido:** importar `data/` ou `presentation/` de outra feature. Isso é
  acoplamento a detalhe de implementação, sempre.

> ⚠️ **DECISÃO PENDENTE (P2).** A regra `no_cross_feature_import` atual é
> `WARNING` **e** bloqueia *qualquer* import cruzado — ou seja, hoje ela está
> ao mesmo tempo **frouxa demais** (só avisa) e **rígida demais** (não conhece
> as exceções acima). Duas decisões acopladas:
> 1. **Severidade:** cruzar para `domain` de outra feature deveria ser
>    permitido (não avisar). Cruzar para `data`/`presentation` deveria ser
>    **ERROR**. A regra precisa olhar *qual camada* da outra feature está sendo
>    importada, não apenas *se* é outra feature.
> 2. Enquanto a regra não distingue camada, mantê-la em `WARNING` evita falso
>    bloqueio — mas aceite que ela está incompleta até lá.

### 5.2 Autenticação como exceção global

- **`[manual]`** O estado de autenticação (Bloc/serviço de auth) é a **única**
  exceção de acesso global entre features. Qualquer feature pode consumi-lo.
- **`[manual]`** Use com cautela: auth é a exceção, não a porta dos fundos para
  compartilhar estado. Se você sentir vontade de "só colocar mais uma coisa no
  auth para todo mundo acessar", provavelmente esse algo pertence a `shared/`.

> ⚠️ **DECISÃO PENDENTE (P3).** Onde exatamente mora o auth? O `architecture.md`
> de referência sugere `features/auth/`; o projeto atual tem `core/services/auth/`.
> São decisões diferentes: em `features/auth/`, auth é uma feature com a exceção
> global do §5.2; em `core/services/auth/`, é um serviço fundacional. Escolha
> um — a allowlist do lint de cross-feature depende disso.

---

## 6. Nomenclatura

Convenções de sufixo. Todas `[manual]` hoje; automatizáveis via análise de
declaração (não de import).

| Elemento | Localização | Sufixo obrigatório |
|---|---|---|
| Datasource remoto | `data/datasources/remote/` | `RemoteDataSource` |
| Datasource local | `data/datasources/local/` | `LocalDataSource` |
| Tabela (Drift) | `.../local/tables/` | `Table` |
| DTO de requisição | `.../remote/dtos/` | `RequestDTO` |
| DTO de resposta | `.../remote/dtos/` | `ResponseDTO` |
| Implementação de repositório | `data/repositories/` | `RepositoryImpl` |
| Entidade de domínio | `domain/entities/` | `Entity` |
| Contrato de repositório | `domain/repositories/` | `Repository` |
| Caso de uso | `domain/usecases/` | `UseCase` |

> **Nota.** Nomenclatura é a família de regras mais barata de automatizar depois
> das de dependência, porque cada uma é local (olha uma declaração de classe e
> sua pasta) e não precisa resolver o grafo de imports. Ver §8.

---

## 7. Estado e navegação

- Gerência de estado: **Bloc** ou **Cubit** por feature, em
  `presentation/cubits|blocs/`.
- Navegação: **Navigation 2.0** via **GoRouter**; rotas da feature em
  `presentation/routes.dart`, compostas pelo `AppRouter` em `core/routing/`.

> ⚠️ **DECISÃO PENDENTE (P4).** O `shared/features/map/presentation/` usa
> `controllers/` em vez de `cubits/`/`blocs/`. Isso é exceção consciente (o mapa
> tem um modelo de estado próprio) ou inconsistência a corrigir? Se for exceção,
> documente-a aqui explicitamente; se não, alinhe à convenção Bloc/Cubit. Não
> automatize "presentation deve ter cubits/blocs" até resolver isto.

---

## 8. Roadmap de automação (para o pacote `arch_lint`)

Ordem recomendada, com justificativa:

1. **Corrigir a resolução de import das 4 regras existentes.** Elas dependem do
   caminho absoluto do arquivo importado; enquanto usarem o identificador da
   biblioteca em vez do `source`/`fullName` resolvido, imports **relativos**
   podem passar despercebidos. Sem esta base, nenhuma regra de dependência é
   confiável. *(Fundação — antes de tudo.)*
2. **`data_must_not_import_presentation`** — completa o triângulo de camadas.
3. **Refinar `no_cross_feature_import`** — distinguir a camada importada da
   outra feature (§5.1 P2) e adicionar a allowlist (`shared/features/`, auth).
4. **Família de nomenclatura (§6)** — barata, local, alto valor no dia a dia.
5. **Contratos de implementação (§4)** — `usecase` de método único, retorno
   `Either`, `SafeCall`. Mais difícil (análise de assinatura/herança).

---

### Legenda

- **`[lint: x]`** — regra normativa que o `arch_lint` implementa ou deve implementar.
- **`[manual]`** — regra em vigor, ainda verificada por revisão humana.
- **⚠️ DECISÃO PENDENTE** — ponto que exige escolha do time antes de virar regra.
