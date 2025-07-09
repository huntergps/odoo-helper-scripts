## Comandos frecuentemente usados

Lista breve de comandos odoo-helper frecuentemente usados

### Gestión del servidor Odoo
- `odoo-helper start` - iniciar servidor odoo
- `odoo-helper restart` - reiniciar servidor odoo
- `odoo-helper stop` - detener servidor odoo-helper
- `odoo-helper log` - ver logs del servidor odoo
- `odoo-helper ps` - mostrar procesos del servidor odoo para el proyecto actual
- `odoo-helper browse` - abrir instalación de odoo ejecutándose en el navegador

### Gestión de complementos de Odoo
- `odoo-helper addons list <path>` - listar complementos de odoo en el directorio especificado
- `odoo-helper addons update-list` - actualizar lista de complementos disponibles en todas las bases de datos disponibles para este servidor
- `odoo-helper addons install <addon1> [addonn]` - instalar complementos de odoo especificados para todas las bases de datos disponibles para este servidor
- `odoo-helper addons update <addon1> [addonn]` - actualizar complementos de odoo especificados para todas las bases de datos disponibles para este servidor
- `odoo-helper addons uninstall <addon1> [addonn]` - desinstalar complementos de odoo especificados para todas las bases de datos disponibles para este servidor
- `odoo-helper addons update --dir <path>` - encontrar todos los complementos instalables en el directorio especificado y actualizarlos
- `odoo-helper addons install --dir <path>` - encontrar todos los complementos instalables en el directorio especificado e instalarlos

### Relacionado con Postgres
- `odoo-helper postgres psql [-d database]` - conectarse a la db vía psql (mismas credenciales que usa el servidor odoo)
- `odoo-helper psql [-d database]` - atajo para el comando `odoo-helper postgres psql`
- `sudo odoo-helper postgres user-create <user name> <password>` - crear usuario postgres para odoo
- `odoo-helper postgres stat-activity` - listar consultas postgres ejecutándose
- `odoo-helper postgres stat-connections` - mostrar estadísticas de conexiones postgres

### Pruebas
- `odoo-helper test -m <module>` - probar módulo único
- `odoo-helper test --dir .` - probar todos los complementos instalables en el directorio actual
- `odoo-helper test --coverage-html -m <module>` - probar módulo único y crear reporte de cobertura html en el directorio actual
- `odoo-helper test --coverage-html --dir .` - probar todos los complementos instalables en el directorio actual y crear reporte de cobertura html en el directorio actual
- `odoo-helper test -m <module> --recreate-db` - probar módulo único, pero recrear base de datos de prueba primero
- `odoo-helper test -m <module> --create-test-db` - probar módulo único en base de datos limpia recién creada. base de datos eliminada después de las pruebas

### Linters
- `odoo-helper lint pylint .` - ejecutar [pylint](https://www.pylint.org/) con [pylint\_odoo](https://pypi.org/project/pylint-odoo/) para todos los complementos en el directorio actual
- `odoo-helper lint flake8 .` - ejecutar [flake8](http://flake8.pycqa.org/en/latest/) para todos los complementos en el directorio actual
- `odoo-helper lint style .` - ejecutar [stylelint](https://stylelint.io/) para todos los complementos en los directorios actuales
- `odoo-helper pylint` - alias para `odoo-helper lint pylint`
- `odoo-helper flake8` - alias para `odoo-helper lint flake8`
- `odoo-helper style` - alias para odoo-helper lint style`

### Obtener complementos
- `odoo-helper link .` - crear enlaces simbólicos para todos los complementos en el directorio actual en la carpeta `custom_addons` para hacerlos visibles para odoo
- `odoo-helper fetch --oca web` - obtener todos los complementos del repositorio [OCA](https://odoo-community.org/) [web](https://github.com/OCA/web)
- `odoo-helper fetch --github <username/repository>` - obtener todos los complementos del repositorio [github](https://github.com) especificado
- `odoo-helper fetch --repo <repository url> --branch 11.0` - obtener todos los complementos del repositorio *git* especificado
- `odoo-helper fetch --hg <repository url> --branch 11.0` - obtener todos los complementos del repositorio *hg* especificado

### Gestión de base de datos
- `odoo-helper db list` - listar todas las bases de datos disponibles para la instancia de odoo actual
- `odoo-helper db create my_db` - crear base de datos
- `odoo-helper db backup my_db zip` - respaldar *my\_db* como archivo ZIP (con filestore)
- `odoo-helper db backup my_db sql` - respaldar *my\_db* como dump SQL solo (sin filestore)
- `odoo-helper db drop my_db` - eliminar base de datos

### Gestión de traducciones
- `odoo-helper tr regenerate --lang uk_UA --file uk <addon1> [addon2]...` - regenerar traducciones para el idioma especificado para los complementos especificados
- `odoo-helper tr regenerate --lang uk_UA --file uk --dir <path>` - regenerar traducciones para el idioma especificado para todos los complementos instalables en la ruta especificada
- `odoo-helper tr rate --lang uk_UA <addon1> [addon2]...` - imprimir tasa de traducción para los complementos especificados
- `odoo-helper tr rate --lang uk_UA --dir <path>` - imprimir tasa de traducción para todos los complementos instalables en el directorio especificado

### Otros
- `odoo-helper pip` - ejecutar [pip](https://pypi.org/project/pip/) dentro del entorno virtual [virtualenv](https://virtualenv.pypa.io/en/stable/) del proyecto actual.
- `odoo-helper npm` - ejecutar [npm](https://www.npmjs.com/) dentro del entorno virtual [nodeenv](https://pypi.python.org/pypi/nodeenv) del proyecto actual
- `odoo-helper exec my-command` - ejecutar comando dentro del entorno virtual del proyecto
