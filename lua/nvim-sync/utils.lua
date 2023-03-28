local M = {}

local config = require("nvim-sync.config").config
local ppath = require "plenary.path"
local glob = require "nvim-sync.globtopattern"
local uv = vim.loop

local function find_lsp_root()
  local buf_ft = vim.api.nvim_buf_get_option(0, "filetype")
  local clients = vim.lsp.buf_get_clients()
  if next(clients) == nil then
    return nil
  end

  for _, client in pairs(clients) do
    local filetypes = client.config.filetypes
    if filetypes and vim.tbl_contains(filetypes, buf_ft) then
      if not vim.tbl_contains(config.ignore_lsp, client.name) then
        return client.config.root_dir, client.name
      end
    end
  end
end

-- find_pattern_root Finds the root directory of the project using the patterns
-- defined in config.lua
-- @return string
local function find_pattern_root()
  local search_dir = vim.fn.expand("%:p:h", true)
  if vim.fn.has "win32" > 0 then
    search_dir = search_dir:gsub("\\", "/")
  end

  local last_dir_cache = ""
  local curr_dir_cache = {}

  local function get_parent(path)
    path = path:match "^(.*)/"
    if path == "" then
      path = "/"
    end
    return path
  end

  local function get_files(file_dir)
    last_dir_cache = file_dir
    curr_dir_cache = {}

    local dir = uv.fs_scandir(file_dir)
    if dir == nil then
      return
    end

    while true do
      local file = uv.fs_scandir_next(dir)
      if file == nil then
        return
      end

      table.insert(curr_dir_cache, file)
    end
  end

  local function is(dir, identifier)
    dir = dir:match ".*/(.*)"
    return dir == identifier
  end

  local function sub(dir, identifier)
    local path = get_parent(dir)
    while true do
      if is(path, identifier) then
        return true
      end
      local current = path
      path = get_parent(path)
      if current == path then
        return false
      end
    end
  end

  local function child(dir, identifier)
    local path = get_parent(dir)
    return is(path, identifier)
  end

  local function has(dir, identifier)
    if last_dir_cache ~= dir then
      get_files(dir)
    end
    local pattern = glob.globtopattern(identifier)
    for _, file in ipairs(curr_dir_cache) do
      if file:match(pattern) ~= nil then
        return true
      end
    end
    return false
  end

  local function match(dir, pattern)
    local first_char = pattern:sub(1, 1)
    if first_char == "=" then
      return is(dir, pattern:sub(2))
    elseif first_char == "^" then
      return sub(dir, pattern:sub(2))
    elseif first_char == ">" then
      return child(dir, pattern:sub(2))
    else
      return has(dir, pattern)
    end
  end

  -- breadth-first search
  while true do
    for _, pattern in ipairs(config.patterns) do
      local exclude = false
      if pattern:sub(1, 1) == "!" then
        exclude = true
        pattern = pattern:sub(2)
      end
      if match(search_dir, pattern) then
        if exclude then
          break
        else
          return search_dir, "pattern " .. pattern
        end
      end
    end

    local parent = get_parent(search_dir)
    if parent == search_dir or parent == nil then
      return nil
    end

    search_dir = parent
  end
end

-- get_file_path Get the path of the current file
-- @return string
M.get_file_path = function()
  return vim.fn.expand "%:p"
end

-- get_project_root Get the root directory of the project
-- @return string
-- @usage local root_dir = utils.get_project_root()
M.get_project_root = function()
  -- returns project root, as well as method
  for _, detection_method in ipairs(config.detection_methods) do
    if detection_method == "lsp" then
      local root, lsp_name = find_lsp_root()
      if root ~= nil then
        return root, '"' .. lsp_name .. '"' .. " lsp"
      end
    elseif detection_method == "pattern" then
      local root, method = find_pattern_root()
      if root ~= nil then
        return root, method
      end
    end
  end
end

-- find_exec_file Finds the executable file in the project root path
-- @param exec_file_name: string
-- @return string
-- @usage local exec_file_path = utils.find_exec_file(exec_file_name)
M.find_exec_file = function(exec_file_name)
  local root_dir = M.get_project_root()
  local exec_file_path = root_dir .. "/" .. exec_file_name

  if M.is_executable(exec_file_path) then
    return exec_file_path
  end

  if vim.fn.executable(exec_file_name) == 1 then
    return exec_file_path
  end
end

-- get_relative_path_to Get the relative path of a file from path
-- @param file_path: string
-- @param path: string
-- @return string
-- @usage local relative_path = utils.get_relative_path_to(file_path, path)
-- @example
--  get_relative_path_to('/home/user/bin/my-script.sh', '/home')
--  Returns user/bin
M.get_relative_path_to = function(file_path, path)
  vim.cmd("lcd " .. path)
  local rl = vim.fn.fnamemodify(file_path, ":.:h")
  vim.cmd "lcd -"
  return rl
end

-- is_executable Checks if a file is executable by the current user
-- @param path: file path string
-- @return boolean
-- @usage local is_executable = utils.is_executable(path)
M.is_executable = function(path)
  return path and os.execute("test -x " .. path) == 0
end

-- is_symlink Checks if a file is a symbolic link
-- @param path: file path string
-- @return boolean
-- @usage local is_symlink = utils.is_symlink(path)
M.is_symlink = function(path)
  return path and vim.fn.getftype(path) == "link"
end

-- is_valid checks if the given path is a valid file
-- @param path: string
-- @return boolean
-- @usage local is_valid = utils.is_valid(path)
M.is_valid = function(path)
  return path
    and not M.is_executable(path)
    and not M.is_symlink(path)
    and vim.fn.filereadable(path) == 1
end

-- absolute return the absolute path of a file
-- @param path: string
-- @return string
M.absolute = function(path)
  return vim.fn.fnamemodify(path, ":p")
end

return M
