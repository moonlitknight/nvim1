-- File: lua/import_finder.lua

local M = {}

M.options = {
    root_dir = '/usr/app',
}

-- Helper function to recursively find files
local function find_files(directory, file_type)
    local files = {}
    local handle = vim.loop.fs_scandir(directory)
    if handle then
        while true do
            local name, type = vim.loop.fs_scandir_next(handle)
            if not name then break end
            local path = directory .. '/' .. name
            if type == 'directory' and name ~= 'node_modules' and name ~= '.git' then
                for _, file in ipairs(find_files(path, file_type)) do
                    table.insert(files, file)
                end
            elseif type == 'file' and vim.fn.fnamemodify(name, ':e') == file_type then
                table.insert(files, path)
            end
        end
    end
    return files
end

-- Function to find Java source file
local function find_java_source(import_statement, files)
    local package_path = import_statement:gsub('%.', '/')
    for _, file in ipairs(files) do
        if file:match(package_path) then
            return file
        end
    end
    return nil
end

-- Function to find TypeScript source file
local function find_ts_source(import_statement, files)
    local package_name = import_statement:match("from%s+'(.+)'")
    if not package_name then return nil end

    -- Find package.json for the imported package
    local package_json_path
    for _, file in ipairs(files) do
        if file:match(package_name .. '/package%.json$') then
            package_json_path = file
            break
        end
    end

    if not package_json_path then return nil end

    -- Find the TypeScript file that exports the imported class
    local imported_class = import_statement:match('{%s*(%w+)%s*}')
    if not imported_class then return nil end

    local package_dir = vim.fn.fnamemodify(package_json_path, ':h')
    for _, file in ipairs(files) do
        if file:match('^' .. package_dir) and file:match('%.ts$') then
            local content = vim.fn.readfile(file)
            for _, line in ipairs(content) do
                if line:match('export.*' .. imported_class) then
                    return file
                end
            end
        end
    end

    return nil
end

function M.find_imports()
    local file_type = vim.bo.filetype
    if file_type ~= 'typescript' and file_type ~= 'java' then
        print("Unsupported file type. Only TypeScript and Java are supported.")
        return
    end

    local files = find_files(M.options.root_dir, file_type == 'typescript' and 'ts' or 'java')

    local start_line, end_line = unpack(vim.fn.getpos("'<"), 2, 3)
    local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)

    for i, line in ipairs(lines) do
        local source_file
        if file_type == 'java' then
            source_file = find_java_source(line, files)
        else
            source_file = find_ts_source(line, files)
        end

        if source_file then
            local new_line = line .. ' // ' .. source_file
            vim.api.nvim_buf_set_lines(0, start_line - 1 + i - 1, start_line - 1 + i, false, {new_line})
            print("Found source for line " .. i .. ": " .. source_file)
        else
            print("Could not find source for line " .. i)
        end
    end
end

function M.setup(opts)
    M.options = vim.tbl_deep_extend("force", M.options, opts or {})
    
    vim.api.nvim_create_user_command('ImportFinderG1', M.find_imports, {range = true})
    vim.api.nvim_set_keymap('v', ',.fi', ':ImportFinderG1<CR>', {noremap = true, silent = true})
end

return M