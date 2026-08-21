import type { NextApiRequest, NextApiResponse } from 'next';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method === 'POST') {
    try {
      const { florId, cliente, cantidad } = req.body;

      const nuevoPedido = await prisma.pedido.create({
        data: {
          florId: Number(florId),
          cliente,
          cantidad: Number(cantidad),
          visto: false,
        },
      });

      return res.status(201).json(nuevoPedido);
    } catch (error) {
      return res.status(500).json({ error: 'Error al registrar el pedido' });
    }
  } else if (req.method === 'GET') {
    try {
      const pedidos = await prisma.pedido.findMany({
        include: { flor: true },
        orderBy: { fecha: 'desc' },
      });

      return res.status(200).json(pedidos);
    } catch (error) {
      return res.status(500).json({ error: 'Error al obtener los pedidos' });
    }
  } else {
    res.setHeader('Allow', ['GET', 'POST']);
    return res.status(405).end(`Método ${req.method} no permitido`);
  }
}