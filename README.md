# Skibideo LSP

Use it with [1f tree-sitter](https://github.com/kukiutihin/1f-treesitter)

## Installation and Configuration in Neovim

Add the following configuration to your `lsp-config` setup:

```lua
return {
    "neovim/nvim-lspconfig",
    dependencies = { "williamboman/mason-lspconfig.nvim" },
    config = function()
        -- Global diagnostics display settings
        vim.diagnostic.config({
            virtual_text = false,
            signs = true,
            underline = true,
            update_in_insert = true,
            severity_sort = true,
        })

        -- HERE
        -- Custom LSP server configuration for Skibideo
        -- Make sure to replace the paths with the correct ones for your system!
        vim.lsp.config['skibideo'] = {
            cmd = { 
                '<path_to_skibideo>/_build/default/bin/main.exe', 
            },
            filetypes = { '1f' },
            root_markers = { '.git' },
            settings = {}
        }
    end
}
```

## Command-Line Flags for the LSP Server

* `--debug`: Enables debug mode. The server logs (both incoming and outgoing JSON-RPC frames) will be recorded into a file for easier integration debugging with the editor.
* `--log <path>`: Specifies the file path for writing logs (defaults to `/tmp/skibideo_log.txt`).
