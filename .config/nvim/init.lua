local opt = vim.opt
opt.number = true
opt.expandtab = true
opt.tabstop = 4
opt.shiftwidth = 4
opt.softtabstop = 4 
opt.smartindent = true
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = false
opt.swapfile = false
opt.undofile = true
opt.splitright = true
opt.splitbelow = true
opt.completeopt = { "menu", "menuone", "noselect" }

opt.path:append("**")
opt.wildmode = { "longest", "full" }
opt.wildignore:append({
  "*/node_modules/*",
  "*/.git/*",
  "*/dist/*",
  "*/build/*",
  "*.o",
  "*.pyc",
  "__pycache__",
})

vim.diagnostic.config({
  virtual_text = { spacing = 2 },
  severity_sort    = true,
  float = {
    border = "rounded",
    source = "always",
  },
})
