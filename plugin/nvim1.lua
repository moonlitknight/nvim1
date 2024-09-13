  -- plugin/hello_world.lua

local hello = require("nvim1")

vim.api.nvim_create_user_command("HelloWorld", hello.say_hello, {})
