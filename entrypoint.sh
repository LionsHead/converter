#!/bin/sh
set -e

# Установка Ruby зависимостей, если нужно
bundle check || bundle install --jobs 20 --retry 5

# Установка JS зависимостей, если нужно (используйте npm ci для точного воспроизведения)
npm ci || npm install

# Запуск основного команды
exec "$@"
