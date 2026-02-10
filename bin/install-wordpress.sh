#!/bin/bash
cd "$(dirname "$0")"

if [ $# -ne 1 ]; then
  echo "Usage: $0 <frontend container>"
  exit 1
fi

frontendContainer="$1"
webRootDir="/var/www/html"

# install WordPress
docker exec --user www-data $frontendContainer bash -c "cd $webRootDir && curl -o wordpress.tar.gz -L https://wordpress.org/latest.tar.gz && tar -xzf wordpress.tar.gz --strip-components=1 && rm wordpress.tar.gz"

# configure database connection
docker exec --user www-data $frontendContainer bash -c "cd $webRootDir && sed -i 's/localhost/database/g' wp-config-sample.php"
docker exec --user www-data $frontendContainer bash -c "cd $webRootDir && sed -i 's/database_name_here/wordpress/g' wp-config-sample.php"
docker exec --user www-data $frontendContainer bash -c "cd $webRootDir && sed -i 's/username_here/wp_user/g' wp-config-sample.php"
docker exec --user www-data $frontendContainer bash -c "cd $webRootDir && sed -i 's/password_here/wp_password/g' wp-config-sample.php"
docker exec --user www-data $frontendContainer bash -c "cd $webRootDir && cp wp-config-sample.php wp-config.php"

# set secret keys and salts
saltKeys=$(curl -s https://api.wordpress.org/secret-key/1.1/salt/)
docker exec --user www-data $frontendContainer bash -c "cd $webRootDir && sed -i '/AUTH_KEY/d' wp-config.php"
docker exec --user www-data $frontendContainer bash -c "cd $webRootDir && sed -i '/SECURE_AUTH_KEY/d' wp-config.php"
docker exec --user www-data $frontendContainer bash -c "cd $webRootDir && sed -i '/LOGGED_IN_KEY/d' wp-config.php"
docker exec --user www-data $frontendContainer bash -c "cd $webRootDir && sed -i '/NONCE_KEY/d' wp-config.php"
docker exec --user www-data $frontendContainer bash -c "cd $webRootDir && sed -i '/AUTH_SALT/d' wp-config.php"
docker exec --user www-data $frontendContainer bash -c "cd $webRootDir && sed -i '/SECURE_AUTH_SALT/d' wp-config.php"
docker exec --user www-data $frontendContainer bash -c "cd $webRootDir && sed -i '/LOGGED_IN_SALT/d' wp-config.php"
docker exec --user www-data $frontendContainer bash -c "cd $webRootDir && sed -i '/NONCE_SALT/d' wp-config.php"
docker exec --user www-data -e saltKeys="$saltKeys" "$frontendContainer" bash -c 'cd /var/www/html && awk -v salts="$saltKeys" "{ if (\$0 ~ /\\/\\*\\*#@-\\*\\//) { print salts } print \$0 }" wp-config.php > wp-config.tmp && mv wp-config.tmp wp-config.php'