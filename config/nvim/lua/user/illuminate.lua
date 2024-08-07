vim.g.Illuminate_ftblacklist = {'alpha', 'NvimTree'}
vim.api.nvim_set_keymap('n', '<a-n>', '<cmd>lua require"illuminate".next_reference{wrap=true}<cr>', {noremap=true})
vim.api.nvim_set_keymap('n', '<a-p>', '<cmd>lua require"illuminate".next_reference{reverse=true,wrap=true}<cr>', {noremap=true})
vim.api.nvim_command [[ hi def link LspReferenceText CursorLine ]]
vim.api.nvim_command [[ hi def link LspReferenceWrite CursorLine ]]
vim.api.nvim_command [[ hi def link LspReferenceRead CursorLine ]]
