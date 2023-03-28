local M = {}

local utils = require("nvim-sync.utils")
local config = require("nvim-sync.config").config
local job = require("plenary.job")

local function check_file_path(file_path)
	if not utils.is_valid(file_path) then
		vim.notify("Invalid file path" .. file_path, vim.log.levels.TRACE)
		return false
	end

	return true
end

-- exec upload or download a file to a remote server using given sync executable
-- @param action: string (upload|download)
-- @param filepath: string
local function exec(action, file_path)
	if not check_file_path(file_path) then
		return
	end

	local project_root = utils.get_project_root()

	if not project_root then
		vim.notify("Project root not found", vim.log.levels.TRACE)
		return
	end

	local filename = vim.fn.fnamemodify(file_path, ":t")
	local file_relative_path = utils.get_relative_path_to(file_path, project_root)

	local sync_exe_path = ""

	if config.sync_exe_path == nil then
		sync_exe_path = require("nvim-sync.utils").find_exec_file(config.sync_exe_filename)
	end

	if not sync_exe_path then
		vim.notify("Nvim-sync: No executable sync file found", vim.log.levels.INFO)
		return
	end

	job:new({
		command = sync_exe_path,
		args = { action, file_relative_path, filename },
		on_start = function()
			print("Nvim-sync: " .. action .. "file " .. file_path .. " started")
		end,
		on_exit = function(_, exit_code)
			if exit_code ~= 0 then
				print("Nvim-sync: " .. action .. "file " .. file_path .. " failed")
			else
				print("Nvim-sync: " .. action .. "file " .. file_path .. " success")
			end
		end,
	}):start()
end

-- upload a file to a remote server
-- @param type: string
-- @param filepath: string
-- @return boolean
M.upload = function()
	local filepath = utils.get_file_path()
	exec("upload", filepath)
end

-- download a file from remote server
-- @param type: string
-- @param filepath: string
-- @return boolean
M.download = function()
	local filepath = utils.get_file_path()
	exec("download", filepath)
end

M.init = function()
	vim.api.nvim_create_user_command("SyncUpload", M.upload, {
		range = false,
		nargs = "*",
	})

	vim.api.nvim_create_user_command("SyncDownload", M.download, {
		range = false,
		nargs = "*",
	})
end

return M
