const { PrismaClient } = require('@prisma/client')
const prisma = new PrismaClient()

async function main() {
  await prisma.flor.createMany({
    data: [
      { nombre: 'Rosas Rojas', descripcion: 'Ramo de 12 rosas rojas', precio: 15.50, stock: 50 },
      { nombre: 'Girasoles', descripcion: 'Arreglo con girasoles', precio: 12.00, stock: 30 },
      { nombre: 'Orquídeas', descripcion: 'Macetas de orquídeas blancas', precio: 25.00, stock: 15 },
    ],
  })
  console.log('🌱 ¡Flores de prueba creadas con éxito!')
}

main()
  .catch((e) => console.error(e))
  .finally(async () => await prisma.$disconnect())