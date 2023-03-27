local M = {}

M.config = {
	-- sync_exe_filename default name of the sync executable
	sync_exe_filename = ".sync",
	-- sync_type ftp support only
	sync_type = "ftp",
	-- sync_exe_path path to the sync executable
	-- if not set, it will be searched in the project root path by default
	-- if not found, it will be searched in the system path
	-- if not found, it will return an error
	sync_exe_path = nil,
	-- Methods of detecting the root directory.
	-- if one is not detected, the other is used as fallback. You can also delete or rearangne the detection methods.
	detection_methods = { "pattern", "lsp" },
	-- All the patterns used to detect root dir, when **"pattern"** is in
	-- detection_methods
	patterns = { ".git", "_darcs", ".hg", ".bzr", ".svn", "package.json" },
	-- Table of lsp clients to ignore by name
	-- eg: { "efm", ... }
	ignore_lsp = {},
}

M.init = function(params)
	M.config = vim.tbl_deep_extend("force", M.config, params or {})
end

return M
