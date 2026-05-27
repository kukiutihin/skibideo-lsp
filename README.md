# Skibideo LSP

## Requirements for the `1f` Compiler

1. **Input via `stdin`:** The compiler must accept the source code for analysis from the standard input stream.
2. **Output errors in JSON:** Upon finding syntax or type errors, the compiler must output an array of JSON objects of a specific format to the standard output stream.

**Example of expected compiler output:**
[
    {
        "message": "undefined variable 'skibidi'",
        "range": {
            "start": { "line": 2, "character": 4 },
            "end": { "line": 2, "character": 11 }
        },
        "severity": 1 
    }
]

*Note: `severity: 1` represents an Error, `2` — Warning, `3` — Information, and `4` — Hint.*

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
                '--debug', 
                '--compiler', 
                '<path_to_compiler_executable>' 
            },
            filetypes = { '1f' },
            root_markers = { '.git' },
            settings = {}
        }
    end
}
```

## Command-Line Flags for the LSP Server

* `--compiler <path>`: Required flag. Specifies the absolute path to the `1f` compiler executable.
* `--debug`: Enables debug mode. The server logs (both incoming and outgoing JSON-RPC frames) will be recorded into a file for easier integration debugging with the editor.
* `--log <path>`: Specifies the file path for writing logs (defaults to `/tmp/skibideo_log.txt`).
