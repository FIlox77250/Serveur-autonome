#!/bin/bash

# Créer le dossier pour les logs. J'ai appris le -p pour pas avoir d'erreur.
mkdir -p /var/log/maintenance

# Créer un nom de fichier simple avec la date
NOM_FICHIER=$(date +%Y%m%d).log
CHEMIN_COMPLET="/var/log/maintenance/$NOM_FICHIER"

# L'IP à chercher
MON_IP="192.168.1.1"

# J'utilise des compteurs qui commencent à zéro
COMPTEUR_TOTAL=0
COMPTEUR_IP=0

# On vérifie si le fichier existe
if [ -f /tmp/analyse.log ]; then

    # Je lis ligne par ligne. C'est la seule méthode que je connais bien.
    for LIGNE in $(cat /tmp/analyse.log)
    do
        # J'ajoute 1 au total
        COMPTEUR_TOTAL=$((COMPTEUR_TOTAL + 1))

        # Je cherche l'IP avec grep
        if echo "$LIGNE" | grep -q "$MON_IP"; then
            COMPTEUR_IP=$((COMPTEUR_IP + 1))
        fi
    done

    # J'écris les résultats directement dans le fichier log
    echo "Rapport du $(date +%c)" >> "$CHEMIN_COMPLET"
    echo "Total lignes : $COMPTEUR_TOTAL" >> "$CHEMIN_COMPLET"
    echo "Lignes avec $MON_IP : $COMPTEUR_IP" >> "$CHEMIN_COMPLET"

    echo "Fini ! Les chiffres sont dans $CHEMIN_COMPLET"
else
    # Si ça ne marche pas, j'écris une erreur
    echo "Problème : le fichier /tmp/analyse.log n'est pas là."
fi
