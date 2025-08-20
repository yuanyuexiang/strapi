# ========== Build Stage ==========
FROM node:22-alpine AS build
# sharp 需要的依赖
RUN apk update && apk add --no-cache \
  build-base gcc autoconf automake zlib-dev libpng-dev vips-dev git
ARG NODE_ENV=production
ENV NODE_ENV=$NODE_ENV

WORKDIR /opt
COPY package.json yarn.lock ./
# 为 node-gyp 做准备
RUN yarn global add node-gyp
RUN yarn config set network-timeout 600000 -g && yarn install --production
ENV PATH=/opt/node_modules/.bin:$PATH

WORKDIR /opt/app
COPY . .
# 这里不会加载 .env（运行时再注入），先编译 Admin
RUN yarn build

# ========== Runtime Stage ==========
FROM node:22-alpine
RUN apk add --no-cache vips-dev
ENV NODE_ENV=production

# 复制依赖与应用
WORKDIR /opt
COPY --from=build /opt/node_modules ./node_modules
WORKDIR /opt/app
COPY --from=build /opt/app ./
ENV PATH=/opt/node_modules/.bin:$PATH

# 以非 root 用户运行更安全
RUN addgroup -S strapi && adduser -S strapi -G strapi \
  && chown -R strapi:strapi /opt/app
USER strapi

EXPOSE 1337
CMD ["yarn", "start"]
