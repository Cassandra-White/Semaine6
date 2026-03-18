#!/bin/bash
# Cle GPG MongoDB
curl -fsSL https://www.mongodb.org/static/pgp/server-6.0.asc | \
    gpg --dearmor -o /usr/share/keyrings/mongodb-server-6.0.gpg

# Depot MongoDB 6.0 pour Debian
echo "deb [ signed-by=/usr/share/keyrings/mongodb-server-6.0.gpg ] \
https://repo.mongodb.org/apt/debian bookworm/mongodb-org/6.0 main" | \
    tee /etc/apt/sources.list.d/mongodb-org-6.0.list

apt-get update
apt-get install -y mongodb-org

# Activer et demarrer
systemctl daemon-reload
systemctl enable mongod
systemctl start mongod

# Verifier -- doit afficher "active (running)"
systemctl status mongod --no-pager | grep "Active:"
mongosh --eval "db.adminCommand('ping')" 2>/dev/null \
    && echo "[OK] MongoDB repond" || echo "[WARN] MongoDB ne repond pas encore -- attendre 10s"
