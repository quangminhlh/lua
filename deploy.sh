#!/bin/bash
# Auto deploy script 😎
set -e
PORT=8767

if ! command -v node >/dev/null; then
  curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
  apt-get install -y nodejs
fi

if ! command -v pm2 >/dev/null; then
  npm install -g pm2
fi

npm install --production
pm2 start server.js --name lua-obf -- --port $PORT
pm2 save
