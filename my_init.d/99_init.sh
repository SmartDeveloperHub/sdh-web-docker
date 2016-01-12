#!/bin/sh

ROOT=$(pwd)
SDHNAME="sdh-web"

Move_Laravel() {
    sed -i \
        -e "s|\DB_HOST=.*|DB_HOST=$MYSQL_ADDR|g" \
        -e "s|\DB_DATABASE=.*|DB_DATABASE=$LARAVEL_DB|g" \
        -e "s|\DB_USERNAME=.*|DB_USERNAME=$MYSQL_USER|g" \
        -e "s|\DB_PASSWORD=.*|DB_PASSWORD=$MYSQL_PASS|g" \
        -e "s|\SDH_API=.*|SDH_API=$SDH_API_HOST|g" \
        -e "s|\SDH_API_INTERNAL=.*|SDH_API_INTERNAL=$SDH_API_INTERNAL|g" \
    /var/www/html/.env
    cd $COMPOSER_HOME
    composer install -n
    chown -R www-data:www-data /var/www/
}

Update() {
    VC_DIR=$1/.git
    if [ ! -d $VC_DIR ]
    then
        echo "Repository is not present, need to clone."
        git clone $2 $1
        cd $1
        git checkout $LARAVEL_VERSION
        cd ..
        rm -rf /var/www/html
        cp -R $1 /var/www/html
        mv /var/www/html/.env.example /var/www/html/.env
        Move_Laravel $1

        #Initialize the database (create and fill with laravel migrations)
        mysql -h $MYSQL_ADDR -u$MYSQL_USER -p$MYSQL_PASS -e "CREATE DATABASE ${LARAVEL_DB};"
        php artisan migrate --force --seed

    else
        echo "Pulling..."
        cp -R $1 /var/www/html
        mv /var/www/html/.env.example /var/www/html/.env
        Move_Laravel $1

    fi

    cd $ROOT
}

# Wait to start mysql server
sleep 25

echo "> SDH Web"
Update $SDHNAME https://github.com/smartdeveloperhub/$SDHNAME.git

service apache2 stop
echo "Starting apache"
service apache2 restart
