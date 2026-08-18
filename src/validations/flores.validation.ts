import { z } from "zod";

export const crearFlorSchema = z.object({
  nombre: z.string().min(3, "El nombre debe tener al menos 3 caracteres"),
  descripcion: z.string().optional(),
  precio: z.number().positive("El precio debe ser un número mayor a 0"),
  stock: z.number().int().nonnegative("El stock no puede ser negativo"),
  categoria: z.string().min(2, "La categoría es requerida"),
  imagenUrl: z.string().url("Debe ser una URL válida").optional(),
});

export const actualizarFlorSchema = crearFlorSchema.partial();