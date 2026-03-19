#!/bin/bash
# Mise a jour du systeme
apt-get update && apt-get upgrade -y

# Outils necessaires
apt-get install -y curl wget gnupg apt-transport-https \
    ca-certificates dirmngr lsb-release pwgen uuid-runtime \
    software-properties-common

# Verifier Java -- requis par OpenSearch et Graylog
java -version 2>&1 | head -1 || apt-get install -y default-jdk-headless

# Verifier la RAM disponible (doit etre >= 4 Go)
free -h
echo ""
echo "IP de cette machine :"
ip a | grep "172.16" | awk '{print $2}'
