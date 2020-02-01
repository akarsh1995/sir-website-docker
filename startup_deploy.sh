#!/bin/bash
source startup.sh
docker-compose up -d app
docker-compose up -d encrypted_nginx
