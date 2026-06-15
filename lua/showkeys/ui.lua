local state = require("showkeys.state")

---@return string[][]
return function()
  local virt_txts = {}
  local len = state.keys_len
  local keys_txt = state.keys_txt

  for i = 1, len do
    local hl = (i == len) and "SkActive" or "SkInactive"
    virt_txts[#virt_txts + 1] = { " " .. keys_txt[i] .. " ", hl }
    virt_txts[#virt_txts + 1] = { " " }
  end

  return virt_txts
end
