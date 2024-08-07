local colorscheme = "night-owl"

local status_okayz, _ = pcall(vim.cmd, "colorscheme " .. colorscheme)
if not status_okayz then
  vim.notify("colorscheme " .. colorscheme .. " not found!")
  vim.cmd [[ colorscheme slate ]]
  return
end

vim.cmd [[ highlight Normal guibg=none ctermbg=none ]]
vim.cmd [[ highlight LineNr guibg=none ctermbg=none ]]
vim.cmd [[ highlight Folded guibg=none ctermbg=none ]]
vim.cmd [[ highlight NonText guibg=none ctermbg=none ]]
vim.cmd [[ highlight SpecialKey guibg=none ctermbg=none ]]
vim.cmd [[ highlight VertSplit guibg=none ctermbg=none ]]
vim.cmd [[ highlight SignColumn guibg=none ctermbg=none ]]
vim.cmd [[ highlight EndOfBuffer guibg=none ctermbg=none ]]

