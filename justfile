default: run
set working-directory := 'frontend'

run:
  npm run dev

test:
  cd frontend && npm run test
  cd frontend && npm run test:e2e
  cd backend && just test
