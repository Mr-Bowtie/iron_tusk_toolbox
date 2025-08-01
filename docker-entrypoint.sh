#!/bin/sh

set -e


# server isnt shutting down nicely and managing this file lock, so Im manually doing it for now
file_path="./tmp/pids/server.pid" # Replace with the actual path to your file

if [ -e "$file_path" ]; then
  rm "$file_path"
  echo "File deleted: $file_path"
else
  echo "No server lock to worry about"
fi

yarn install
bundle install

bundle exec rails db:prepare

bundle exec foreman start -f Procfile.dev
