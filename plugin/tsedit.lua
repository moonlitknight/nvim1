local tsedit = require("tsedit")
vim.api.nvim_create_user_command("TsStartEdit", tsedit.ts_start_edit, { range = true, nargs = 0 })
vim.api.nvim_create_user_command("TsEndEdit", tsedit.ts_end_edit, { range = true, nargs = 0 })
