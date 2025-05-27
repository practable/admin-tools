

AFter running nginx and wordpress-install-prereq scripts, there are manual configuration steps as follows.

### Mariadb

#### Key info:
database: wordpress
username: wordpress
password:`$PRACTABLE_SECRETS/web.practable.io/mariadb-wordpress-user.pat`

#### Setup instructions

requires (securing against attacks](https://cloudcone.com/docs/article/how-to-install-lemp-stack-on-ubuntu-22-04/)

```
sudo mysql_secure_installation
```

![set1](./img/set-root-password-mariadb-server.png)
![set2](./img/secure-mariadb-ubuntu-22.04.png)

The root password is in `$PRACTABLE_SECRETS/web.practable.io/mariadb-root.pat`

Create a wordpress user by starting mariadb as root

```
sudo mysql -u root -p
```

Then issuing

```
create database wordpress;
grant all privileges on wordpress.* TO 'wordpress'@'%' identified by 'password';
```

where password is the contents of `$PRACTABLE_SECRETS/web.practable.io/mariadb-wordpress-user.pat`

Check user is present:

```
SELECT user FROM mysql.user;
```

Exit back to terminal, then connect as the user to the database:
```
sudo mysql -u wordpress -p wordpress
```

There should now be an empty set of tables, which can be verified by 
```
show tables;
```

## Install wordpress

In the terminal, move to the `web` directory and login (assuming you have already run configure.sh) to the GCP instance (web-practable-io-alpha-default):

```
cd <path-to>/admin-tools/web
./login.sh
```

On the GCP instance, download the latest version of wordpress:

```
wget https://wordpress.org/latest.tar.gz
```

And then extract:

```
tar -xzvf latest.tar.gz
```

This will create a directory called wordpress.

In that directory make a copy of the `wp-config-sample.php` file and rename it `wp-config.php`:

```
cd wordpress
sudo cp wp-config-sample.php wp-config.php
```

Edit the wp-config.php file to include the database details created earlier. The authentication keys can be generated [here](https://api.wordpress.org/secret-key/1.1/salt/)

```
sudo nano wp-config.php
```

Move the contents of the wordpress folder to the location you are hosting the wordpress site e.g.:

```
sudo mv ./wordpress/* /var/www/<domain-name>/
```

You may need to make nginx the owner of that directory:

```
sudo chown -R www-data:www-data /var/www/<domain-name>
```

On a browser, start the wordpress installation by going to:

```
https://<domain-name>/wp-admin/install.php
```

And complete the details there to install wordpress.


## Install astra pro

we want to modify background colours etc, so have paid for a year of astra pro (3 Oct 2024)

This needs an addon to be uploaded, but it exceeds the default file size limit

we need to change php.ini for our php installation (not wordpress)

you can find your `php.ini` file with 

```
php -i | grep ini
```

For our initial installation that yields our location as `/etc/php/8.1/cli/php.ini`

Except that only changes the cli settings, so we need to edit `/etc/php/8.1/fpm/php.ini` instead:-

Change these lines from (other lines inbetween snipped for clarity)

```
; https://php.net/max-execution-time
max_execution_time = 30
; https://php.net/max-input-time
max_input_time = 60
; https://php.net/post-max-size
post_max_size = 8M
; https://php.net/upload-max-filesize
upload_max_filesize = 2M
```

to

```
; https://php.net/max-execution-time
max_execution_time = 300
; https://php.net/max-input-time
max_input_time = 300
; https://php.net/post-max-size
post_max_size = 256M
; https://php.net/upload-max-filesize
upload_max_filesize = 64M
```

Then restart php
```
sudo systemctl restart php8.1-fpm.service 
```

## Moving from one domain to another on same server

We want to move from practable.dev to practable.io

This appears to need some care, see [this guide](https://developer.wordpress.org/advanced-administration/upgrade/migrating/#moving-directories-on-your-existing-server)

Steps

### Backup files & database

## Create admin user for mariadb

create mariabackup.pat in `credentials-uoe-soe/secret/web.practable.io/mariabackup.pat`

log into instance, then log into mariadb with 'mysql -u root -p` (password is in secrets, see above)

privileges needed for 10.6.22 are those for >10.5, as listed [here](https://mariadb.com/kb/en/mariabackup-overview/#:~:text=Authentication%20and%20Privileges,-Mariabackup%20needs%20to&text=For%20most%20use%20cases%2C%20the,%2D%2Dslave%2Dinfo%20is%20specified.)

create user, using string from mariabackup.pat in place of mypassword
```
CREATE USER 'mariabackup'@'localhost' IDENTIFIED BY 'mypassword';
GRANT SELECT, SHOW VIEW, RELOAD, PROCESS, LOCK TABLES, BINLOG MONITOR ON *.* TO 'mariabackup'@'localhost';
```

note we added SELECT, SHOW VIEW because it was needed for the dump all operation (SHOW VIEW, not just SHOW, as trying to add SHOW causes misleading syntax error about `ON *.*`, presumably because SHOW is a command)

check user exists
```
MariaDB [(none)]> SELECT User, Host FROM mysql.user;
+-------------+-----------+
| User        | Host      |
+-------------+-----------+
| wordpress   | %         |
| mariabackup | localhost |
| mariadb.sys | localhost |
| mysql       | localhost |
| root        | localhost |
+-------------+-----------+
5 rows in set (0.001 sec)
```

## Run the backup

log into the instance, create `/home/tim/backup` if it does not exist

```
mariadb-dump -u mariabackup -p -x -A > /home/tim/backup/dbs.sql
```

Check backup exists - was 19MB on 27/5/25

0. Create new A record for the server at practable.io

(was ALIAS to practable.github.io)
wait for DNS to update (keep set to 1min for speed of future updates)

0. Update nginx to server new location 

edit nginx.conf template, upload with playbook

0. Update lets encrypt certbot to work with new location

log into instance and run sudo certbot --nginx
tidy up certbot edits in template, and reupload nginx conf.

0. follow steps in guide linked above

note that disk space is limited, so did `sudo mv practable.dev practable.io`
and therefore need to remove practable.dev server blocks from nginx.conf

step 10 permalinks - we did not find an .htaccess file in practable.io where index.php is, so ignoring

use better search and replace to update image links - no, doesn't preview

install wp-cli instead, instructions [here](https://make.wordpress.org/cli/handbook/guides/installing/)

```
wp search-replace --path=/var/www/practable.io --log=/home/tim/sr.log  'https://practable.dev' 'https://practable.io' --skip-columns=guid
```

this made changes to three tables. We thought about limiting changes to wp_posts only, but it seems weird to leave old address in anywhere ...
```
+------------+--------------+--------------+------+
| Table      | Column       | Replacements | Type |
+------------+--------------+--------------+------+
| wp_options | option_value | 8            | PHP  |
| wp_posts   | post_content | 138          | SQL  |
| wp_users   | user_url     | 1            | SQL  |
+------------+--------------+--------------+------+
Success: Made 147 replacements.
```

## redirect practable.dev 

Create dir `/var/www/practable.dev` and chown www-data:www-data

Create file `/var/www/practable.dev/index.html` with:

```
<head>
  <meta http-equiv='refresh' content='0; URL=https://practable.io/'>
</head>
```

This redirects without affecting any future usage of practable.dev (whereas an nginx redirect might)



