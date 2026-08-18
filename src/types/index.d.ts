export type EstadoPedido = "PENDIENTE" | "EN_PREPARACION" | "ENVIADO" | "ENTREGADO" | "CANCELADO";

export interface FlorCrearInput {
  nombre: string;
  descripcion?: string;
  precio: number;
  stock: number;
  categoria: string;
  imagenUrl?: string;
}

export interface PedidoCrearInput {
  usuarioId: string;
  direccionEnvio: string;
  telefonoContacto: string;
  items: {
    florId: string;
    cantidad: number;
  }[];
}