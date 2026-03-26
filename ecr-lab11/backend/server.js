const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');

const app = express();
const port = process.env.PORT || 3000;
const useDb = process.env.USE_DB === 'true';

app.use(cors());
app.use(express.json());

let pool = null;
if (useDb) {
  pool = new Pool({
    host: process.env.DB_HOST || 'db',
    port: Number(process.env.DB_PORT || 5432),
    user: process.env.DB_USER || 'appuser',
    password: process.env.DB_PASSWORD || 'appsecret',
    database: process.env.DB_NAME || 'appdb'
  });
}

app.get('/api/health', async (_req, res) => {
  if (!useDb) {
    return res.json({ status: 'ok', db: 'disabled' });
  }

  try {
    await pool.query('SELECT 1');
    return res.json({ status: 'ok', db: 'connected' });
  } catch (err) {
    return res.status(500).json({ status: 'error', db: err.message });
  }
});

app.get('/api/messages', async (_req, res) => {
  if (!useDb) {
    return res.json([
      { id: 1, message: 'Hello from backend (no DB mode)' },
      { id: 2, message: 'ECS/ECR-ready API' }
    ]);
  }

  try {
    const { rows } = await pool.query('SELECT id, message FROM messages ORDER BY id');
    return res.json(rows);
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

app.listen(port, () => {
  console.log(`Backend listening on port ${port}`);
});
