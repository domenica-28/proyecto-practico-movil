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
        console.log('⚡ [API] Datos servidos desde la CACHÉ')
        return res.status(200).json({
          success: true,
          source: 'cache',
          data: cachedData,
        })
      }

      console.log('🛢️ [API] Consultando la Base de Datos PostgreSQL...')

      // Consulta a PostgreSQL optimizando la selección de campos
      const flores = await prisma.flor.findMany({
        select: {
          id: true,
          nombre: true,
          descripcion: true,
          precio: true,
          stock: true,
          estado: true,
        },
        orderBy: { nombre: 'asc' },
      })

      // Guardar resultados en la caché por 60 segundos
      memoryCache.set(CACHE_KEY_FLORES, flores, 60)

      return res.status(200).json({
        success: true,
        source: 'database',
        data: flores,
      })
    } catch (error) {
      // Imprime el detalle técnico exacto en la terminal de VS Code
      console.error('❌ DETALLE DEL ERROR EN GET /api/flores:', error)
      return res.status(500).json({ 
        success: false, 
        error: 'Error al consultar el catálogo',
        details: error instanceof Error ? error.message : String(error)
      })
    }
  }

  // 2. CREACIÓN CON INVALIDACIÓN DE CACHÉ
  if (req.method === 'POST') {
    try {
      const { nombre, descripcion, precio, stock } = req.body

      if (!nombre || precio === undefined || stock === undefined) {
        return res.status(400).json({
          success: false,
          error: 'Los campos nombre, precio y stock son obligatorios',
        })
      }

      const nuevaFlor = await prisma.flor.create({
        data: {
          nombre,
          descripcion: descripcion || '',
          precio: parseFloat(precio),
          stock: parseInt(stock),
          estado: 'ACTIVO',
        },
      })

      // Limpiar la caché para mantener consistencia
      memoryCache.clear(CACHE_KEY_FLORES)
      console.log('🧹 [API] Caché limpiada tras la creación de un nuevo producto')

      return res.status(201).json({
        success: true,
        message: 'Producto creado exitosamente',
        data: nuevaFlor,
      })
    } catch (error) {
      console.error('❌ DETALLE DEL ERROR EN POST /api/flores:', error)
      return res.status(400).json({ 
        success: false, 
        error: 'Error al registrar el producto',
        details: error instanceof Error ? error.message : String(error)
      })
    }
  }

  res.setHeader('Allow', ['GET', 'POST'])
  return res.status(405).json({ success: false, error: `Método ${req.method} no permitido` })
}