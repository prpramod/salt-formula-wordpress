apt_update:
  cmd.run:
    - name: sudo apt update

nginx_server:
  pkg.installed:
    - names:
      - nginx

start_nginx:
  service.running:
    - name: nginx
    - enable: True

install_php_packages:
  pkg.installed:
    - names:
      - php
      - php-mysql
      - php-fpm
      - php-curl
      - php-gd
      - php-intl
      - php-mbstring
      - php-soap
      - php-xml
      - php-xmlrpc
      - php-zip

mysql_server:
  pkg.installed:
    - names:
      - mysql-server

start_mysql:
  service.running:
    - name: mysql
    - enable: True

start_php_fpm:
  service.running:
    - name: php7.4-fpm
    - enable: True


mysql-python:
  pkg.installed:
    - pkgs:
      - python3-mysqldb



create_wordpress_db:
  mysql_database.present:
    - name: wordpress
    - character_set: utf8mb4
    - collate: utf8mb4_general_ci



mysql-user:
  mysql_user.present:
    - name: pramod
    - host: localhost
    - password: metrix@123



mysql-privileges:
  mysql_grants.present:
    - grant: ALL PRIVILEGES
    - database: '*.*'
    - user: pramod
    - host: localhost



mysql-flush:
  cmd.run:
    - name: mysql -e "FLUSH PRIVILEGES;"
    - require:
      - mysql-privileges

download_wordpress:
  cmd.run:
    - name: sudo wget -c http://wordpress.org/latest.tar.gz
    - cwd: /tmp

extract_wordpress:
  cmd.run:
    - name: sudo tar -xzvf /tmp/latest.tar.gz
    - cwd: /var/www/html

wordpress_ownership:
  file.directory:
    - name: /var/www/html/wordpress
    - user: www-data
    - group: www-data
    - recurse:
      - user
      - group
      - mode

wordpress_permissions:
  file.directory:
    - name: /var/www/html/wordpress
    - dir_mode: 775
    - file_mode: 775
    - recurse:
      - user
      - group
      - mode


create_wordpress_conf:
  cmd.run:
    - name: touch /etc/nginx/conf.d/wordpress.conf
    - cwd: /
    - user: root
    - shell: /bin/bash

write_to_file_wordpress_conf:
  file.managed:
    - name: /etc/nginx/conf.d/wordpress.conf
    - contents: |
        server {
            listen 80;
            listen [::]:80;
            root /var/www/html/wordpress;
            index index.php index.html index.htm;
            server_name wordpress.conf www.wordpress.conf;
            error_log /var/log/nginx/wordpress.conf_error.log;
            access_log /var/log/nginx/wordpress.conf_access.log;
            client_max_body_size 100M;
            location / {
                try_files $uri $uri/ /index.php?$args;
            }
            location ~ \.php$ {
                include snippets/fastcgi-php.conf;
                fastcgi_pass unix:/run/php/php7.4-fpm.sock;
            }
        }
    - user: root
    - group: root
    - mode: 0644

remove_nginx_default:
  file.absent:
    - name: /etc/nginx/sites-enabled/default


check_nginx_configuration:
  cmd.run:
    - name: nginx -t
    - require:
      - service: nginx


copy_wp_config:
  cmd.run:
    - name: sudo cp /var/www/html/wordpress/wp-config-sample.php /var/www/html/wordpress/wp-config.php


update_wp_config:
  cmd.run:
    - name: sed -i "s/define( 'DB_NAME', 'database_name_here' );/define( 'DB_NAME', 'wordpress' );/g; s/define( 'DB_USER', 'username_here' );/define( 'DB_USER', 'pramod' );/g; s/define( 'DB_PASSWORD', 'password_here' );/define( 'DB_PASSWORD', 'metrix@123' );/g; s/define( 'DB_HOST', 'localhost' );/define( 'DB_HOST', 'localhost' );/g" wp-config.php
    - cwd: /var/www/html/wordpress

restart_nginx:
  cmd.run:
    - name: systemctl restart nginx
    - require:
      - service: nginx


