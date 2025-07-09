# Colección de scripts auxiliares de Odoo

| Master        | [![pipeline status](https://gitlab.com/katyukha/odoo-helper-scripts/badges/master/pipeline.svg)](https://gitlab.com/katyukha/odoo-helper-scripts/commits/master) |  [![coverage report](https://gitlab.com/katyukha/odoo-helper-scripts/badges/master/coverage.svg)](https://gitlab.com/katyukha/odoo-helper-scripts/commits/master)| [![CHANGELOG](https://img.shields.io/badge/CHANGELOG-master-brightgreen.svg)](https://gitlab.com/katyukha/odoo-helper-scripts/blob/master/CHANGELOG.md)              |
| ------------- |:---------------|:--------------|:------------|
| Dev           | [![pipeline status](https://gitlab.com/katyukha/odoo-helper-scripts/badges/dev/pipeline.svg)](https://gitlab.com/katyukha/odoo-helper-scripts/commits/dev) | [![coverage report](https://gitlab.com/katyukha/odoo-helper-scripts/badges/dev/coverage.svg)](https://gitlab.com/katyukha/odoo-helper-scripts/commits/dev) | [![CHANGELOG](https://img.shields.io/badge/CHANGELOG-dev-yellow.svg)](https://gitlab.com/katyukha/odoo-helper-scripts/blob/dev/CHANGELOG.md) |

## Descripción general

Este proyecto tiene como objetivo simplificar el proceso de desarrollo de complementos de Odoo tanto como sea posible.

## Fuente canónica

La fuente canónica de odoo-helper-scripts está alojada en [GitLab](https://gitlab.com/katyukha/odoo-helper-scripts).

## Características

- Gestionar fácilmente algunas instancias de Odoo que se ejecutan en la misma máquina
- Alto uso de [virtualenv](https://virtualenv.pypa.io/en/stable/) para propósitos de aislamiento
- Usar [nodeenv](https://pypi.python.org/pypi/nodeenv) para instalar [node.js](https://nodejs.org/en/), [phantom.js](http://phantomjs.org/), etc. en [virtualenv](https://virtualenv.pypa.io/en/stable/) aislado
- Capacidades de prueba potentes, incluyendo soporte para:
    - verificación de código *python* y *js* vía [pylint\_odoo](https://pypi.python.org/pypi/pylint-odoo) (que usa [ESLint](https://eslint.org/) para verificar archivos JS)
    - verificación de código *python* vía [flake8](https://pypi.python.org/pypi/flake8)
    - verificación de estilos (*.css*, *.scss*, *.less* archivos) vía [stylelint](https://stylelint.io/)
    - calcular cobertura de código de prueba vía [coverage.py](https://coverage.readthedocs.io)
    - Probar tours web vía [phantom.js](http://phantomjs.org/) o *navegador chromium* (Odoo 12.0+)
- Instalación fácil de complementos
    - Resolver y obtener automáticamente dependencias
        - oca\_dependencies.txt ([muestra](https://github.com/OCA/maintainer-quality-tools/blob/master/sample_files/oca_dependencies.txt), [código de herramienta mqt](https://github.com/OCA/maintainer-quality-tools/blob/master/sample_files/oca_dependencies.txt))
        - [requirements.txt](https://pip.readthedocs.io/en/stable/user_guide/#requirements-files)
    - Formato de archivo propio para rastrear dependencias de complementos: [odoo\_requirements.txt](https://katyukha.gitlab.io/odoo-helper-scripts/odoo-requirements-txt/)
    - instalación directamente desde [Odoo Market](https://apps.odoo.com/apps) (**experimental**)
        - Solo complementos gratuitos
        - Incluyendo dependencias
        - Actualización semi-automática cuando se lanza nueva versión
    - instalación desde repositorios *git*
    - instalación desde repositorios *Mercurial* (**experimental**)
    - instalación de dependencias python desde [PyPI](pypi.python.org/pypi) o cualquier [vcs soportado por setuptools](https://setuptools.readthedocs.io/en/latest/setuptools.html?highlight=develop%20mode#dependencies-that-aren-t-in-pypi)
    - procesamiento automático de archivos [requirements.txt](https://pip.pypa.io/en/stable/user_guide/#requirements-files) ubicados dentro del directorio raíz del repositorio y directorios de complementos.
    - atajos que simplifican la obtención de complementos desde [OCA](https://github.com/OCA) o [github](https://github.com)
    - funciona bien con dependencias recursivas largas.
      Una de las razones para el desarrollo de esta colección de scripts fue,
      la capacidad de instalar automáticamente más de 50 complementos,
      que dependen entre sí, y donde cada complemento tiene su propio repositorio git.
- Características relacionadas con Integración Continua
    - asegurar que la versión del complemento cambió
    - asegurar que la versión del repositorio cambió
    - asegurar que cada complemento tenga icono
- Gestión de traducciones desde línea de comandos
    - importar / exportar traducciones por comando desde shell
    - probar tasa de traducción para idioma especificado
    - regenerar traducciones para idioma especificado
    - cargar idioma (para una db o para bases de datos antiguas)
- Versiones de Odoo soportadas:
    - *8.0*
    - *9.0*
    - *10.0*
    - *11.0*
    - *12.0*
    - *13.0* (requiere ubuntu 18.04+ u otra distribución linux con python 3.6+)
    - *14.0* (requiere ubuntu 18.04+ u otra distribución linux con python 3.8+)
    - *15.0* (requiere ubuntu 18.04+ u otra distribución linux con python 3.8+)
    - *16.0* (requiere ubuntu 18.04+ u otra distribución linux con python 3.8+)
    - *17.0* (requiere ubuntu 18.04+ u otra distribución linux con python 3.8+)
    - *18.0* (requiere ubuntu 20.04+ u otra distribución linux con python 3.10+)
    - *18.3* (requiere ubuntu 22.04+ u otra distribución linux con python 3.10+)
- Soporte de SO:
    - En *Ubuntu* debería funcionar bien
    - También debería funcionar en sistemas basados en *Debian*, pero pueden ocurrir algunos problemas con la instalación de dependencias del sistema.
    - Otros sistemas linux - en la mayoría de casos debería funcionar, pero las dependencias del sistema deben instalarse manualmente.
- ¿Falta alguna característica? [Llena un issue](https://gitlab.com/katyukha/odoo-helper-scripts/issues/new)


## Documentación

***Nota*** ¡La documentación en este readme, o en otras fuentes, puede no estar actualizada!
Así que usa la opción `--help`, que está disponible para la mayoría de comandos.

- [Documentación](https://katyukha.gitlab.io/odoo-helper-scripts/)
- [Instalación](https://katyukha.gitlab.io/odoo-helper-scripts/installation/)
- [Comandos frecuentemente usados](https://katyukha.gitlab.io/odoo-helper-scripts/frequently-used-commands/)
- [Referencia de Comandos](https://katyukha.gitlab.io/odoo-helper-scripts/command-reference/)


## Nota de uso

Esta colección de scripts está diseñada para simplificar la vida del desarrollador de complementos.
¡Este proyecto ***no está*** diseñado para instalar y configurar instancias de Odoo listas para producción!

Para instalaciones listas para producción mira el proyecto [crnd-deploy](http://github.com/crnd-inc/crnd-deploy).

También echa un vistazo al proyecto [Yodoo Cockpit](https://crnd.pro/yodoo-cockpit).


## Instalación

Para la lista completa de opciones de instalación mira la [documentación de instalación](https://katyukha.gitlab.io/odoo-helper-scripts/installation/)

*A partir de la versión 0.1.7 odoo-helper-scripts se puede instalar como* [paquetes .deb](https://katyukha.gitlab.io/odoo-helper-scripts/installation#install-as-deb-package)*,
pero esta característica sigue siendo experimental. Ve la página de* [releases](https://gitlab.com/katyukha/odoo-helper-scripts/tags) *.*

Para instalar *odoo-helper-scripts* a nivel del sistema haz lo siguiente:

```bash
# Instalar odoo-helper-scripts
wget -O - https://gitlab.com/katyukha/odoo-helper-scripts/raw/master/install-system.bash | sudo bash -s

# Instalar dependencias del sistema requeridas para odoo-helper-scripts
# NOTA: Solo funciona en sistemas basados en debian
odoo-helper install pre-requirements

# Instalar Odoo 18.3
odoo-install --odoo-version 18.3 --local-postgres --local-nginx
```

o de forma más explícita:

```bash
# Descargar script de instalación
wget -O /tmp/odoo-helper-install.bash https://gitlab.com/katyukha/odoo-helper-scripts/raw/master/install-system.bash;

# Instalar odoo-helper-scripts
sudo bash /tmp/odoo-helper-install.bash;

#  Instalar pre-requisitos del sistema para odoo-helper-scripts
# NOTA: Solo funciona en sistemas basados en debian
odoo-helper install pre-requirements
```

## Probar soporte de tu SO

Es posible ejecutar pruebas básicas vía docker.
Para esta tarea, el repositorio odoo-helper-scripts contiene el script `scripts/run_docker_test.bash`.
Ejecuta `bash scripts/run_docker_test.bash --help` para ver todas las opciones disponibles para ese script.

Por ejemplo para probar cómo funcionará odoo-helper-scripts en debian:stretch, haz lo siguiente:

```bash
cd $ODOO_HELPER_ROOT
bash scripts/run_docker_test.bash --docker-ti --docker-image debian:stretch
```


## Uso

Y después de instalar tendrás disponibles los siguientes scripts en tu path:

- odoo-install
- odoo-helper

Cada script tiene la opción `-h` o `--help` que muestra la información más relevante
sobre el script y todas las opciones y subcomandos posibles del script

También hay algunos alias para comandos comunes:

- odoo-helper-addons
- odoo-helper-db
- odoo-helper-fetch
- odoo-helper-log
- odoo-helper-restart
- odoo-helper-server
- odoo-helper-test

Para más información mira la [documentación](https://katyukha.gitlab.io/odoo-helper-scripts/). (actualmente el estado de la documentación es *trabajo-en-progreso*).
También mira [Comandos frecuentemente usados](https://katyukha.gitlab.io/odoo-helper-scripts/frequently-used-commands/) y [Referencia de comandos](https://katyukha.gitlab.io/odoo-helper-scripts/command-reference/)

También mira las [pruebas de odoo-helper-scripts](./tests/test.bash) para obtener un ejemplo completo de uso (busca el comentario *Start test*).

## Soporte

¿Tienes alguna pregunta? Solo [llena un issue](https://gitlab.com/katyukha/odoo-helper-scripts/issues/new) o [envía email](mailto:incoming+katyukha/odoo-helper-scripts@incoming.gitlab.com)
