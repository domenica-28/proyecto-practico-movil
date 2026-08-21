-- CreateTable
CREATE TABLE "Flores" (
    "id" SERIAL NOT NULL,
    "nombre" TEXT NOT NULL,
    "descripcion" TEXT NOT NULL,
    "precio" DOUBLE PRECISION NOT NULL,
    "stock" INTEGER NOT NULL,
    "estado" BOOLEAN NOT NULL DEFAULT true,
    "imagenUrl" TEXT,

    CONSTRAINT "Flores_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Pedido" (
    "id" SERIAL NOT NULL,
    "florId" INTEGER NOT NULL,
    "cliente" TEXT NOT NULL,
    "cantidad" INTEGER NOT NULL,
    "visto" BOOLEAN NOT NULL DEFAULT false,
    "fecha" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Pedido_pkey" PRIMARY KEY ("id")
);

-- AddForeignKey
ALTER TABLE "Pedido" ADD CONSTRAINT "Pedido_florId_fkey" FOREIGN KEY ("florId") REFERENCES "Flores"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
