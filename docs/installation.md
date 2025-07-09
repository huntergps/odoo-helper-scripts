# Instalación de odoo-helper-scripts

La instalación de *odoo-helper-scripts* consiste en tres pasos:

1. Instalar *odoo-helper-scripts*
2. Instalar dependencias del sistema para *odoo-helper-scripts*
3. Instalar dependencias para la versión específica de *Odoo*

El segundo paso está separado, porque instalar dependencias del sistema en diferentes
plataformas puede diferir y la instalación automática de dependencias del sistema
solo está soportada en sistemas tipo debian (usando apt)


## Instalando odoo-helper-scripts en sí
Hay tres opciones para instalar *odoo-helper-scripts*:

- [instalación *espacio de usuario*](#instalación-espacio-de-usuario)
- [instalación *a nivel del sistema*](#instalación-a-nivel-del-sistema)
- [*como paquete .deb* (**experimental**)](#instalar-como-paquete-deb)

### Instalación espacio de usuario

```bash
wget -O - https://gitlab.com/katyukha/odoo-helper-scripts/raw/master/install-user.bash | bash -s
```

o de forma más explícita:

```bash
wget -O odoo-helper-install-user.bash https://gitlab.com/katyukha/odoo-helper-scripts/raw/master/install-user.bash
bash odoo-helper-install-user.bash
```

Después de la instalación tendrás el directorio ``odoo-helper-scripts`` dentro de tu directorio home
Y se generará el archivo ``$HOME/odoo-helper.conf`` con la ruta al directorio de instalación de odoo-helper-scripts.
Los ejecutables de *odoo-helper-scripts* se colocarán en el directorio ``$HOME/bin/``.
Si este directorio no existe al momento de la instalación, entonces se creará.

#### Bugs conocidos y soluciones para instalación espacio de usuario

1. *comando no encontrado `odoo-helper`* después de la instalación. Usualmente esto sucede, porque no hay
   directorio `$HOME/bin` o no está en `$PATH` antes de la instalación.
   Después de la instalación este directorio se creará, pero pueden requerirse pasos adicionales para agregarlo a `$PATH`
    - reiniciar sesión de shell (por ejemplo abrir nueva ventana o pestaña de terminal).
      Esto puede ayudar si el shell está configurado para usar el directorio `$HOME/bin` si existe.
    - si se usa *bash* como shell, entonces puede ser suficiente hacer source del archivo `.profile` (`$ source $HOME/.profile`)
    - agregar directorio `$HOME/bin` a `$PATH` en tu configuración de inicio de shell ([Pregunta de Stack Exchange](https://unix.stackexchange.com/questions/381228/home-bin-dir-is-not-on-the-path))

### Instalación a nivel del sistema

Para instalar (a nivel del sistema) solo haz lo siguiente:

```bash
# Instalar odoo-helper-scripts
wget -O - https://gitlab.com/katyukha/odoo-helper-scripts/raw/master/install-system.bash | sudo bash -s
```

o de forma más explícita:

```bash
# Descargar script de instalación
wget -O /tmp/odoo-helper-install.bash https://gitlab.com/katyukha/odoo-helper-scripts/raw/master/install-system.bash;

# Instalar odoo-helper-scripts
sudo bash /tmp/odoo-helper-install.bash;
```

Después de la instalación el código de *odoo-helper-scripts* se colocará en el directorio ``/opt/odoo-helper-scripts``.
El archivo ``odoo-helper.conf`` que contiene la configuración global de odoo-helper se colocará dentro del directorio ``/etc/``
Los ejecutables de *odoo-helper-scripts* se colocarán en el directorio ``/usr/local/bin``.

### Instalar como paquete .deb

***Nota***: ¡esta característica es experimental!

Desde el lanzamiento *0.1.7-alpha* es posible instalar *odoo-helper-scripts* como paquete *.deb*.

Busca un enlace en la [página de releases](https://gitlab.com/katyukha/odoo-helper-scripts/tags)


## Instalar dependencias del sistema para odoo-helper-scripts

En este paso se deben instalar las dependencias del sistema.
Esto se puede hacer automáticamente para sistemas *basados en debian*:

```bash
odoo-helper install pre-requirements
```

En otros sistemas operativos puede requerir instalar dependencias del sistema manualmente
Por ejemplo el siguiente comando instalará dependencias del sistema para [OpenSUSE](https://www.opensuse.org/) linux

```bash
zypper install git wget python-setuptools gcc postgresql-devel python-devel expect-devel libevent-devel libjpeg-devel libfreetype6-devel zlib-devel libxml2-devel libxslt-devel cyrus-sasl-devel openldap2-devel libssl43 libffi-devel
```

También, *PostgreSQL* es usualmente requerido para desarrollo local.
Para sistemas *basados en debian* se puede usar odoo-helper:

```bash
odoo-helper install postgres
```

El usuario postgres para odoo puede crearse al mismo tiempo

```bash
odoo-helper install postgres odoo_user odoo_password
```

*Nota: se recomienda crear nuevo usuario postgres para cada instancia de Odoo*

Para otros sistemas debe instalarse manualmente


## Instalar dependencias del sistema de Odoo

Para hacer que Odoo funcione, pueden requerirse algunas dependencias del sistema específicas para la versión.
La mayoría de dependencias python se instalan en virtualenv, así que no se necesita acceso sudo.
Pero algunas librerías del sistema no-python pueden ser requeridas.

Por esta razón para sistemas *basados en debian* existe un comando más de odoo-helper

```bash
#odoo-helper install sys-deps <odoo-version>
odoo-helper install sys-deps 11.0
```

Para otros sistemas tales dependencias deben instalarse manualmente


## Instalación de versión de desarrollo

Los scripts de instalación pueden recibir argumento de *referencia*. Esto puede ser nombre de rama, nombre de tag o hash de commit.
Así que para instalar versión de *desarrollo* a nivel del sistema ejecuta el siguiente comando:

```bash
# Instalar odoo-helper-scripts  (nota '- dev' al final del comando)
wget -O - https://gitlab.com/katyukha/odoo-helper-scripts/raw/master/install-system.bash | sudo bash -s - dev

#  Instalar pre-requisitos del sistema para odoo-helper-scripts
odoo-helper install pre-requirements
```

Para instalación espacio de usuario:

```bash
wget -O - https://gitlab.com/katyukha/odoo-helper-scripts/raw/master/install-user.bash | bash -s - dev

#  Instalar pre-requisitos del sistema para odoo-helper-scripts
#  NOTA: solo funciona en sistemas basados en debian
odoo-helper install pre-requirements
```

## Actualizar odoo-helper-scripts

Si instalaste versión antigua de odoo-helper scripts y quieres actualizarlos a nueva versión,
entonces el siguiente comando te ayudará:

```bash
odoo-helper system update
```

Por ejemplo para actualizar al último commit de *dev* se puede usar el siguiente comando:

```
odoo-helper system update dev
```
