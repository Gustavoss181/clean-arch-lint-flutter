**Regras da Clean Architecture:**

- Features:
    - Domain não pode depender de Data ou Presentation
    - Presentation não pode depender de Data
    - Data não pode depender de Presentation
    - Uma Feature pode acessar apenas UseCases e Entities de outras Features (casos como AppShell, Dashboard, etc)
    - em data/datasources/ a pasta remote/ deve ter seus DTOs e a pasta local/ suas Tables
    - A conversão entre DTOs, Companions (Drift) e Entities deve ser feito por meio de mappers
    - Repositories devem retornar Either do fpdart com Failures e Unit em caso de void
    - Repositories devem extender SafeCall que mapeia exceptions em failures
    - usecase_must_have_single_public_method (força o padrão call() nos usecases)
    - Salvo excessões, uma feature não pode ter outras pastas na raiz além de data, domain e presentation
    - Bloc de Autenticação é uma excessão para acesso em outras features por ser global, mas deve ser usado com cautela

- Nomenclaturas:
    - Data DataSources devem terminar em RemoteDataSource se em remote
    - Data DataSources devem terminar em LocalDataSource se em local
    - Tables devem terminar em Table
    - DTOs devem terminar em RequestDTO ou ResponseDTO
    - Data Repositories devem terminar em RepositoryImpl
    - Domain Entities devem terminar em Entity
    - Repositories Interfaces devem terminar em Repository
    - UseCases devem terminar em UseCase
    - etc
