-- settings that need to be declared after plugins are loaded

-- colorscheme
vim.cmd.colorscheme("night-owl")

-- substitution
vim.keymap.set("n", "s", require("substitute").operator, { noremap = true, desc = "Substitue with motion" })
vim.keymap.set("n", "ss", require("substitute").line, { noremap = true, desc = "Substitue line" })
vim.keymap.set("n", "S", require("substitute").eol, { noremap = true, desc = "Substitue to end of line" })
vim.keymap.set("x", "s", require("substitute").visual, { noremap = true, desc = "Substitue in visual mode" })
