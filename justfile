default: run

run:
  cd frontend && npm run dev

test:
  cd frontend && npm run test
  cd frontend && npm run test:e2e
  cd backend && just test
