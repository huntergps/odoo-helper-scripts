# Contribuyendo a odoo-helper-scripts

¡Gracias por tu interés en contribuir a odoo-helper-scripts!

## Contribuyendo a este proyecto

1. Haz fork del repositorio en [GitHub](https://github.com/katyukha/odoo-helper-scripts) o [GitLab](https://github.com/huntergps/odoo-helper-scripts/)
2. Crea una nueva rama, ej., `git checkout -b bug-12345` basada en la rama `dev`
3. Arregla el bug o agrega la característica
4. Agrega o modifica el mensaje de ayuda relacionado (si es necesario)
5. Agrega o modifica documentación (si es necesario) para tu cambio
6. Agrega entrada en el changelog para tu cambio en la sección *Unreleased*
7. Haz commit y push a tu fork
8. Crea Merge Request o Pull Request

## Cómo construir documentación

Instala [MkDocs](https://www.mkdocs.org/)

```bash
pip install mkdocs
```

Ejecuta el script `build_docs` en la raíz del repositorio.

```bash
./scripts/build_docs.sh
```

Ejecuta el servidor de desarrollo integrado de MkDocs con el siguiente comando en la raíz del repositorio.

```bash
mkdocs serve
```

La documentación generada estará disponible en `http://127.0.0.1:8000/`.
