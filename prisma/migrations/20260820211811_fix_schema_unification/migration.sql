/*
  Warnings:

  - The primary key for the `flores` table will be changed. If it partially fails, the table could be left without primary key constraint.
  - You are about to drop the column `created_at` on the `flores` table. All the data in the column will be lost.
  - You are about to drop the column `updated_at` on the `flores` table. All the data in the column will be lost.
  - The `id` column on the `flores` table would be dropped and recreated. This will lead to data loss if there is data in the column.
  - The `estado` column on the `flores` table would be dropped and recreated. This will lead to data loss if there is data in the column.
  - You are about to drop the `Flores` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `Pedido` table. If the table is not empty, all the data it contains will be lost.
  - Made the column `descripcion` on table `flores` required. This step will fail if there are existing NULL values in that column.

*/
-- DropForeignKey
ALTER TABLE "Pedido" DROP CONSTRAINT "Pedido_florId_fkey";

-- AlterTable
ALTER TABLE "flores" DROP CONSTRAINT "flores_pkey",
DROP COLUMN "created_at",
DROP COLUMN "updated_at",
ADD COLUMN     "imagenUrl" TEXT,
DROP COLUMN "id",
ADD COLUMN     "id" SERIAL NOT NULL,
ALTER COLUMN "nombre" SET DATA TYPE TEXT,
ALTER COLUMN "descripcion" SET NOT NULL,
ALTER COLUMN "stock" DROP DEFAULT,
DROP COLUMN "estado",
ADD COLUMN     "estado" BOOLEAN NOT NULL DEFAULT true,
ADD CONSTRAINT "flores_pkey" PRIMARY KEY ("id");

-- DropTable
DROP TABLE "Flores";

-- DropTable
DROP TABLE "Pedido";

-- CreateTable
CREATE TABLE "flor_uuid" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "nombre" VARCHAR(150) NOT NULL,
    "descripcion" TEXT,
    "precio" DOUBLE PRECISION NOT NULL,
    "stock" INTEGER NOT NULL DEFAULT 0,
    "estado" VARCHAR(30) NOT NULL DEFAULT 'ACTIVO',
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "flor_uuid_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "pedidos" (
    "id" SERIAL NOT NULL,
    "florId" INTEGER NOT NULL,
    "cliente" TEXT NOT NULL,
    "cantidad" INTEGER NOT NULL,
    "visto" BOOLEAN NOT NULL DEFAULT false,
    "estado" TEXT NOT NULL DEFAULT 'Pendiente',
    "fecha" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "pedidos_pkey" PRIMARY KEY ("id")
);

-- AddForeignKey
ALTER TABLE "pedidos" ADD CONSTRAINT "pedidos_florId_fkey" FOREIGN KEY ("florId") REFERENCES "flores"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
