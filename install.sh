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

export GITHUB_SOURCE="main"
export SCRIPT_RELEASE="main"
export GITHUB_BASE_URL="https://raw.githubusercontent.com/mrflytbs/pterodactyl-installer"

LOG_PATH="/var/log/pterodactyl-installer.log"

# check for curl
if ! [ -x "$(command -v curl)" ]; then
  echo "* curl est requis pour que ce script fonctionne."
  echo "* installer en utilisant apt (Debian et dérivés) ou yum/dnf (CentOS)"
  exit 1
fi

# Always remove lib.sh, before downloading it
rm -rf /tmp/lib.sh
curl -sSL -o /tmp/lib.sh "$GITHUB_BASE_URL"/"$GITHUB_SOURCE"/lib/lib.sh
# shellcheck source=lib/lib.sh
source /tmp/lib.sh

execute() {
  echo -e "\n\n* pterodactyl-installer $(date) \n\n" >>$LOG_PATH

  [[ "$1" == *"canary"* ]] && export GITHUB_SOURCE="master" && export SCRIPT_RELEASE="canary"
  update_lib_source
  run_ui "${1//_canary/}" |& tee -a $LOG_PATH

  if [[ -n $2 ]]; then
    echo -e -n "* Installation de $1 complété. Voulez-vous passer à $2 installation? (y/N): "
    read -r CONFIRM
    if [[ "$CONFIRM" =~ [Yy] ]]; then
      execute "$2"
    else
      error "Installation de $2 annulé."
      exit 1
    fi
  fi
}

welcome "TRTESTETS"

done=false
while [ "$done" == false ]; do
  options=(
    "Installer le panel"
    "Installer Wings"
    "Installez les deux [0] et [1] sur la même machine (le script Wings se lancera apres le Panel)"
    # "Uninstall panel or wings\n"

    # "Install panel with canary version of the script (the versions that lives in master, may be broken!)"
    # "Install Wings with canary version of the script (the versions that lives in master, may be broken!)"
    # "Install both [3] and [4] on the same machine (wings script runs after panel)"
    # "Uninstall panel or wings with canary version of the script (the versions that lives in master, may be broken!)"
  )

  actions=(
    "panel"
    "wings"
    "panel;wings"
    # "uninstall"

    # "panel_canary"
    # "wings_canary"
    # "panel_canary;wings_canary"
    # "uninstall_canary"
  )

  output "Qu'est-ce que tu aimerais faire?"

  for i in "${!options[@]}"; do
    output "[$i] ${options[$i]}"
  done

  echo -n "* Input 0-$((${#actions[@]} - 1)): "
  read -r action

  [ -z "$action" ] && error "Une entrée est requise" && continue

  valid_input=("$(for ((i = 0; i <= ${#actions[@]} - 1; i += 1)); do echo "${i}"; done)")
  [[ ! " ${valid_input[*]} " =~ ${action} ]] && error "Option invalide"
  [[ " ${valid_input[*]} " =~ ${action} ]] && done=true && IFS=";" read -r i1 i2 <<<"${actions[$action]}" && execute "$i1" "$i2"
done

# Remove lib.sh, so next time the script is run the, newest version is downloaded.
rm -rf /tmp/lib.sh
