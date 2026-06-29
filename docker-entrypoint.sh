#!/bin/sh

set -eu


# server isnt shutting down nicely and managing this file lock, so Im manually doing it for now
file_path="./tmp/pids/server.pid" # Replace with the actual path to your file

if [ -e "$file_path" ]; then
  rm "$file_path"
  echo "File deleted: $file_path"
else
  echo "No server lock to worry about"
fi

DB_HOST="${DB_HOST:-db}"
DB_PORT="${DB_PORT:-5432}"
POSTGRES_USER="${POSTGRES_USER:-postgres}"

until pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$POSTGRES_USER" >/dev/null 2>&1; do
  echo "Waiting for Postgres at ${DB_HOST}:${DB_PORT}..."
  sleep 2
done

bundle exec rails db:prepare

bundle exec foreman start -f Procfile.dev
