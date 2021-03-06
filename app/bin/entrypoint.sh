#!/bin/bash

#--------------------------------------------
# ENTRYPOINT SCRIPT
#
#  - Database is assumed to be created.
#  - Django admin user is not created as part of this.
#  - No special behaviour to be added for the initial run. That is outside this scripts responsibilities.
#  - Set `DJANGO_DEBUG` to trigger installation of Python dev dependencies.
#  - Set `DJANGO_MANAGEPY_MIGRATE` to trigger migrations.
#  - Set `DJANGO_MANAGEPY_COLLECTSTATIC` to trigger the collection of static files.
#
#--------------------------------------------

# TODO: Move this into the wsgi.py file so application code isn't maintained in multiple places.

set -e


#--------------------------------------------
# Check required environment vars are set
#--------------------------------------------

required_vars=(DJANGO_SECRET_KEY DB_NAME DB_USER DB_PASSWORD DB_HOST DB_PORT CACHE_HOST CACHE_PORT)

missing_vars=()
for i in "${required_vars[@]}"
do
    test -n "${!i+set}" || missing_vars+=("$i")
done

if [ ${#missing_vars[@]} -gt 0 ]
then
    echo "[error]: Aborting application start as required environment vars are not set:" >&2
    printf ' - %q\n' "${missing_vars[@]}" >&2
    exit 1
fi


#-----------------------------------------------------------
# Wait for MySQL and Redis to be accepting connections
#-----------------------------------------------------------

./bin/wait-for-it.sh ${DB_HOST}:${DB_PORT} -- echo "[info]: MySQL is up at ${DB_HOST} on ${DB_PORT}."
./bin/wait-for-it.sh ${CACHE_HOST}:${CACHE_PORT} -- echo "[info]: Redis is up at ${CACHE_HOST} on ${CACHE_PORT}."


#-------------------------------------------------------------------------------
# Optional vars for specifying additional operations before application start
#-------------------------------------------------------------------------------

if [ -v DJANGO_DEBUG ]; then
    echo '[info]: Installing development packages as DJANGO_DEBUG is set.'
    pipenv install --dev --deploy --system
fi

if [ -v DJANGO_MANAGEPY_MIGRATE ]; then
    echo '[info]: Performing database migrations as DJANGO_MANAGEPY_MIGRATE is set.'
    ./manage.py migrate --noinput
fi

if [ -v DJANGO_MANAGEPY_COLLECTSTATIC ]; then
    echo '[info]: Collecting static resources as DJANGO_MANAGEPY_COLLECTSTATIC is set.'
    ./manage.py collectstatic --noinput
fi

if [ -z DJANGO_DEBUG ]; then
    ./manage.py check --deploy
fi


#-------------
# Start!
#-------------

echo "[info]: Starting application with command - \"${@}.\""
exec "$@"
