# CO – R4 Administration des systèmes 2025-2026

Projet collaboratif réalisé à 4 personnes.
Ce projet contient un script d'audit et de maintenance des systèmes, avec journalisation, sauvegarde dynamique et contrôle des services critiques.

## 🚀 Description du projet

CO est un projet développé en équipe pour :

* Apprendre à travailler en collaboration avec Git et GitHub.
* Développer un script de gestion et maintenance système.
* Auditer les performances et la sécurité d'un serveur Linux.

Le projet est divisé en 4 scripts spécialisés, chacun géré par un membre de l'équipe :

---

## 1️⃣ Antonin : Le Gardien des Ressources et Services

**Mission** : Surveiller l'état de santé du serveur et s'assurer que les services tournent.

### 📊 Vérification Disque & RAM
* Récupérer le pourcentage d'utilisation de `/home` (avec `df`)
* Récupérer le pourcentage d'utilisation de la RAM (avec `free`)
* **Logique** : Si Disque > 85% OU RAM > 90%, écrire un message "WARNING"

### 🌐 Surveillance Réseau
* Utiliser `netstat` pour compter les connexions en état `ESTABLISHED` sur les ports 80 ou 443

### 🔄 Redémarrage des Services (La boucle)
* Créer un tableau : `services=(fail2ban rsyslog mariadb)`
* Faire une boucle `for` qui teste chaque service avec `systemctl is-active`
* **Action** : Si un service est KO, tenter un redémarrage
* Si le redémarrage échoue, logger une "ERROR"

---

## 2️⃣ Lucas : L'Expert Sauvegarde et Arguments

**Mission** : Gérer les paramètres d'entrée du script et créer les archives sécurisées.

### 🎯 Gestion des Arguments (Le "Check-in")
* Vérifier que le premier argument est `-d`
* Vérifier que le deuxième argument est un dossier valide
* **Codes d'erreur** :
  - Dossier invalide → `exit 102`
  - Argument `-d` manquant → `exit 103`

### 💾 Archivage Sélectif
* Créer le dossier `/mnt/sauvegardes`
* Utiliser `tar` avec compression **Xz**
* **Contrainte** : Le nom de l'archive doit contenir la date/heure (ex: `BACKUP_2025_12_03_21h30`)
* N'inclure que les fichiers `.conf` et `.html`

### 🔐 Intégrité
* Après la sauvegarde, générer le hash du fichier avec `sha512sum`
* Stocker le hash dans un fichier `.sha512` à côté de l'archive

---

## 3️⃣ Guillaume : L'Auditeur de Sécurité

**Mission** : Repérer les utilisateurs fantômes et gérer l'interaction avec l'admin.

### 🔍 Détection d'inactivité
* Variable : `jours_inactifs=30`
* Utiliser `find` dans `/home` pour chercher les dossiers utilisateurs non accédés (`atime`) depuis plus de 30 jours

### 📝 Stockage temporaire
* Envoyer la liste des utilisateurs trouvés dans `/tmp/utilisateurs_inactifs.txt`

### 💬 Interaction Humaine
* Afficher le contenu du fichier à l'écran
* Utiliser la commande `read` pour poser une question à l'utilisateur :
  - "Voulez-vous procéder au nettoyage ? [O/N]"
* Stocker la réponse dans une variable et agir en conséquence

---

## 4️⃣ Baptiste : Le Maître des Logs et de l'Automatisation

**Mission** : Analyser les fichiers logs, gérer les plantages et planifier le script.

### 📋 Journalisation et Analyse (La boucle While)
* Créer le dossier `/var/log/maintenance` s'il n'existe pas
* Créer un fichier de log avec la date : `/var/log/maintenance/YYYY-MM-DD_HH-MM-SS.log`
* Lire le fichier `/tmp/analyse.log` ligne par ligne avec une boucle `while`
* **Compteurs** :
  - Compter le nombre total de lignes
  - Compter le nombre de lignes contenant l'IP `192.168.1.1`
* Afficher les résultats dans le fichier de log

### ⚠️ Gestion des erreurs (Trap)
* Écrire une commande `trap` qui capture le signal `INT` (Ctrl+C)
* Créer une fonction qui affiche "Arrêt du script" et quitte proprement (`exit 1`)

### ⏰ Cron (Planification)
* Ligne à ajouter dans la crontab root pour exécuter le script **tous les dimanches à 20h00** :

```cron
0 20 * * 0 /chemin/vers/le/script.sh
```

---

## 👥 Équipe

* Baptiste Margalef
* Guillaume LeGrand
* Lucas Pacheco Ribeiro
* Antonin Gouhoury

## 🛠️ Technologies utilisées

* Git / GitHub
* Visual Studio Code
* Bash / Linux

## 📦 Installation

Pour récupérer le projet sur votre machine :

```bash
git clone https://github.com/FIlox77250/Serveur-autonome.git
cd Serveur-autonome
```

Puis ouvrez le dossier dans VS Code.

## 🔧 Contribution

1. Créez une branche pour chaque fonctionnalité :

```bash
git checkout -b nom-de-branche
```

2. Travaillez sur votre code
3. Ouvrez une **pull request** sur GitHub pour fusionner

## 📄 Licence

Ce projet est disponible sous licence libre (à définir selon vos besoins).
