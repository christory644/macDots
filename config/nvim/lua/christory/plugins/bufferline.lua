return {
  "akinsho/bufferline.nvim",
  dependencies = {
    "nvim-tree/nvim-web-devicons"
  },
  version = "*",
  opts = {
    options = {
      always_show_bufferline = true,
      color_icons = true,
      hover = {
        enabled = true,
        delay = 200,
        reveal = { "close" },
      },
      indicator = { "underline" },
      mode = "buffers",
      numbers = function(opts)
        return string.format('%s', opts.lower(opts.ordinal))
      end,
      offsets = {
        {
          filetype = "NvimTree",
          text = "File Explorer",
          text_align = "left",
          separator = true,
        },
      },
      separator_style = "slant",
    },
  },
}
