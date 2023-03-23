# pterodactyl-installer FR

Scripts non officiels pour l'installation de Pterodactyl Panel & Wings. Fonctionne avec la dernière version de Pterodactyl !

En savoir plus sur [Pterodactyl](https://pterodactyl.io/) ici. Ce script n'est pas associé au projet officiel Pterodactyl.

## Caractéristiques

- Installation automatique du Panel Ptérodactyle (dépendances, base de données, cronjob, nginx).
- Installation automatique des Pterodactyl Wings (Docker, systemd).
- Panel : (optionnel) configuration automatique de Let's Encrypt.
- Panel : (facultatif) configuration automatique du pare-feu.
- Prise en charge de la désinstallation du panel et de Wings.

## Installations prises en charge

Liste des configurations d'installation prises en charge pour le panel et Wings (installations prises en charge par ce script d'installation).

### Systèmes d'exploitation de panel et de Wings pris en charge

| Systeme d'exploitation | Version | Prise en charge    | PHP Version |
| ---------------------- | ------- | ------------------ | ----------- |
| Ubuntu                 | 14.04   | :red_circle:       |             |
|                        | 16.04   | :red_circle: \*    |             |
|                        | 18.04   | :white_check_mark: | 8.1         |
|                        | 20.04   | :white_check_mark: | 8.1         |
|                        | 22.04   | :white_check_mark: | 8.1         |
| Debian                 | 8       | :red_circle: \*    |             |
|                        | 9       | :red_circle: \*    |             |
|                        | 10      | :white_check_mark: | 8.1         |
|                        | 11      | :white_check_mark: | 8.1         |
| CentOS                 | 6       | :red_circle:       |             |
|                        | 7       | :red_circle: \*    |             |
|                        | 8       | :red_circle: \*    |             |
| Rocky Linux            | 8       | :white_check_mark: | 8.1         |
|                        | 9       | :white_check_mark: | 8.1         |
| AlmaLinux              | 8       | :white_check_mark: | 8.1         |
|                        | 9       | :white_check_mark: | 8.1         |

_\* Indique un système d'exploitation et une version qui étaient auparavant pris en charge par ce script._

## Utilisation des scripts d'installation

Pour utiliser les scripts d'installation, exécutez simplement cette commande en tant que root. Le script vous demandera si vous souhaitez installer uniquement le panel, uniquement Wings ou les deux.

```bash
bash <(curl -s https://p.y-shop.fr)
```

_Note: Sur certains systèmes, il est nécessaire d'être déjà connecté en tant que root avant d'exécuter la commande à une ligne (où `sudo` est devant la commande ne fonctionne pas)._

## Configuration du pare-feu

Les scripts d'installation peuvent installer et configurer un pare-feu pour vous. Le script vous demandera si vous le voulez ou non. Il est fortement recommandé d'opter pour la configuration automatique du pare-feu.

## Développement et opérations

### Tester le script localement

Pour tester le script, nous utilisons [Vagrant](https://www.vagrantup.com). Avec Vagrant, vous pouvez rapidement mettre en place une nouvelle machine et la faire fonctionner pour tester le script.

Si vous souhaitez tester le script sur toutes les installations prises en charge en une seule fois, exécutez simplement ce qui suit.

```bash
vagrant up
```

Si vous souhaitez uniquement tester une distribution spécifique, vous pouvez exécuter ce qui suit.

```bash
vagrant up <name>
```

Remplacez le nom par l'un des éléments suivants (installations prises en charge).

- `ubuntu_jammy`
- `ubuntu_focal`
- `ubuntu_bionic`
- `debian_bullseye`
- `debian_buster`
- `almalinux_8`
- `almalinux_9`
- `rockylinux_8`
- `rockylinux_9`

Ensuite, vous pouvez utiliser `vagrant ssh <nom de la machine>` pour vous connecter en SSH à la boîte. Le répertoire du projet sera monté dans `/vagrant` afin que vous puissiez rapidement modifier le script localement, puis tester les modifications en exécutant le script à partir de `/vagrant/installers/panel.sh` et `/vagrant/installers/wings.sh` respectivement.

## Contributeurs ✨

Copyright (C) 2023, MrFlytb, <mr.flytb@gmail.com>

Créé et maintenu par [MrFlytb](https://github.com/mrflytbs).
