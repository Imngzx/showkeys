---@class ShowkeysPlugin
local M = {}

local api = vim.api
local uv = vim.uv or vim.loop
local nvim_create_buf = api.nvim_create_buf
local nvim_open_win = api.nvim_open_win
local nvim_set_option_value = api.nvim_set_option_value
local nvim_create_namespace = api.nvim_create_namespace
local schedule_wrap = vim.schedule_wrap

local state = require("showkeys.state")
local utils = require("showkeys.utils")

state.ns = nvim_create_namespace("Showkeys")

--- Dynamically set highlights based on current colorscheme
local function setup_highlights()
  api.nvim_set_hl(0, "SkInactive", { default = true, link = "Visual" })

  local diag_err = api.nvim_get_hl(0, { name = "DiagnosticError", link = false })

  api.nvim_set_hl(0, "SkActive", {
    default = true,
    fg = diag_err.fg,
    reverse = true,
    bold = true,
  })
end

--- Setup showkeys plugin
---@param opts? ShowkeysConfig
M.setup = function(opts)
  state.config = vim.tbl_deep_extend("force", state.config, opts or {})
  state.excluded_modes_map = {}
  for _, mode in ipairs(state.config.excluded_modes) do
    state.excluded_modes_map[mode] = true
  end
end

--- Open the showkeys UI
M.open = function()
  state.visible = true
  state.buf = nvim_create_buf(false, true)
  utils.gen_winconfig()
  vim.bo[state.buf].ft = "Showkeys"

  state.timer = uv.new_timer()
  local config = state.config
  local timeout_ms = config.timeout * 1000

  state.on_key = vim.on_key(function(_, char)
    if not state.win then
      state.win = nvim_open_win(state.buf, false, config.winopts)
      nvim_set_option_value("winhl", config.winhl, { win = state.win })
    end

    utils.parse_key(char)

    state.timer:stop()
    state.timer:start(timeout_ms, 0, schedule_wrap(utils.clear_and_close))
  end)

  setup_highlights()

  local augroup = api.nvim_create_augroup("ShowkeysAu", { clear = true })

  api.nvim_create_autocmd("ColorScheme", {
    group = augroup,
    callback = setup_highlights,
  })

  api.nvim_create_autocmd("VimResized", {
    group = augroup,
    callback = function()
      if state.win then utils.redraw() end
    end,
  })

  api.nvim_create_autocmd("TabEnter", {
    group = augroup,
    callback = function()
      if state.win then
        M.close()
        M.open()
      end
    end,
  })

  api.nvim_create_autocmd("WinClosed", {
    group = augroup,
    buf = state.buf,
    callback = function()
      if state.win then
        M.close()
        M.open()
      end
    end,
  })
end

--- Close the showkeys UI and clean up state
M.close = function()
  pcall(api.nvim_del_augroup_by_name, "ShowkeysAu")

  if state.timer then
    state.timer:stop()
    if not state.timer:is_closing() then
      state.timer:close()
    end
    state.timer = nil
  end

  state.keys_key = {}
  state.keys_txt = {}
  state.keys_count = {}
  state.keys_len = 0
  state.w = 1
  state.extmark_id = nil

  if state.buf and api.nvim_buf_is_valid(state.buf) then
    api.nvim_buf_delete(state.buf, { force = true })
  end

  vim.on_key(nil, state.on_key)
  state.visible = false
  state.win = nil
end

--- Toggle the showkeys UI
M.toggle = function()
  if state.visible then
    M.close()
  else
    M.open()
  end
end

return M
