-- ts_embedded_edit.lua

local M = {}

-- Default configuration
M.config = {
  delimiter = "---",
  temp_suffix = ".ts"
}

-- Function to set up the plugin
function M.setup(user_config)
  M.config = vim.tbl_deep_extend("force", M.config, user_config or {})

end

-- Function to start editing TypeScript
function M.ts_start_edit()
  local current_buf = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(current_buf, 0, -1, false)
  
  -- Find the start and end lines containing the delimiter
  local start_line, end_line
  for i, line in ipairs(lines) do
    if line:match("^" .. M.config.delimiter .. "$") then
      if not start_line then
        start_line = i
      else
        end_line = i
        break
      end
    end
  end
  
  if not start_line or not end_line then
    print("Could not find TypeScript section delimited by " .. M.config.delimiter)
    return
  end
  
  -- Extract the TypeScript content
  local ts_content = table.concat(vim.list_slice(lines, start_line + 1, end_line - 1), "\n")
  
  -- Create a temporary file
  local current_file = vim.fn.expand("%:p")
  local temp_file = current_file .. M.config.temp_suffix
  
  -- Write TypeScript content to the temporary file
  local file = io.open(temp_file, "w")
  if file then
    file:write(ts_content)
    file:close()
  else
    print("Failed to create temporary file: " .. temp_file)
    return
  end
  
  -- Open the temporary file in a split window at the top
  vim.cmd("topleft split " .. temp_file)
  
  -- Store the original buffer number and line range in the temporary buffer's variables
  vim.api.nvim_buf_set_var(vim.api.nvim_get_current_buf(), "original_buf", current_buf)
  vim.api.nvim_buf_set_var(vim.api.nvim_get_current_buf(), "start_line", start_line)
  vim.api.nvim_buf_set_var(vim.api.nvim_get_current_buf(), "end_line", end_line)
end

-- Function to end editing TypeScript
function M.ts_end_edit()
  local current_buf = vim.api.nvim_get_current_buf()
  local current_file = vim.fn.expand("%:p")
  
  -- Check if the current buffer is a temporary TypeScript file
  if not current_file:match(M.config.temp_suffix .. "$") then
    print("Warning: This is not a temporary TypeScript file.")
    return
  end
  
  -- Get the original buffer number and line range
  local original_buf = vim.api.nvim_buf_get_var(current_buf, "original_buf")
  local start_line = vim.api.nvim_buf_get_var(current_buf, "start_line")
  local end_line = vim.api.nvim_buf_get_var(current_buf, "end_line")
  
  -- Get the content of the temporary buffer
  local lines = vim.api.nvim_buf_get_lines(current_buf, 0, -1, false)
  
  -- Replace the content in the original buffer
  vim.api.nvim_buf_set_lines(original_buf, start_line + 1, end_line - 1, false, lines)
  
  -- Close the temporary buffer and delete the temporary file
  vim.cmd("bdelete!")
  os.remove(current_file)
  
  -- Switch to the original buffer
  vim.api.nvim_set_current_buf(original_buf)
end

return M
