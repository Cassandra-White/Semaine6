#!/bin/bash
# Mise a jour et outils necessaires
apt-get update && apt-get upgrade -y

apt-get install -y curl wget gnupg apt-transport-https \
    ca-certificates dirmngr lsb-release pwgen uuid-runtime

# Verifier la RAM disponible
free -h
echo ""
echo "RAM disponible ci-dessus -- si < 4 Go : augmenter dans Proxmox"

# Verifier Java (requis par OpenSearch et Graylog)
java -version 2>&1 || apt-get install -y default-jdk-headless
java -version
