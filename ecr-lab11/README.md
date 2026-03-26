# Campus Event Board

A polished full-stack showcase for course submission with frontend, backend, optional database, and ECS/ECR deployment assets.

## What this project demonstrates

- Frontend: premium event dashboard UI served by Nginx
- Backend: Node.js + Express API with filtering, validation, and analytics
- Database (optional): PostgreSQL with seeded production-style data
- Cloud-ready packaging: ECR build/push script and ECS task definitions
- Open-source compliance: MIT License in repository root

## Feature highlights

- Rich event model: title, date, location, category, audience, seats, description
- Event filtering: query by keyword and category
- Live metrics panel: total events, seats total, seats reserved, occupancy rate
- Event publishing flow: add events from UI and instantly refresh feed
- Backward compatibility endpoint: `/api/messages` still available

## API endpoints

- `GET /api/health` - service health
- `GET /api/events` - list events
- `GET /api/events?q=cloud&category=Tech` - filtered events
- `POST /api/events` - create an event
- `GET /api/stats` - aggregate event/seat statistics
- `GET /api/messages` - compatibility endpoint

## Local demo

```bash
cd ecr-lab11
docker compose up --build -d

curl http://localhost:8080/api/health
curl http://localhost:8080/api/events
curl "http://localhost:8080/api/events?q=cloud&category=Tech"
curl http://localhost:8080/api/stats
curl http://localhost:8080/api/messages
```

Open http://localhost:8080 to view the dashboard.

## ECR push (when permissions allow)

```bash
cd ecr-lab11
bash scripts/build_and_push_ecr.sh
```

## ECS deploy (manual)

1. Replace placeholders in `ecs/taskdef-backend.json` and `ecs/taskdef-frontend.json`.
2. Register task definitions:

```bash
aws ecs register-task-definition --cli-input-json file://ecs/taskdef-backend.json
aws ecs register-task-definition --cli-input-json file://ecs/taskdef-frontend.json
```

3. Create or update ECS services in your cluster.

## AWS Academy note

If `AccessDeniedException` appears for ECS/ECR actions, it is usually a sandbox policy restriction, not an application issue. In that case:

- Run and demonstrate locally with Docker Compose
- Push code to GitHub
- Include deny output evidence in submission
