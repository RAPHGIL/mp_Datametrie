#!/bin/bash

# Configuration des fichiers et paramètres
FICHIER_LOG="ac-rennes.log"
URL="https://www.ac-rennes.fr"
HOST="ac-rennes.fr"
EMAIL="destinataire@example.com" # Remplacez par l'adresse email du destinataire

# Nettoyage des anciens fichiers logs
> "$FICHIER_LOG"

while true; do
    START_TIME=$(date "+%Y-%m-%d %H:%M:%S")
    REPORT_DATA=""
    HTML_REPORT=""
    
    # Collecte des données sur 5 minutes (10 itérations, pause de 30 sec)
    for ((i=0; i<10; i++)); do
        TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
        
        # Temps de chargement avec curl
        CURL_TIME=$(curl -s -w '%{time_total}' -o /dev/null "$URL")
        
        # Temps de ping
        PING_RESULT=$(ping -c 1 "$HOST" | grep 'time=' | awk -F 'time=' '{print $2}' | cut -d ' ' -f1)
        PING_RESULT=${PING_RESULT:-"Ping Failed"} # Valeur par défaut si ping échoue
        
        # Ajouter au log et construire les lignes pour le tableau HTML
        LOG_LINE="[$TIMESTAMP] Ping: ${PING_RESULT}ms | Temps Chargement: ${CURL_TIME}s"
        echo "$LOG_LINE" >> "$FICHIER_LOG"
        REPORT_DATA+="<tr><td>$TIMESTAMP</td><td>${PING_RESULT}</td><td>${CURL_TIME}</td></tr>"

        sleep 30
    done

    END_TIME=$(date "+%Y-%m-%d %H:%M:%S")

    # Générer le contenu HTML avec les données collectées
    HTML_REPORT=$(cat <<EOF
<!DOCTYPE html>
<html lang='fr'>
<head>
    <meta charset='UTF-8'>
    <title>Rapport Datamétrie</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.5; }
        table { border-collapse: collapse; width: 100%; font-size: 14px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <h1 style="color: #333;">Rapport Datamétrie</h1>
    <p style="color: #555;">Plage horaire : $START_TIME à $END_TIME</p>
    <table>
        <tr>
            <th>Date et Heure</th>
            <th>Ping (ms)</th>
            <th>Temps de Chargement (s)</th>
        </tr>
        $REPORT_DATA
    </table>
</body>
</html>
EOF
)

    # Sauvegarder le rapport HTML pour référence
    echo "$HTML_REPORT" > rapport.html

    # Envoi de l'email avec le contenu HTML
    (
        echo "Subject: Rapport Datamétrie : $START_TIME à $END_TIME"
        echo "To: $EMAIL"
        echo "MIME-Version: 1.0"
        echo "Content-Type: text/html; charset=UTF-8"
        echo "Content-Transfer-Encoding: 8bit"
        echo ""
        echo "$HTML_REPORT"
    ) | sendmail -t

    echo "Rapport envoyé par email à $EMAIL (Plage $START_TIME à $END_TIME)"
    
    # Attente de 5 minutes avant le prochain rapport
    sleep 300
done
