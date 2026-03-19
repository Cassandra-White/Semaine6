04-install-graylog.sh
Bash Root -- Debian
#!/bin/bash
# Depot Graylog 5.2
wget -qO /tmp/graylog.deb \
    https://packages.graylog2.org/repo/packages/graylog-5.2-repository_latest.deb
dpkg -i /tmp/graylog.deb
apt-get update
apt-get install -y graylog-server

# Generer le password_secret (64 caracteres minimum -- obligatoire)
SECRET=$(pwgen -N 1 -s 96)

# Choisir le mot de passe admin puis generer son hash SHA256
# Ici : BillU-Admin-2025! -- changer si souhaite
MDP_ADMIN="BillU-Admin-2025!"
HASH=$(echo -n "$MDP_ADMIN" | sha256sum | awk '{print $1}')

# IP de la VM Debian
IP=$(hostname -I | awk '{print $1}')

# Editer /etc/graylog/server/server.conf
CONF="/etc/graylog/server/server.conf"
sed -i "s|^password_secret =.*|password_secret = $SECRET|"       $CONF
sed -i "s|^root_password_sha2 =.*|root_password_sha2 = $HASH|"   $CONF
sed -i "s|#http_bind_address = .*|http_bind_address = 0.0.0.0:9000|" $CONF
sed -i "s|#http_external_uri = .*|http_external_uri = http://$IP:9000/|" $CONF

echo ""
echo "============================================="
echo " Graylog configure"
echo "  Interface web : http://$IP:9000"
echo "  Login         : admin"
echo "  Mot de passe  : $MDP_ADMIN"
echo "============================================="

# Activer et demarrer
systemctl daemon-reload
systemctl enable graylog-server
systemctl start graylog-server

echo "Demarrage Graylog en cours (60 a 90 secondes)..."
echo "Verifier avec : systemctl status graylog-server"
