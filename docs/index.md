# odoo-helper-scripts documentation

*Documentation is work-in-progress, so here is only basic documentation*

Quick links:

- [Quick Start Guide](./quick-start-guide.md) 
- [Frequently used commands](./frequently-used-commands.md)
- [Command reference](./command-reference.md)

## Overview

This project aims to simplify development process of Odoo addons as much as possible.


## Features

- Easily manage few instances of odoo that ran on same machine
- High usage of [virtualenv](https://virtualenv.pypa.io/en/stable/) for isolation purpose
- Use [nodeenv](https://pypi.python.org/pypi/nodeenv) to install [node.js](https://nodejs.org/en/), [phantom.js](http://phantomjs.org/), etc in isolated [virtualenv](https://virtualenv.pypa.io/en/stable/)
- Powerful testing capabilities, including support for:
    - *python* and *js* code check via [pylint\_odoo](https://pypi.python.org/pypi/pylint-odoo) (which uses [ESLint](https://eslint.org/) to check JS files)
    - *python* code check via [flake8](https://pypi.python.org/pypi/flake8)
    - styles (*.css*, *.scss*, *.less* files) check via [stylelint](https://stylelint.io/)
    - compute test code coverage via [coverage.py](https://coverage.readthedocs.io)
    - Test web tours via [phantom.js](http://phantomjs.org/) or *chromium browser* (Odoo 12.0+)
- Easy addons installation
    - Automatiacly resolve and fetch dependencies
        - oca\_dependencies.txt ([sample](https://github.com/OCA/maintainer-quality-tools/blob/master/sample_files/oca_dependencies.txt), [mqt tool code](https://github.com/OCA/maintainer-quality-tools/blob/master/sample_files/oca_dependencies.txt))
        - [requirements.txt](https://pip.readthedocs.io/en/stable/user_guide/#requirements-files)
    - Own file format to track addon dependencies: [odoo\_requirements.txt](https://katyukha.gitlab.io/odoo-helper-scripts/odoo-requirements-txt/)
    - installation directly from [Odoo Market](https://apps.odoo.com/apps) (**experimental**)
        - Only free addons
        - Including dependencies
        - Semi-automatic upgrade when new version released
    - installation from *git* repositories
    - installation from *Mercurial* repositories (**experimental**)
    - installation of python dependencies from [PyPI](pypi.python.org/pypi) or any [vcs supported by setuptools](https://setuptools.readthedocs.io/en/latest/setuptools.html?highlight=develop%20mode#dependencies-that-aren-t-in-pypi)
    - automatically processing of [requirements.txt](https://pip.pypa.io/en/stable/user_guide/#requirements-files) files located inside repository root and addon directories.
    - shortcuts that simplifies fetching addons from [OCA](https://github.com/OCA) or [github](https://github.com)
    - works good with long recursive dependencies.
      One of the reasons for this script collection development was,
      ability to automaticaly install more that 50 addons,
      that depend on each other, and where each addon have it's own git repo.
- Continious Integration related features
    - ensure addon version changed
    - ensure repository version changed
    - ensure each addon have icon
- Translation management from command line
    - import / export translations by command from shell
    - test translation rate for specified language
    - regenerate translations for specified language
    - load language (for one db or for old databases)
- Supported odoo versions:
    - *8.0*
    - *9.0*
    - *10.0*
    - *11.0*
    - *12.0*
    - *13.0* (requires ubuntu 18.04+ or other linux distribution with python 3.6+)
    - *14.0* (requires ubuntu 18.04+ or other linux distribution with python 3.8+)
    - *15.0* (requires ubuntu 18.04+ or other linux distribution with python 3.8+)
    - *16.0* (requires ubuntu 18.04+ or other linux distribution with python 3.8+)
    - *17.0* (requires ubuntu 18.04+ or other linux distribution with python 3.8+)
    - *18.0* (requires ubuntu 20.04+ or other linux distribution with python 3.10+)
    - *18.3* (requires ubuntu 22.04+ or other linux distribution with python 3.10+)
- OS support:
    - On *Ubuntu* should work nice
    - Also should work on *Debian* based systems, but some troubles may happen with installation of system dependencies.
    - Other linux systems - in most cases should work, but system dependecies must be installed manualy.
- Missed feature? [Fill an issue](https://github.com/huntergps/odoo-helper-scripts/issues/new)


## Usage note

This script collection is designed to simplify life of addons developer.
This project ***is not*** designed, to install and configure production ready Odoo instances!

For production-ready installations look at [crnd-deploy](http://github.com/crnd-inc/crnd-deploy) project.

Also take a look at [Yodoo Cockpit](https://crnd.pro/yodoo-cockpit) project.



## Installation

For full list of installation options look at [installation documentation](./installation.md)
or [Quick Start Guide](./quick-start-guide.md)

*Starting from 0.1.7-alpha release odoo-helper-scripts could be installed as* [.deb packages](https://katyukha.gitlab.io/odoo-helper-scripts/installation#install-as-deb-package)*,
but this feature is still in alpha. See* [releases](https://github.com/huntergps/odoo-helper-scripts/releases) *page.*

To install *odoo-helper-scripts* system-wide do folowing:

```bash
# Install odoo-helper-scripts
wget -O - https://github.com/huntergps/odoo-helper-scripts/raw/master/install-system.bash | sudo bash -s

# Install system dependencies required for odoo-helper-scripts
# NOTE: Works only on debian-based systems
odoo-helper install pre-requirements
```

or more explicit way:

```bash
# Download installation script
wget -O /tmp/odoo-helper-install.bash https://github.com/huntergps/odoo-helper-scripts/raw/master/install-system.bash;

# Install odoo-helper-scripts
sudo bash /tmp/odoo-helper-install.bash;

#  Intall system pre-requirements for odoo-helper-scripts
# NOTE: Works only on debian-based systems
odoo-helper install pre-requirements
```

Do not forget to install and configure postgres:

```bash
# install postgres and create db user with name 'odoo' and password 'odoo'
odoo-helper install postgres odoo odoo
```


## Basic usage

### odoo-install

Install Odoo in specified directory (using virtualenv)

```bash
odoo-helper install sys-deps 11.0  # install global system dependencies for specified version of Odoo
odoo-install --odoo-version 11.0   # no sudo required
```

After this you will have odoo and it's dependencies installed into *odoo-11.0* directory.

This installation also creates *odoo-helper.conf* file inside project, which allows to use
*odoo-helper* script to simplify interaction with this odoo installation.

Description of *odoo-helper* project's directory structure is [here](./project-directory-structure.md)


### odoo-helper

This is the main script to manage Odoo instances installed by *odoo-install*

Most of *odoo-helper-scripts* functionality is implemented as *subcommands* of `odoo-helper`.
For example `odoo-helper server` contains server management commands like:

- `odoo-helper server start`
- `odoo-helper server stop`
- `odoo-helper server restart`
- etc

All *odoo-helper commands* may be splited in two groups:

- Odoo instance management commands
- Other

*Odoo instance management commands* are commands that manage Odoo instances installed using `odoo-install` script.
Example of such commands may be: `odoo-helper server` or `odoo-helper db` commands.
These commands are required to be ran inside Odoo instance directory (directory with Odoo installed using `odoo-install`)
or its subdirectories. Thus*odoo-helper* could find project/instance [config file](./odoo-helper-configuration.md).

See [Frequently used commands](./frequently-used-commands.md) and [Command reference](./command-reference.md) for more info about available commands
or just run `odoo-helper --help`

## Support

Have you any quetions? Just [fill an issue](https://github.com/huntergps/odoo-helper-scripts/issues/new) or [send email](mailto:incoming+katyukha/odoo-helper-scripts@incoming.gitlab.com)
