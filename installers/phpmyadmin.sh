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

# When #280 is merged
