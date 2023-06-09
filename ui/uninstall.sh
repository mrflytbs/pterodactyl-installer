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
  ! fn_exists lib_loaded && echo "* ERROR: Could not load lib script" && exit 1
fi

# ------------------ Variables ----------------- #

export RM_PANEL=false
export RM_WINGS=false

# --------------- Main functions --------------- #

main() {
  welcome ""

  if [ -d "/var/www/pterodactyl" ]; then
    output "Panel installation has been detected."
    echo -e -n "* Do you want to remove panel? (y/N): "
    read -r RM_PANEL_INPUT
    [[ "$RM_PANEL_INPUT" =~ [Yy] ]] && RM_PANEL=true
  fi

  if [ -d "/etc/pterodactyl" ]; then
    output "Wings installation has been detected."
    warning "This will remove all the servers!"
    echo -e -n "* Do you want to remove Wings (daemon)? (y/N): "
    read -r RM_WINGS_INPUT
    [[ "$RM_WINGS_INPUT" =~ [Yy] ]] && RM_WINGS=true
  fi

  if [ "$RM_PANEL" == false ] && [ "$RM_WINGS" == false ]; then
    error "Nothing to uninstall!"
    exit 1
  fi

  summary

  # confirm uninstallation
  echo -e -n "* Continue with uninstallation? (y/N): "
  read -r CONFIRM
  if [[ "$CONFIRM" =~ [Yy] ]]; then
    run_installer "uninstall"
  else
    error "Uninstallation aborted."
    exit 1
  fi
}

summary() {
  print_brake 30
  output "Uninstall panel? $RM_PANEL"
  output "Uninstall wings? $RM_WINGS"
  print_brake 30
}

goodbye() {
  print_brake 62
  [ "$RM_PANEL" == true ] && output "Panel uninstallation completed"
  [ "$RM_WINGS" == true ] && output "Wings uninstallation completed"
  output "Thank you for using this script."
  print_brake 62
}

main
goodbye
