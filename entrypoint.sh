#!/usr/bin/env bash
set -e

# ==== dev only: JS 依存の存在チェック ====
if [ "${RAILS_ENV}" != "production" ]; then
  # ホストマウントで node_modules が消えるケースに対応
  if [ ! -d node_modules ] || [ -z "$(ls -A node_modules 2>/dev/null)" ]; then
    echo "[entrypoint] Installing JS deps for dev..."
    yarn install --frozen-lockfile || yarn install
  fi
fi

# 本番は dev/test を除外
if [ "${RAILS_ENV}" = "production" ]; then
  bundle config set path "/usr/local/bundle"
  bundle config set without "development:test"
else
  bundle config set path "/usr/local/bundle"
  bundle config set without ""
  bundle check || bundle install --jobs 4 --retry 3
fi


# 初回起動時等に tmp/pids が残っていると Puma が起動しない
rm -f tmp/pids/server.pid || true

if [ "${AUTO_DB_PREPARE}" = "1" ]; then
  bundle exec rails db:prepare
fi

exec "$@"
