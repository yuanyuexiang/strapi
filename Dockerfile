# ========== Build Stage ==========
FROM node:22-alpine AS build
# sharp 依赖
RUN apk update && apk add --no-cache \
  build-base gcc autoconf automake zlib-dev libpng-dev vips-dev git
ARG NODE_ENV=production
ENV NODE_ENV=$NODE_ENV

WORKDIR /opt
COPY package.json package-lock.json ./
RUN npm ci --omit=dev

WORKDIR /opt/app
COPY . .
RUN npm run build

# ========== Runtime Stage ==========
FROM node:22-alpine
RUN apk add --no-cache vips-dev
ENV NODE_ENV=production

WORKDIR /opt
COPY --from=build /opt/node_modules ./node_modules
WORKDIR /opt/app
COPY --from=build /opt/app ./

USER node
EXPOSE 1337
CMD ["npm", "run", "start"]
