default: run
set working-directory := 'frontend'

run:
  npm run dev

test:
  npm run test
  npm run test:e2e
  cd ../backend && just test
