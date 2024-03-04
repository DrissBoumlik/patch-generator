#!/bin/bash

cd /var/www/html/b2b

echo "Indicate the target branch to pull from :"
read branch_name

if [[ -z "$branch_name" ]]; then echo "Branch name is missing !!"; exit; fi
git checkout $branch_name
git reset --hard HEAD
git pull origin $branch_name

echo "Run composer install ?: (leave it empty if no)"
read run_composer_install

echo "Run npm install ?: (leave it empty if no)"
read run_npm_install

echo "Run npm run prod ?: (leave it empty if no)"
read run_npm_run_prod

echo "Run php artisan migrate ?: (leave it empty if no)"
read run_php_artisan_migrate

echo "Run php artisan seed:data ?: (leave it empty if no)"
read run_php_artisan_seed_data

echo "Run composer dumpautoload ?: (leave it empty if no)"
read run_composer_dumpautoload

echo "Edit storage, database, web_logs_ws permissions ?: (leave it empty if no)"
read run_chmod

if [[ -n "$run_composer_install" ]]; then composer install; fi
if [[ -n "$run_npm_install" ]]; then npm install; fi
if [[ -n "$run_npm_run_prod" ]]; then npm run production; fi;
if [[ -n "$run_php_artisan_migrate" ]]; then php artisan migrate; fi;
if [[ -n "$run_php_artisan_seed_data" ]]; then php artisan seed:data; fi;
if [[ -n "$run_composer_dumpautoload" ]]; then composer dumpautoload; fi;
if [[ -n "$run_chmod" ]]; then chmod 777 -R storage database web_logs_ws; fi;
