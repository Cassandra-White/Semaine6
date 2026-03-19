#!/bin/bash
# Cle GPG OpenSearch
curl -fsSL https://artifacts.opensearch.org/publickeys/opensearch.pgp | \
    gpg --dearmor -o /usr/share/keyrings/opensearch.gpg

# Depot OpenSearch 2.x
echo "deb [signed-by=/usr/share/keyrings/opensearch.gpg] \
https://artifacts.opensearch.org/releases/bundle/opensearch/2.x/apt stable main" | \
    tee /etc/apt/sources.list.d/opensearch-2.x.list

apt-get update

# Installer avec mot de passe admin (requis par le paquet)
OPENSEARCH_INITIAL_ADMIN_PASSWORD="BillU-OS-2025!" \
    apt-get install -y opensearch

# Configuration minimale pour Graylog
cat >> /etc/opensearch/opensearch.yml << 'EOF'

# Configuration Graylog BillU
cluster.name: graylog
action.auto_create_index: false
plugins.security.disabled: true
EOF

# Limiter la JVM a 2 Go (laisser de la RAM pour Graylog)
sed -i 's/-Xms[0-9]*[gGmM]/-Xms2g/g' /etc/opensearch/jvm.options
sed -i 's/-Xmx[0-9]*[gGmM]/-Xmx2g/g' /etc/opensearch/jvm.options

# vm.max_map_count : requis par OpenSearch
echo "vm.max_map_count=262144" >> /etc/sysctl.conf
sysctl -w vm.max_map_count=262144

# Activer et demarrer
systemctl daemon-reload
systemctl enable opensearch
systemctl start opensearch

echo "Demarrage OpenSearch en cours (60 secondes)..."
sleep 45
curl -s http://localhost:9200 2>/dev/null | grep -q "cluster_name" \
    && echo "[OK] OpenSearch demarre" \
    || echo "[INFO] Attendre 30s de plus puis : curl http://localhost:9200"
