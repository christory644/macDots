return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  init = function()
    vim.o.timeout = true
    vim.o.timeoutlen = 500
  end,
  opts = {
    defer = function(ctx)
      return ctx.mode == "V" or ctx.mode == "<C-V>" or ctx.mode == "v"
    end,
    preset = "helix",
  },
}
