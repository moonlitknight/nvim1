-- File: import_finder.lua
local M = {}

-- Default configuration
local config = {
    root_dir = vim.fn.getcwd(), -- Default to current working directory
    java_script_path = "findjavaimports.sh", -- Default assumes script is in PATH
    typescript_script_path = "findtypescriptimports.sh", -- Default assumes script is in PATH
}

-- Utility function to display error messages
local function show_error(msg)
    vim.api.nvim_err_writeln(msg)
end

-- Utility function to get visual selection lines
local function get_visual_selection()
    -- Save the current mode
    local mode = vim.fn.mode()
    -- Get the start and end positions of the visual selection
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), 'n', true)
    local pos_start = vim.fn.getpos("'<")
    local pos_end = vim.fn.getpos("'>")

    local start_row, start_col = pos_start[2], pos_start[3]
    local end_row, end_col = pos_end[2], pos_end[3]

    -- Get the lines in the range
    local lines = vim.api.nvim_buf_get_lines(0, start_row - 1, end_row, false)

    return lines
end

-- Helper function to parse Java import lines and call findjavaimports.sh
function M.find_java_imports(import_lines)
    local root_dir = config.root_dir
    local java_script = config.java_script_path
    local classnames = {}

    -- Parse each import line to extract the class name
    for _, line in ipairs(import_lines) do
        -- Example line: import com.example.FooClass;
        local import_path = line:match('import%s+([%w%.]+);')
        if import_path then
            table.insert(classnames, import_path)
        end
    end

    if #classnames == 0 then
        show_error("No valid Java import statements found in selection.")
        return nil
    end

    -- Construct the shell command
    -- Ensure the shell scripts are executable and in PATH, or specify the full path
    local cmd = { java_script, root_dir }
    for _, classname in ipairs(classnames) do
        table.insert(cmd, classname)
    end

    -- Execute the shell script and capture the output
    local output = vim.fn.systemlist(cmd)
    local exit_code = vim.v.shell_error

    if exit_code ~= 0 then
        show_error("Error running " .. java_script .. ":\n" .. table.concat(output, "\n"))
        return nil
    end

    if #output == 0 then
        show_error("No files found for the specified Java imports.")
        return nil
    end

    return output
end

-- Helper function to parse TypeScript import lines and call findtypescriptimports.sh
function M.find_typescript_imports(import_lines)
    local root_dir = config.root_dir
    local typescript_script = config.typescript_script_path
    local package_class_pairs = {}

    -- Parse each import line to extract package and class names
    for _, line in ipairs(import_lines) do
        -- Example line: import {Foo1, Foo2} from 'foo_package';
        -- Updated pattern to accept both single and double quotes
        local classes_str, quote, package = line:match('import%s+{([^}]+)}%s+from%s+([\'"])([^\'"]+)%2')
        if classes_str and package then
            -- Split the classes by comma and trim whitespace
            for class in classes_str:gmatch("%s*([^,%s]+)%s*") do
                local pair = package .. "/" .. class
                table.insert(package_class_pairs, pair)
            end
        end
    end

    if #package_class_pairs == 0 then
        show_error("No valid TypeScript import statements found in selection.")
        return nil
    end

    -- Construct the shell command
    -- Ensure the shell scripts are executable and in PATH, or specify the full path
    local cmd = { typescript_script, root_dir }
    for _, pair in ipairs(package_class_pairs) do
        table.insert(cmd, pair)
    end

    -- Execute the shell script and capture the output
    local output = vim.fn.systemlist(cmd)
    local exit_code = vim.v.shell_error

    if exit_code ~= 0 then
        show_error("Error running " .. typescript_script .. ":\n" .. table.concat(output, "\n"))
        return nil
    end

    if #output == 0 then
        show_error("No files found for the specified TypeScript imports.")
        return nil
    end

    return output
end

-- Main function mapped to the FindImports command
function M.find_imports()
    -- Determine the current file type
    local filetype = vim.bo.filetype
    if filetype ~= "java" and filetype ~= "typescript" and filetype ~= "typescriptreact" then
        show_error("FindImports command only supports Java and TypeScript files.")
        return
    end

    -- Get the visual selection
    local import_lines = get_visual_selection()
    if not import_lines or #import_lines == 0 then
        show_error("No visual selection found.")
        return
    end

    local files_to_open = {}

    if filetype == "java" then
        files_to_open = M.find_java_imports(import_lines)
    else -- typescript or typescriptreact
        files_to_open = M.find_typescript_imports(import_lines)
    end

    if not files_to_open or #files_to_open == 0 then
        -- Errors are already handled in helper functions
        return
    end

    -- Open each file in a new Neovim tab
    for _, filepath in ipairs(files_to_open) do
        vim.cmd("tabnew " .. vim.fn.fnameescape(filepath))
    end
end

-- Setup function to configure the plugin
function M.setup(user_config)
    -- Merge user_config into default config
    if user_config then
        if user_config.root_dir then
            if vim.fn.isdirectory(user_config.root_dir) == 1 then
                config.root_dir = user_config.root_dir
            else
                show_error("Invalid root_dir: " .. user_config.root_dir)
                return
            end
        end
        if user_config.java_script_path then
            if vim.fn.executable(user_config.java_script_path) == 1 then
                config.java_script_path = user_config.java_script_path
            else
                show_error("findjavaimports.sh not executable or not found at: " .. user_config.java_script_path)
                return
            end
        end
        if user_config.typescript_script_path then
            if vim.fn.executable(user_config.typescript_script_path) == 1 then
                config.typescript_script_path = user_config.typescript_script_path
            else
                show_error("findtypescriptimports.sh not executable or not found at: " .. user_config.typescript_script_path)
                return
            end
        end
    end

    -- Register the FindImports command
    vim.api.nvim_create_user_command('FindImports', M.find_imports, { range = true, nargs = 0 })
end

return M

