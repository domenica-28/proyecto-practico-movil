# Guía de Desarrollo - Florería Backend

## Comandos Principales
- `npm run dev`: Inicia el servidor de desarrollo en Next.js.
- `npx vitest`: Ejecuta las pruebas unitarias.
- `npx prisma db push`: Actualiza el esquema de la base de datos.

## Arquitectura
- Utilizar siempre `src/validations/` con Zod antes de procesar entradas.
- Lógica de la florería agrupada en `src/services/`.
- Manejo de excepciones utilizando `AppError` o `ValidationError`.