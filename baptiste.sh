#!/bin/bash
mkdir -p ./mes_logs

DATE=$(date +%d-%m-%Y_%Hh%M)
FICHIER_LOG="./mes_logs/rapport_$DATE.txt"

IP_A_CHERCHER="10.0.1.1"

total=0
nb_ip=0

if [ -f "/tmp/analyse.log" ]; then

    while read LIGNE
    do
        total=$((total + 1))

        if echo "$LIGNE" | grep -q "$IP_A_CHERCHER"; then
            nb_ip=$((nb_ip + 1))
        fi
    done < "/tmp/analyse.log"

    echo "--- Rapport fait le $(date) ---" > "$FICHIER_LOG"
    echo "Nombre de lignes lues : $total" >> "$FICHIER_LOG"
    echo "Lignes contenant $IP_A_CHERCHER : $nb_ip" >> "$FICHIER_LOG"

    echo "C'est bon, le rapport est ici : $FICHIER_LOG"

else
    echo "Erreur : Je trouve pas le fichier /tmp/analyse.log..."
fi
