return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    local lualine = require("lualine")
    local lazy_status = require("lazy.status") -- to configure lazy pending update count

    local colors = {
      bg1 = "#011627",
      bg2 = "#0b2942",
      bg3 = "#084d81",
      gray = "#637777",
      orange = "#f78c6c",
      magenta = "#c792ea",
      purple = "#7e57c2",
      yellow = "#ecc48d",
      lime = "#addb67",
      blue = "#82aaff",
      cyan = "#7fdbca",
      red = "#ff6363",
      fg = "d6deeb",
    }

    local night_owl_lualine_theme = {
      normal = {
        a = { bg = colors.purple, fg = colors.bg1, gui = "bold" },
        b = { bg = colors.bg1, fg = colors.fg },
        c = { bg = colors.bg2, fg = colors.fg },
      },
      insert = {
        a = { bg = colors.cyan, fg = colors.bg1, gui = "bold" },
        b = { bg = colors.bg1, fg = colors.fg },
        c = { bg = colors.bg2, fg = colors.fg },
      },
      visual = {
        a = { bg = colors.blue, fg = colors.bg1, gui = "bold" },
        b = { bg = colors.bg1, fg = colors.fg },
        c = { bg = colors.bg2, fg = colors.fg },
      },
      command = {
        a = { bg = colors.orange, fg = colors.bg1, gui = "bold" },
        b = { bg = colors.bg1, fg = colors.fg },
        c = { bg = colors.bg2, fg = colors.fg },
      },
      replace = {
        a = { bg = colors.red, fg = colors.bg1, gui = "bold" },
        b = { bg = colors.bg1, fg = colors.fg },
        c = { bg = colors.bg2, fg = colors.fg },
      },
      inactive = {
        a = { bg = colors.bg1, fg = colors.gray, gui = "bold" },
        b = { bg = colors.bg1, fg = colors.gray },
        c = { bg = colors.bg1, fg = colors.gray },
      },
    }

    -- configure lualine
    lualine.setup({
      options = {
        theme = night_owl_lualine_theme,
      },
      sections = {
        lualine_x = {
          {
            lazy_status.updates,
            cond = lazy_status.has_updates,
            color = { colors.yellow },
          },
          { "encoding" },
          { "fileformat" },
          { "filetype" },
        },
      },
    })
  end,
}
