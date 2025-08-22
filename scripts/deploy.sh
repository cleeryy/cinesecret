#!/bin/bash

set -e

echo "🎬 Déploiement de CineSecret en Production..."

# Charger les variables d'environnement
if [ -f .env.prod ]; then
    export $(cat .env.prod | xargs)
else
    echo "❌ Fichier .env.prod introuvable !"
    exit 1
fi

# Vérifier que l'image existe
echo "🔍 Vérification de l'image Docker..."
if ! docker manifest inspect ghcr.io/cleeryy/cinesecret:latest > /dev/null 2>&1; then
    echo "❌ Image ghcr.io/cleeryy/cinesecret:latest introuvable"
    echo "Assurez-vous que le workflow GitHub Actions s'est exécuté avec succès"
    exit 1
fi

# Pull de la dernière image
echo "📦 Récupération de la dernière image Docker..."
docker pull ghcr.io/cleeryy/cinesecret:latest

# Arrêt et redémarrage des services
echo "🚀 Redémarrage des services..."
docker-compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.prod.yml up -d

# Attendre que la base soit prête
echo "⏳ Attente de la base de données..."
sleep 20

# Exécuter les migrations
echo "🔄 Exécution des migrations de base de données..."
if docker-compose -f docker-compose.prod.yml exec -T cinesecret-app npx prisma migrate deploy; then
    echo "✅ Migrations réussies"
else
    echo "⚠️ Erreur lors des migrations, mais on continue..."
fi

# Vérifier la santé des services
echo "🏥 Vérification de la santé des services..."
sleep 10

if docker-compose -f docker-compose.prod.yml ps | grep -q "Up"; then
    echo "✅ Services démarrés avec succès !"
    echo ""
    echo "🎬 CineSecret est disponible sur http://localhost:3001"
    echo "🗄️ Base de données PostgreSQL sur le port 5432"
    echo "👀 Watchtower surveille les mises à jour toutes les 5 minutes"
    echo ""
    echo "📊 Pour voir les logs :"
    echo "  - Application: docker-compose -f docker-compose.prod.yml logs -f cinesecret-app"
    echo "  - Watchtower: docker-compose -f docker-compose.prod.yml logs -f watchtower"
    echo "  - Base: docker-compose -f docker-compose.prod.yml logs -f postgres"
else
    echo "❌ Erreur lors du démarrage des services"
    docker-compose -f docker-compose.prod.yml logs
    exit 1
fi
