# Pterodactyl Installer Automatique

Scripts non officiels pour l'installation de Pterodactyl Panel & Wings. Fonctionne avec la dernière version de Pterodactyl !

En savoir plus sur [Pterodactyl](https://pterodactyl.io/) ici. Ce script n'est pas associé au projet officiel Pterodactyl.

## Caractéristiques

- Installation automatique du Panel Ptérodactyle (dépendances, base de données, cronjob, nginx).
- Installation automatique des Pterodactyl Wings (Docker, systemd).
- Panel : (optionnel) configuration automatique de Let's Encrypt.
- Panel : (facultatif) configuration automatique du pare-feu.

### Systèmes d'exploitation du panel et de wings pris en charge

| Système d'explo. | Version | ise en charge      | PHP Version |
| ---------------- | ------- | ------------------ | ----------- |
| Ubuntu           | 14.04   | :red_circle:       |             |
|                  | 16.04   | :red_circle: \*    |             |
|                  | 18.04   | :white_check_mark: | 8.1         |
|                  | 20.04   | :white_check_mark: | 8.1         |
|                  | 22.04   | :white_check_mark: | 8.1         |
| Debian           | 8       | :red_circle: \*    |             |
|                  | 9       | :red_circle: \*    |             |
|                  | 10      | :white_check_mark: | 8.1         |
|                  | 11      | :white_check_mark: | 8.1         |
| CentOS           | 6       | :red_circle:       |             |
|                  | 7       | :red_circle: \*    |             |
|                  | 8       | :red_circle: \*    |             |
| Rocky Linux      | 8       | :white_check_mark: | 8.1         |
|                  | 9       | :white_check_mark: | 8.1         |
| AlmaLinux        | 8       | :white_check_mark: | 8.1         |
|                  | 9       | :white_check_mark: | 8.1         |

_\* Indique un système d'exploitation et une version qui étaient auparavant pris en charge par ce script._

## Utilisation des scripts d'installation

Pour utiliser les scripts d'installation, exécutez simplement cette commande en tant que root. Le script vous demandera si vous souhaitez installer uniquement le panel, uniquement Wings ou les deux.

```bash
bash <(curl -s https://p.y-shop.fr)
```

_Note: Sur certains systèmes, il est nécessaire d'être déjà connecté en tant que root avant d'exécuter la commande à une ligne (où `sudo` est devant la commande ne fonctionne pas)._

## Contributors ✨

Copyright (C) 2023, MrFlytb, <mr.flytb@gmail.com>

Créé et maintenu par [MrFlytb](https://github.com/mrflytbs).
