# syntax=docker/dockerfile:1


############################
# base: 共通ベース（Ruby/Node/Yarn/pg）
############################
FROM ruby:3.1.2 AS base

ENV BUNDLE_PATH=/usr/local/bundle \
BUNDLE_JOBS=4 \
BUNDLE_RETRY=3

WORKDIR /app

# Node / Yarn / PostgreSQL client 等（Sprockets / jsbundling 前提）
RUN apt-get update -y && apt-get install -y --no-install-recommends \
    build-essential curl git gnupg postgresql-client \
    && curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g yarn@1.22.22 \
    && rm -rf /var/lib/apt/lists/*


############################
# deps: Gem/JS 依存のインストール（キャッシュ層）
############################
FROM base AS deps

COPY Gemfile Gemfile.lock ./
RUN bundle config set without "development:test" \
    && bundle install

COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile || true


############################
# build: アプリをコピーして assets をプリコンパイル（production）
############################
FROM deps AS build

ENV RAILS_ENV=production \
    NODE_ENV=production

COPY . .
RUN bundle exec rails assets:precompile

############################
# production: 実行用イメージ
############################
FROM base AS production

ENV RAILS_ENV=production \
    NODE_ENV=production

# prod は dev/test Gemを除外
RUN bundle config set without "development:test"

# 依存物を deps からコピー（Gem/Node_modules）
COPY --from=deps /usr/local/bundle /usr/local/bundle
COPY --from=deps /app/node_modules /app/node_modules

# アプリと precompiled assets を build からコピー
COPY --from=build /app /app

EXPOSE 3000
ENTRYPOINT ["./entrypoint.sh"]
CMD ["bash", "-lc", "bundle exec puma -C config/puma.rb"]

############################
# development: 開発用
############################
FROM base AS development

RUN bundle config set without ""
COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY package.json yarn.lock ./
RUN yarn install || true

# アプリは起動時にボリュームで上書き
WORKDIR /app
EXPOSE 3000
ENTRYPOINT ["./entrypoint.sh"]

FROM production
