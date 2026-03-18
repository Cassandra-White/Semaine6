#!/bin/bash
# Cle GPG OpenSearch
curl -fsSL https://artifacts.opensearch.org/publickeys/opensearch.pgp | \
    gpg --dearmor -o /usr/share/keyrings/opensearch.gpg

# Depot OpenSearch 2.x
echo "deb [signed-by=/usr/share/keyrings/opensearch.gpg] \
https://artifacts.opensearch.org/releases/bundle/opensearch/2.x/apt stable main" | \
    tee /etc/apt/sources.list.d/opensearch-2.x.list

apt-get update

# Installer OpenSearch avec mot de passe initial
OPENSEARCH_INITIAL_ADMIN_PASSWORD="BillU-OS-2025!" \
    apt-get install -y opensearch

# Configuration requise par Graylog
cat >> /etc/opensearch/opensearch.yml << 'EOF'
cluster.name: graylog
action.auto_create_index: false
plugins.security.disabled: true
EOF

# Limiter la JVM a 2 Go pour laisser de la RAM a Graylog
sed -i 's/-Xms[0-9]*[gGmM]/-Xms2g/g' /etc/opensearch/jvm.options
sed -i 's/-Xmx[0-9]*[gGmM]/-Xmx2g/g' /etc/opensearch/jvm.options

# Stocker les donnees sur le volume LVM (plus d espace que le disque systeme)
systemctl stop opensearch 2>/dev/null || true
mkdir -p /srv/data/opensearch
if [ ! -L /var/lib/opensearch ]; then
    mv /var/lib/opensearch /srv/data/opensearch/data 2>/dev/null || true
    ln -s /srv/data/opensearch/data /var/lib/opensearch
fi
chown -R opensearch:opensearch /srv/data/opensearch

# Activer et demarrer
systemctl daemon-reload
systemctl enable opensearch
systemctl start opensearch

echo "Demarrage OpenSearch en cours (peut prendre 60 secondes)..."
sleep 30
curl -s http://localhost:9200 2>/dev/null | grep -q "cluster_name" \
    && echo "[OK] OpenSearch demarre" \
    || echo "[INFO] Attendre encore 30s et relancer : curl http://localhost:9200"
