vim.opt.number = true
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.smarttab = true
vim.opt.undofile = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.opt.nrformats = 'octal'
vim.opt.diffopt:append('iwhite')
vim.opt.diffopt:append('algorithm:histogram')
vim.opt.diffopt:append('indent-heuristic')
vim.opt.listchars = 'tab:> ,trail:-,extends:>,precedes:<,nbsp:+'
vim.opt.path:append("**")
vim.opt.wildmenu = true
vim.opt.wildmode = { "longest", "full" }
vim.opt.wildignore:append({
  ".hg",".svn","*~","*.png","*.jpg","*.gif",
  "*.min.js","*.swp","*.o","vendor","dist","_site",
})

vim.diagnostic.config({
  virtual_text = { spacing = 2 },
  severity_sort    = true,
  float = {
    border = "rounded",
    source = "always",
  },
})

--- lazy.nvim ---
-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Setup lazy.nvim
require("lazy").setup({
    spec = {
        {
            "Julian/lean.nvim",
            ft="lean",
            dependencies={
                "nvim-lua/plenary.nvim",
            },
            opts={
                mappings=true,
            },
        },
        {
            "MeanderingProgrammer/render-markdown.nvim",
            ft="markdown",
            dependencies={
                "nvim-treesitter/nvim-treesitter",
            },
            opts={
                enabled=false,
                render_modes={"n","c"},
            },
            keys={
                "<leader>mp",
                "<cmd>RenderMarkdowm toggle<cr>",
                ft="markdown",
                desc="Toggle Markdown preview",
            },
        },
    },
})
