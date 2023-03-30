# nvim-sync.nvim

Automatic sync/async SFTP,FTP,... for buffers in Neovim.

## Install

For lazy.lua

```lua
{
    "SDGLBL/nvim-sync.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    config = function()
      require("nvim-sync").setup {
        -- sync_exe_filename default name of the sync executable
        sync_exe_filename = ".sync",
        -- enable_paths
        enable_paths = {},
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
    end,
}

```

## Setup

Copy cmd `sync_ftp.sh` to project root and rename it as `.sync` then edit it.

```bash
#!/bin/sh
if [ "upload" = "$1" ]; then
  ncftpput -t 1 -m -u login_name -p login_password -P 21 remote_host remote_path/"$2" "$(dirname "$0")"/"$2"/"$3"
elif [ 'download' = "$1" ]; then
  ncftpget -t 1 -u login_name -p login_password -P 21 remote_host "$(dirname "$0")"/"$2" remote_path/"$2"/"$3"
fi
```

## Manual Upload / Download

Use command (recommend use keymap)

- `SyncUpload` upload current buffer to remote
- `SyncDownload` download current buffer from remote

## Automatic Upload / Download

Add autocmds in neovim

```lua
vim.api.nvim_create_autocmd("BufWritePost", {
    group = "_sync_file",
    pattern = "*",
    desc = "sync file",
    command = "SyncUpload",
})

-- Not recommended may be result performance issue
vim.api.nvim_create_autocmd("BufReadPre", {
    group = "_sync_file",
    pattern = "*",
    desc = "sync file",
    command = "SyncDownload",
})
```
