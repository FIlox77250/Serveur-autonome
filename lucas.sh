#!/bin/bash

if [ "$1" != "-d" ]; then
    echo "Erreur : il faut mettre -d au début."
    exit 103
fi

if [ ! -d "$2" ]; then
    echo "Erreur : Le dossier n'existe pas."
    exit 102
fi

dossier_source="$2"
dossier_dest="/mnt/sauvegardes"

mkdir -p $dossier_dest

date_actuelle=$(date +%Y_%m_%d_%Hh%M)
nom_archive="BACKUP_$date_actuelle.tar.xz"
chemin_final="$dossier_dest/$nom_archive"

echo "Je prépare la sauvegarde de $dossier_source vers $chemin_final"

fichier_liste="/tmp/liste_fichiers.txt"

find "$dossier_source" -name "*.conf" > $fichier_liste

find "$dossier_source" -name "*.html" >> $fichier_liste

tar -cJf "$chemin_final" -T $fichier_liste

rm $fichier_liste

sha512sum "$chemin_final" > "$chemin_final.sha512"

echo "Sauvegarde terminée et Hash calculé."
