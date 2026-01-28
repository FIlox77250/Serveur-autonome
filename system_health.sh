#!/bin/bash


mkdir -p ./mes_logs
DATE=$(date +%d-%m-%Y_%Hh%M)
FICHIER_LOG="./mes_logs/rapport_$DATE.txt"



fonction_verification_systeme() {
 
    
    if [ -z "$FICHIER_LOG" ]; then
        sortie_log="/dev/stdout"
    else
        sortie_log="$FICHIER_LOG"
    fi
   
    
    check_disk=$(df -h /home | grep /)

        if [ -z "$check_disk" ]; then
        usage_disk=$(df -h / | grep /$ | tr -s ' ' | cut -d ' ' -f5 | tr -d '%')
    else
        usage_disk=$(echo $check_disk | tr -s ' ' | cut -d ' ' -f5 | tr -d '%')
    fi

        if [ "$usage_disk" -gt 85 ]; then
        echo "[WARNING] Espace disque critique : $usage_disk%" >> "$sortie_log"
    fi

   
        
    ram_used=$(free -m | grep Mem | tr -s ' ' | cut -d ' ' -f3)
   
    
    pourcentage_ram=$((ram_used * 100 / ram_total))
    if [ "$pourcentage_ram" -gt 90 ]; then
        echo "[WARNING] RAM critique : $pourcentage_ram%" >> "$sortie_log"
    fi
 
    
    nb_connexions=$(netstat -an | grep ESTABLISHED | grep -E ":80|:443" | wc -l)
    echo "[INFO] Connexions HTTP/HTTPS : $nb_connexions" >> "$sortie_log"

    
    liste_services="fail2ban rsyslog mariadb"
    for s in $liste_services
    do
      
        
        systemctl is-active --quiet $s
        

                if [ $? -ne 0 ]; then
            echo "[WARNING] Le service $s est inactif. J'essaie de le relancer..." >> "$sortie_log"
            
            systemctl restart $s
            

                        systemctl is-active --quiet $s
            
            if [ $? -eq 0 ]; then
                echo "[INFO] Service $s redémarré." >> "$sortie_log"
            else
                echo "[ERROR] Echec du redémarrage de $s." >> "$sortie_log"
            fi
        fi
    done
}


fonction_analyse_logs() {
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
}


fonction_nettoyage_utilisateurs() {
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
}


fonction_sauvegarde() {
    if [ "$1" != "-d" ]; then
        echo "Erreur : il faut mettre -d au début."
        echo "Usage : $0 4 -d /chemin/du/dossier"
        return 103
    fi
    if [ ! -d "$2" ]; then
        echo "Erreur : Le dossier n'existe pas."
        return 102
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
}


afficher_menu() {
    echo "============================================="
    echo "       SCRIPT UNIFIE - ADMINISTRATION       "
    echo "============================================="
    echo "1) Vérification système (Disque, RAM, Réseau, Services)"
    echo "2) Analyse de logs"
    echo "3) Nettoyage utilisateurs inactifs"
    echo "4) Sauvegarde (nécessite -d /chemin)"
    echo "5) Exécuter TOUT"
    echo "0) Quitter"
    echo "============================================="
}


if [ $# -gt 0 ]; then
    case "$1" in
        1) fonction_verification_systeme ;;
        2) fonction_analyse_logs ;;
        3) fonction_nettoyage_utilisateurs ;;
        4) shift; fonction_sauvegarde "$@" ;;
        5) 
            fonction_verification_systeme
            fonction_analyse_logs
            fonction_nettoyage_utilisateurs
            ;;
        *)
            echo "Option invalide : $1"
            echo "Usage : $0 [1|2|3|4|5] [options]"
            exit 1
            ;;
    esac
    exit 0
fi


while true; do
    afficher_menu
    read -p "Votre choix : " choix
    case "$choix" in
        1) fonction_verification_systeme ;;
        2) fonction_analyse_logs ;;
        3) fonction_nettoyage_utilisateurs ;;
        4) 
            read -p "Entrez le chemin du dossier à sauvegarder : " chemin_dossier
            fonction_sauvegarde "-d" "$chemin_dossier"
            ;;
        5)
            echo "Exécution de toutes les fonctions..."
            fonction_verification_systeme
            fonction_analyse_logs
            fonction_nettoyage_utilisateurs
            read -p "Voulez-vous aussi faire une sauvegarde ? [O/N] " rep
            if [[ "$rep" == "O" || "$rep" == "o" ]]; then
                read -p "Entrez le chemin du dossier : " chemin_dossier
                fonction_sauvegarde "-d" "$chemin_dossier"
            fi
            ;;
        0) 
            echo "Au revoir !"
            exit 0
            ;;
        *)
            echo "Choix invalide, réessayez."
            ;;
    esac
    echo ""
    read -p "Appuyez sur Entrée pour continuer..."
    clear
done
