-- name: GetItem :one
SELECT
  *
FROM
  items
WHERE
  uid = $1
  AND diagram_id = $2
  AND location = $3;

-- name: ListItems :many
SELECT
  *
FROM
  items
WHERE
  uid = $1
  AND is_public = $2
  AND is_bookmark = $3
  AND location = $4
LIMIT
  $5
OFFSET
  $6;

-- name: CreateItem :exec
INSERT INTO
  items (
    uid,
    diagram,
    diagram_id,
    is_bookmark,
    is_public,
    title,
    text,
    thumbnail,
    location
  )
VALUES
  ($1, $2, $3, $4, $5, $6, $7, $8, $9);

-- name: UpdateItem :exec
UPDATE items
SET
  diagram = $1,
  is_bookmark = $2,
  is_public = $3,
  title = $4,
  text = $5,
  thumbnail = $6,
  location = $7,
  updated_at = NOW()
WHERE
  uid = $8
  AND diagram_id = $9;

-- name: DeleteItem :exec
DELETE FROM items
WHERE
  uid = $1
  AND diagram_id = $2;

-- name: GetShareCondition :one
SELECT
  *
FROM
  share_conditions
WHERE
  hashkey = $1;

-- name: CreateShareCondition :exec
INSERT INTO
  share_conditions (
    hashkey,
    uid,
    diagram_id,
    location,
    allow_ip_list,
    allow_email_list,
    expire_time,
    password,
    token
  )
VALUES
  ($1, $2, $3, $4, $5, $6, $7, $8, $9);

-- name: DeleteShareCondition :exec
DELETE FROM share_conditions
WHERE
  hashkey = $1;

-- name: GetSettings :one
SELECT
  *
FROM
  settings
WHERE
  uid = $1
  AND diagram = $2;

-- name: CreateSettings :exec
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

-- name: UpdateSettings :exec
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
