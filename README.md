# Flags API — Docker Challenge

API REST de feature flags desenvolvida com Node.js, TypeScript e PostgreSQL, preparada para execução em ambientes de desenvolvimento e produção com Docker Compose.

## Índice

- [Visão geral](#visão-geral)
- [Imagem Docker](#imagem-docker)
- [Requisitos](#requisitos)
- [Desenvolvimento](#desenvolvimento)
- [Adminer](#adminer)
- [Produção](#produção)
- [Decisões técnicas](#decisões-técnicas)
- [Segurança e cadeia de suprimentos](#segurança-e-cadeia-de-suprimentos)
- [Validação do desafio](#validação-do-desafio)

## Visão geral

O projeto utiliza uma API Node.js com TypeScript e PostgreSQL como banco de dados. As migrações são executadas automaticamente antes da inicialização da API.

A estrutura Docker contempla:

- Estágio de desenvolvimento com recarga automática.
- Estágio de compilação do TypeScript.
- Estágio de produção com dependências de produção.
- Docker Compose para desenvolvimento e produção.
- Banco de dados com volume persistente e healthcheck.
- Suporte multi-arquitetura para `linux/amd64` e `linux/arm64`.

## Imagem Docker

**Docker Hub:** https://hub.docker.com/r/isqualham/flags-api

Baixe a versão publicada:

```bash
docker pull isqualham/flags-api:1.0.0
```

Tags publicadas:

- `1.0.0`: versão semântica do projeto.
- `latest`: referência à versão mais recente publicada.

**Digest do índice multi-arquitetura:**

```text
sha256:0de9db52bb0d3f2f428d0b6f222fdd8e7baee82501d157f0184791d92be49cb9
```

Arquiteturas publicadas:

- `linux/amd64`
- `linux/arm64`

O tamanho reportado pelo Docker Scout para a imagem publicada na arquitetura ARM64 foi de **63 MB**. Os tamanhos exibidos pelo Docker local podem variar conforme a imagem, a arquitetura e as camadas armazenadas.

## Requisitos

- Docker Desktop ou Docker Engine.
- Docker Compose v2.
- Git, caso deseje clonar o repositório.

## Desenvolvimento

Crie o arquivo de ambiente a partir do exemplo:

```bash
cp .env.example .env
```

Inicie os serviços com reconstrução da imagem e monitoramento dos arquivos:

```bash
docker compose up --build --watch
```

A API ficará disponível em:

- API: http://localhost:3000
- Healthcheck: http://localhost:3000/health
- Lista de flags: http://localhost:3000/flags

O Compose aguarda o banco de dados ficar saudável e executa as migrações antes de iniciar a API.

Para encerrar os serviços:

```bash
docker compose down
```

O volume do PostgreSQL é mantido por esse comando. Evite usar `docker compose down -v` se quiser preservar os dados.

## Adminer

O Adminer é um serviço opcional, ativado pelo perfil `tools`. Para iniciá-lo:

```bash
docker compose --profile tools up -d
```

Acesse http://localhost:8081.

Use os dados definidos no arquivo `.env`, com o servidor de banco `db`. Para encerrar:

```bash
docker compose --profile tools down
```

## Produção

O arquivo `compose.prod.yaml` utiliza a imagem publicada no Docker Hub, sem etapa de compilação local.

Prepare o arquivo de ambiente:

```bash
cp .env.example .env
```

Inicie a aplicação:

```bash
docker compose -f compose.prod.yaml up -d
```

Verifique os serviços:

```bash
docker compose -f compose.prod.yaml ps
```

Teste a API:

```bash
curl -i http://localhost:3000/health
curl -i http://localhost:3000/flags
```

Para encerrar os serviços sem remover os dados persistidos:

```bash
docker compose -f compose.prod.yaml down
```

A configuração de produção inclui política de reinicialização, limites de CPU e memória, volume persistente para o PostgreSQL, healthcheck e execução das migrações antes da API.

## Decisões técnicas

- **Node.js 22 com Alpine Linux:** base enxuta para reduzir o tamanho da imagem.
- **Multi-stage build:** separa desenvolvimento, compilação e produção.
- **Cache do npm:** utiliza cache mounts do BuildKit para evitar downloads desnecessários durante as compilações.
- **Instalação reproduzível:** utiliza `npm ci` com o manifesto e o lockfile existentes.
- **Dependências de produção:** instala somente dependências necessárias em runtime no estágio final e atualiza dependências transitivas selecionadas durante a construção.
- **Usuário não privilegiado:** a aplicação de produção é executada com o usuário `node`.
- **Healthcheck:** verifica o endpoint `/health`.
- **Docker Compose:** separa as configurações de desenvolvimento e produção.
- **Persistência:** utiliza volume nomeado para os dados do PostgreSQL.

## Segurança e cadeia de suprimentos

A imagem foi publicada com Buildx para duas arquiteturas e com geração de SBOM e proveniência.

A construção publicada utilizou:

```bash
docker buildx build \
  --builder multiarch-builder \
  --platform linux/amd64,linux/arm64 \
  --target production \
  --build-arg VERSION=1.0.0 \
  --build-arg SOURCE=--build-arg SOURCE=https://github.com/isqualham/fc4-desafio-docker-node-api \
  --tag isqualham/flags-api:1.0.0 \
  --tag isqualham/flags-api:latest \
  --sbom=true \
  --provenance=true \
  --push \
  .
```

Inspecione as arquiteturas e o digest:

```bash
docker buildx imagetools inspect isqualham/flags-api:1.0.0
```

Analise as vulnerabilidades da imagem publicada:

```bash
docker scout cves registry://isqualham/flags-api:1.0.0
```

O relatório gerado está disponível em `reports/scout-cves.txt`.

Na análise registrada para a variante ARM64, o Docker Scout identificou 103 pacotes e não detectou pacotes vulneráveis: zero vulnerabilidades críticas, altas, médias ou baixas. Essa conclusão se refere à imagem e à análise realizadas; novas versões de dependências e novas bases de vulnerabilidades podem alterar resultados futuros.

## Validação do desafio

| Requisito                   | Implementação                                     |
| --------------------------- | ------------------------------------------------- |
| Dockerfile multi-stage      | Estágios `dev`, `build` e `production`            |
| Imagem enxuta               | Estágio final Alpine com dependências de produção |
| Execução sem root           | Usuário `node`                                    |
| Healthcheck da API          | Endpoint `/health`                                |
| Compose de desenvolvimento  | `compose.yaml`                                    |
| Sincronização de código     | `develop.watch`                                   |
| Banco saudável antes da API | `depends_on` com `service_healthy`                |
| Migrações automáticas       | Executadas antes da API                           |
| Adminer opcional            | Perfil `tools`, porta local 8081                  |
| Compose de produção         | `compose.prod.yaml`, sem `build`                  |
| Persistência do banco       | Volume nomeado                                    |
| Multi-arquitetura           | `linux/amd64` e `linux/arm64`                     |
| SBOM e proveniência         | Opções `--sbom=true` e `--provenance=true`        |
| Análise de vulnerabilidades | Docker Scout e relatório salvo                    |

---

Projeto desenvolvido como solução para o desafio Docker da Full Cycle.
