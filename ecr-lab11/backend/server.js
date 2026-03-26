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

const fallbackEvents = [
  {
    id: 1,
    title: 'AI Club Meetup',
    date: '2026-04-02',
    location: 'Room B12',
    description: 'Weekly discussion on practical AI tools.',
    category: 'Tech',
    audience: 'All Students',
    seats_total: 50,
    seats_taken: 38
  },
  {
    id: 2,
    title: 'Career Networking Night',
    date: '2026-04-08',
    location: 'Main Hall',
    description: 'Meet alumni and recruiters from tech companies.',
    category: 'Career',
    audience: 'Graduating Students',
    seats_total: 120,
    seats_taken: 92
  }
];

async function ensureSchema() {
  if (!useDb) return;

  await pool.query(`
    CREATE TABLE IF NOT EXISTS events (
      id SERIAL PRIMARY KEY,
      title TEXT NOT NULL,
      date TEXT NOT NULL,
      location TEXT NOT NULL,
      description TEXT NOT NULL,
      category TEXT NOT NULL DEFAULT 'General',
      audience TEXT NOT NULL DEFAULT 'All Students',
      seats_total INTEGER NOT NULL DEFAULT 100,
      seats_taken INTEGER NOT NULL DEFAULT 0
    )
  `);

  // Keep existing DBs compatible with the richer event model.
  await pool.query("ALTER TABLE events ADD COLUMN IF NOT EXISTS category TEXT NOT NULL DEFAULT 'General'");
  await pool.query("ALTER TABLE events ADD COLUMN IF NOT EXISTS audience TEXT NOT NULL DEFAULT 'All Students'");
  await pool.query('ALTER TABLE events ADD COLUMN IF NOT EXISTS seats_total INTEGER NOT NULL DEFAULT 100');
  await pool.query('ALTER TABLE events ADD COLUMN IF NOT EXISTS seats_taken INTEGER NOT NULL DEFAULT 0');
}

ensureSchema().catch((err) => {
  console.error('Failed to ensure DB schema:', err.message);
});

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

app.get('/api/events', async (_req, res) => {
  const { q, category } = _req.query;

  if (!useDb) {
    let events = fallbackEvents;

    if (category) {
      events = events.filter((event) => event.category.toLowerCase() === String(category).toLowerCase());
    }

    if (q) {
      const needle = String(q).toLowerCase();
      events = events.filter(
        (event) =>
          event.title.toLowerCase().includes(needle) ||
          event.location.toLowerCase().includes(needle) ||
          event.description.toLowerCase().includes(needle)
      );
    }

    return res.json(events);
  }

  try {
    const filters = [];
    const params = [];

    if (category) {
      params.push(category);
      filters.push(`category = $${params.length}`);
    }

    if (q) {
      params.push(`%${q}%`);
      filters.push(`(title ILIKE $${params.length} OR location ILIKE $${params.length} OR description ILIKE $${params.length})`);
    }

    const whereClause = filters.length ? `WHERE ${filters.join(' AND ')}` : '';
    const { rows } = await pool.query(
      `SELECT id, title, date, location, description, category, audience, seats_total, seats_taken
       FROM events
       ${whereClause}
       ORDER BY date, id`,
      params
    );
    return res.json(rows);
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

app.get('/api/stats', async (_req, res) => {
  if (!useDb) {
    const seatsTotal = fallbackEvents.reduce((sum, event) => sum + event.seats_total, 0);
    const seatsTaken = fallbackEvents.reduce((sum, event) => sum + event.seats_taken, 0);
    return res.json({
      total_events: fallbackEvents.length,
      seats_total: seatsTotal,
      seats_taken: seatsTaken,
      occupancy_rate: seatsTotal ? Number(((seatsTaken / seatsTotal) * 100).toFixed(1)) : 0
    });
  }

  try {
    const { rows } = await pool.query(
      `SELECT
        COUNT(*)::int AS total_events,
        COALESCE(SUM(seats_total), 0)::int AS seats_total,
        COALESCE(SUM(seats_taken), 0)::int AS seats_taken
       FROM events`
    );
    const stats = rows[0];
    stats.occupancy_rate =
      stats.seats_total > 0 ? Number(((stats.seats_taken / stats.seats_total) * 100).toFixed(1)) : 0;
    return res.json(stats);
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

app.post('/api/events', async (req, res) => {
  const { title, date, location, description, category, audience, seats_total, seats_taken } = req.body || {};

  if (!title || !date || !location || !description) {
    return res.status(400).json({ error: 'title, date, location and description are required' });
  }

  const normalizedCategory = category || 'General';
  const normalizedAudience = audience || 'All Students';
  const normalizedSeatsTotal = Number(seats_total ?? 100);
  const normalizedSeatsTaken = Number(seats_taken ?? 0);

  if (!Number.isFinite(normalizedSeatsTotal) || normalizedSeatsTotal < 1) {
    return res.status(400).json({ error: 'seats_total must be a positive number' });
  }

  if (!Number.isFinite(normalizedSeatsTaken) || normalizedSeatsTaken < 0 || normalizedSeatsTaken > normalizedSeatsTotal) {
    return res.status(400).json({ error: 'seats_taken must be between 0 and seats_total' });
  }

  if (!useDb) {
    return res.status(201).json({
      id: Date.now(),
      title,
      date,
      location,
      description,
      category: normalizedCategory,
      audience: normalizedAudience,
      seats_total: normalizedSeatsTotal,
      seats_taken: normalizedSeatsTaken
    });
  }

  try {
    const { rows } = await pool.query(
      `INSERT INTO events (title, date, location, description, category, audience, seats_total, seats_taken)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       RETURNING id, title, date, location, description, category, audience, seats_total, seats_taken`,
      [
        title,
        date,
        location,
        description,
        normalizedCategory,
        normalizedAudience,
        normalizedSeatsTotal,
        normalizedSeatsTaken
      ]
    );
    return res.status(201).json(rows[0]);
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

app.get('/api/messages', async (_req, res) => {
  if (!useDb) {
    return res.json(fallbackEvents.map((event) => ({ id: event.id, message: event.title })));
  }

  try {
    const { rows } = await pool.query('SELECT id, title AS message FROM events ORDER BY id');
    return res.json(rows);
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

app.listen(port, () => {
  console.log(`Backend listening on port ${port}`);
});
