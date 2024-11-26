#!/bin/bash

FICHIER_LOG="ac-rennes.log"
URL="https://www.ac-rennes.fr"
HOST="ac-rennes.fr"

# Effacer le fichier log si existant
> "$FICHIER_LOG"

while true; do
# Obtenir la date et l'heure
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

# Mesurer le temps total avec curl
CURL_TIME=$(curl -s -w '%{time_total}' -o /dev/null "$URL")

# Mesurer le ping moyen
PING_RESULT=$(ping -c 1 "$HOST" | grep 'time=' | awk -F 'time=' '{print $2}' | cut -d ' ' -f1)
if [ -z "$PING_RESULT" ]; then
    PING_RESULT="Ping Failed"
fi

# Construire et écrire la trame de log
echo "[$TIMESTAMP] Ping: ${PING_RESULT}ms | Temps Chargement: ${CURL_TIME}s" | tee -a "$FICHIER_LOG"

sleep 30
done
