import type { NextApiRequest, NextApiResponse } from 'next'
import bcrypt from 'bcryptjs'
import jwt from 'jsonwebtoken'
import { prisma } from '../../../lib/prisma'

const JWT_SECRET = process.env.JWT_SECRET || 'secret_default'

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method !== 'POST') {
    return res.status(405).json({ success: false, error: 'Método no permitido' })
  }

  try {
    const { email, password } = req.body

    if (!email || !password) {
      return res.status(400).json({ success: false, error: 'Correo y contraseña son obligatorios' })
    }

    const user = await prisma.user.findUnique({
      where: { email },
      include: { userRoles: { include: { role: true } } },
    })

    if (!user || !user.passwordHash) {
      return res.status(401).json({ success: false, error: 'Credenciales incorrectas' })
    }

    const isPasswordValid = await bcrypt.compare(password, user.passwordHash)
    if (!isPasswordValid) {
      return res.status(401).json({ success: false, error: 'Credenciales incorrectas' })
    }

    const userRole = user.userRoles[0]?.role?.code || 'CLIENT'

    const token = jwt.sign(
      { userId: user.id, email: user.email, role: userRole },
      JWT_SECRET,
      { expiresIn: '15m' }
    )

    return res.status(200).json({
      success: true,
      message: 'Inicio de sesión exitoso',
      token,
      user: { id: user.id, email: user.email, role: userRole },
    })
  } catch (error) {
    return res.status(500).json({ success: false, error: 'Error interno del servidor' })
  }
}