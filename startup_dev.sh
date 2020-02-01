#!/bin/bash
source startup.sh
docker-compose run --service-ports app dev
