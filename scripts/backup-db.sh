#!/bin/bash

set -e

# Charger les variables d'environnement
if [ -f .env.prod ]; then
    export $(cat .env.prod | xargs)
fi

BACKUP_DIR="backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/cinesecret_backup_$TIMESTAMP.sql"

# Créer le dossier de sauvegarde
mkdir -p $BACKUP_DIR

echo "💾 Création de la sauvegarde de la base de données..."

# Créer la sauvegarde
docker-compose -f docker-compose.prod.yml exec -T postgres pg_dump \
    -U ${POSTGRES_USER:-postgres} \
    -d ${POSTGRES_DB:-cinesecret} \
    > $BACKUP_FILE

# Compresser la sauvegarde
gzip $BACKUP_FILE

echo "✅ Sauvegarde créée : ${BACKUP_FILE}.gz"

# Nettoyer les anciennes sauvegardes (garder les 7 dernières)
find $BACKUP_DIR -name "cinesecret_backup_*.sql.gz" -type f -mtime +7 -delete

echo "🧹 Anciennes sauvegardes nettoyées"
