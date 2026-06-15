local M = {}
local api = vim.api
local nvim_win_set_config = api.nvim_win_set_config
local nvim_buf_set_lines = api.nvim_buf_set_lines
local nvim_buf_set_extmark = api.nvim_buf_set_extmark
local nvim_win_close = api.nvim_win_close
local nvim_get_mode = api.nvim_get_mode
local nvim_strwidth = api.nvim_strwidth
local nvim_win_is_valid = api.nvim_win_is_valid
local nvim_buf_is_valid = api.nvim_buf_is_valid

local math_floor = math.floor
local string_match = string.match
local string_lower = string.lower
local string_byte = string.byte
local keytrans = vim.fn.keytrans

local state = require("showkeys.state")
local build_ui = require("showkeys.ui")

---@param x string
---@return boolean|string|nil
local function is_mouse(x)
  return string_match(x, "Mouse") or string_match(x, "Scroll")
      or string_match(x, "Drag") or string_match(x, "Release")
end

---@param str string
---@return string
local function format_mapping(str)
  if not str or string_byte(str) ~= 60 then return str end

  local keyformat = state.config.keyformat
  local str1 = string_match(str, "<(.-)>")
  if not str1 then return str end

  local before, after = string_match(str1, "([^%-]+)%-(.+)")
  if before then
    before = "<" .. before .. ">"
    before = keyformat[before] or before
    str1 = before .. " + " .. string_lower(after)
  end

  local str2 = string_match(str, ">(.+)")
  return str1 .. (str2 and (" " .. str2) or "")
end

M.gen_winconfig = function()
  local lines = vim.o.lines
  local cols = vim.o.columns
  local winopts = state.config.winopts
  winopts.width = state.w

  local pos = state.config.position

  if string_match(pos, "bottom") then
    winopts.row = lines - 5
  end

  if pos == "top-right" or pos == "bottom-right" then
    winopts.col = cols - state.w - 3
  elseif pos == "top-center" or pos == "bottom-center" then
    winopts.col = math_floor(cols / 2) - math_floor(state.w / 2)
  end
end

local function update_win_w()
  local len = state.keys_len
  local w = len + 1 + (2 * len)

  local keys_txt = state.keys_txt
  for i = 1, len do
    w = w + nvim_strwidth(keys_txt[i])
  end

  state.w = w
  M.gen_winconfig()

  if state.win and nvim_win_is_valid(state.win) then
    nvim_win_set_config(state.win, state.config.winopts)
  end
end

M.draw = function()
  if not (state.buf and nvim_buf_is_valid(state.buf)) then return end

  local virt_txts = build_ui()

  if not state.extmark_id then
    nvim_buf_set_lines(state.buf, 0, -1, false, { " " })
  end

  local opts = { virt_text = virt_txts, virt_text_pos = "overlay", id = state.extmark_id }
  local id = nvim_buf_set_extmark(state.buf, state.ns, 0, 1, opts)

  if not state.extmark_id then
    state.extmark_id = id
  end
end

M.redraw = function()
  update_win_w()
  M.draw()
end

M.clear_and_close = function()
  state.keys_key = {}
  state.keys_txt = {}
  state.keys_count = {}
  state.keys_len = 0

  M.redraw()
  local tmp = state.win
  state.win = nil

  if tmp and nvim_win_is_valid(tmp) then
    nvim_win_close(tmp, true)
  end
end

---@param char string
M.parse_key = function(char)
  if state.excluded_modes_map[nvim_get_mode().mode] then
    if state.win then M.clear_and_close() end
    return
  end

  local key = keytrans(char)
  if not key or key == "" or is_mouse(key) then return end

  local opts = state.config
  key = opts.keyformat[key] or key
  key = format_mapping(key)

  local len = state.keys_len
  local last_key = state.keys_key[len]

  if opts.show_count and last_key and key == last_key then
    local count = state.keys_count[len] + 1
    state.keys_count[len] = count
    state.keys_txt[len] = count .. " " .. key
  else
    if len >= opts.maxkeys then
      local offset = len - opts.maxkeys + 1
      for i = 1, opts.maxkeys - 1 do
        state.keys_key[i] = state.keys_key[i + offset]
        state.keys_txt[i] = state.keys_txt[i + offset]
        state.keys_count[i] = state.keys_count[i + offset]
      end
      len = opts.maxkeys - 1
    end

    len = len + 1
    state.keys_key[len] = key
    state.keys_txt[len] = key
    state.keys_count[len] = 1
    state.keys_len = len
  end

  M.redraw()
end

return M
