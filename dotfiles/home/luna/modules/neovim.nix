{ pkgs, ... }:

{
  programs.neovim = {
    enable        = true;
    defaultEditor = true;
    viAlias       = true;
    vimAlias      = true;

    plugins = with pkgs.vimPlugins; [
      # ── Colorscheme ──────────────────────────────────────────────────────────
      tokyonight-nvim

      # ── Icons ─────────────────────────────────────────────────────────────────
      nvim-web-devicons

      # ── File explorer ─────────────────────────────────────────────────────────
      nvim-tree-lua

      # ── Statusline + bufferline ───────────────────────────────────────────────
      lualine-nvim
      bufferline-nvim

      # ── Treesitter ────────────────────────────────────────────────────────────
      nvim-treesitter.withAllGrammars
      nvim-treesitter-textobjects
      nvim-treesitter-context

      # ── LSP ───────────────────────────────────────────────────────────────────
      nvim-lspconfig
      fidget-nvim          # LSP progress indicator
      neodev-nvim          # Neovim Lua dev

      # ── Completion ────────────────────────────────────────────────────────────
      nvim-cmp
      cmp-nvim-lsp
      cmp-buffer
      cmp-path
      cmp-cmdline
      cmp_luasnip

      # ── Snippets ──────────────────────────────────────────────────────────────
      luasnip
      friendly-snippets

      # ── Formatting / linting ──────────────────────────────────────────────────
      conform-nvim
      none-ls-nvim

      # ── Telescope ─────────────────────────────────────────────────────────────
      telescope-nvim
      telescope-fzf-native-nvim
      telescope-ui-select-nvim
      plenary-nvim

      # ── Git ───────────────────────────────────────────────────────────────────
      gitsigns-nvim
      lazygit-nvim

      # ── UI / UX ───────────────────────────────────────────────────────────────
      which-key-nvim
      indent-blankline-nvim
      nvim-autopairs
      todo-comments-nvim
      trouble-nvim
      nvim-notify
      dressing-nvim           # Better vim.ui.input / vim.ui.select
      noice-nvim              # Command line + notifications overhaul
      nui-nvim                # noice dependency

      # ── DAP (debugging) ───────────────────────────────────────────────────────
      nvim-dap
      nvim-dap-ui
      nvim-dap-python
      nvim-dap-virtual-text
    ];

    extraPackages = with pkgs; [
      # LSP servers
      lua-language-server
      nil                          # Nix
      nixpkgs-fmt
      pyright                      # Python
      nodePackages.typescript-language-server
      nodePackages.vscode-langservers-extracted  # HTML, CSS, JSON, ESLint
      jdt-language-server          # Java
      rust-analyzer
      dart                         # Dart / Flutter
      taplo                        # TOML

      # Formatters
      stylua
      nodePackages.prettier
      black
      isort
      rustfmt
      google-java-format

      # Linters / tools
      ripgrep
      fd
      fzf
      lazygit
      gcc                          # treesitter needs a C compiler
    ];

    initLua = ''
      -- ── Options ──────────────────────────────────────────────────────────────
      vim.o.number         = true
      vim.o.relativenumber = true
      vim.o.cursorline     = true
      vim.o.signcolumn     = "yes"
      vim.o.wrap           = false
      vim.o.scrolloff      = 8
      vim.o.sidescrolloff  = 8
      vim.o.tabstop        = 2
      vim.o.shiftwidth     = 2
      vim.o.expandtab      = true
      vim.o.smartindent    = true
      vim.o.ignorecase     = true
      vim.o.smartcase      = true
      vim.o.updatetime     = 250
      vim.o.timeoutlen     = 300
      vim.o.splitright     = true
      vim.o.splitbelow     = true
      vim.o.termguicolors  = true
      vim.o.clipboard      = "unnamedplus"
      vim.o.undofile       = true
      vim.o.completeopt    = "menu,menuone,noselect"
      vim.g.mapleader      = " "
      vim.g.maplocalleader = " "

      -- ── Colorscheme ──────────────────────────────────────────────────────────
      require("tokyonight").setup({
        style       = "night",
        transparent = true,
        styles      = {
          sidebars    = "transparent",
          floats      = "transparent",
        },
      })
      vim.cmd("colorscheme tokyonight-night")
      vim.api.nvim_set_hl(0, "LineNr",       { fg = "#ffffff" })
      vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "#ffffff", bold = true })

      -- ── Treesitter ────────────────────────────────────────────────────────────
      -- New API: highlight/indent are vim filetype plugins, not setup options.
      -- Enable highlight via treesitter's built-in mechanism:
      vim.api.nvim_create_autocmd("FileType", {
        callback = function(ev)
          local ok, parsers = pcall(require, "nvim-treesitter.parsers")
          if ok and parsers.has_parser() then
            vim.treesitter.start(ev.buf)
          end
        end,
      })

      -- Textobjects (separate plugin, keeps its own setup via nvim-treesitter.configs shim)
      local ok_ts, ts_configs = pcall(require, "nvim-treesitter.configs")
      if not ok_ts then
        -- Fallback: textobjects setup via the textobjects plugin directly if available
        ts_configs = nil
      end
      if ts_configs then
        ts_configs.setup({
          textobjects = {
            select = {
              enable    = true,
              lookahead = true,
              keymaps   = {
                ["af"] = "@function.outer",
                ["if"] = "@function.inner",
                ["ac"] = "@class.outer",
                ["ic"] = "@class.inner",
              },
            },
            move = {
              enable              = true,
              set_jumps           = true,
              goto_next_start     = { ["]f"] = "@function.outer", ["]c"] = "@class.outer" },
              goto_previous_start = { ["[f"] = "@function.outer", ["[c"] = "@class.outer" },
            },
          },
        })
      end
      require("treesitter-context").setup({ max_lines = 4 })

      -- ── Autopairs ────────────────────────────────────────────────────────────
      require("nvim-autopairs").setup({})

      -- ── Indent guides ────────────────────────────────────────────────────────
      require("ibl").setup({
        indent = { char = "│" },
        scope  = { enabled = true },
      })

      -- ── Fidget (LSP progress) ────────────────────────────────────────────────
      require("fidget").setup({})

      -- ── neodev (nvim Lua completions) ─────────────────────────────────────────
      require("neodev").setup({})

      -- ── LSP ───────────────────────────────────────────────────────────────────
      local lspconfig  = require("lspconfig")
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      local on_attach = function(_, bufnr)
        local map = function(keys, func, desc)
          vim.keymap.set("n", keys, func, { buffer = bufnr, desc = "LSP: " .. desc })
        end
        map("gd",         vim.lsp.buf.definition,      "Go to Definition")
        map("gD",         vim.lsp.buf.declaration,     "Go to Declaration")
        map("gr",         require("telescope.builtin").lsp_references, "References")
        map("gI",         vim.lsp.buf.implementation,  "Go to Implementation")
        map("K",          vim.lsp.buf.hover,           "Hover Docs")
        map("<leader>rn", vim.lsp.buf.rename,          "Rename")
        map("<leader>ca", vim.lsp.buf.code_action,     "Code Action")
        map("<leader>ds", require("telescope.builtin").lsp_document_symbols, "Document Symbols")
        map("<leader>ws", require("telescope.builtin").lsp_workspace_symbols, "Workspace Symbols")
        map("[d",         vim.diagnostic.goto_prev,    "Prev Diagnostic")
        map("]d",         vim.diagnostic.goto_next,    "Next Diagnostic")
        map("<leader>e",  vim.diagnostic.open_float,   "Show Diagnostic")
      end

      -- Diagnostic signs
      local signs = { Error = " ", Warn = " ", Hint = "󰌵 ", Info = " " }
      for type, icon in pairs(signs) do
        local hl = "DiagnosticSign" .. type
        vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
      end
      vim.diagnostic.config({
        virtual_text  = { prefix = "●" },
        severity_sort = true,
        float         = { border = "rounded" },
      })

      -- Servers
      local servers = {
        lua_ls        = { settings = { Lua = { workspace = { checkThirdParty = false }, telemetry = { enable = false } } } },
        nil_ls        = { settings = { ["nil"] = { formatting = { command = { "nixpkgs-fmt" } } } } },
        pyright       = {},
        ts_ls         = {},
        html          = {},
        cssls         = {},
        jsonls        = {},
        rust_analyzer = {},
        dartls        = {},
        taplo         = {},
        jdtls         = {},
      }
      for server, config in pairs(servers) do
        config.capabilities = capabilities
        config.on_attach    = on_attach
        lspconfig[server].setup(config)
      end

      -- ── Snippets ─────────────────────────────────────────────────────────────
      require("luasnip.loaders.from_vscode").lazy_load()
      local luasnip = require("luasnip")

      -- ── Completion ───────────────────────────────────────────────────────────
      local cmp = require("cmp")
      cmp.setup({
        snippet = {
          expand = function(args) luasnip.lsp_expand(args.body) end,
        },
        window = {
          completion    = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-n>"]     = cmp.mapping.select_next_item(),
          ["<C-p>"]     = cmp.mapping.select_prev_item(),
          ["<C-b>"]     = cmp.mapping.scroll_docs(-4),
          ["<C-f>"]     = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"]     = cmp.mapping.abort(),
          ["<CR>"]      = cmp.mapping.confirm({ select = true }),
          ["<Tab>"]     = cmp.mapping(function(fallback)
            if cmp.visible() then cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then luasnip.expand_or_jump()
            else fallback() end
          end, { "i", "s" }),
          ["<S-Tab>"]   = cmp.mapping(function(fallback)
            if cmp.visible() then cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then luasnip.jump(-1)
            else fallback() end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "buffer" },
          { name = "path" },
        }),
        formatting = {
          format = function(entry, item)
            local source_names = {
              nvim_lsp = "[LSP]",
              luasnip  = "[Snip]",
              buffer   = "[Buf]",
              path     = "[Path]",
            }
            item.menu = source_names[entry.source.name] or ""
            return item
          end,
        },
      })
      -- Cmdline completion
      cmp.setup.cmdline({ "/", "?" }, {
        mapping = cmp.mapping.preset.cmdline(),
        sources = { { name = "buffer" } },
      })
      cmp.setup.cmdline(":", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({ { name = "path" } }, { { name = "cmdline" } }),
      })
      -- Autopairs integration
      local cmp_autopairs = require("nvim-autopairs.completion.cmp")
      cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())

      -- ── Formatting ────────────────────────────────────────────────────────────
      require("conform").setup({
        formatters_by_ft = {
          lua        = { "stylua" },
          nix        = { "nixpkgs_fmt" },
          python     = { "isort", "black" },
          javascript = { "prettier" },
          typescript = { "prettier" },
          html       = { "prettier" },
          css        = { "prettier" },
          json       = { "prettier" },
          rust       = { "rustfmt" },
          java       = { "google-java-format" },
          dart       = { "dart_format" },
        },
        format_on_save = {
          timeout_ms = 2000,
          lsp_fallback = true,
        },
      })

      -- ── Telescope ─────────────────────────────────────────────────────────────
      local telescope = require("telescope")
      telescope.setup({
        defaults = {
          mappings = {
            i = {
              ["<C-u>"] = false,
              ["<C-d>"] = false,
            },
          },
        },
        extensions = {
          ["ui-select"] = { require("telescope.themes").get_dropdown() },
        },
      })
      telescope.load_extension("fzf")
      telescope.load_extension("ui-select")
      local builtin = require("telescope.builtin")
      vim.keymap.set("n", "<leader>ff", builtin.find_files,   { desc = "Find Files" })
      vim.keymap.set("n", "<leader>fg", builtin.live_grep,    { desc = "Live Grep" })
      vim.keymap.set("n", "<leader>fb", builtin.buffers,      { desc = "Buffers" })
      vim.keymap.set("n", "<leader>fh", builtin.help_tags,    { desc = "Help Tags" })
      vim.keymap.set("n", "<leader>fr", builtin.oldfiles,     { desc = "Recent Files" })
      vim.keymap.set("n", "<leader>fd", builtin.diagnostics,  { desc = "Diagnostics" })
      vim.keymap.set("n", "<leader>/",  function()
        builtin.current_buffer_fuzzy_find(require("telescope.themes").get_dropdown())
      end, { desc = "Fuzzy search buffer" })

      -- ── File explorer (nvim-tree) ─────────────────────────────────────────────
      require("nvim-tree").setup({
        view            = { width = 32 },
        renderer        = {
          group_empty   = true,
          icons         = { show = { git = true, folder = true, file = true } },
        },
        filters         = { dotfiles = false },
        git             = { enable = true },
      })
      vim.keymap.set("n", "<leader>tt", "<cmd>NvimTreeToggle<CR>",  { desc = "Toggle file tree" })
      vim.keymap.set("n", "<leader>tf", "<cmd>NvimTreeFocus<CR>",   { desc = "Focus file tree" })

      -- ── Statusline ────────────────────────────────────────────────────────────
      require("lualine").setup({
        options = {
          theme            = "tokyonight",
          globalstatus     = true,
          component_separators = { left = "", right = "" },
          section_separators  = { left = "", right = "" },
        },
        sections = {
          lualine_a = { "mode" },
          lualine_b = { "branch", "diff", "diagnostics" },
          lualine_c = { { "filename", path = 1 } },
          lualine_x = { "encoding", "fileformat", "filetype" },
          lualine_y = { "progress" },
          lualine_z = { "location" },
        },
      })

      -- ── Bufferline ────────────────────────────────────────────────────────────
      require("bufferline").setup({
        options = {
          diagnostics          = "nvim_lsp",
          show_buffer_close_icons = true,
          show_close_icon         = false,
          separator_style         = "slant",
        },
      })
      vim.keymap.set("n", "<S-l>", "<cmd>BufferLineCycleNext<CR>", { desc = "Next buffer" })
      vim.keymap.set("n", "<S-h>", "<cmd>BufferLineCyclePrev<CR>", { desc = "Prev buffer" })
      vim.keymap.set("n", "<leader>bd", "<cmd>bdelete<CR>",        { desc = "Close buffer" })

      -- ── Git signs ────────────────────────────────────────────────────────────
      require("gitsigns").setup({
        on_attach = function(bufnr)
          local gs = package.loaded.gitsigns
          local map = function(mode, l, r, opts)
            opts = opts or {}
            opts.buffer = bufnr
            vim.keymap.set(mode, l, r, opts)
          end
          map("n", "]h", gs.next_hunk,               { desc = "Next hunk" })
          map("n", "[h", gs.prev_hunk,               { desc = "Prev hunk" })
          map("n", "<leader>hs", gs.stage_hunk,      { desc = "Stage hunk" })
          map("n", "<leader>hr", gs.reset_hunk,      { desc = "Reset hunk" })
          map("n", "<leader>hp", gs.preview_hunk,    { desc = "Preview hunk" })
          map("n", "<leader>hb", gs.blame_line,      { desc = "Blame line" })
        end,
      })
      vim.keymap.set("n", "<leader>gg", "<cmd>LazyGit<CR>", { desc = "LazyGit" })

      -- ── Trouble v3 (diagnostics panel) ───────────────────────────────────────
      require("trouble").setup({})
      vim.keymap.set("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<CR>",           { desc = "Toggle Trouble" })
      vim.keymap.set("n", "<leader>xw", "<cmd>Trouble diagnostics toggle filter.buf=0<CR>", { desc = "Buffer Diagnostics" })
      vim.keymap.set("n", "<leader>xd", "<cmd>Trouble diagnostics<CR>",                  { desc = "Workspace Diagnostics" })
      vim.keymap.set("n", "<leader>xs", "<cmd>Trouble symbols toggle<CR>",               { desc = "Symbols" })

      -- ── Todo comments ─────────────────────────────────────────────────────────
      require("todo-comments").setup({})
      vim.keymap.set("n", "<leader>ft", "<cmd>TodoTelescope<CR>", { desc = "Find TODOs" })

      -- ── Which-key ─────────────────────────────────────────────────────────────
      require("which-key").setup({})

      -- ── Noice ────────────────────────────────────────────────────────────────
      require("noice").setup({
        lsp = {
          override = {
            ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
            ["vim.lsp.util.stylize_markdown"]                = true,
            ["cmp.entry.get_documentation"]                  = true,
          },
        },
        presets = {
          bottom_search         = true,
          command_palette       = true,
          long_message_to_split = true,
          inc_rename            = false,
          lsp_doc_border        = true,
        },
      })

      -- ── Notify ───────────────────────────────────────────────────────────────
      require("notify").setup({
        background_colour = "#000000",
        render            = "compact",
        timeout           = 3000,
      })

      -- ── Dressing ─────────────────────────────────────────────────────────────
      require("dressing").setup({})

      -- ── DAP (debugging) ───────────────────────────────────────────────────────
      local dap    = require("dap")
      local dapui  = require("dapui")
      require("nvim-dap-virtual-text").setup({})
      require("dap-python").setup("python")
      dapui.setup({})
      dap.listeners.after.event_initialized["dapui_config"]  = function() dapui.open() end
      dap.listeners.before.event_terminated["dapui_config"]  = function() dapui.close() end
      dap.listeners.before.event_exited["dapui_config"]      = function() dapui.close() end
      vim.keymap.set("n", "<F5>",        dap.continue,          { desc = "DAP Continue" })
      vim.keymap.set("n", "<F10>",       dap.step_over,         { desc = "DAP Step Over" })
      vim.keymap.set("n", "<F11>",       dap.step_into,         { desc = "DAP Step Into" })
      vim.keymap.set("n", "<F12>",       dap.step_out,          { desc = "DAP Step Out" })
      vim.keymap.set("n", "<leader>db",  dap.toggle_breakpoint, { desc = "Toggle Breakpoint" })
      vim.keymap.set("n", "<leader>du",  dapui.toggle,          { desc = "Toggle DAP UI" })

      -- ── General keymaps ───────────────────────────────────────────────────────
      -- Window navigation
      vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Window left" })
      vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Window down" })
      vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Window up" })
      vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Window right" })
      -- Move lines
      vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move line down" })
      vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move line up" })
      -- Keep cursor centered
      vim.keymap.set("n", "<C-d>", "<C-d>zz")
      vim.keymap.set("n", "<C-u>", "<C-u>zz")
      vim.keymap.set("n", "n",     "nzzzv")
      vim.keymap.set("n", "N",     "Nzzzv")
      -- Clear search highlight
      vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")
      -- Save
      vim.keymap.set({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<CR><esc>", { desc = "Save" })
      -- Split
      vim.keymap.set("n", "<leader>sv", "<C-w>v",  { desc = "Split vertical" })
      vim.keymap.set("n", "<leader>sh", "<C-w>s",  { desc = "Split horizontal" })
    '';
  };
}
