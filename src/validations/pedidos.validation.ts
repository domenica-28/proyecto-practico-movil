import { z } from "zod";

export const crearPedidoSchema = z.object({
  usuarioId: z.string().uuid("ID de usuario inválido"),
  direccionEnvio: z.string().min(5, "Ingresa una dirección de entrega válida"),
  telefonoContacto: z.string().min(7, "Teléfono de contacto requerido"),
  items: z.array(
    z.object({
      florId: z.string().uuid("ID de producto inválido"),
      cantidad: z.number().int().positive("La cantidad debe ser al menos 1"),
    })
  ).min(1, "El pedido debe contener al menos un producto"),
})