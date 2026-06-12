FROM node:20-alpine

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

RUN npm run build && \
    echo "=== main.js location ===" && \
    find /app/dist -name "main.js"

RUN npm prune --production

CMD ["sh", "-c", "node $(find /app/dist -name 'main.js' | head -1)"]
