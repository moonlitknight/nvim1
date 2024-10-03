local readmefinder = require("readmefinder")
vim.api.nvim_create_user_command("ReadmeFinder", readmefinder.open_readme_finder, { range = true, nargs = 0 })
