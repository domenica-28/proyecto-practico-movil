import type { NextApiRequest, NextApiResponse } from 'next';
import { prisma } from '../../lib/prisma';

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse
) {
  if (req.method === 'GET') {
    try {
      const usuarios = await prisma.user.findMany({
        orderBy: {
          createdAt: 'desc',
        },
      });

      return res.status(200).json(usuarios);
    } catch (error) {
      return res.status(500).json({ message: 'Error al obtener usuarios' });
    }
  }

  res.setHeader('Allow', ['GET']);

  return res.status(405).json({
    message: 'Método no permitido',
  });
}