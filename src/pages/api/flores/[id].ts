import type { NextApiRequest, NextApiResponse } from 'next'
import { prisma } from '../../../lib/prisma'

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse
) {
  const { id } = req.query

  if (typeof id !== 'string') {
    return res.status(400).json({ success: false, error: 'ID no válido' })
  }

  // GET: Consultar recurso específico por ID
  if (req.method === 'GET') {
    try {
      const flor = await prisma.flor.findUnique({ where: { id: Number(id) } })
      if (!flor) {
        return res.status(404).json({ success: false, error: 'Flor no encontrada' })
      }
      return res.status(200).json({ success: true, data: flor })
    } catch (error) {
      return res.status(500).json({ success: false, error: 'Error al consultar la flor' })
    }
  }

  // PATCH: Actualización parcial
  if (req.method === 'PATCH') {
    try {
      const { nombre, descripcion, precio, stock } = req.body

      const florActualizada = await prisma.flor.update({
        where: { id: Number(id) },
        data: {
          ...(nombre && { nombre }),
          ...(descripcion && { descripcion }),
          ...(precio !== undefined && { precio: parseFloat(precio) }),
          ...(stock !== undefined && { stock: parseInt(stock) }),
        },
      })

      return res.status(200).json({ success: true, data: florActualizada, message: 'Flor actualizada con éxito' })
    } catch (error) {
      return res.status(400).json({ success: false, error: 'No se pudo actualizar la flor' })
    }
  }

  // DELETE: Eliminación lógica / Desactivación
  if (req.method === 'DELETE') {
    try {
      // Si usas eliminación lógica, puedes actualizar el estado a INACTIVO
      await prisma.flor.delete({ where: { id: Number(id) } })
      return res.status(200).json({ success: true, message: 'Registro eliminado correctamente' })
    } catch (error) {
      return res.status(400).json({ success: false, error: 'No se pudo eliminar el registro' })
    }
  }

  res.setHeader('Allow', ['GET', 'PATCH', 'DELETE'])
  return res.status(405).json({ success: false, error: `Método ${req.method} no permitido` })
}