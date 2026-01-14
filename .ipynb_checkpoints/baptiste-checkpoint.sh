#!/bin/bash

mkdir -p /var/log/maintenance

NOM_FICHIER=$(date +%Y%m%d).log
CHEMIN_COMPLET="/var/log/maintenance/$NOM_FICHIER"

MON_IP="192.168.1.1"

COMPTEUR_TOTAL=0
COMPTEUR_IP=0

if [ -f /tmp/analyse.log ]; then

    for LIGNE in $(cat /tmp/analyse.log)
    do
        COMPTEUR_TOTAL=$((COMPTEUR_TOTAL + 1))

        if echo "$LIGNE" | grep -q "$MON_IP"; then
            COMPTEUR_IP=$((COMPTEUR_IP + 1))
        fi
    done

    echo "Rapport du $(date +%c)" >> "$CHEMIN_COMPLET"
    echo "Total lignes : $COMPTEUR_TOTAL" >> "$CHEMIN_COMPLET"
    echo "Lignes avec $MON_IP : $COMPTEUR_IP" >> "$CHEMIN_COMPLET"

    echo "Fini ! Les chiffres sont dans $CHEMIN_COMPLET"
else
    echo "Problème : le fichier /tmp/analyse.log n'est pas là."
fi
