---@class ShowkeysConfig
---@field winopts? vim.api.keyset.win_config Window options for `nvim_open_win`
---@field winhl? string Highlight mapping, e.g., "FloatBorder:Comment,Normal:Normal"
---@field timeout? number Timeout in seconds before hiding the UI
---@field maxkeys? number Maximum number of keys to display
---@field show_count? boolean Whether to show counts for repeated keys
---@field excluded_modes? string[] Modes where showkeys should be disabled (e.g., {"i"})
---@field position? "bottom-left"|"bottom-right"|"bottom-center"|"top-left"|"top-right"|"top-center"
---@field keyformat? table<string, string> Key translation mappings

---@class ShowkeysState
---@field keys_key string[]
---@field keys_txt string[]
---@field keys_count number[]
---@field keys_len number
---@field w number
---@field extmark_id integer|nil
---@field visible boolean
---@field buf integer|nil
---@field win integer|nil
---@field timer uv.uv_timer_t|nil
---@field on_key integer|nil
---@field excluded_modes_map table<string, boolean>
---@field ns integer
---@field config ShowkeysConfig

---@type ShowkeysState
local M = {
  keys_key = {},
  keys_txt = {},
  keys_count = {},
  keys_len = 0,

  w = 1,
  extmark_id = nil,
  visible = false,
  buf = nil,
  win = nil,
  timer = nil,
  on_key = nil,
  excluded_modes_map = {},
  ns = 0,

  config = {
    winopts = {
      relative = 'editor',
      style = 'minimal',
      border = 'single',
      height = 1,
      row = 1,
      col = 0,
      zindex = 100,
    },
    winhl = 'FloatBorder:Comment,Normal:Normal',
    timeout = 3,
    maxkeys = 3,
    show_count = false,
    excluded_modes = {},
    position = 'bottom-right',
    keyformat = {
      ['<BS>'] = '󰁮 ',
      ['<CR>'] = '󰘌',
      ['<Space>'] = '󱁐',
      ['<Up>'] = '󰁝',
      ['<Down>'] = '󰁅',
      ['<Left>'] = '󰁍',
      ['<Right>'] = '󰁔',
      ['<PageUp>'] = 'Page 󰁝',
      ['<PageDown>'] = 'Page 󰁅',
      ['<M>'] = 'Alt',
      ['<C>'] = 'Ctrl',
    },
  },
}

return M
