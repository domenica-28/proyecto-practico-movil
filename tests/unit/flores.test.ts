import { describe, it, expect, vi } from "vitest";
import { crearFlorSchema } from "../../src/validations/flores.validation";

describe("Validación de Flores", () => {
  it("Debe validar correctamente un arreglo floral válido", () => {
    const florValida = {
      nombre: "Rosas Rojas Elegantes",
      precio: 25.5,
      stock: 10,
      categoria: "Amor",
    };

    const resultado = crearFlorSchema.safeParse(florValida);
    expect(resultado.success).toBe(true);
  });

  it("Debe rechazar un precio negativo", () => {
    const florInvalida = {
      nombre: "Girasoles",
      precio: -10,
      stock: 5,
      categoria: "Primavera",
    };

    const resultado = crearFlorSchema.safeParse(florInvalida);
    expect(resultado.success).toBe(false);
  });
});