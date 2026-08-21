import type { NextApiRequest, NextApiResponse } from 'next';

export default function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method === 'POST') {
    const { usuario, password } = req.body;

    if (usuario === 'admin' && password === 'admin123') {
      return res.status(200).json({ success: true, token: 'admin-token-secret' });
    } else {
      return res.status(401).json({ error: 'Usuario o contraseña incorrectos' });
    }
  }
  return res.status(405).end();
}