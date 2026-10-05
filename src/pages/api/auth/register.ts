import type { NextApiRequest, NextApiResponse } from 'next';
import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcrypt';

const prisma = new PrismaClient();

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method !== 'POST') {
    return res.status(405).json({ message: 'Método no permitido. Usa POST.' });
  }

  try {
    const { nombre, apellido, email, password } = req.body;

    // Verificar que lleguen todos los campos
    if (!nombre || !apellido || !email || !password) {
      return res.status(400).json({ message: 'Todos los campos son obligatorios' });
    }

    // Verificar si el usuario ya existe
    const usuarioExistente = await prisma.users.findFirst({
      where: { email: email },
    });

    if (usuarioExistente) {
      return res.status(400).json({ message: 'El correo ya está registrado' });
    }

    // Encriptar contraseña
    const hashedPassword = await bcrypt.hash(password, 10);

    // Crear el usuario y su perfil asociado en una sola operación
    const nuevoUsuario = await prisma.users.create({
      data: {
        email: email,
        password_hash: hashedPassword,
        user_profiles: {
          create: {
            first_name: nombre,
            last_name: apellido,
          },
        },
      },
      include: {
        user_profiles: true,
      },
    });

    return res.status(201).json({
      message: 'Usuario registrado con éxito',
      usuario: {
        id: nuevoUsuario.id,
        email: nuevoUsuario.email,
        nombre: nuevoUsuario.user_profiles?.first_name,
        apellido: nuevoUsuario.user_profiles?.last_name,
      },
    });

  } catch (error: any) {
    console.error('Error en el registro:', error);
    return res.status(500).json({ error: error.message || 'Error interno del servidor' });
  }
}