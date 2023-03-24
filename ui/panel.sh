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
  ! fn_exists lib_loaded && echo "* Erreur: Impossible de charger le script lib" && exit 1
fi

# ------------------ Variables ----------------- #

# Domain name / IP
export FQDN=""

# Default MySQL credentials
export MYSQL_DB=""
export MYSQL_USER=""
export MYSQL_PASSWORD=""

# Environment
export timezone=""
export email=""

# Initial admin account
export user_email=""
export user_username=""
export user_firstname=""
export user_lastname=""
export user_password=""

# Assume SSL, will fetch different config if true
export ASSUME_SSL=false
export CONFIGURE_LETSENCRYPT=false

# Firewall
export CONFIGURE_FIREWALL=false

# ------------ User input functions ------------ #

ask_letsencrypt() {
  if [ "$CONFIGURE_UFW" == false ] && [ "$CONFIGURE_FIREWALL_CMD" == false ]; then
    warning "Let's Encrypt nécessite l'ouverture du port 80/443 ! Vous avez désactivé la configuration automatique du pare-feu ; utilisez-le à vos risques et périls (si le port 80/443 est fermé, le script échouera) !"
  fi

  echo -e -n "* Voulez-vous configurer automatiquement HTTPS à l'aide de Let's Encrypt ? (y/N): "
  read -r CONFIRM_SSL

  if [[ "$CONFIRM_SSL" =~ [Yy] ]]; then
    CONFIGURE_LETSENCRYPT=true
    ASSUME_SSL=false
  fi
}

ask_assume_ssl() {
  output "Let's Encrypt ne sera pas configuré automatiquement par ce script (l'utilisateur s'est désabonné)."
  output "Vous pouvez « supposer » Let's Encrypt, ce qui signifie que le script téléchargera une configuration nginx configurée pour utiliser un certificat Let's Encrypt, mais le script n'obtiendra pas le certificat pour vous."
  output "Si vous assumez SSL et n'obtenez pas le certificat, votre installation ne fonctionnera pas."
  echo -n "* Supposer SSL ou pas ? (y/N): "
  read -r ASSUME_SSL_INPUT

  [[ "$ASSUME_SSL_INPUT" =~ [Yy] ]] && ASSUME_SSL=true
  true
}

check_FQDN_SSL() {
  if [[ $(invalid_ip "$FQDN") == 1 && $FQDN != 'localhost' ]]; then
    SSL_AVAILABLE=true
  else
    warning "* Let's Encrypt ne sera pas disponible pour les adresses IP."
    output "Pour utiliser Let's Encrypt, vous devez utiliser un nom de domaine valide."
  fi
}

main() {
  # check if we can detect an already existing installation
  if [ -d "/var/www/pterodactyl" ]; then
    warning "Le script a détecté que vous avez déjà un panneau Pterodactyl sur votre système ! Vous ne pouvez pas exécuter le script plusieurs fois, il échouera !"
    echo -e -n "* Êtes-vous sur de vouloir continuer? (y/N): "
    read -r CONFIRM_PROCEED
    if [[ ! "$CONFIRM_PROCEED" =~ [Yy] ]]; then
      error "Installation interrompue !"
      exit 1
    fi
  fi

  welcome "panel"

  check_os_x86_64

  # set database credentials
  output "Configuration de la base de données."
  output ""
  output "Ce seront les informations d'identification utilisées pour la communication entre le MySQL"
  output "base de données et le panel. Vous n'avez pas besoin de créer la base de données"
  output "avant d'exécuter ce script, le script le fera pour vous."
  output ""

  MYSQL_DB="-"
  while [[ "$MYSQL_DB" == *"-"* ]]; do
    required_input MYSQL_DB "Nom de la base de données (panel): " "" "panel"
    [[ "$MYSQL_DB" == *"-"* ]] && error "Le nom de la base de données ne peut pas contenir de tirets"
  done

  MYSQL_USER="-"
  while [[ "$MYSQL_USER" == *"-"* ]]; do
    required_input MYSQL_USER "Nom d'utilisateur de la base de données (pterodactyl): " "" "pterodactyl"
    [[ "$MYSQL_USER" == *"-"* ]] && error "L'utilisateur de la base de données ne peut pas contenir de tirets"
  done

  # MySQL password input
  rand_pw=$(gen_passwd 64)
  password_input MYSQL_PASSWORD "Mot de passe (appuyez sur Entrée pour utiliser un mot de passe généré aléatoirement) :" "Le mot de passe MySQL ne peut pas être vide" "$rand_pw"

  readarray -t valid_timezones <<<"$(curl -s "$GITHUB_URL"/configs/valid_timezones.txt)"
  output "List of valid timezones here $(hyperlink "https://www.php.net/manual/en/timezones.php")"

  while [ -z "$timezone" ]; do
    echo -n "* Sélectionnez le fuseau horaire [Europe/Paris]: "
    read -r timezone_input

    array_contains_element "$timezone_input" "${valid_timezones[@]}" && timezone="$timezone_input"
    [ -z "$timezone_input" ] && timezone="Europe/Paris" # because köttbullar!
  done

  email_input email "Indiquez l'adresse e-mail qui sera utilisée pour configurer Let's Encrypt et Pterodactyl : " "L'e-mail ne peut pas être vide ou invalide"

  # Initial admin account
  email_input user_email "Adresse e-mail du compte administrateur initial : " "L'e-mail ne peut pas être vide ou invalide"
  required_input user_username "Nom d'utilisateur pour le compte administrateur initial : " "Le nom d'utilisateur ne peut pas être vide"
  required_input user_firstname "Prénom du compte administrateur initial : " "Le nom ne peut pas être vide"
  required_input user_lastname "Nom de famille du compte administrateur initial : " "Le nom ne peut pas être vide"
  password_input user_password "Mot de passe du compte administrateur initial : " "Le mot de passe ne peut pas être vide"

  print_brake 72

  # set FQDN
  while [ -z "$FQDN" ]; do
    echo -n "* Définissez le FQDN/IP de ce panel (panel.ygaming.fr/XX.XXX.XXX.XX): "
    read -r FQDN
    [ -z "$FQDN" ] && error "Le FQDN/IP ne peut pas être vide"
  done

  # Check if SSL is available
  check_FQDN_SSL

  # Ask if firewall is needed
  ask_firewall CONFIGURE_FIREWALL

  # Only ask about SSL if it is available
  if [ "$SSL_AVAILABLE" == true ]; then
    # Ask if letsencrypt is needed
    ask_letsencrypt
    # If it's already true, this should be a no-brainer
    [ "$CONFIGURE_LETSENCRYPT" == false ] && ask_assume_ssl
  fi

  # verify FQDN if user has selected to assume SSL or configure Let's Encrypt
  [ "$CONFIGURE_LETSENCRYPT" == true ] || [ "$ASSUME_SSL" == true ] && bash <(curl -s "$GITHUB_URL"/lib/verify-fqdn.sh) "$FQDN"

  # summary
  summary

  # confirm installation
  echo -e -n "\n* Configuration initiale terminée. Continuer l'installation ? (y/N): "
  read -r CONFIRM
  if [[ "$CONFIRM" =~ [Yy] ]]; then
    run_installer "panel"
  else
    error "Installation interrompue."
    exit 1
  fi
}

summary() {
  print_brake 62
  output "Pterodactyl panel $PTERODACTYL_PANEL_VERSION nginx activé avec $OS"
  output "Nom de la base de données: $MYSQL_DB"
  output "Utilisateur de la base de données: $MYSQL_USER"
  output "Mot de passe de la base de données: $MYSQL_PASSWORD"
  output "Fuseau horaire: $timezone"
  output "E-mail: $email"
  output "Mail de l'utilisateur: $user_email"
  output "Nom d'utilisateur: $user_username"
  output "Prénom: $user_firstname"
  output "Nom de famille: $user_lastname"
  output "Mot de passe de l'utilisateur: (cacher)"
  output "Nom d'hôte/FQDN/IP: $FQDN"
  output "Configurer le pare-feu? $CONFIGURE_FIREWALL"
  output "Configurer Let's Encrypt? $CONFIGURE_LETSENCRYPT"
  output "Assume SSL? $ASSUME_SSL"
  print_brake 62
}

goodbye() {
  print_brake 62
  output "Panel installation terminée"
  output ""

  [ "$CONFIGURE_LETSENCRYPT" == true ] && output "Votre panneau doit être accessible depuis $(hyperlink "$FQDN")"
  [ "$ASSUME_SSL" == true ] && [ "$CONFIGURE_LETSENCRYPT" == false ] && output "Vous avez choisi d'utiliser SSL, mais pas via Let's Encrypt automatiquement. Votre panneau ne fonctionnera pas tant que SSL n'aura pas été configuré."
  [ "$ASSUME_SSL" == false ] && [ "$CONFIGURE_LETSENCRYPT" == false ] && output "Votre panneau doit être accessible depuis $(hyperlink "$FQDN")"

  output ""
  output "L'installation utilise nginx sur $OS"
  output "Merci d'avoir utilisé ce script."
  [ "$CONFIGURE_FIREWALL" == false ] && echo -e "* ${COLOR_RED}Note${COLOR_NC}: Si vous n'avez pas configuré le pare-feu : 80/443 (HTTP/HTTPS) doit être ouvert !"
  print_brake 62
}

# run script
main
goodbye
