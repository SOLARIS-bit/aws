CREATE TABLE IF NOT EXISTS messages (
  id SERIAL PRIMARY KEY,
  message TEXT NOT NULL
);

INSERT INTO messages (message) VALUES
('Hello from PostgreSQL'),
('Backend is connected to DB'),
('Ready for ECS/ECR deployment')
ON CONFLICT DO NOTHING;
