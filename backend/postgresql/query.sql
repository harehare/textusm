-- name: GetItem :one
SELECT
  *
FROM
  items
WHERE
  uid = $1
  AND diagram_id = $2;

-- name: ListItems :many
SELECT
  *
FROM
  items
WHERE
  uid = $1;

-- name: CreateItem :batchexec
INSERT INTO
  items (
    diagram,
    diagram_id,
    is_bookmark,
    is_public,
    title,
    text,
    thumbnail
  )
VALUES
  ($1, $2, $3, $4, $5, $6, $7);

-- name: UpdateItem :batchexec
UPDATE items
SET
  diagram = $1,
  is_bookmark = $2,
  is_public = $3,
  title = $4,
  text = $5,
  thumbnail = $6,
  updated_at = NOW()
WHERE
  uid = $1
  AND diagram_id = $7;

-- name: GetSettings :one
SELECT
  *
FROM
  settings
WHERE
  uid = $1
  AND diagram = $2;

-- name: CreateSettings :batchexec
INSERT INTO
  settings (
    id,
    activity_color,
    activity_background_color,
    background_color,
    height,
    diagram,
    line_color,
    label_color,
    lock_editing,
    text_color,
    toolbar,
    scale,
    show_grid,
    story_color,
    story_background_color,
    task_color,
    task_background_color,
    width,
    zoom_control
  )
VALUES
  (
    1,
    $1,
    $2,
    $3,
    $4,
    $5,
    $6,
    $7,
    $8,
    $9,
    $10,
    $11,
    $12,
    $13,
    $14,
    $15,
    $16,
    $17,
    $18
  );

-- name: UpdateSettings :batchexec
UPDATE settings
SET
  activity_color = $1,
  activity_background_color = $2,
  background_color = $3,
  height = $4,
  line_color = $5,
  label_color = $6,
  lock_editing = $7,
  text_color = $8,
  toolbar = $9,
  scale = $10,
  show_grid = $11,
  story_color = $12,
  story_background_color = $13,
  task_color = $14,
  task_background_color = $15,
  width = $16,
  zoom_control = $17
WHERE
  uid = $1
  AND diagram = $2;
