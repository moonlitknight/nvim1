-- readme-finder.lua

local M = {}

-- Default configuration
M.config = {
  marker_files = {"READMEROOTDIR", "pnpm-workspaces.yaml", "package.json"}
}

-- Function to find the project root
local function find_project_root()
  local current_dir = vim.fn.expand('%:p:h')
  while current_dir ~= '/' do
    for _, marker in ipairs(M.config.marker_files) do
      local marker_path = current_dir .. '/' .. marker
      if vim.fn.filereadable(marker_path) == 1 then
        return current_dir
      end
    end
    current_dir = vim.fn.fnamemodify(current_dir, ':h')
  end
  return nil
end

-- Function to find all README.md files
local function find_readme_files(root)
  local command = string.format("find %s -name README.md", root)
  local handle = io.popen(command)
  local result = handle:read("*a")
  handle:close()
  
  local files = {}
  for file in result:gmatch("[^\r\n]+") do
    table.insert(files, file)
  end
  return files
end

-- Function to open README finder
function M.open_readme_finder()
  local project_root = find_project_root()
  if not project_root then
    print("Could not find project root.")
    return
  end

  local readme_files = find_readme_files(project_root)
  
  require('telescope.builtin').find_files {
    prompt_title = "README Files",
    cwd = project_root,
    find_command = { "find", ".", "-name", "README.md" },
    attach_mappings = function(_, map)
      map('i', '<CR>', function(prompt_bufnr)
        local selection = require('telescope.actions.state').get_selected_entry()
        require('telescope.actions').close(prompt_bufnr)
        vim.cmd('edit ' .. selection.path)
      end)
      return true
    end,
    previewer = require('telescope.previewers').vim_buffer_cat.new
  }
end

-- Setup function
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

return M
