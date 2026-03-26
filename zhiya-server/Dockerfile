FROM node:20

WORKDIR /app

COPY package.json package-lock.json .npmrc ./
RUN npm ci

COPY tsconfig.json drizzle.config.ts ./
COPY src/ src/

RUN mkdir -p data

EXPOSE 3000

CMD ["npx", "tsx", "src/index.ts"]
