#!/bin/bash

# Fonction pour arrêter le script si on appuie sur Ctrl+C
stop_script() {
    echo "Arrêt du script"
    exit 1
}
# On dit au script d'utiliser cette fonction quand on reçoit un signal INT (Ctrl+C)
trap stop_script INT

# Créer le dossier où on va mettre le fichier log (si il n'existe pas déjà)
mkdir -p /var/log/maintenance

# Créer le nom du fichier log avec la date et l'heure
date_actuelle=$(date +%Y-%m-%d_%H-%M-%S)
fichier_log="/var/log/maintenance/$date_actuelle.log"

# Initialiser les compteurs
total_lignes=0
lignes_mauvaise_ip=0

# Vérifier si le fichier /tmp/analyse.log existe
if [ -f /tmp/analyse.log ]; then
    # Lire le fichier ligne par ligne
    while read ligne
    do
        # Ajouter 1 au compteur total
        total_lignes=$((total_lignes + 1))

        # Vérifier si la ligne contient l'IP 192.168.1.1
        if echo "$ligne" | grep -q "192.168.1.1"; then
            lignes_mauvaise_ip=$((lignes_mauvaise_ip + 1))
        fi
    done < /tmp/analyse.log
fi

# Écrire les résultats dans le fichier log
echo "Nombre total de lignes : $total_lignes" >> "$fichier_log"
echo "Nombre de lignes avec l'adresse IP 192.168.1.1 : $lignes_mauvaise_ip" >> "$fichier_log"

# Message de fin
echo "Analyse terminée ! Résultats dans $fichier_log"
