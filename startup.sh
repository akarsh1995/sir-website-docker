docker-compose build
docker-compose up -d postgres
# sleep to let postgres completely up.
sleep 5s
docker-compose run app setup_db
docker-compose up -d app
docker-compose up -d encrypted_nginx
