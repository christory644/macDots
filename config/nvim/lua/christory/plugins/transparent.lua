return {
  "xiyaowong/transparent.nvim",
  lazy = false,
  config = function()
    require("transparent").setup({
      groups = {
        "Normal",
        "NormalNC",
        "Comment",
        "Constant",
        "Special",
        "Identifier",
        "Statement",
        "PreProc",
        "Type",
        "Underlined",
        "Todo",
        "String",
        "Function",
        "Conditional",
        "Repeate",
        "Operator",
        "Structure",
        "LineNr",
        "NonText",
        "SignColumn",
        "StatusLine",
        "StatusLineNC",
        "EndOfBuffer",
      },
      extra_groups = {
        "NvimTreeNormal",
      },
    })
  end,
}
