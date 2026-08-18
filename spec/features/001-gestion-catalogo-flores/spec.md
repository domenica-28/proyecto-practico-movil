# Especificación Técnica - Catálogo de Flores

## Entidades
- **Flor / Arreglo**: ID, nombre, descripción, precio, stock, categoriaId, creadoEn.

## Requisitos de API
- `GET /api/flores`: Lista todas las flores con soporte para filtros.
- `POST /api/flores`: Crea un nuevo producto (solo admins).
- `GET /api/flores/[id]`: Retorna el detalle de una flor.