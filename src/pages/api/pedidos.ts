import type { NextApiRequest, NextApiResponse } from 'next';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  // 1. OBTENER PEDIDOS (GET)
  if (req.method === 'GET') {
    try {
      const { userId } = req.query;

      // Si se envía un userId desde la app móvil, filtramos solo los pedidos de ese cliente.
      // Si no se envía (ej. vista de administrador), trae todos los pedidos.
      const donde = userId ? { userId: String(userId) } : {};

      const pedidos = await prisma.pedido.findMany({
        where: donde,
        include: {
          flor: true, // Incluye los datos del producto/flor asociada
          user: {
            select: {
              id: true,
              email: true,
              profile: true,
            },
          },
        },
        orderBy: {
          fecha: 'desc',
        },
      });

      return res.status(200).json(pedidos);
    } catch (error) {
      console.error('Error al obtener pedidos:', error);
      return res.status(500).json({ error: 'Error al obtener los pedidos' });
    }
  }

  // 2. CREAR UN NUEVO PEDIDO (POST)
  if (req.method === 'POST') {
    try {
      const {
        florId,
        userId,
        cantidad,
        precioTotal,
        tipoEntrega,
        direccion,
        latitud,
        longitud,
        metodoPago,
        comprobantePagoUrl,
      } = req.body;

      // Validaciones básicas de campos requeridos
      if (!florId || !userId || !cantidad) {
        return res.status(400).json({ error: 'Faltan campos obligatorios: florId, userId o cantidad' });
      }

      const nuevoPedido = await prisma.pedido.create({
        data: {
          florId: Number(florId),
          userId: String(userId),
          cantidad: Number(cantidad),
          precioTotal: precioTotal ? parseFloat(precioTotal) : 0,
          tipoEntrega: tipoEntrega || 'DOMICILIO',
          direccion: direccion || null,
          latitud: latitud ? parseFloat(latitud) : null,
          longitud: longitud ? parseFloat(longitud) : null,
          metodoPago: metodoPago || 'TRANSFERENCIA',
          comprobantePagoUrl: comprobantePagoUrl || null,
          estado: 'Pendiente Pago',
          visto: false,
        },
      });

      return res.status(201).json(nuevoPedido);
    } catch (error) {
      console.error('Error al registrar el pedido:', error);
      return res.status(500).json({ error: 'Error al registrar el pedido' });
    }
  }

  // 3. MÉTODOS NO PERMITIDOS
  res.setHeader('Allow', ['GET', 'POST']);
  return res.status(405).end(`Método ${req.method} no permitido`);
}