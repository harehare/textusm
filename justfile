default: dev

dev:
  cd frontend && npm run dev

test:
  cd frontend && npm run test
  cd frontend && npm run test:e2e:run
  cd backend && just test
