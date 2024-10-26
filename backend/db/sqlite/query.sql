-- name: GetItem :one
SELECT
  *
FROM
  items
WHERE
  uid = ?
  AND location = ?
  AND diagram_id = ?;

-- name: ListItems :many
SELECT
  *
FROM
  items
WHERE
  uid = ?
  AND location = ?
  AND is_public = ?
  AND is_bookmark = ?
LIMIT
  ?
OFFSET
  ?;

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
    location,
    created_at,
    updated_at
  )
VALUES
  (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);

-- name: UpdateItem :exec
UPDATE items
SET
  diagram = ?,
  is_bookmark = ?,
  is_public = ?,
  title = ?,
  text = ?,
  thumbnail = ?,
  location = ?,
  updated_at = ?
WHERE
  uid = ?
  AND diagram_id = ?;

-- name: DeleteItem :exec
DELETE FROM items
WHERE
  uid = ?
  AND diagram_id = ?;

-- name: GetShareCondition :one
SELECT
  *
FROM
  share_conditions
WHERE
  hashkey = ?;

-- name: GetShareConditionItem :one
SELECT
  *
FROM
  share_conditions
WHERE
  uid = ?
  AND location = ?
  AND diagram_id = ?;

-- name: CreateShareCondition :exec
INSERT INTO
  share_conditions (
    uid,
    hashkey,
    diagram_id,
    location,
    allow_ip_list,
    allow_email_list,
    expire_time,
    password,
    token,
    created_at,
    updated_at
  )
VALUES
  (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);

-- name: DeleteShareCondition :exec
DELETE FROM share_conditions
WHERE
  hashkey = ?;

-- name: DeleteShareConditionItem :exec
DELETE FROM share_conditions
WHERE
  uid = ?
  AND location = ?
  AND diagram_id = ?;

-- name: GetSettings :one
SELECT
  *
FROM
  settings
WHERE
  uid = ?
  AND diagram = ?;

-- name: CreateSettings :exec
INSERT INTO
  settings (
    uid,
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
    zoom_control,
    created_at,
    updated_at
  )
VALUES
  (
    ?,
    ?,
    ?,
    ?,
    ?,
    ?,
    ?,
    ?,
    ?,
    ?,
    ?,
    ?,
    ?,
    ?,
    ?,
    ?,
    ?,
    ?,
    ?,
    ?,
    ?
  );

-- name: UpdateSettings :exec
UPDATE settings
SET
  activity_color = ?,
  activity_background_color = ?,
  background_color = ?,
  height = ?,
  line_color = ?,
  label_color = ?,
  lock_editing = ?,
  text_color = ?,
  toolbar = ?,
  scale = ?,
  show_grid = ?,
  story_color = ?,
  story_background_color = ?,
  task_color = ?,
  task_background_color = ?,
  width = ?,
  zoom_control = ?,
  updated_at = ?
WHERE
  uid = ?
  AND diagram = ?;
