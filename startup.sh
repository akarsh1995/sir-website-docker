# Export the vars in .env into your shell:
export $(egrep -v '^#' .env | xargs)

# app directory and clone into it if not empty pull
mkdir -p app
if [ -z "$(ls -A ./app)" ]; then
   git clone "${GIT_URL}" ./app
else
   cd app && git pull
   cd ..
fi
docker-compose build
docker-compose up -d postgres
# sleep to let postgres completely up.
sleep 15s
# setup db
docker-compose run app setup_db
