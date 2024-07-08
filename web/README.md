

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

