
# Ambiente de desenvolvimento
FROM node:22.23.3-alpine3.24 AS dev

WORKDIR /app
ENV NODE_ENV=development

COPY package.json package-lock.json ./
RUN --mount=type=cache,target=/root/.npm npm ci

COPY --chown=node:node . .
USER node

EXPOSE 3000
CMD ["npm", "run", "dev"]


# Compilação do TypeScript
FROM node:22.23.3-alpine3.24 AS build

WORKDIR /app

COPY package.json package-lock.json ./
RUN --mount=type=cache,target=/root/.npm npm ci

COPY . .
RUN npm run build


# Imagem enxuta de produção
FROM node:22.23.3-alpine3.24 AS production

WORKDIR /app
ENV NODE_ENV=production

ARG VERSION=1.0.0
ARG SOURCE=ARG SOURCE=https://github.com/isqualham/fc4-desafio-docker-node-api

LABEL org.opencontainers.image.title="flags-api" \
      org.opencontainers.image.description="API REST de feature flags com Node.js, TypeScript e PostgreSQL" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.source="${SOURCE}"

COPY package.json package-lock.json ./

RUN --mount=type=cache,target=/root/.npm \
    npm ci --omit=dev \
    && npm update proxy-addr qs --omit=dev \
    && apk upgrade --no-cache zlib \
    && rm -rf /usr/local/lib/node_modules/npm \
              /usr/local/bin/npm \
              /usr/local/bin/npx

COPY --from=build --chown=node:node /app/dist ./dist

RUN chown -R node:node /app
USER node

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD ["node", "-e", "fetch('http://127.0.0.1:'+(process.env.PORT||3000)+'/health').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"]

ENTRYPOINT ["node"]
CMD ["dist/server.js"]
