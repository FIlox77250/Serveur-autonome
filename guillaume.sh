
#!/bin/bash
JOURS_INACTIFS=30
FICHIER_INACTIFS="/tmp/utilisateurs_inactifs.txt"
find /home -maxdepth 1 -type d -atime +$JOURS_INACTIFS | awk -F'/' '{print $3}' > "$FICHIER_INACTIFS"
if [ -s "$FICHIER_INACTIFS" ]; then
    echo "Utilisateurs inactifs depuis plus de $JOURS_INACTIFS jours :"
    cat "$FICHIER_INACTIFS"
    read -p "Voulez-vous procéder au nettoyage ? [O/N] " REPONSE
    if [[ "$REPONSE" == "O" || "$REPONSE" == "o" ]]; then
        while read -r UTILISATEUR; do
            userdel -r "$UTILISATEUR"
            if [ $? -eq 0 ]; then
                echo "Utilisateur $UTILISATEUR supprimé avec succès."
            else
                echo "Échec de la suppression de l'utilisateur $UTILISATEUR."
            fi
        done < "$FICHIER_INACTIFS"
    else
        echo "Nettoyage annulé par l'utilisateur."
    fi
else
    echo "Aucun utilisateur inactif trouvé depuis plus de $JOURS_INACTIFS jours."
fi
rm "$FICHIER_INACTIFS"
