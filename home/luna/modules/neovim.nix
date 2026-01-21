{ ... }

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;

    plugins = with pkgs.vimPlugins; [
      nvim-treesitter
      telescope-nvim
    ];

    extraLuaConfig = ''
      vim.o.number = true
      vim.o.relativenumber = true
      vim.cmd = {
          highlight Normal guibg = none
          highlight NonText guibg = none
          highlight Normal ctermbg = none
          highlight NonText ctermbg = none
      }
    '';
  };
}
