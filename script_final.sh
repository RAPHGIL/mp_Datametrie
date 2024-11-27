#!/bin/bash

# Fichier HTML
HTML_FILE="tableau.html"
URL="https://www.ac-rennes.fr"
HOST="ac-rennes.fr"

# Initialisation des variables pour le calcul des moyennes
PING_TOTAL=0
TIME_TOTAL=0
COUNT=0

# Jours de la semaine
JOURS=("Lundi" "Mardi" "Mercredi" "Jeudi" "Vendredi" "Samedi" "Dimanche")

# Adresse email du destinataire
TO_EMAIL="miniprojetscriptdatametrie@gmail.com"

# Sujet de l'email
SUBJECT="Email envoyé automatiquement"

# Corps de l'email
#MESSAGE="Ci-joint un exemple de fichier"

FILE="tableau.html"

# Nombre maximum d'e-mails à envoyer (ou utilisez `while true` pour une boucle infinie)
MAX_EMAILS=5

# Compteur
COMPTEUR=0

# Tableau pour stocker les moyennes
declare -A PING_MOYEN
declare -A TIME_MOYEN

# Calculer l'indice du jour actuel
get_jour_actuel() {
    DAY_OF_WEEK=$(date +%u)  # 1 = Lundi, 2 = Mardi, ..., 7 = Dimanche
    echo $((DAY_OF_WEEK - 1))  # Ajuster l'index pour correspondre à l'array JOURS
}

# Fonction pour générer ou mettre à jour le tableau HTML
generer_html() {
    local jour=$1
    local ping_moyen=$2
    local time_moyen=$3

    # Créer l'en-tête du fichier HTML si il n'existe pas
    if [ ! -f "$HTML_FILE" ]; then
        cat <<EOF > "$HTML_FILE"
<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <title>Stats Hebdomadaires</title>
  <style>
    table { width: 80%; margin: 20px auto; border-collapse: collapse; font-family: Arial, sans-serif; }
    th, td { border: 1px solid #ccc; padding: 10px; text-align: center; }
    th { background: #007bff; color: white; }
    tr:nth-child(even) { background: #f2f2f2; }
    h1 { text-align: center; color: #333; }
  </style>
</head>
<body>
  <h1>Statistiques Hebdomadaires</h1>
  <table>
    <thead>
      <tr>
        <th>Jour</th>
        <th>Ping Moyen (ms)</th>
        <th>Temps de Chargement Moyen (s)</th>
      </tr>
    </thead>
    <tbody>
EOF
    fi

    # Vérifier si la ligne pour le jour existe déjà, sinon l'ajouter
    if ! grep -q "<tr><td>${JOURS[$jour]}</td>" "$HTML_FILE"; then
        echo "<tr><td>${JOURS[$jour]}</td><td>${ping_moyen}</td><td>${time_moyen}</td></tr>" >> "$HTML_FILE"
    else
        # Si la ligne existe, la mettre à jour
        sed -i "s|<tr><td>${JOURS[$jour]}</td><td>.*</td><td>.*</td></tr>|<tr><td>${JOURS[$jour]}</td><td>${ping_moyen}</td><td>${time_moyen}</td></tr>|" "$HTML_FILE"
    fi

    # Fermer le tableau HTML
    cat <<EOF >> "$HTML_FILE"
    </tbody>
  </table>
</body>
</html>
EOF
}

# Boucle principale pour collecter les données toutes les 5 minutes
while true; do

# Boucle pour envoyer des e-mails toutes les n secondes
while [ $COMPTEUR -lt $MAX_EMAILS ]; do

    # Récupérer la date et l'heure actuelle
    TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

    # Mesurer le temps total avec curl
    CURL_TIME=$(curl -s -w '%{time_total}' -o /dev/null "$URL")

    # Mesurer le ping moyen
    PING_RESULT=$(ping -c 1 "$HOST" | grep 'time=' | awk -F 'time=' '{print $2}' | cut -d ' ' -f1)
    if [ -z "$PING_RESULT" ]; then
        PING_RESULT=0
    fi

    # Ajouter les résultats au total
    PING_TOTAL=$(echo "$PING_TOTAL + $PING_RESULT" | bc)
    TIME_TOTAL=$(echo "$TIME_TOTAL + $CURL_TIME" | bc)
    COUNT=$((COUNT + 1))

    # Si on a fait 10 mesures (5 minutes), calculer la moyenne et réinitialiser
    if [ "$COUNT" -eq 10 ]; then
        # Calculer la moyenne
        AVG_PING=$(echo "scale=2; $PING_TOTAL / $COUNT" | bc)
        AVG_TIME=$(echo "scale=2; $TIME_TOTAL / $COUNT" | bc)

        # Enregistrer les moyennes pour ce jour
        JOUR_ACTUEL=$(get_jour_actuel)
        PING_MOYEN[$JOUR_ACTUEL]=$AVG_PING
        TIME_MOYEN[$JOUR_ACTUEL]=$AVG_TIME

        # Mettre à jour le fichier HTML avec les nouvelles moyennes
        generer_html $JOUR_ACTUEL ${PING_MOYEN[$JOUR_ACTUEL]} ${TIME_MOYEN[$JOUR_ACTUEL]}

        # Réinitialiser les compteurs pour les prochaines mesures
        COUNT=0
        PING_TOTAL=0
        TIME_TOTAL=0
    fi

    # Augmenter le compteur
    COMPTEUR=$((COMPTEUR + 1))

    # Attendre 30 secondes avant la prochaine itération
    sleep 20
done

  HTML_CONTENT=$(cat "$FILE")

  # Construire l'email avec en-tête MIME pour indiquer que le contenu est HTML
  (
    echo "To: $TO_EMAIL"
    echo "Subject: $SUBJECT"
    echo "MIME-Version: 1.0"
    echo "Content-Type: text/html; charset=UTF-8"
    echo ""
    echo "$HTML_CONTENT"
  ) | sendmail -t


  #echo "$MESSAGE" | mutt -s "$SUBJECT" -a "$FILE" -- "$TO_EMAIL"

  # Afficher un message de confirmation dans le terminal
  echo "E-mail $((COUNT + 1)) envoyé à $TO_EMAIL"

echo "Ping effectuer"
    sleep 100
    #COMPTEUR=0
done
