import type { NextApiRequest, NextApiResponse } from 'next'
import { prisma } from '../../../lib/prisma'
import { memoryCache } from '../../../lib/cache'

const CACHE_KEY_FLORES = 'flores_catalogo_list'

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  // 1. OBTENER CATÁLOGO (GET)
  if (req.method === 'GET') {
    try {
      // Verificar si existe en la memoria caché
      const cachedData = memoryCache.get(CACHE_KEY_FLORES)
      if (cachedData) {
        console.log('⚡ [API] Servido desde la CACHÉ')
        return res.status(200).json(cachedData)
      }

      console.log('🛢️ [API] Consultando tabla "flores" en PostgreSQL...')

      // Consulta directa al modelo Flores utilizado por Flutter
      const flores = await prisma.flores.findMany({
        orderBy: { id: 'desc' },
      })

      // Guardar en la caché por 60 segundos
      memoryCache.set(CACHE_KEY_FLORES, flores, 60)

      return res.status(200).json(flores)
    } catch (error) {
      console.error('❌ ERROR EN GET /api/flores:', error)
      return res.status(500).json({ 
        error: 'Error al consultar el catálogo',
        details: error instanceof Error ? error.message : String(error)
      })
    }
  }

  // 2. CREAR PRODUCTO (POST)
  if (req.method === 'POST') {
    try {
      const { nombre, descripcion, precio, stock, imagenUrl } = req.body

      if (!nombre || precio === undefined || stock === undefined) {
        return res.status(400).json({
          error: 'Los campos nombre, precio y stock son obligatorios',
        })
      }

      const nuevaFlor = await prisma.flores.create({
        data: {
          nombre,
          descripcion: descripcion || '',
          precio: parseFloat(precio),
          stock: parseInt(stock),
          estado: true,
          imagenUrl: imagenUrl || null,
        },
      })

      // Invalidar la caché para forzar la lectura de datos actualizados
      memoryCache.clear(CACHE_KEY_FLORES)
      console.log('🧹 [API] Caché limpiada tras añadir nuevo registro')

      return res.status(201).json(nuevaFlor)
    } catch (error) {
      console.error('❌ ERROR EN POST /api/flores:', error)
      return res.status(400).json({ 
        error: 'Error al registrar el producto',
        details: error instanceof Error ? error.message : String(error)
      })
    }
  }

  res.setHeader('Allow', ['GET', 'POST'])
  return res.status(405).json({ error: `Método ${req.method} no permitido` })
}