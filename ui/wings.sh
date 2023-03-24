#!/bin/bash

set -e

######################################################################################
#                                                                                    #
# Project 'pterodactyl-installer'                                                    #
#                                                                                    #
# Copyright (C) 2023, MrFlytb, <mr.flytb@gmail.com>                                  #
#                                                                                    #
#   Ce programme est un logiciel libre : vous pouvez le redistribuer et/ou le        #
#   modifier sous les termes de la licence publique générale GNU telle que publiée   #
#   par la Free Software Foundation, soit la version 3 de la Licence, soit           #
#   (à votre choix) toute version ultérieure.                                        #
#                                                                                    #
#   Ce programme est distribué dans l'espoir qu'il sera utile,                       #
#   mais SANS AUCUNE GARANTIE ; sans même la garantie implicite de                   #
#   QUALITÉ MARCHANDE ou ADAPTATION À UN USAGE PARTICULIER. Voir le                  #
#   Licence publique générale GNU pour plus de détails.                              #
#                                                                                    #
#   Vous devriez avoir reçu une copie de la licence publique générale GNU            #
#   avec ce programme. Sinon, consultez <https://www.gnu.org/licenses/>.             #
#                                                                                    #
# https://github.com/mrflytbs/pterodactyl-installer/blob/main/LICENSE                #
#                                                                                    #
# Ce script n'est pas associé au projet officiel Pterodactyl.                        #
# https://github.com/mrflytbs/pterodactyl-installer                                  #
#                                                                                    #
######################################################################################

# Check if script is loaded, load if not or fail otherwise.
fn_exists() { declare -F "$1" >/dev/null; }
if ! fn_exists lib_loaded; then
  # shellcheck source=lib/lib.sh
  source /tmp/lib.sh || source <(curl -sSL "$GITHUB_BASE_URL/$GITHUB_SOURCE"/lib/lib.sh)
  ! fn_exists lib_loaded && echo "* ERREUR : Impossible de charger le script lib" && exit 1
fi

# ------------------ Variables ----------------- #

# Install mariadb
export INSTALL_MARIADB=false

# Firewall
export CONFIGURE_FIREWALL=false

# SSL (Let's Encrypt)
export CONFIGURE_LETSENCRYPT=false
export FQDN=""
export EMAIL=""

# Database host
export CONFIGURE_DBHOST=false
export CONFIGURE_DB_FIREWALL=false
export MYSQL_DBHOST_HOST="127.0.0.1"
export MYSQL_DBHOST_USER="pterodactyluser"
export MYSQL_DBHOST_PASSWORD=""

# ------------ User input functions ------------ #

ask_letsencrypt() {
  if [ "$CONFIGURE_UFW" == false ] && [ "$CONFIGURE_FIREWALL_CMD" == false ]; then
    warning "Let's Encrypt nécessite l'ouverture du port 80/443 ! Vous avez désactivé la configuration automatique du pare-feu ; utilisez-le à vos risques et périls (si le port 80/443 est fermé, le script échouera) !"
  fi

  warning "Vous ne pouvez pas utiliser Let's Encrypt avec votre nom d'hôte comme adresse IP ! Il doit s'agir d'un nom de domaine complet (par exemple, node.ygaming.fr)."

  echo -e -n "* Voulez-vous configurer automatiquement HTTPS à l'aide de Let's Encrypt ? (y/N): "
  read -r CONFIRM_SSL

  if [[ "$CONFIRM_SSL" =~ [Yy] ]]; then
    CONFIGURE_LETSENCRYPT=true
  fi
}

ask_database_user() {
  echo -n "* Voulez-vous configurer automatiquement un utilisateur pour les hôtes de base de données ? (y/N): "
  read -r CONFIRM_DBHOST

  if [[ "$CONFIRM_DBHOST" =~ [Yy] ]]; then
    ask_database_external
    CONFIGURE_DBHOST=true
  fi
}

ask_database_external() {
  echo -n "* Voulez-vous configurer MySQL pour qu'il soit accessible en externe ? (y/N): "
  read -r CONFIRM_DBEXTERNAL

  if [[ "$CONFIRM_DBEXTERNAL" =~ [Yy] ]]; then
    echo -n "* Entrez l'adresse du panel (vide pour toute adresse): "
    read -r CONFIRM_DBEXTERNAL_HOST
    if [ "$CONFIRM_DBEXTERNAL_HOST" == "" ]; then
      MYSQL_DBHOST_HOST="%"
    else
      MYSQL_DBHOST_HOST="$CONFIRM_DBEXTERNAL_HOST"
    fi
    [ "$CONFIGURE_FIREWALL" == true ] && ask_database_firewall
    return 0
  fi
}

ask_database_firewall() {
  warning "Autoriser le trafic entrant sur le port 3306 (MySQL) peut potentiellement constituer un risque pour la sécurité, à moins que vous ne sachiez ce que vous faites !"
  echo -n "* Souhaitez-vous autoriser le trafic entrant sur le port 3306 ? (y/N): "
  read -r CONFIRM_DB_FIREWALL
  if [[ "$CONFIRM_DB_FIREWALL" =~ [Yy] ]]; then
    CONFIGURE_DB_FIREWALL=true
  fi
}

####################
## MAIN FUNCTIONS ##
####################

main() {
  # check if we can detect an already existing installation
  if [ -d "/etc/pterodactyl" ]; then
    warning "Le script a détecté que vous avez déjà des ailes de Ptérodactyle sur votre système ! Vous ne pouvez pas exécuter le script plusieurs fois, il échouera !"
    echo -e -n "* Êtes-vous sur de vouloir continuer? (y/N): "
    read -r CONFIRM_PROCEED
    if [[ ! "$CONFIRM_PROCEED" =~ [Yy] ]]; then
      error "Installation interrompue !"
      exit 1
    fi
  fi

  welcome "wings"

  check_virt

  echo "* "
  echo "* Le programme d'installation installera Docker, les dépendances requises pour Wings"
  echo "* ainsi que Wings lui-même. Mais il est toujours nécessaire de créer le nœud"
  echo "* sur le panneau, puis placez manuellement le fichier de configuration sur le nœud après"
  echo "* l'installation est terminée. En savoir plus sur ce processus sur le"
  echo "* documents officiels: $(hyperlink 'https://pterodactyl.io/wings/1.0/installing.html#configure')"
  echo "* "
  echo -e "* ${COLOR_RED}Note${COLOR_NC}: ce script ne démarrera pas Wings automatiquement (installera le service systemd, ne le démarrera pas)."
  echo -e "* ${COLOR_RED}Note${COLOR_NC}: ce script n'activera pas l'échange (pour docker)."
  print_brake 42

  ask_firewall CONFIGURE_FIREWALL

  ask_database_user

  if [ "$CONFIGURE_DBHOST" == true ]; then
    type mysql >/dev/null 2>&1 && HAS_MYSQL=true || HAS_MYSQL=false

    if [ "$HAS_MYSQL" == false ]; then
      INSTALL_MARIADB=true
    fi

    MYSQL_DBHOST_USER="-"
    while [[ "$MYSQL_DBHOST_USER" == *"-"* ]]; do
      required_input MYSQL_DBHOST_USER "Nom d'utilisateur de l'hôte de la base de données (pterodactyluser) : " "" "pterodactyluser"
      [[ "$MYSQL_DBHOST_USER" == *"-"* ]] && error "L'utilisateur de la base de données ne peut pas contenir de tirets"
    done

    password_input MYSQL_DBHOST_PASSWORD "Mot de passe de l'hôte de la base de données : " "Le mot de passe ne peut pas être vide"
  fi

  ask_letsencrypt

  if [ "$CONFIGURE_LETSENCRYPT" == true ]; then
    while [ -z "$FQDN" ]; do
      echo -n "* Définissez le nom de domaine complet à utiliser pour Let's Encrypt (node.ygaming.fr) : "
      read -r FQDN

      ASK=false

      [ -z "$FQDN" ] && error "Le FQDN ne peut pas être vide"                                                            # check if FQDN is empty
      bash <(curl -s "$GITHUB_URL"/lib/verify-fqdn.sh) "$FQDN" || ASK=true                                      # check if FQDN is valid
      [ -d "/etc/letsencrypt/live/$FQDN/" ] && error "Un certificat avec ce FQDN existe déjà !" && ASK=true # check if cert exists

      [ "$ASK" == true ] && FQDN=""
      [ "$ASK" == true ] && echo -e -n "* Souhaitez-vous toujours configurer automatiquement HTTPS à l'aide de Let's Encrypt ? (y/N): "
      [ "$ASK" == true ] && read -r CONFIRM_SSL

      if [[ ! "$CONFIRM_SSL" =~ [Yy] ]] && [ "$ASK" == true ]; then
        CONFIGURE_LETSENCRYPT=false
        FQDN=""
      fi
    done
  fi

  if [ "$CONFIGURE_LETSENCRYPT" == true ]; then
    # set EMAIL
    while ! valid_email "$EMAIL"; do
      echo -n "* Entrez l'adresse e-mail pour Let's Encrypt: "
      read -r EMAIL

      valid_email "$EMAIL" || error "L'e-mail ne peut pas être vide ou invalide"
    done
  fi

  echo -n "* Continuer l'installation ? (y/N): "

  read -r CONFIRM
  if [[ "$CONFIRM" =~ [Yy] ]]; then
    run_installer "wings"
  else
    error "Installation interrompue."
    exit 1
  fi
}

function goodbye {
  echo ""
  print_brake 70
  echo "* Installation de wings terminée"
  echo "*"
  echo "* Pour continuer, vous devez configurer Wings pour qu'il fonctionne avec votre panneau"
  echo "* Veuillez vous référer au guide officiel, $(hyperlink 'https://pterodactyl.io/wings/1.0/installing.html#configure')"
  echo "* "
  echo "* Vous pouvez soit copier manuellement le fichier de configuration du panneau vers /etc/pterodactyl/config.yml"
  echo "* ou, vous pouvez utiliser le bouton \"déploiement automatique\" du panneau et simplement coller la commande dans ce terminal"
  echo "* "
  echo "* Vous pouvez ensuite démarrer Wings manuellement pour vérifier qu'il fonctionne"
  echo "*"
  echo "* sudo wings"
  echo "*"
  echo "* Une fois que vous avez vérifié que cela fonctionne, utilisez CTRL + C puis démarrez Wings en tant que service (s'exécute en arrière-plan)"
  echo "*"
  echo "* systemctl start wings"
  echo "*"
  echo -e "* ${COLOR_RED}Note${COLOR_NC}: Il est recommandé d'activer le swap (pour Docker, en savoir plus à ce sujet dans la documentation officielle)."
  [ "$CONFIGURE_FIREWALL" == false ] && echo -e "* ${COLOR_RED}Note${COLOR_NC}: Si vous n'avez pas configuré votre pare-feu, les ports 8080 et 2022 doivent être ouverts."
  print_brake 70
  echo ""
}

# run script
main
goodbye
