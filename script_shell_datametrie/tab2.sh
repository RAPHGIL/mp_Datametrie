#!/bin/bash

FICHIER_LOG="ac-rennes.log"
HTML_REPORT="rapport.html"
URL="https://www.ac-rennes.fr"
HOST="ac-rennes.fr"

# Effacer les anciens fichiers
> "$FICHIER_LOG"
> "$HTML_REPORT"

while true; do
    START_TIME=$(date "+%Y-%m-%d %H:%M:%S")
    REPORT_DATA=""

    # Collecte des données sur 5 minutes (10 itérations, pause de 30 sec)
    for ((i=0; i<10; i++)); do
        TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
        CURL_TIME=$(curl -s -w '%{time_total}' -o /dev/null "$URL")
        PING_RESULT=$(ping -c 1 "$HOST" | grep 'time=' | awk -F 'time=' '{print $2}' | cut -d ' ' -f1)
        PING_RESULT=${PING_RESULT:-"Ping Failed"} # Valeur par défaut si ping échoue

        # Ajouter au log et au tableau HTML
        LOG_LINE="[$TIMESTAMP] Ping: ${PING_RESULT}ms | Temps Chargement: ${CURL_TIME}s"
        echo "$LOG_LINE" >> "$FICHIER_LOG"
        REPORT_DATA+="<tr><td>$TIMESTAMP</td><td>${PING_RESULT}</td><td>${CURL_TIME}</td></tr>"

        sleep 30
    done

    END_TIME=$(date "+%Y-%m-%d %H:%M:%S")

    # Générer le fichier HTML
    echo "<!DOCTYPE html>
<html lang='fr'>
<head>
    <meta charset='UTF-8'>
    <title>Rapport Datamétrie</title>
    <style>
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <h1>Rapport Datamétrie</h1>
    <p>Plage horaire : $START_TIME à $END_TIME</p>
    <table>
        <tr><th>Date et Heure</th><th>Ping (ms)</th><th>Temps de Chargement (s)</th></tr>
        $REPORT_DATA
    </table>
</body>
</html>" > "$HTML_REPORT"

    echo "Rapport généré : $HTML_REPORT (Plage $START_TIME à $END_TIME)"

    sleep 300 # Attendre 5 minutes avant le prochain rapport
done
