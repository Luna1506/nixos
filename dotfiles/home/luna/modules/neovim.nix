{ pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    plugins = with pkgs.vimPlugins; [
      nvim-treesitter
      telescope-nvim
      nvim-cmp
      cmp-path
      cmp-buffer
      nvim-lspconfig
    ];

    extraPackages = with pkgs; [
      lua-language-server
      nil
      nixpkgs-fmt
      pyright
      nodePackages.prettier
      stylua
    ];

    initLua = ''
            vim.o.number = true
            vim.o.relativenumber = true
            vim.cmd [[
                highlight Normal guibg = none
                highlight NonText guibg = none
                highlight Normal ctermbg = none
                highlight NonText ctermbg = none
            ]]
            vim.api.nvim_set_hl(0, "LineNr", { fg = "#ffffff" })
            vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "#ffffff", bold = true })

            vim.opt.clipboard = "unnamedplus"

            local cmp = require("cmp")

            cmp.setup({
              completion = { autocomplete = { cmp.TriggerEvent.TextChanged } },
              sources = cmp.config.sources({
                { name = "path" },    -- <— Dateipfade
                { name = "buffer" },  -- Wörter aus aktuellem Buffer
              }),
              mapping = cmp.mapping.preset.insert({
                ["<C-Space>"] = cmp.mapping.complete(),   -- manuell öffnen
                ["<CR>"] = cmp.mapping.confirm({ select = true }),
                ["<Tab>"] = cmp.mapping.select_next_item(),
                ["<S-Tab>"] = cmp.mapping.select_prev_item(),
              }),
            })

            local lspconfig = require("lspconfig")

            -- Lua
            lspconfig.lua_ls.setup({
              settings = {
                Lua = {
                  format = { enable = true },
                },
              },
            })

            -- Nix
            lspconfig.nil_ls.setup({
              settings = {
                ["nil"] = {
                  formatting = {
                    command = { "nixpkgs-fmt" },
                  },
                },
              },
            })

            vim.api.nvim_create_autocmd("BufWritePre", {
              callback = function()
              pcall(function()
            vim.lsp.buf.format({ async = false, timeout_ms = 2000 })
          end)
        end,
      })
    '';
  };
}
