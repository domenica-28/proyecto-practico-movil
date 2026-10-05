import type { NextApiRequest, NextApiResponse } from 'next';
import { prisma } from '../../lib/prisma';
import bcrypt from 'bcryptjs';

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method === 'POST') {
    try {
      const { email, password, firstName, lastName } = req.body;

      if (!email || !password) {
        return res.status(400).json({ message: 'Email y contraseña requeridos' });
      }

      const existingUser = await prisma.user.findUnique({ where: { email } });
      if (existingUser) {
        return res.status(400).json({ message: 'El usuario ya existe' });
      }

      const hashedPassword = await bcrypt.hash(password, 10);

      // Crear usuario y su perfil con nombre y apellido
      const nuevoUsuario = await prisma.user.create({
        data: {
          email,
          username: email.split('@')[0],
          passwordHash: hashedPassword,
          status: 'ACTIVO',
          profile: {
            create: {
              firstName: firstName || 'Cliente',
              lastName: lastName || 'Nuevo',
            },
          },
        },
        include: { profile: true },
      });

      return res.status(201).json({
        message: 'Usuario registrado con éxito',
        user: { 
          id: nuevoUsuario.id, 
          email: nuevoUsuario.email,
          firstName: nuevoUsuario.profile?.firstName,
          lastName: nuevoUsuario.profile?.lastName 
        },
      });
    } catch (error: any) {
      console.error('Error al registrar:', error);
      return res.status(500).json({ message: 'Error al registrar usuario', error: error.message });
    }
  }

  res.setHeader('Allow', ['POST']);
  return res.status(405).json({ message: 'Método no permitido' });
}