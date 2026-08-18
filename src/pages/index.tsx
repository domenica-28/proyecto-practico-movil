import { useEffect, useState } from 'react';

interface Flor {
  id: string;
  nombre: string;
  descripcion: string;
  precio: number;
  stock: number;
  estado: string;
}

export default function Home() {
  const [flores, setFlores] = useState<Flor[]>([]);
  const [cargando, setCargando] = useState(true);
  const [florSeleccionada, setFlorSeleccionada] = useState<Flor | null>(null);
  
  // Datos del formulario de pedido
  const [direccion, setDireccion] = useState('');
  const [telefono, setTelefono] = useState('');
  const [cantidad, setCantidad] = useState(1);
  const [mensaje, setMensaje] = useState('');

  useEffect(() => {
    cargarFlores();
  }, []);

  const cargarFlores = () => {
    fetch('/api/flores')
      .then((res) => res.json())
      .then((res) => {
        if (res.success) setFlores(res.data);
        setCargando(false);
      })
      .catch(() => setCargando(false));
  };

  const procesarPedido = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!florSeleccionada) return;

    try {
      const res = await fetch('/api/pedidos', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          usuarioId: "usr-cliente-demo", // ID simulado o autenticado
          direccionEnvio: direccion,
          telefonoContacto: telefono,
          items: [{ florId: florSeleccionada.id, cantidad: Number(cantidad) }]
        })
      });

      const data = await res.json();
      if (res.ok) {
        setMensaje(`¡Pedido realizado con éxito! ID: ${data.data?.id || 'OK'}`);
        setTimeout(() => {
          setFlorSeleccionada(null);
          setMensaje('');
          cargarFlores(); // Recargar stock actualizado
        }, 2000);
      } else {
        setMensaje(`Error: ${data.message || 'No se pudo procesar'}`);
      }
    } catch {
      setMensaje('Error al conectar con el servidor.');
    }
  };

  return (
    <div className="min-h-screen bg-slate-50 p-8 font-sans">
      <header className="max-w-5xl mx-auto mb-10 flex justify-between items-center">
        <div>
          <h1 className="text-4xl font-extrabold text-pink-600 tracking-tight">
            🌺 Catálogo de Florería
          </h1>
          <p className="text-slate-600 mt-1">Elige tus arreglos florales favoritos y haz tu pedido en línea</p>
        </div>
        <a 
          href="/admin" 
          className="bg-slate-800 text-white px-4 py-2 rounded-lg text-sm font-semibold hover:bg-slate-700 transition"
        >
          ⚙️ Panel Admin
        </a>
      </header>

      <main className="max-w-5xl mx-auto">
        {cargando ? (
          <p className="text-center text-slate-500">Cargando catálogo...</p>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {flores.map((flor) => (
              <div key={flor.id} className="bg-white rounded-xl shadow-md border border-slate-100 p-6 flex flex-col justify-between">
                <div>
                  <span className="inline-block px-3 py-1 text-xs font-semibold text-emerald-700 bg-emerald-50 rounded-full mb-3">
                    {flor.estado}
                  </span>
                  <h2 className="text-xl font-bold text-slate-800">{flor.nombre}</h2>
                  <p className="text-slate-600 text-sm mt-2 mb-4">{flor.descripcion}</p>
                </div>
                <div>
                  <div className="flex justify-between items-center pt-4 border-t border-slate-100 mb-4">
                    <span className="text-2xl font-extrabold text-pink-600">${flor.precio}</span>
                    <span className="text-xs text-slate-500 font-medium">Stock: {flor.stock} uds.</span>
                  </div>
                  <button
                    onClick={() => setFlorSeleccionada(flor)}
                    disabled={flor.stock <= 0}
                    className="w-full bg-pink-600 text-white font-bold py-2 px-4 rounded-lg hover:bg-pink-700 disabled:bg-slate-300 transition"
                  >
                    {flor.stock > 0 ? '🛒 Hacer Pedido' : 'Sin Stock'}
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}

        {/* MODAL DE COMPRA */}
        {florSeleccionada && (
          <div className="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-50">
            <div className="bg-white rounded-xl max-w-md w-full p-6 shadow-2xl">
              <h3 className="text-xl font-bold text-slate-800 mb-2">Realizar Pedido</h3>
              <p className="text-sm text-slate-600 mb-4">Producto: <span className="font-semibold text-pink-600">{florSeleccionada.nombre}</span></p>

              {mensaje && <div className="mb-4 p-3 text-sm bg-pink-50 text-pink-700 rounded-lg">{mensaje}</div>}

              <form onSubmit={procesarPedido} className="space-y-4">
                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1">Dirección de Entrega</label>
                  <input
                    type="text"
                    required
                    placeholder="Ej. Av. Amazonas y República"
                    value={direccion}
                    onChange={(e) => setDireccion(e.target.value)}
                    className="w-full border rounded-lg p-2 text-sm focus:ring-2 focus:ring-pink-500 outline-none"
                  />
                </div>
                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1">Teléfono de Contacto</label>
                  <input
                    type="text"
                    required
                    placeholder="Ej. 0991234567"
                    value={telefono}
                    onChange={(e) => setTelefono(e.target.value)}
                    className="w-full border rounded-lg p-2 text-sm focus:ring-2 focus:ring-pink-500 outline-none"
                  />
                </div>
                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1">Cantidad</label>
                  <input
                    type="number"
                    min="1"
                    max={florSeleccionada.stock}
                    value={cantidad}
                    onChange={(e) => setCantidad(Number(e.target.value))}
                    className="w-full border rounded-lg p-2 text-sm focus:ring-2 focus:ring-pink-500 outline-none"
                  />
                </div>
                <div className="flex gap-2 pt-2">
                  <button
                    type="button"
                    onClick={() => setFlorSeleccionada(null)}
                    className="w-1/2 bg-slate-200 text-slate-700 font-bold py-2 rounded-lg hover:bg-slate-300"
                  >
                    Cancelar
                  </button>
                  <button
                    type="submit"
                    className="w-1/2 bg-pink-600 text-white font-bold py-2 rounded-lg hover:bg-pink-700"
                  >
                    Confirmar
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}
      </main>
    </div>
  );
}