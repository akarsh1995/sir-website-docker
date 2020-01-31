#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
# http://stackoverflow.com/questions/19622198/what-does-set-e-mean-in-a-bash-script
set -e

# Check if the required PostgreSQL environment variables are set

# Used by docker-entrypoint.sh to start the dev server
# If not configured you'll receive this: CommandError: "0.0.0.0:" is not a valid port number or address:port pair.
[ -z "$APP_PORT" ] && echo "ERROR: Need to set APP_PORT. E.g.: 8000" && exit 1;
[ -z "$POSTGRES_DATABASE" ] && echo "ERROR: Need to set POSTGRES_DATABASE" && exit 1;
[ -z "$POSTGRES_USER" ] && echo "ERROR: Need to set POSTGRES_USER" && exit 1;
[ -z "$POSTGRES_PASSWORD" ] && echo "ERROR: Need to set POSTGRES_PASSWORD" && exit 1;

export PGPASSWORD=$POSTGRES_PASSWORD

# write uwsgi
write_uwsgi() {
    envsubst < /deployment/uwsgi.ini > /uwsgi.ini
}

# Define help message
show_help() {
    echo """
Usage: docker run <imagename> COMMAND

Commands

dev      : Start a normal Django development server
bash     : Start a bash shell
manage   : Start manage.py
setup_db : Setup the initial database. Configure \$POSTGRES_DB_NAME in docker-compose.yml
lint     : Run pylint
python   : Run a python command
shell    : Start a Django Python shell
uwsgi    : Run uwsgi socket
help     : Show this message
"""
}

before_starting_server() {
    pipenv run python manage.py migrate
}

# Run
case "$1" in
    dev)
        before_starting_server
        echo "Running Development Server on 0.0.0.0:${APP_PORT}"
        pipenv run python manage.py runserver 0.0.0.0:"${APP_PORT}"
    ;;
    bash)
        /bin/bash "${@:2}"
    ;;
    manage)
        pipenv run python manage.py "${@:2}"
    ;;
    setup_db)
        if psql -h "$POSTGRES_DOCKER_HOST" -U "$POSTGRES_USER" -lqt | cut -d \| -f 1 | grep -qw "$POSTGRES_DATABASE"; then
            echo "Database already exists skipping"
        else
            echo "Database does not exist creating one and setting up django superuser"
            psql -h "$POSTGRES_DOCKER_HOST" -U "$POSTGRES_USER" -c "CREATE DATABASE $POSTGRES_DATABASE"
            # migrate before starting server.
            before_starting_server
            pipenv run python manage.py createsuperuser --noinput
        fi
    ;;
    lint)
        pipenv run pylint "${@:2}"
    ;;
    python)
        pipenv run python "${@:2}"
    ;;
    shell)
        pipenv run python manage.py shell_plus
    ;;
    uwsgi)
        before_starting_server
        pipenv run python manage.py collectstatic --noinput
        echo "Running App (uWSGI)..."
        write_uwsgi
        pipenv run uwsgi --ini /uwsgi.ini
    ;;
    *)
        show_help
    ;;
esac
