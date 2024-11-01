local M = {}

local tmpdir = vim.fn.resolve(vim.fn.stdpath("cache") .. "/textusm")
vim.fn.mkdir(tmpdir, "p")

---@class Config
local config = {
  font = nil,
  size = {
    width = 140,
    height = 65,
  },
  backgroundColor = '#F5F5F6',
  color = {
    activity = {
      color = '#000000',
      backgroundColor = '#FFFFFF'
    },
    task = {
      color = '#FFFFFF',
      backgroundColor = '#3E9BCD'
    },
    story = {
      color = '#000000',
      backgroundColor = '#FFFFFF'
    },
    line = '#434343',
    label = '#8C9FAE',
    text = '#111111'
  },
  scale = 1.0
}

local buffer_to_string = function()
  -- local buf = vim.api.nvim_get_current_buf()
  local content = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  return table.concat(content, "\n")
end

---@param text string
---@return string
local renderPng = function(text)
  if not vim.fn.executable("textusm") then
    error("textusm not found in PATH")
  end

  local tmpname = vim.fn.tempname()
  vim.fn.writefile(vim.split(text, '\n'), tmpname)

  local configfile = tmpdir .. '/config.json'
  vim.fn.writefile(vim.split(vim.fn.json_encode(config), '\n'), tmpname)

  local output = tmpdir .. '/textusm.png'
  local params = {
    "textusm",
    '-i',
    tmpname,
    '-c',
    configfile,
    '-o',
    output,
  }

  local command = table.concat(params, " ")
  vim.fn.system(command)
  if vim.v.shell_error ~= 0 then
    vim.notify("textusm: textusm failed to render diagram", vim.log.levels.ERROR)
    return ""
  end

  os.remove(tmpname)

  return output
end

---@param path string
local displaySixel = function(path)
  if not vim.fn.executable("img2sixel") then
    error("img2sixel not found in PATH")
  end

  local stderr = vim.loop.new_tty(2, false)
  stderr:write(vim.fn.system(string.format("img2sixel %s", path)))
end

---@param config Config
M.setup = function(config)
  -- TODO:
end

M.preview = function()
  vim.cmd('vsplit')
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_create_buf(true, true)
  vim.api.nvim_win_set_buf(win, buf)
  displaySixel(renderPng(buffer_to_string()))
end

return M
