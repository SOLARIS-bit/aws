CREATE TABLE IF NOT EXISTS events (
  id SERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  date TEXT NOT NULL,
  location TEXT NOT NULL,
  category TEXT NOT NULL DEFAULT 'General',
  audience TEXT NOT NULL DEFAULT 'All Students',
  seats_total INTEGER NOT NULL DEFAULT 100,
  seats_taken INTEGER NOT NULL DEFAULT 0,
  description TEXT NOT NULL
);

INSERT INTO events (title, date, location, category, audience, seats_total, seats_taken, description) VALUES
('AI Club Meetup', '2026-04-02', 'Room B12', 'Tech', 'Engineering Students', 120, 75, 'Weekly discussion on practical AI tools.'),
('Career Networking Night', '2026-04-08', 'Main Hall', 'Career', 'All Students', 200, 143, 'Meet alumni and recruiters from tech companies.'),
('Cloud Study Jam', '2026-04-12', 'Lab C3', 'Tech', 'Cloud Certification Cohort', 90, 66, 'Hands-on AWS practice before exams.'),
('Open Campus Social', '2026-04-18', 'North Plaza', 'Community', 'All Students', 260, 190, 'Student clubs host demos, live music, and volunteer signups.')
ON CONFLICT DO NOTHING;
