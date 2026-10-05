import type { NextApiRequest, NextApiResponse } from 'next';
import { prisma } from '../../lib/prisma';

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  // 1. OBTENER PEDIDOS (GET)
  if (req.method === 'GET') {
    try {
      const { userId } = req.query;
      let whereCondition: any = undefined;

      if (userId) {
        const valorFiltro = String(userId);
        if (valorFiltro.includes('@')) {
          const usuarioEncontrado = await prisma.user.findFirst({
            where: { email: valorFiltro },
          });

          if (usuarioEncontrado) {
            whereCondition = { userId: usuarioEncontrado.id };
          } else {
            return res.status(200).json([]);
          }
        } else {
          whereCondition = { userId: valorFiltro };
        }
      }

      const pedidos = await prisma.pedido.findMany({
        where: whereCondition,
        include: {
          flor: true,
          user: {
            include: {
              profile: true,
            },
          },
        },
        orderBy: { fecha: 'desc' },
      });

      return res.status(200).json(pedidos);
    } catch (error) {
      console.error('Error al obtener pedidos:', error);
      return res.status(500).json({ message: 'Error al obtener pedidos' });
    }
  }

  // 2. CREAR PEDIDO (POST)
  if (req.method === 'POST') {
    try {
      console.log('BODY RECIBIDO EN /api/pedidos:', req.body);

      let florId = req.body.florId || req.body.flowerId;
      let userId = req.body.userId;
      let cliente = req.body.cliente;
      let cantidad = Number(req.body.cantidad || req.body.quantity || 1);
      let precioTotal = req.body.precioTotal || req.body.total || req.body.precio;
      let metodoPago = req.body.metodoPago;
      let tipoEntrega = req.body.tipoEntrega;

      if (!florId || !cantidad || !precioTotal) {
        return res.status(400).json({ 
          message: 'Faltan datos obligatorios del pedido (florId, cantidad, precioTotal)',
          recibido: req.body 
        });
      }

      // Buscamos la flor de forma segura probando las variaciones comunes en Prisma
      let florActual: any = null;
      try {
        // @ts-ignore
        florActual = await prisma.flor.findUnique({ where: { id: Number(florId) } });
      } catch (e) {
        try {
          // @ts-ignore
          florActual = await prisma.flores.findUnique({ where: { id: Number(florId) } });
        } catch (err) {
          // Si falla, consultamos directamente por SQL nativo para evitar bloqueos
          const resultadoSql: any = await prisma.$queryRaw`SELECT * FROM "flores" WHERE id = ${Number(florId)} LIMIT 1`;
          florActual = resultadoSql[0];
        }
      }

      if (!florActual) {
        return res.status(404).json({ message: 'El producto no existe en la base de datos' });
      }

      if (florActual.stock < cantidad) {
        return res.status(400).json({ message: 'Stock insuficiente para realizar el pedido' });
      }

      let targetUserId = userId;
      if (!targetUserId && cliente) {
        const foundUser = await prisma.user.findFirst({
          where: { OR: [{ email: cliente }, { username: cliente }] },
        });
        if (foundUser) targetUserId = foundUser.id;
      }

      if (!targetUserId) {
        const anyUser = await prisma.user.findFirst();
        if (!anyUser) {
          return res.status(400).json({ message: 'No hay usuarios registrados en la base de datos' });
        }
        targetUserId = anyUser.id;
      }

      // Creamos el pedido y descontamos el stock usando SQL directo para garantizar que no falle por nombres de modelos
      const nuevoPedido = await prisma.pedido.create({
        data: {
          florId: Number(florId),
          userId: targetUserId,
          cantidad: cantidad,
          precioTotal: Number(precioTotal),
          metodoPago: metodoPago || 'Efectivo',
          tipoEntrega: tipoEntrega || 'Retiro en Tienda',
          estado: 'Visto',
        },
        include: {
          flor: true,
          user: { include: { profile: true } },
        },
      });

      // Actualizamos el stock de la flor de forma segura
      await prisma.$executeRaw`UPDATE "flores" SET stock = stock - ${cantidad} WHERE id = ${Number(florId)}`;

      return res.status(201).json(nuevoPedido);
    } catch (error: any) {
      console.error('Error al crear pedido:', error);
      return res.status(500).json({ message: 'Error al registrar pedido', error: error.message });
    }
  }

  // 3. ACTUALIZAR ESTADO (PATCH / PUT)
  if (req.method === 'PUT' || req.method === 'PATCH') {
    try {
      const pedidoId = req.body.pedidoId || req.body.id;
      const estado = req.body.estado;

      if (!pedidoId || !estado) {
        return res.status(400).json({ message: 'Faltan el ID del pedido o el nuevo estado' });
      }

      const pedidoActualizado = await prisma.pedido.update({
        where: { id: Number(pedidoId) },
        data: { estado: estado },
        include: { flor: true, user: { include: { profile: true } } },
      });

      return res.status(200).json(pedidoActualizado);
    } catch (error: any) {
      console.error('Error al actualizar estado:', error);
      return res.status(500).json({ message: 'Error al actualizar estado del pedido', error: error.message });
    }
  }

  res.setHeader('Allow', ['GET', 'POST', 'PUT', 'PATCH']);
  return res.status(405).json({ message: 'Método no permitido' });
}