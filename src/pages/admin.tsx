import { useState } from 'react';

export default function AdminPage() {
  // Estado para controlar si el usuario está autenticado
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [passwordInput, setPasswordInput] = useState('');
  const [errorAuth, setErrorAuth] = useState('');

  // Estados del formulario de productos
  const [nombre, setNombre] = useState('');
  const [descripcion, setDescripcion] = useState('');
  const [precio, setPrecio] = useState('');
  const [stock, setStock] = useState('');
  const [categoria, setCategoria] = useState('General');
  const [mensaje, setMensaje] = useState('');

  // Validación de contraseña
  const handleLogin = (e: React.FormEvent) => {
    e.preventDefault();
    // Puedes cambiar 'admin123' por la contraseña que tú quieras
    if (passwordInput === 'admin123') {
      setIsAuthenticated(true);
      setErrorAuth('');
    } else {
      setErrorAuth('Clave incorrecta. Intenta de nuevo.');
    }
  };

  const guardarFlor = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      const res = await fetch('/api/flores', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          nombre,
          descripcion,
          precio: parseFloat(precio),
          stock: parseInt(stock),
          categoria
        })
      });

      if (res.ok) {
        setMensaje('✅ ¡Arreglo floral agregado con éxito!');
        setNombre('');
        setDescripcion('');
        setPrecio('');
        setStock('');
      } else {
        const errorData = await res.json();
        setMensaje(`❌ Error: ${errorData.message || 'No se pudo guardar'}`);
      }
    } catch {
      setMensaje('❌ Error de conexión al guardar.');
    }
  };

  // 1. PANTALLA DE BLOQUEO DE CONTRASEÑA
  if (!isAuthenticated) {
    return (
      <div className="min-h-screen bg-slate-900 flex items-center justify-center p-4 font-sans">
        <div className="bg-white p-8 rounded-2xl shadow-xl max-w-sm w-full">
          <div className="text-center mb-6">
            <span className="text-4xl">🔒</span>
            <h1 className="text-2xl font-bold text-slate-800 mt-2">Acceso Restringido</h1>
            <p className="text-xs text-slate-500 mt-1">Ingresa la clave de administrador para continuar</p>
          </div>

          {errorAuth && (
            <div className="mb-4 p-3 bg-red-50 text-red-600 text-xs font-semibold rounded-lg text-center">
              {errorAuth}
            </div>
          )}

          <form onSubmit={handleLogin} className="space-y-4">
            <div>
              <label className="block text-xs font-bold text-slate-700 mb-1">Contraseña</label>
              <input
                type="password"
                required
                placeholder="••••••••"
                value={passwordInput}
                onChange={(e) => setPasswordInput(e.target.value)}
                className="w-full border rounded-lg p-2.5 text-sm focus:ring-2 focus:ring-slate-800 outline-none"
              />
            </div>
            <button
              type="submit"
              className="w-full bg-slate-900 text-white font-bold py-2.5 rounded-lg hover:bg-slate-800 transition"
            >
              Ingresar al Panel
            </button>
          </form>

          <div className="mt-6 text-center">
            <a href="/" className="text-xs text-pink-600 hover:underline font-semibold">
              ← Volver a la Tienda
            </a>
          </div>
        </div>
      </div>
    );
  }

  // 2. PANEL DE ADMINISTRACIÓN (SOLO SE MUESTRA SI INGRESA LA CLAVE CORRECTA)
  return (
    <div className="min-h-screen bg-slate-100 p-8 font-sans">
      <header className="max-w-2xl mx-auto mb-8 flex justify-between items-center">
        <h1 className="text-3xl font-extrabold text-slate-800">⚙️ Panel de Administración</h1>
        <div className="flex gap-4 items-center">
          <button
            onClick={() => setIsAuthenticated(false)}
            className="text-xs bg-slate-200 text-slate-700 font-bold px-3 py-1.5 rounded-lg hover:bg-slate-300"
          >
            🔒 Cerrar Sesión
          </button>
          <a href="/" className="text-sm font-semibold text-pink-600 hover:underline">
            ← Volver
          </a>
        </div>
      </header>

      <main className="max-w-2xl mx-auto bg-white p-8 rounded-xl shadow-md border border-slate-200">
        <h2 className="text-xl font-bold text-slate-800 mb-4">Agregar Nuevo Arreglo Floral</h2>

        {mensaje && (
          <div className="mb-6 p-4 rounded-lg bg-slate-100 text-slate-800 font-medium text-sm">
            {mensaje}
          </div>
        )}

        <form onSubmit={guardarFlor} className="space-y-4">
          <div>
            <label className="block text-xs font-bold text-slate-700 mb-1">Nombre del Arreglo</label>
            <input
              type="text"
              required
              placeholder="Ej. Ramos de Tulipanes Amarillos"
              value={nombre}
              onChange={(e) => setNombre(e.target.value)}
              className="w-full border rounded-lg p-2 text-sm focus:ring-2 focus:ring-slate-800 outline-none"
            />
          </div>

          <div>
            <label className="block text-xs font-bold text-slate-700 mb-1">Descripción</label>
            <textarea
              placeholder="Detalles sobre las flores, empaque..."
              value={descripcion}
              onChange={(e) => setDescripcion(e.target.value)}
              className="w-full border rounded-lg p-2 text-sm focus:ring-2 focus:ring-slate-800 outline-none h-24"
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-bold text-slate-700 mb-1">Precio ($)</label>
              <input
                type="number"
                step="0.01"
                required
                placeholder="29.99"
                value={precio}
                onChange={(e) => setPrecio(e.target.value)}
                className="w-full border rounded-lg p-2 text-sm focus:ring-2 focus:ring-slate-800 outline-none"
              />
            </div>

            <div>
              <label className="block text-xs font-bold text-slate-700 mb-1">Stock Inicial</label>
              <input
                type="number"
                required
                placeholder="20"
                value={stock}
                onChange={(e) => setStock(e.target.value)}
                className="w-full border rounded-lg p-2 text-sm focus:ring-2 focus:ring-slate-800 outline-none"
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-bold text-slate-700 mb-1">Categoría</label>
            <select
              value={categoria}
              onChange={(e) => setCategoria(e.target.value)}
              className="w-full border rounded-lg p-2 text-sm focus:ring-2 focus:ring-slate-800 outline-none"
            >
              <option value="General">General</option>
              <option value="Rosas">Rosas</option>
              <option value="Eventos">Eventos</option>
              <option value="Cumpleaños">Cumpleaños</option>
            </select>
          </div>

          <button
            type="submit"
            className="w-full bg-slate-900 text-white font-bold py-3 rounded-lg hover:bg-slate-800 transition mt-4"
          >
            Guardar Producto en la Base de Datos
          </button>
        </form>
      </main>
    </div>
  );
}