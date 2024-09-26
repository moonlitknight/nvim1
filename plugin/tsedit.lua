local tsedit = require("tsedit")
vim.api.nvim_create_user_command("TsStartEdit", tsedit.ts_start_edit, { range = true, nargs = 0 })
vim.api.nvim_create_user_command("TsEndEdit", tsedit.ts_end_edit, { range = true, nargs = 0 })
vim.api.nvim_set_keymap('n', '<leader>.ts', ':TsStartEdit<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>.te', ':TsEndEdit<CR>', { noremap = true, silent = true })

