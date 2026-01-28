#!/bin/bash

# RECUPERATION DU LOG
# J'utilise une condition pour vérifier si la variable de Baptiste existe
# Si elle est vide, j'affiche à l'écran (/dev/stdout)
if [ -z "$CHEMIN_COMPLET" ]; then
    sortie_log="/dev/stdout"
else
    sortie_log="$CHEMIN_COMPLET"
fi

# VERIFICATION DISQUE
# df -h /home : affiche les infos
# grep / : pour etre sur d'avoir la ligne du disque 
# tr -s ' ' : supprime les espaces multiples pour que cut marche bien 
# cut -d ' ' -f5 : garder la 5eme colonne (Use%)

check_disk=$(df -h /home | grep /)
# Si /home n'existe pas, la commande est vide, je prends la racine /
if [ -z "$check_disk" ]; then
    usage_disk=$(df -h / | grep /$ | tr -s ' ' | cut -d ' ' -f5 | tr -d '%')
else
    usage_disk=$(echo $check_disk | tr -s ' ' | cut -d ' ' -f5 | tr -d '%')
fi

# Vérifier si le disque est > 85
if [ "$usage_disk" -gt 85 ]; then
    echo "[WARNING] Espace disque critique : $usage_disk%" >> "$sortie_log"
fi


# 2. VERIFICATION RAM
# free -m donne la ram en megas
# Recupere la ligne Mem, nettoie les espaces avec tr -s prendre la colonne 2 (total) et 3 (utilisé)

ram_total=$(free -m | grep Mem | tr -s ' ' | cut -d ' ' -f2)
ram_used=$(free -m | grep Mem | tr -s ' ' | cut -d ' ' -f3)

# Pas les virgules, donc je multiplie par 100 avant de diviser
pourcentage_ram=$((ram_used * 100 / ram_total))

if [ "$pourcentage_ram" -gt 90 ]; then
    echo "[WARNING] RAM critique : $pourcentage_ram%" >> "$sortie_log"
fi


# 3. VERIFICATION RESEAU
# netstat -an pour tout voir
# grep ESTABLISHED pour les connexions actives
# egrep ":80|:443" pour filtrer HTTP ou HTTPS (le pipe | veut dire OU)
# wc -l compte les lignes

nb_connexions=$(netstat -an | grep ESTABLISHED | grep -E ":80|:443" | wc -l)
echo "[INFO] Connexions HTTP/HTTPS : $nb_connexions" >> "$sortie_log"


# 4. SERVICES
# Liste simple des services demandés
liste_services="fail2ban rsyslog mariadb"

for s in $liste_services
do
    # systemctl is-active renvoie "active" si c'est bon, ou "inactive"/"failed" sinon
    # Redirige la sortie vers null car je veux juste le code de retour ou tester la chaine
    systemctl is-active --quiet $s
    
    # $? contient 0 si ça a marché, autre chose si ça a planté
    if [ $? -ne 0 ]; then
        echo "[WARNING] Le service $s est inactif. J'essaie de le relancer..." >> "$sortie_log"
        
        systemctl restart $s
        
        # Vérification après le restart
        systemctl is-active --quiet $s
        
        if [ $? -eq 0 ]; then
            echo "[INFO] Service $s redémarré." >> "$sortie_log"
        else
            echo "[ERROR] Echec du redémarrage de $s." >> "$sortie_log"
        fi
    fi
done