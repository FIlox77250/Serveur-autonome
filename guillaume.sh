#!/bin/bash
mkdir -p ./mes_logs
DATE=$(date +%d-%m-%Y_%Hh%M)
FICHIER_LOG="./mes_logs/rapport_$DATE.txt"
UTILISATEUR_FANTOME="ghost_user"
total=0
nb_fantomes=0
if [ -f "/tmp/user_activity.log" ]; then

    while read LIGNE
    do
        total=$((total + 1))

        if echo "$LIGNE" | grep -q "$UTILISATEUR_FANTOME"; then
            nb_fantomes=$((nb_fantomes + 1))
        fi
    done < "/tmp/user_activity.log"

    echo "--- Rapport fait le $(date) ---" > "$FICHIER_LOG"
    echo "Nombre de lignes lues : $total" >> "$FICHIER_LOG"
    echo "Lignes contenant $UTILISATEUR_FANTOME : $nb_fantomes" >> "$
