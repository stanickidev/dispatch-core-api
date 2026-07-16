# dispatch-core-api

Projeto Spring Boot (Java 21) para um sistema de despacho logístico, persistência feita sem ORM (
Spring Data JDBC puro).

[Clique aqui para conferir a Wiki do projeto](https://github.com/stanickidev/dispatch-core-api/wiki)

## Tecnologias

- Java 21
- Spring Boot 4.1.0
- Spring Data JDBC
- Spring Web MVC
- Spring Security
- Flyway
- PostgreSQL 17
- Docker / Docker Compose
- Maven (wrapper `mvnw`)

## Pré-requisitos

- Java 21 (JDK)
- Docker e Docker Compose
- Git

## Como rodar

Clone o repositório:

```bash
git clone https://github.com/stanickidev/dispatch-core-api.git
cd dispatch-core-api
```

Suba o banco:

```bash
docker compose up -d
```

Sobe um container Postgres (`dispatch-postgres-db`) em `localhost:5433`.

Rode a aplicação:

```bash
./mvnw spring-boot:run
```

No Windows, use `mvnw.cmd spring-boot:run`. A aplicação sobe em `http://localhost:8080`.

## Variáveis de ambiente

O `.env` na raiz já vem preenchido com valores de desenvolvimento local, usados pelo
`docker-compose.yml`:

```env
DB_NAME=dispatch-core
DB_USER=postgres
DB_PASS=postgres
```

Os mesmos valores estão hardcoded em `src/main/resources/application.properties`, então o fluxo
acima funciona sem ajustes. Não use essas credenciais fora de ambiente local.

## Testes

```bash
./mvnw test
```**