# Guía de Inicio Rápido

Esta es la guía de inicio rápido para *odoo-helper-scripts*.

## Instalar scripts odoo-helper

Para lista completa de opciones de instalación mira la [documentación de instalación](./installation.md)

Para instalar *odoo-helper-scripts* a nivel del sistema haz lo siguiente:

```bash
wget -O - https://gitlab.com/katyukha/odoo-helper-scripts/raw/master/install-system.bash | sudo bash -s
```

o de forma más explícita:

```bash
# Descargar script de instalación
wget -O /tmp/odoo-helper-install.bash https://gitlab.com/katyukha/odoo-helper-scripts/raw/master/install-system.bash;

# Instalar odoo-helper-scripts
sudo bash /tmp/odoo-helper-install.bash;
```

## Instalar dependencias

Asegúrate de que los pre-requisitos de *odoo-helper-scripts* estén instalados
Este paso usualmente debe ejecutarse una vez.
Instala dependencias de *odoo-helper-scripts* en sí y dependencias comunes de odoo.

```bash
odoo-helper install pre-requirements
```

Instalar dependencias del sistema para versión específica de Odoo (en este ejemplo *18.3*)
Nota, que esta opción requiere *sudo*.

```bash
odoo-helper install sys-deps 18.3;
```

Instalar [Servidor PostgreSQL](https://www.postgresql.org/) y crear
usuario postgres para Odoo con `name='odoo'` y `password='odoo'`.
El primer argumento es nombre de usuario postgres y el segundo es contraseña.

```bash
odoo-helper install postgres odoo odoo
```

## Instalar Odoo

Instalar *Odoo* 18.3 en directorio *odoo-18.3*

```bash
odoo-install -i odoo-18.3 --odoo-version 18.3
```

## Gestionar Odoo instalado

Cambiar directorio al que contiene la instancia de Odoo recién instalada.
Esto es requerido para hacer que funcionen los comandos de gestión de instancia.

```bash
cd odoo-18.3
```

Ahora tienes *Odoo 18.3* instalado en este directorio.
Nota, que esta instalación de odoo usa [virtualenv](https://virtualenv.pypa.io/en/stable/)
(directorio `venv`)
También encontrarás ahí el archivo de configuración `odoo-helper.conf`

Así que ahora puedes ejecutar servidor odoo local (es decir script `openerp-server` o `odoo.py` o `odoo-bin`).
Nota que este comando ejecuta el servidor en primer plano.
El archivo de configuración `conf/odoo.conf` se usará automáticamente

```bash
odoo-helper server run
```

Presiona `Ctrl+C` para detener el servidor

Para ejecutar servidor en segundo plano usa el siguiente comando:

```bash
odoo-helper server start
```

Ejecuta el comando de abajo para abrir la instancia actual de odoo en el navegador:

```bash
odoo-helper browse
```

Por defecto el servicio Odoo será accesible en [localhost:8069](http://localhost:8069/)

También hay comandos adicionales relacionados con el servidor (ver [Comandos Frecuentemente Usados](./frequently-used-commands.md)):

```bash
odoo-helper server status
odoo-helper server log
odoo-helper server ps
odoo-helper server restart
odoo-helper server stop
```

También hay atajos para estos comandos

```bash
odoo-helper status
odoo-helper log
odoo-helper restart
odoo-helper stop
```


## Crear base de datos con datos de demostración

Para crear base de datos de Odoo con datos de demostración ejecuta el siguiente comando

```bash
odoo-helper db create --demo my-database
```

Luego inicia el servidor Odoo (si no se había iniciado aún)

```bash
odoo-helper start
```

Y inicia sesión en la base de datos recién creada con las siguientes credenciales por defecto:

- login: admin
- password: admin


## Obtener e instalar complementos de Odoo

Vamos a obtener módulos del [repositorio OCA contract](https://github.com/OCA/contract)
La rama será detectada automáticamente por *odoo-helper-scripts*

```bash
odoo-helper fetch --oca contract
```

O alternativamente

```bash
odoo-helper fetch --github OCA/contract --branch 11.0
```

Si el repositorio tiene estructura de rama estándar las ramas tienen los mismos nombres que las versiones de Odoo (series)
entonces odoo-helper automáticamente intentará cambiar a la rama correcta,
así que no es requerido especificar nombre de rama en este caso.
Así que el comando de arriba puede verse como:

```bash
odoo-helper fetch --github OCA/contract
```

Ahora mira el directorio `custom_addons/`, ahí se colocarán enlaces a complementos
del [repositorio OCA 'contract'](https://github.com/OCA/contract)
Pero el repositorio en sí está colocado en el directorio `repositories/`

En este punto los complementos obtenidos no se muestran en el menú *Apps* de Odoo.
Por eso tenemos que actualizar la lista de complementos en la base de datos.
Esto se puede hacer por la UI de Odoo en modo desarrollador (*Apps / Update Applications List*)
o con un simple comando de shell:

```bash
odoo-helper addons update-list
```

Ahora los complementos están presentes en la base de datos de Odoo, así que pueden instalarse vía UI (menú *Apps*)
También es posible hacer esto vía línea de comandos con el siguiente comando:

```bash
odoo-helper addons install [-d database] <addon name>
```

Por ejemplo el siguiente comando instalará el complemento [contract](https://github.com/OCA/contract/tree/11.0/contract)

```bash
odoo-helper addons install -d my-database contract
```

También si la base de datos no está especificada el complemento se instalará en todas las bases de datos disponibles


## Ejecutar tests

Ahora vamos a ejecutar tests para estos módulos recién instalados

```bash
odoo-helper test --create-test-db -m contract
```

Esto creará *base de datos de test* (será eliminada después de que terminen los tests) y 
ejecutará tests para el módulo `contract`

O podemos ejecutar tests para todos los complementos en directorio especificado, *odoo-helper-scripts*