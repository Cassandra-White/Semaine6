#!/bin/bash
# Depot Graylog 6.x
wget -qO /tmp/graylog.deb \
    https://packages.graylog2.org/repo/packages/graylog-6.1-repository_latest.deb
dpkg -i /tmp/graylog.deb
apt-get update
apt-get install -y graylog-server

# Generer le password_secret (64 caracteres minimum -- OBLIGATOIRE)
SECRET=$(pwgen -N 1 -s 96)

# Mot de passe admin : BillU-Admin-2025!
# Generer son hash SHA256
MDP="BillU-Admin-2025!"
HASH=$(echo -n "$MDP" | sha256sum | awk '{print $1}')

CONF="/etc/graylog/server/server.conf"

# Injecter les valeurs dans la configuration
sed -i "s|^password_secret =.*|password_secret = $SECRET|"           $CONF
sed -i "s|^root_password_sha2 =.*|root_password_sha2 = $HASH|"       $CONF
sed -i "s|#http_bind_address = .*|http_bind_address = 0.0.0.0:9000|" $CONF
sed -i "s|#http_external_uri = .*|http_external_uri = http://172.16.100.21:9000/|" $CONF

echo ""
echo "==========================================="
echo " Graylog configure"
echo "  Interface : http://172.16.100.21:9000"
echo "  Login     : admin"
echo "  Mot passe : $MDP"
echo "==========================================="

# Activer et demarrer
systemctl daemon-reload
systemctl enable graylog-server
systemctl start graylog-server

echo ""
echo "Demarrage en cours -- attendre 90 secondes"
echo "Puis ouvrir http://172.16.100.21:9000 dans un navigateur"
