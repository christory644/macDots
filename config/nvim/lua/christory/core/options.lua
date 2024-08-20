vim.cmd("let g:netrw_liststyle = 3")

local opt = vim.opt -- simply for conciseness

-- relative line numbering
opt.relativenumber = true

-- exact number for current line
opt.number = true

-- tabs and indentation
opt.tabstop = 2 -- 2 spaces for tabs (default for prettier, and better than 4)
opt.shiftwidth = 2 -- 2 spaces for indent width
opt.expandtab = true -- expand tab key to spaces
opt.autoindent = true -- copy indent from current line when starting a new one

-- no line wrapping
opt.wrap = false

-- search settings
opt.ignorecase = true -- ignore case when searching
opt.smartcase = true -- if you include mixed case in your search, use case-sensitive searching

-- turn on the cursor line
opt.cursorline = true

-- intuitive backspace settings
opt.backspace = "indent,eol,start" -- allow backspace on indent, end of line, or start position when in insert mode

-- split window behavior
opt.splitright = true -- split vertical windows to the right
opt.splitbelow = true -- split horizontal windows to the bottom

-- clipboard
opt.clipboard:append("unnamedplus") -- use the system clipboard as the default register, allows copy pasting to and from nvim

-- appearance settings

-- turn on termguicolors, needed for some colorschemes to work
-- this requires a true color terminal (iterm2, kitty, alacritty, etc)
opt.termguicolors = true
opt.background = "dark" -- use the dark version of colorschemes with a light and dark mode

-- always show the sign column to avoid text shifting
opt.signcolumn = "yes"

-- enable mouse movement
opt.mouse = "nv"
opt.mousemoveevent = true
