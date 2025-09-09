# syntax=docker/dockerfile:1
FROM ruby:3.1.2

# Node / Yarn / PostgreSQL client 等（Sprockets / jsbundling 前提）
RUN apt-get update -y && apt-get install -y --no-install-recommends \
    build-essential curl git libpq-dev nodejs npm postgresql-client \
    && npm install --global yarn \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Cache - Gemをインストール
COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs 4 --retry 3

# Cache - JS依存パッケージをインストール
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile || true

# アプリ本体
COPY . .

# 本番で assets:precompile するなら下行を有効化（Render ではエントリポイントで制御可）
# RUN RAILS_ENV=production bundle exec rails assets:precompile

# Puma を前提（Gemfile 記載あり）
EXPOSE 3000
ENTRYPOINT ["./entrypoint.sh"]
CMD ["bash", "-lc", "bundle exec puma -C config/puma.rb"]
