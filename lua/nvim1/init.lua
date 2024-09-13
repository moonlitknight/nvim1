-- lua/nvim1/init.lua

local M = {}

-- Default configuration
M.config = {
    message = "Hello, World!"
}

-- Setup function to allow user configuration
function M.setup(user_config)
    M.config = vim.tbl_deep_extend("force", M.config, user_config or {})
end

function M.say_hello()
    print(M.config.message)
end

return M
