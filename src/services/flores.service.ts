import { prisma } from "@/lib/prisma";
import { FlorCrearInput } from "@/types";
import { AppError } from "@/errors/app-error";

export class FloresService {
  static async obtenerTodas() {
    return await prisma.flor.findMany({
      where: { disponible: true },
      orderBy: { nombre: "asc" },
    });
  }

  static async obtenerPorId(id: string) {
    const flor = await prisma.flor.findUnique({ where: { id } });
    if (!flor) {
      throw new AppError("Arreglo floral no encontrado", 404);
    }
    return flor;
  }

  static async crear(data: FlorCrearInput) {
    return await prisma.flor.create({
      data: {
        ...data,
        disponible: data.stock > 0,
      },
    });
  }

  static async actualizarStock(id: string, cantidadComprada: number) {
    const flor = await this.obtenerPorId(id);
    if (flor.stock < cantidadComprada) {
      throw new AppError(`Stock insuficiente para: ${flor.nombre}`, 400);
    }

    const nuevoStock = flor.stock - cantidadComprada;
    return await prisma.flor.update({
      where: { id },
      data: {
        stock: nuevoStock,
        disponible: nuevoStock > 0,
      },
    });
  }
}