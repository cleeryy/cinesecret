#!/bin/bash

set -e

echo "🎬 Déploiement de CineSecret avec next-authjs-template..."

# Charger les variables d'environnement
if [ -f .env.prod ]; then
    export $(cat .env.prod | xargs)
fi

# Pull de la dernière image
echo "📦 Récupération de la dernière image Docker..."
docker pull ghcr.io/cleeryy/cinesecret:latest

# Redémarrage des services
echo "🚀 Redémarrage des services..."
docker-compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.prod.yml up -d

# Attendre que les services soient prêts
echo "⏳ Attente des services..."
sleep 25

# Exécuter les migrations Prisma
echo "🔄 Exécution des migrations Prisma..."
docker-compose -f docker-compose.prod.yml exec -T cinesecret-app pnpm prisma migrate deploy

echo "✅ CineSecret déployé avec succès !"
echo "🎬 Application disponible sur http://localhost:3001"
