# Nettoyer l ancienne tentative
rm -f /usr/share/keyrings/mongodb-server-6.0.gpg
rm -f /etc/apt/sources.list.d/mongodb-org-6.0.list

# Ajouter MongoDB 7.0 avec la bonne cle SHA256
curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | \
    gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg

# Depot pour Debian Trixie (bookworm est utilise car pas encore de depot trixie officiel)
echo "deb [ signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] \
https://repo.mongodb.org/apt/debian bookworm/mongodb-org/7.0 main" | \
    tee /etc/apt/sources.list.d/mongodb-org-7.0.list

apt-get update
apt-get install -y mongodb-org

systemctl daemon-reload
systemctl enable mongod
systemctl start mongod

systemctl status mongod --no-pager | grep "Active:"
mongosh --eval "db.adminCommand('ping')" && echo "[OK] MongoDB 7.0 operationnel"
