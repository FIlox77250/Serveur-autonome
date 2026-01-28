#!/bin/bash

# ==============================================================================
# 1. INITIALISATION ET SÉCURITÉ (Mission Baptiste)
# ==============================================================================
# Capture du signal CTRL+C
arret_propre() {
    echo -e "\n[!] Arrêt du script."
    exit 1
}
trap arret_propre SIGINT

# Préparation des logs
mkdir -p /var/log/maintenance
DATE_ACTUELLE=$(date +"%Y-%m-%d_%H-%M-%S")
LOG_FINAL="/var/log/maintenance/${DATE_ACTUELLE}.log"

# Vérification des arguments (Mission Lucas)
if [ "$1" != "-d" ]; then
    echo "Erreur : il faut mettre -d au début."
    exit 103
fi

if [ ! -d "$2" ]; then
    echo "Erreur : Le dossier source $2 n'existe pas."
    exit 102
fi

DOSSIER_SOURCE="$2"
LOG_TARGET="${CHEMIN_COMPLET:-/dev/tty}" # Sortie par défaut (console)

echo "--- Début du script unifié : $DATE_ACTUELLE ---" | tee -a "$LOG_FINAL"

# ==============================================================================
# 2. AUDIT RESSOURCES ET SERVICES (Mission Antonin)
# ==============================================================================
echo "[*] Analyse des ressources système..."

# Utilisation Disque
DISK_USAGE=$(df /home 2>/dev/null | grep / | awk '{print $5}' | tr -d "%" | head -n 1)
if [ -z "$DISK_USAGE" ]; then
    DISK_USAGE=$(df / | grep / | awk '{print $5}' | tr -d "%" | head -n 1)
fi

# Utilisation RAM
TOTAL_RAM=$(free | grep Mem | awk '{print $2}')
USED_RAM=$(free | grep Mem | awk '{print $3}')
RAM_PERCENT=$(( ($USED_RAM * 100) / $TOTAL_RAM ))

if [ "$DISK_USAGE" -gt 85 ]; then
    echo "[WARNING] Espace disque critique : ${DISK_USAGE}%" | tee -a "$LOG_TARGET" "$LOG_FINAL"
fi

if [ "$RAM_PERCENT" -gt 90 ]; then
    echo "[WARNING] RAM critique : ${RAM_PERCENT}%" | tee -a "$LOG_TARGET" "$LOG_FINAL"
fi

# Réseau
CONNEXIONS=$(netstat -an 2>/dev/null | grep ESTABLISHED | grep -E ":80 |:443 " | wc -l)
echo "[INFO] Connexions HTTP/HTTPS : $CONNEXIONS" | tee -a "$LOG_TARGET" "$LOG_FINAL"

# Services Critiques
SERVICES=("fail2ban" "rsyslog" "mariadb")
for SERVICE in "${SERVICES[@]}"; do
    systemctl is-active --quiet "$SERVICE"
    if [ $? -ne 0 ]; then
        echo "[WARNING] Service $SERVICE inactif. Tentative de redémarrage..." | tee -a "$LOG_FINAL"
        systemctl restart "$SERVICE"
        
        systemctl is-active --quiet "$SERVICE"
        if [ $? -eq 0 ]; then
            echo "[INFO] Service $SERVICE redémarré avec succès." | tee -a "$LOG_FINAL"
        else
            echo "[ERROR] Échec du redémarrage de $SERVICE." | tee -a "$LOG_FINAL"
        fi
    fi
done

# ==============================================================================
# 3. ANALYSE DES LOGS (Mission Baptiste) - IP : 172.23.108.33
# ==============================================================================
echo "[*] Analyse du fichier de logs..."
FICHIER_SOURCE="/tmp/analyse.log"
total_lignes=0
compteur_ip=0
IP_CIBLE="172.23.108.33"

if [ -f "$FICHIER_SOURCE" ]; then
    while read -r ligne; do
        total_lignes=$((total_lignes + 1))
        # Recherche de la nouvelle IP fournie
        if echo "$ligne" | grep -q "$IP_CIBLE"; then
            compteur_ip=$((compteur_ip + 1))
        fi
    done < "$FICHIER_SOURCE"
    
    {
        echo "Nombre total de lignes analysées : $total_lignes"
        echo "Nombre de lignes avec l'IP $IP_CIBLE : $compteur_ip"
    } >> "$LOG_FINAL"
else
    echo "Erreur : Le fichier $FICHIER_SOURCE est introuvable." >> "$LOG_FINAL"
fi

# ==============================================================================
# 4. UTILISATEURS INACTIFS (Mission Guillaume)
# ==============================================================================
echo "[*] Recherche des utilisateurs inactifs..."
JOURS_INACTIFS=30
FICHIER_INACTIFS="/tmp/utilisateurs_inactifs.txt"

# Extraction du nom de l'utilisateur (3ème champ du chemin /home/user)
find /home -maxdepth 1 -type d -atime +$JOURS_INACTIFS | awk -F'/' '{print $3}' | grep -v '^$' > "$FICHIER_INACTIFS"

if [ -s "$FICHIER_INACTIFS" ]; then
    echo "Utilisateurs inactifs depuis plus de $JOURS_INACTIFS jours :"
    cat "$FICHIER_INACTIFS"
    read -p "Voulez-vous procéder au nettoyage ? [O/N] " REPONSE
    if [[ "$REPONSE" == "O" || "$REPONSE" == "o" ]]; then
        while read -r UTILISATEUR; do
            userdel -r "$UTILISATEUR" 2>/dev/null
            if [ $? -eq 0 ]; then
                echo "Utilisateur $UTILISATEUR supprimé." | tee -a "$LOG_FINAL"
            else
                echo "Échec de la suppression de $UTILISATEUR." | tee -a "$LOG_FINAL"
            fi
        done < "$FICHIER_INACTIFS"
    else
        echo "Nettoyage annulé."
    fi
else
    echo "Aucun utilisateur inactif trouvé."
fi
rm -f "$FICHIER_INACTIFS"

# ==============================================================================
# 5. SAUVEGARDE ET HASH (Mission Lucas)
# ==============================================================================
echo "[*] Préparation de la sauvegarde..."
dossier_dest="/mnt/sauvegardes"
mkdir -p "$dossier_dest"

date_archive=$(date +%Y_%m_%d_%Hh%M)
nom_archive="BACKUP_$date_archive.tar.xz"
chemin_final="$dossier_dest/$nom_archive"

fichier_liste="/tmp/liste_fichiers.txt"
find "$DOSSIER_SOURCE" -name "*.conf" > "$fichier_liste"
find "$DOSSIER_SOURCE" -name "*.html" >> "$fichier_liste"

if [ -s "$fichier_liste" ]; then
    tar -cJf "$chemin_final" -T "$fichier_liste" 2>/dev/null
    sha512sum "$chemin_final" > "${chemin_final}.sha512"
    echo "Sauvegarde terminée : $chemin_final" | tee -a "$LOG_FINAL"
    rm "$fichier_liste"
else
    echo "Aucun fichier (.conf, .html) trouvé dans $DOSSIER_SOURCE." | tee -a "$LOG_FINAL"
fi

echo "--- Rapport de maintenance disponible : $LOG_FINAL ---"