  -- plugin/hello_world.lua

local hello = require("nvim1")
vim.api.nvim_create_user_command("HelloWorld", hello.say_hello, {})

local find_imports = require("find_imports")
vim.api.nvim_create_user_command("FindImports", find_imports.find_imports, { range = true, nargs = 0 })
