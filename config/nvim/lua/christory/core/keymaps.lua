-- set leader to space
vim.g.mapleader = " "

local keymap = vim.keymap -- for conciseness

-- local function to assist with setting keymaps
local kmap = function(mode, keys, func, description)
  keymap.set(mode, keys, func, { desc = description })
end

-- General Keymappings --------------------------------------------------
-- Plugin or functional specific keymaps are in
-- the respective file

-- different ways to exit insert mode
kmap("i", "jk", "<ESC>", "Exit insert mode with jk")
kmap("i", "jj", "<ESC>", "Exit insert mode with jj")
kmap("i", "kj", "<ESC>", "Exit insert mode with kj")
kmap("i", "kk", "<ESC>", "Exit insert mode with kk")

-- clear search highlights
kmap("n", "<leader>ch", ":nohl<CR>", "Clear search highlights")

-- delete single character without copying into the register
keymap.set("n", "x", '"_x')

-- increment and decrement numbers
kmap("n", "<leader>+", "<C-a>", "Increment number")
kmap("n", "<leader>-", "<C-x>", "Decrement number")

-- window management
kmap("n", "<leader>sv", "<C-w>v", "Split window vertically")
kmap("n", "<leader>sh", "<C-w>s", "Split window horizontally")
kmap("n", "<leader>se", "<C-w>=", "Make splits equal size")
kmap("n", "<leader>sx", "<cmd>close<CR>", "Close current split")
kmap("n", "<C-h>", "<C-w>h", "Move focus left one window")
kmap("n", "<C-j>", "<C-w>j", "Move focus down one window")
kmap("n", "<C-k>", "<C-w>k", "Move focus up one window")
kmap("n", "<C-l>", "<C-w>l", "Move focus right one window")

-- tab management
kmap("n", "<leader>to", "<cmd>tabnew<CR>", "Open a new tab")
kmap("n", "<leader>tx", "<cmd>tabclose<CR>", "Close current tab")
kmap("n", "<leader>tn", "<cmd>tabn<CR>", "Go to next tab")
kmap("n", "<leader>tp", "<cmd>tabp<CR>", "Go to previous tab")
kmap("n", "<leader>tf", "<cmd>tabnew %<CR>", "Open current buffer in a new tab")

-- buffer management
kmap("n", "<leader>bp", "<cmd>BufferLineCyclePrev<CR>", "Go to previous buffer")
kmap("n", "H", "<cmd>BufferLineCyclePrev<CR>", "Go to previous buffer")
kmap("n", "L", "<cmd>BufferLineCycleNext<CR>", "Go to next buffer")
kmap("n", "<leader>bx", "<cmd>bdelete<CR>", "Close (delete) current buffer")
kmap(
  "n",
  "<leader>bxl",
  "<cmd>BufferLineCloseLeft<CR>",
  "Close all visible buffers to the left of the current in bufferline"
)
kmap(
  "n",
  "<leader>bxr",
  "<cmd>BufferLineCloseRight<CR>",
  "Close all visible buffers to the right of the current in bufferline"
)
kmap("n", "<leader>bxf", "<cmd>BufferLinePickClose<CR>", "Pick a buffer to close")
kmap("n", "<leader>bs", "<cmd>BufferLineTogglePin<CR>", "Pin/Unpin current buffer")
kmap("n", "<leader>bf", "<cmd>BufferLinePick<CR>", "Pick a buffer")
kmap("n", "<leader>1", "<cmd>lua require('bufferline').go_to(1, true)<CR>", "Go to buffer 1")
kmap("n", "<leader>2", "<cmd>lua require('bufferline').go_to(2, true)<CR>", "Go to buffer 2")
kmap("n", "<leader>3", "<cmd>lua require('bufferline').go_to(3, true)<CR>", "Go to buffer 3")
kmap("n", "<leader>4", "<cmd>lua require('bufferline').go_to(4, true)<CR>", "Go to buffer 4")
kmap("n", "<leader>5", "<cmd>lua require('bufferline').go_to(5, true)<CR>", "Go to buffer 5")
kmap("n", "<leader>6", "<cmd>lua require('bufferline').go_to(6, true)<CR>", "Go to buffer 6")
kmap("n", "<leader>7", "<cmd>lua require('bufferline').go_to(7, true)<CR>", "Go to buffer 7")
kmap("n", "<leader>8", "<cmd>lua require('bufferline').go_to(8, true)<CR>", "Go to buffer 8")
kmap("n", "<leader>9", "<cmd>lua require('bufferline').go_to(9, true)<CR>", "Go to buffer 9")
kmap("n", "<leader>$", "<cmd>lua leader('bufferline').go_to(-1, true)<CR>", "Go to last buffer")
