#!/bin/bash
# =============================================================
# Lab 4 (Part 2) - Setup MySQL Database Server
# Run this ON the Database EC2 instance via SSH:
#   ssh -i MyLabKey.pem ubuntu@<DATABASE_IP> 'bash -s' < 03_setup_database.sh
# =============================================================

set -e

if command -v apt-get >/dev/null 2>&1; then
  UPDATE_CMD="sudo apt-get update -y"
  INSTALL_CMD="sudo DEBIAN_FRONTEND=noninteractive apt-get install -y"
  DB_PACKAGE="mysql-server"
  DB_SERVICE="mysql"
  DB_CONF_FILE="/etc/mysql/mysql.conf.d/z-lab.cnf"
elif command -v dnf >/dev/null 2>&1; then
  UPDATE_CMD="sudo dnf makecache"
  INSTALL_CMD="sudo dnf install -y"
  DB_PACKAGE="mariadb105-server"
  DB_SERVICE="mariadb"
  DB_CONF_FILE="/etc/my.cnf.d/z-lab.cnf"
else
  echo "Unsupported package manager"
  exit 1
fi

echo "=== Installing MySQL Server ==="
$UPDATE_CMD
$INSTALL_CMD "$DB_PACKAGE" wget || {
  if [[ "$DB_PACKAGE" == "mariadb105-server" ]]; then
    $INSTALL_CMD mariadb-server wget
  else
    exit 1
  fi
}

echo "=== Starting MySQL ==="
sudo systemctl enable "$DB_SERVICE"
sudo systemctl start "$DB_SERVICE"
sudo systemctl status "$DB_SERVICE" --no-pager

echo "=== Creating database user ==="
sudo mysql << 'SQL'
CREATE USER IF NOT EXISTS 'user'@'%' IDENTIFIED BY 'Password2026$$';
GRANT ALL PRIVILEGES ON *.* TO 'user'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
SQL
echo "User 'user' created with full privileges."

echo "=== Creating database ==="
sudo mysql -e "CREATE DATABASE IF NOT EXISTS mydatabase;"
sudo mysql -e "SHOW DATABASES;"

echo "=== Downloading and importing database schema ==="
wget -q https://mtbinds.github.io/CLOUD-COMPUTING-AIVANCITY/practice/00/foundational/database.sql \
  -O /tmp/database.sql
mysql -u user -p'Password2026$$' mydatabase < /tmp/database.sql

echo "=== Verifying data ==="
mysql -u user -p'Password2026$$' -e "USE mydatabase; SELECT * FROM messages;"

echo "=== Allowing remote connections ==="
sudo tee "$DB_CONF_FILE" > /dev/null << 'EOF'
[mysqld]
bind-address = 0.0.0.0
EOF

echo "=== Restarting MySQL to apply changes ==="
sudo systemctl restart "$DB_SERVICE"
sudo systemctl status "$DB_SERVICE" --no-pager

echo ""
echo "=== Done! ==="
echo "Database IP : $(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
echo "Port        : 3306 (make sure it is open in your EC2 Security Group Inbound Rules)"
echo "User        : user"
echo "Password    : Password2026\$\$"
echo "Database    : mydatabase"
