#!/bin/bash

LOG_TARGET="${CHEMIN_COMPLET:-/dev/tty}"

DISK_USAGE=$(df /home 2>/dev/null | grep / | awk '{print $5}' | tr -d "%" | head -n 1)
if [ -z "$DISK_USAGE" ]; then
    DISK_USAGE=$(df / | grep / | awk '{print $5}' | tr -d "%" | head -n 1)
fi

TOTAL_RAM=$(free | grep Mem | awk '{print $2}')
USED_RAM=$(free | grep Mem | awk '{print $3}')
RAM_PERCENT=$(( ($USED_RAM * 100) / $TOTAL_RAM ))

if [ "$DISK_USAGE" -gt 85 ]; then
    echo "[WARNING] Espace disque critique : ${DISK_USAGE}%" >> "$LOG_TARGET"
fi

if [ "$RAM_PERCENT" -gt 90 ]; then
    echo "[WARNING] RAM critique : ${RAM_PERCENT}%" >> "$LOG_TARGET"
fi

CONNEXIONS=$(netstat -an | grep ESTABLISHED | grep -E ":80 |:443 " | wc -l)
echo "[INFO] Connexions HTTP/HTTPS : $CONNEXIONS" >> "$LOG_TARGET"

SERVICES=("fail2ban" "rsyslog" "mariadb")

for SERVICE in "${SERVICES[@]}"
do
    systemctl is-active --quiet "$SERVICE"
    if [ $? -ne 0 ]; then
        echo "[WARNING] Service $SERVICE inactif. Tentative de redémarrage..." >> "$LOG_TARGET"
        systemctl restart "$SERVICE"
        
        systemctl is-active --quiet "$SERVICE"
        if [ $? -eq 0 ]; then
            echo "[INFO] Service $SERVICE redémarré avec succès." >> "$LOG_TARGET"
        else
            echo "[ERROR] Échec du redémarrage de $SERVICE." >> "$LOG_TARGET"
        fi
    fi
done