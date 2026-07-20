import { NextApiRequest, NextApiResponse } from 'next'
import jwt from 'jsonwebtoken'

const JWT_SECRET = process.env.JWT_SECRET || 'secret_default'

export interface AuthenticatedUser {
  userId: string
  email: string
  role: string
}

export interface AuthenticatedRequest extends NextApiRequest {
  user?: AuthenticatedUser
}

export function authMiddleware(
  req: AuthenticatedRequest,
  res: NextApiResponse,
  requiredRole?: string
): boolean {
  const authHeader = req.headers.authorization

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    res.status(401).json({ success: false, error: 'Token no proporcionado o formato inválido' })
    return false
  }

  const token = authHeader.split(' ')[1]

  try {
    const decoded = jwt.verify(token, JWT_SECRET) as AuthenticatedUser
    req.user = decoded

    if (requiredRole && decoded.role !== requiredRole && decoded.role !== 'ADMIN') {
      res.status(403).json({ success: false, error: 'Acceso denegado: Permisos insuficientes' })
      return false
    }

    return true
  } catch (error) {
    res.status(401).json({ success: false, error: 'Token inválido o expirado' })
    return false
  }
}