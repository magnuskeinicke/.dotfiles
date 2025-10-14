---@diagnostic disable: param-type-mismatch
local M = { -- LSP Configuration & Plugins
  'neovim/nvim-lspconfig',
  dependencies = {
    -- Automatically install LSPs and related tools to stdpath for Neovim
    { 'mason-org/mason.nvim', config = true }, -- NOTE: Must be loaded before dependants
    'mason-org/mason-lspconfig.nvim',
    'WhoIsSethDaniel/mason-tool-installer.nvim',

    -- `lazydev` configures Lua LSP for your Neovim config, runtime and plugins
    -- used for completion, annotations and signatures of Neovim apis
    {
      'folke/lazydev.nvim',
      ft = 'lua',
      opts = {
        library = {
          -- Load luvit types when the `vim.uv` word is found
          { path = 'luvit-meta/library', words = { 'vim%.uv' } },
        },
      },
    },
    { 'Bilal2453/luvit-meta', lazy = true },
  },
  config = function()
    -- Configure keybinds for the LSP attached to the buffer
    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup(
        'kickstart-lsp-attach',
        { clear = true }
      ),
      callback = function(event)
        -- In this case, we create a function that lets us more easily define mappings specific
        -- for LSP related items. It sets the mode, buffer and description for us each time.
        local map = function(keys, func, desc)
          vim.keymap.set(
            'n',
            keys,
            func,
            { buffer = event.buf, desc = 'LSP: ' .. desc }
          )
        end
        local fzf = require 'fzf-lua'

        --  To jump back, press <C-t>.
        map('gd', fzf.lsp_definitions, '[G]oto [D]efinition')

        -- Find references for the word under your cursor.
        map('gr', fzf.lsp_references, '[G]oto [R]eferences')

        -- Jump to the implementation of the word under your cursor.
        map('gI', fzf.lsp_implementations, '[G]oto [I]mplementation')

        -- Jump to the type of the word under your cursor.
        map('gtd', fzf.lsp_typedefs, 'Type [D]efinition')

        map('<leader>ss', fzf.lsp_document_symbols, 'Search Symbols')

        --  Similar to document symbols, except searches over your entire project.
        map(
          '<leader>ws',
          fzf.lsp_live_workspace_symbols,
          '[W]orkspace [S]ymbols'
        )

        -- Rename the variable under your cursor.
        --  Most Language Servers support renaming across files, etc.
        map('<F2>', vim.lsp.buf.rename, 'Rename')

        -- Execute a code action, usually your cursor needs to be on top of an error
        -- or a suggestion from your LSP for this to activate.
        map('<leader>ca', fzf.lsp_code_actions, '[C]ode [A]ction')

        map('gD', fzf.lsp_declarations, '[G]oto [D]eclaration')

        map('[d', function()
          vim.diagnostic.jump { count = -1, float = { border = 'rounded' } }
        end, 'Jump to Previous Diagnostic')

        map(']d', function()
          vim.diagnostic.jump { count = 1, float = { border = 'rounded' } }
        end, 'Jump to Previous Diagnostic')

        map('K', function()
          vim.lsp.buf.hover { border = 'rounded' }
        end, 'Hover')

        -- The following two autocommands are used to highlight references of the
        -- word under your cursor when your cursor rests there for a little while.
        -- When you move your cursor, the highlights will be cleared (the second autocommand).
        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if
          client
          and client:supports_method(
            vim.lsp.protocol.Methods.textDocument_documentHighlight,
            nil
          )
        then
          local highlight_augroup = vim.api.nvim_create_augroup(
            'kickstart-lsp-highlight',
            { clear = false }
          )
          vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.document_highlight,
          })

          vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.clear_references,
          })

          vim.api.nvim_create_autocmd('CursorHold', {
            buffer = event.buf,
            group = highlight_augroup,
            callback = function()
              for _, winid in pairs(vim.api.nvim_tabpage_list_wins(0)) do
                if vim.api.nvim_win_get_config(winid).zindex then
                  return
                end
              end
              local opts = {
                focusable = false,
                close_events = {
                  'BufLeave',
                  'CursorMoved',
                  'InsertEnter',
                  'FocusLost',
                },
                border = 'rounded',
                source = 'always',
                prefix = '',
                scope = 'cursor',
              }
              vim.diagnostic.open_float(nil, opts)
            end,
          })

          vim.api.nvim_create_autocmd('LspDetach', {
            group = vim.api.nvim_create_augroup(
              'kickstart-lsp-detach',
              { clear = true }
            ),
            callback = function(event2)
              vim.lsp.buf.clear_references()
              vim.api.nvim_clear_autocmds {
                group = 'kickstart-lsp-highlight',
                buffer = event2.buf,
              }
            end,
          })
        end

        -- This may be unwanted, since they displace some of your code
        if
          client
          and client:supports_method(
            vim.lsp.protocol.Methods.textDocument_inlayHint,
            vim.api.nvim_get_current_buf()
          )
        then
          map('<leader>th', function()
            vim.lsp.inlay_hint.enable(
              not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf }
            )
          end, '[T]oggle Inlay [H]ints')
        end

        -- Show signature help
        if
          client
          and client:supports_method(
            vim.lsp.protocol.Methods.textDocument_signatureHelp,
            vim.api.nvim_get_current_buf()
          )
        then
          vim.keymap.set('i', '<C-k>', function()
            vim.lsp.buf.signature_help { border = 'rounded' }
          end, {
            buffer = event.buf,
            desc = 'LSP: Show Signature Help',
          })
        end
        if client and client.name == 'clangd' then
          map(
            '<leader>ch',
            '<cmd>ClangdSwitchSourceHeader<cr>',
            'Switch Source/Header'
          )
        end
      end,
    })

    -- LSP servers and clients are able to communicate to each other what features they support.
    --  By default, Neovim doesn't support everything that is in the LSP specification.
    --  When you add nvim-cmp, luasnip, etc. Neovim now has *more* capabilities.
    --  So, we create new capabilities with nvim cmp, and then broadcast that to the servers.
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    capabilities = vim.tbl_deep_extend(
      'force',
      capabilities,
      require('cmp_nvim_lsp').default_capabilities()
    )

    -- Enable the following language servers
    local servers = {
      vtsls = {}, -- TS and JS LSP, faster than tsserver
      cssls = {}, -- CSS LSP
      tailwindcss = {}, -- Tailwind CSS LSP
      html = {}, -- HTML LSP
      jsonls = {}, -- JSON LSP
      lua_ls = {
        Lua = {
          diagnostics = {
            globals = { 'vim' },
          },
        },
      }, -- Lua LSP
      marksman = {}, -- Markdown LSP
      pyright = {}, -- Python LSP
      clangd = {
        root_dir = function(fname)
          return require('lspconfig.util').root_pattern(
            'Makefile',
            'configure.ac',
            'configure.in',
            'config.h.in',
            'meson.build',
            'meson_options.txt',
            'build.ninja'
          )(fname) or require('lspconfig.util').root_pattern(
            'compile_commands.json',
            'compile_flags.txt'
          )(fname) or vim.fs.dirname(
            vim.fs.find('.git', { path = fname, upward = true })[1]
          )
        end,
        capabilities = {
          offsetEncoding = { 'utf-16' },
        },
        cmd = {
          'clangd',
          '--background-index',
          '--clang-tidy',
          '--header-insertion=iwyu',
          '--completion-style=detailed',
          '--function-arg-placeholders',
          '--fallback-style=llvm',
        },
        init_options = {
          usePlaceholders = true,
          completeUnimported = true,
          clangdFileStatus = true,
        },
      },
      cmake = {},
      asm_lsp = {},
      textlsp = {},
      roslyn = {},
    }

    -- Ensure the servers and tools above are installed
    require('mason').setup()

    -- You can add other tools here that you want Mason to install
    -- for you, so that they are available from within Neovim.
    local ensure_installed = vim.tbl_keys(servers or {})
    vim.list_extend(ensure_installed, {
      'stylua', -- Lua Formatter
      'markdownlint', -- Markdown Linter
      'prettierd', -- Formatter { Markdown, }
      'eslint_d', -- Linting JS/TS
      'htmlhint', -- HTML Linter
      'stylelint', -- CSS Linter
      'isort', -- Python Formatter
      'black', -- Python Formatter
      'ruff', -- Python Linter
      'clang-format', -- C/C++ Formatter
      'cpplint', -- C/C++ Linter
      'cmakelint', -- CMake Linter
      'cmakelang', -- Needed for cmake-format apparently
      'cpptools', -- debugger, apparently cannot be installed from dap ensure installed
      'roslyn', -- C# LSP, we don't want to have a server setup, as we use a plugin for it
    })
    require('mason-tool-installer').setup { ensure_installed = ensure_installed }

    require('mason-lspconfig').setup {
      handlers = {
        function(server_name)
          local server = servers[server_name] or {}
          -- This handles overriding only values explicitly passed
          -- by the server configuration above. Useful when disabling
          -- certain features of an LSP (for example, turning off formatting for tsserver)
          server.capabilities = vim.tbl_deep_extend(
            'force',
            {},
            capabilities,
            server.capabilities or {}
          )
          require('lspconfig')[server_name].setup(server)
        end,
      },
      ensure_installed = {},
      automatic_installation = false,
      automatic_enable = true,
    }

    -- Setup cool lsp signs
    local signs = {
      Error = '',
      Warn = '',
      Hint = '',
      Information = '',
    }

    vim.diagnostic.config {
      signs = {
        text = {
          [vim.diagnostic.severity.ERROR] = signs.Error,
          [vim.diagnostic.severity.WARN] = signs.Warn,
          [vim.diagnostic.severity.INFO] = signs.Information,
          [vim.diagnostic.severity.HINT] = signs.Hint,
        },
      },
    }
  end,
}
return M
