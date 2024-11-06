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

-- Function to find all README.md files, excluding node_modules
local function find_readme_files(root)
  local command = string.format("find %s -name README\* -not -path '*/node_modules/*'", root)
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
  
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  pickers.new({}, {
    prompt_title = "README Files",
    finder = finders.new_table {
      results = readme_files,
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry,
          ordinal = entry,
          path = entry,
        }
      end
    },
    sorter = conf.generic_sorter({}),
    previewer = conf.file_previewer({}),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        vim.cmd('edit ' .. selection.path)
      end)
      return true
    end,
  }):find()
end

-- Setup function
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

return M
