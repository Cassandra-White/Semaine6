#!/bin/bash
# Nettoyer d eventuelles tentatives precedentes
rm -f /usr/share/keyrings/mongodb-server-*.gpg
rm -f /etc/apt/sources.list.d/mongodb-org-*.list

# Cle GPG MongoDB 8.0 (SHA256 -- compatible Ubuntu 24.04)
curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | \
    gpg --dearmor -o /usr/share/keyrings/mongodb-server-8.0.gpg

# Depot MongoDB 8.0 pour Ubuntu 24.04 Noble
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] \
https://repo.mongodb.org/apt/ubuntu noble/mongodb-org/8.0 multiverse" | \
    tee /etc/apt/sources.list.d/mongodb-org-8.0.list

apt-get update
apt-get install -y mongodb-org

# Activer et demarrer
systemctl daemon-reload
systemctl enable mongod
systemctl start mongod

# Verification
sleep 5
systemctl status mongod --no-pager | grep "Active:"
mongosh --eval "db.adminCommand('ping')" 2>/dev/null \
    && echo "[OK] MongoDB 8.0 operationnel" \
    || echo "[WARN] MongoDB ne repond pas encore -- attendre 10s et reessayer"
