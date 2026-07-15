# Etapa 1: Build da Aplicação
FROM maven:3.9.6-eclipse-temurin-21-alpine AS build
WORKDIR /app

# Copia apenas o pom.xml primeiro para aproveitar o cache de dependências do Docker
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copia o código fonte e builda o projeto pulando os testes para acelerar o processo
COPY src ./src
RUN mvn clean package -DskipTests

# Etapa 2: Runtime da Aplicação
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app

# Cria um usuário não-root por boas práticas de segurança
RUN addgroup -S dispatch && adduser -S dispatch -G dispatch
USER dispatch

# Copia o jar gerado na etapa de build
COPY --from=build /app/target/*.jar app.jar

# Configurações de JVM otimizadas para containers e performance concorrente
ENV JAVA_OPTS="-XX:+UseG1GC -XX:+UseStringDeduplication -XX:MaxRAMPercentage=75.0"

EXPOSE 8080

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]