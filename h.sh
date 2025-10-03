
#!/bin/bash

#color-codes

function print_color(){
   NC='\033[0m' # No Color
   case $1 in
        "green") COLOR='\033[0;32m' ;;
        "red") COLOR='\033[0;31m' ;;
        "*") COLOR='\033[0m' ;;
   esac

   echo -e "${COLOR} $2 {NC}"
}

echo print_color "green" "_____________SETTING_UP_DB___________"


print_color "green" "Installing FirewallD.. "
sudo yum install -y firewalld

sudo systemctl start firewalld
sudo systemctl enable firewalld
sudo systemctl status firewalld

print_color "green" "Installing MariaDB.... "
sudo yum install -y mariadb-server
sudo vi /etc/my.cnf
sudo systemctl start mariadb
sudo systemctl enable mariadb

print_color "green" "Setting up firewall for Database...."
sudo firewall-cmd --permanent --zone=public --add-port=3306/tcp
sudo firewall-cmd --reload

print_color "green" "Configure Databse"

cat> setup.sql <<-EOF
  CREATE DATABASE ecomdb;
  CREATE USER 'ecomuser'@'localhost' IDENTIFIED BY 'ecompassword';
  GRANT ALL PRIVILEGES ON *.* TO 'ecomuser'@'localhost';
  FLUSH PRIVILEGES;
EOF
sudo mysql < setup-db.sql

print_color "green" "Loading inventory data into database"


cat > db-load-script.sql <<-EOF
  USE ecomdb;
CREATE TABLE products (id mediumint(8) unsigned NOT NULL auto_increment,Name varchar(255) default NULL,Price varchar(255) default
NULL, ImageUrl varchar(255) default NULL,PRIMARY KEY (id)) AUTO_INCREMENT=1;

INSERT INTO products (Name,Price,ImageUrl) VALUES ("Laptop","100","c-1.png"),("Drone","200","c-2.png"),("VR","300","c-3.png"),("Tablet","50","c-5.png"),("Watch","90","c-6.png"),("Phone Covers","20","c-7.png"),("Phone","80","c-8.png"),("Laptop","150","c-4.png");

EOF

sudo mysql < db-load-script.sql

my_sql_db_results=$(sudo mysql -e "use ecomdb; select * from products;")

if [[my_sql_db_results == "*"]]
then
  print_color "green" "Inventory data loaded into MySQl"
else
  print_color "red" "Inventory data not loaded into MySQl"
  exit 1
fi


print_color "green" "---------------- Setup Database Server - Finished ------------------"

print_color "green" "---------------- Setup Web Server --------------"


print_color "green" "---------------- Setup Web Server --------------"

print_color "green" "Installing Web Server Packages .."
sudo yum install -y httpd php php-mysqlnd
sudo firewall-cmd --permanent --zone=public --add-port=80/tcp
sudo firewall-cmd --reload


sudo sed -i 's/index.html/index.php/g' /etc/httpd/conf/httpd.conf

print_color "green" "Start httpd service.."
sudo systemctl  start httpd
sudo systemctl enable httpd

print_color "green" "Install GIT.."
sudo yum install -y git
sudo git clone https://github.com/kodekloudhub/learning-app-ecommerce.git /var/www/html/

sudo sed -i 's#// \(.*mysqli_connect.*\)#\1#' /var/www/html/index.php
sudo sed -i 's#// \(\$link = mysqli_connect(.*172\.20\.1\.101.*\)#\1#; s#^\(\s*\)\(\$link = mysqli_connect(\$dbHost, \$dbUser, \$dbPassword, \$dbName);\)#\1// \2#' /var/www/html/index.php

print_color "green" "Updating index.php.."
sudo sed -i 's/172.20.1.101/localhost/g' /var/www/html/index.php

print_color "green" "---------------- Setup Web Server - Finished ------------------"

# Test Script
web_page=$(curl http://localhost)

for item in Laptop Drone VR Watch Phone
do
  check_item "$web_page" $item
done