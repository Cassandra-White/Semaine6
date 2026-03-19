# Nettoyer toutes les tentatives precedentes
rm -f /usr/share/keyrings/mongodb-server-*.gpg
rm -f /etc/apt/sources.list.d/mongodb-org-*.list

# Telecharger la cle sans verification stricte
curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | \
    gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg

# Ajouter le depot avec [trusted=yes] pour bypasser la verification SHA1
echo "deb [trusted=yes] https://repo.mongodb.org/apt/debian bookworm/mongodb-org/7.0 main" | \
    tee /etc/apt/sources.list.d/mongodb-org-7.0.list

# Mettre a jour en ignorant les erreurs de signature
apt-get update --allow-insecure-repositories

# Installer en forçant
apt-get install -y --allow-unauthenticated mongodb-org

# Demarrer
systemctl daemon-reload
systemctl enable mongod
systemctl start mongod

sleep 5
systemctl status mongod --no-pager | grep "Active:"
mongosh --eval "db.adminCommand('ping')" && echo "[OK] MongoDB operationnel"
