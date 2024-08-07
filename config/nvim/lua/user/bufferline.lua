local status_okayz, bufferline = pcall(require, "bufferline")
if not status_okayz then
  return
end

bufferline.setup {
  options = {
    close_command = "Bdelete! %d", -- can be a string | function, see "Mouse actions"
    right_mouse_command = "Bdelete! %d", -- can be a string | function, see "Mouse actions"
    offsets = { { filetype = "NvimTree", text = "", padding = 1 } },
    separator_style = "thick" -- | "thick" | "thin" | { 'any', 'any' },
  },
}
