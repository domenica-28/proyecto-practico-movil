import { prisma } from "@/lib/prisma";
import { PedidoCrearInput } from "@/types";
import { FloresService } from "./flores.service";
import { AppError } from "@/errors/app-error";

export class PedidosService {
  static async crearPedido(datos: PedidoCrearInput) {
    let totalCalculado = 0;

    // Validar disponibilidad de stock y calcular total
    for (const item of datos.items) {
      const flor = await FloresService.obtenerPorId(item.florId);
      if (flor.stock < item.cantidad) {
        throw new AppError(`Sin stock suficiente para ${flor.nombre}`, 400);
      }
      totalCalculado += flor.precio * item.cantidad;
    }

    // Transacción para registrar el pedido y reducir stock
    return await prisma.$transaction(async (tx) => {
      const nuevoPedido = await tx.pedido.create({
        data: {
          usuarioId: datos.usuarioId,
          direccionEnvio: datos.direccionEnvio,
          telefonoContacto: datos.telefonoContacto,
          total: totalCalculado,
          estado: "PENDIENTE",
          detalles: {
            create: datos.items.map((item) => ({
              florId: item.florId,
              cantidad: item.cantidad,
            })),
          },
        },
        include: { detalles: true },
      });

      for (const item of datos.items) {
        await tx.flor.update({
          where: { id: item.florId },
          data: { stock: { decrement: item.cantidad } },
        });
      }

      return nuevoPedido;
    });
  }
}