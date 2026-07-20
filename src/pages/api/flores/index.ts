import type { NextApiRequest, NextApiResponse } from 'next'
import { prisma } from '../../../lib/prisma'
import { memoryCache } from '../../../lib/cache'

const CACHE_KEY_FLORES = 'flores_catalogo_list'

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  // 1. LECTURA OPTIMIZADA CON CACHÉ Y SELECCIÓN DE CAMPOS (Eager Loading)
  if (req.method === 'GET') {
    try {
      // Intentar obtener desde la caché en memoria (Cache-Aside)
      const cachedData = memoryCache.get(CACHE_KEY_FLORES)
      if (cachedData) {
        return res.status(200).json({
          success: true,
          source: 'cache',
          data: cachedData,
        })
      }

      // Si no está en caché, consultar a PostgreSQL optimizando campos
      const flores = await prisma.flor.findMany({
        where: { estado: 'ACTIVO' },
        select: {
          id: true,
          nombre: true,
          precio: true,
          stock: true,
        },
        orderBy: { nombre: 'asc' },
      })

      // Guardar en caché por 60 segundos
      memoryCache.set(CACHE_KEY_FLORES, flores, 60)

      return res.status(200).json({
        success: true,
        source: 'database',
        data: flores,
      })
    } catch (error) {
      return res.status(500).json({ success: false, error: 'Error al consultar el catálogo' })
    }
  }

  // 2. CREACIÓN CON INVALIDACIÓN DE CACHÉ
  if (req.method === 'POST') {
    try {
      const { nombre, descripcion, precio, stock } = req.body

      const nuevaFlor = await prisma.flor.create({
        data: {
          nombre,
          descripcion,
          precio: parseFloat(precio),
          stock: parseInt(stock),
          estado: 'ACTIVO',
        },
      })

      // Invalidate la caché para garantizar la consistencia de datos
      memoryCache.clear(CACHE_KEY_FLORES)

      return res.status(201).json({
        success: true,
        message: 'Producto creado exitosamente',
        data: nuevaFlor,
      })
    } catch (error) {
      return res.status(400).json({ success: false, error: 'Error al registrar el producto' })
    }
  }

  res.setHeader('Allow', ['GET', 'POST'])
  return res.status(405).json({ success: false, error: `Método ${req.method} no permitido` })
}