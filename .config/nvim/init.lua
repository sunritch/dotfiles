-- init.lua
-- Native Neovim, zero plugins

local opt = vim.opt
local map = vim.keymap.set


-- Options
-- =======

opt.number = true

opt.expandtab   = true
opt.tabstop     = 4
opt.shiftwidth  = 4
opt.softtabstop = 4     -- fix: backspace deletes a full indent unit, not one space
opt.smartindent = true

opt.ignorecase = true
opt.smartcase  = true
opt.hlsearch   = false
opt.incsearch  = true

opt.swapfile = false
opt.backup   = false
opt.undofile = true

opt.splitright = true
opt.splitbelow = true

opt.completeopt = { "menu", "menuone", "noselect" }
opt.pumheight   = 12    -- limit completion menu height
opt.signcolumn  = "yes"
opt.scrolloff   = 8

opt.updatetime = 300
opt.timeoutlen = 500

opt.path:append("**")
opt.wildmenu = true
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


-- Leader
-- ======

vim.g.mapleader      = " "
vim.g.maplocalleader = " "


-- General
-- =======

map("n", "<Esc>", "<cmd>nohlsearch<CR>", {
  desc = "Clear search highlight",
})



-- Diagnostics
-- ===========

vim.diagnostic.config({
  virtual_text = { spacing = 2 },
  signs        = true,
  underline    = true,
  update_in_insert = false,
  severity_sort    = true,
  float = {
    border = "rounded",
    source = "always",
  },
})

map("n", "[d", vim.diagnostic.goto_prev, {
  desc = "Previous diagnostic",
})

map("n", "]d", vim.diagnostic.goto_next, {
  desc = "Next diagnostic",
})

map("n", "<leader>d", vim.diagnostic.open_float, {
  desc = "Show diagnostic",
})

map("n", "<leader>D", vim.diagnostic.setloclist, {
  desc = "Diagnostic list",
})


-- LSP
-- ===

local function start_lsp(buf, name, cmd, markers, settings)
  if vim.fn.executable(cmd[1]) == 0 then
    return
  end

  local root = vim.fs.root(buf, markers)
  if not root then
    return
  end

  vim.lsp.start({
    name     = name,
    cmd      = cmd,
    root_dir = root,
    settings = settings,
  })
end


vim.api.nvim_create_autocmd("FileType", {
  pattern = "python",
  callback = function(ev)
    start_lsp(
      ev.buf,
      "pyright",
      { "pyright-langserver", "--stdio" },
      {
        "pyproject.toml",
        "pyrightconfig.json",
        "setup.py",
        "setup.cfg",
        "requirements.txt",
        ".git",
      },
      {
        python = {
          analysis = {
            typeCheckingMode       = "basic",
            autoSearchPaths        = true,
            useLibraryCodeForTypes = true,
          },
        },
      }
    )
  end,
})


vim.api.nvim_create_autocmd("FileType", {
  pattern = { "c", "cpp", "objc", "objcpp" },
  callback = function(ev)
    start_lsp(
      ev.buf,
      "clangd",
      { "clangd", "--background-index", "--clang-tidy" },
      {
        "compile_commands.json",
        "compile_flags.txt",
        "CMakeLists.txt",
        ".clangd",
        ".git",
      }
    )
  end,
})


vim.api.nvim_create_autocmd("FileType", {
  pattern = "rust",
  callback = function(ev)
    start_lsp(
      ev.buf,
      "rust-analyzer",
      { "rust-analyzer" },
      { "Cargo.toml", ".git" },
      {
        ["rust-analyzer"] = {
          checkOnSave = { command = "clippy" },
          inlayHints  = {
            bindingModeHints       = { enable = true },
            chainingHints          = { enable = true },
            parameterHints         = { enable = true },
            typeHints              = { enable = true },
            closureReturnTypeHints = { enable = "always" },
          },
        },
      }
    )
  end,
})


vim.api.nvim_create_autocmd("FileType", {
  pattern = "go",
  callback = function(ev)
    start_lsp(
      ev.buf,
      "gopls",
      { "gopls" },
      { "go.work", "go.mod", ".git" }
    )
  end,
})


vim.api.nvim_create_autocmd("FileType", {
  pattern = "lua",
  callback = function(ev)
    start_lsp(
      ev.buf,
      "lua-language-server",
      { "lua-language-server" },
      { ".luarc.json", ".luarc.jsonc", ".git" },
      {
        Lua = {
          runtime   = { version = "LuaJIT" },
          workspace = {
            checkThirdParty = false,
            library         = vim.api.nvim_get_runtime_file("", true),
          },
          diagnostics = { globals = { "vim" } },
          telemetry   = { enable = false },
        },
      }
    )
  end,
})


vim.api.nvim_create_autocmd("FileType", {
  pattern = {
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact",
  },
  callback = function(ev)
    start_lsp(
      ev.buf,
      "typescript-language-server",
      { "typescript-language-server", "--stdio" },
      {
        "tsconfig.json",
        "jsconfig.json",
        "package.json",
        ".git",
      }
    )
  end,
})


-- LSP keymaps
-- ============

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)

    if not client then
      return
    end

    -- fix: bind omnifunc to LSP so <C-x><C-o> / <C-Space> calls the LSP
    -- completer. without this it falls back to the filetype omnifunc.
    vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"

    local o = { buffer = ev.buf }

    map("n", "gd", vim.lsp.buf.definition,
      vim.tbl_extend("force", o, { desc = "LSP definition" }))

    map("n", "gD", vim.lsp.buf.declaration,
      vim.tbl_extend("force", o, { desc = "LSP declaration" }))

    map("n", "gi", vim.lsp.buf.implementation,
      vim.tbl_extend("force", o, { desc = "LSP implementation" }))

    map("n", "gt", vim.lsp.buf.type_definition,
      vim.tbl_extend("force", o, { desc = "LSP type definition" }))

    map("n", "gr", vim.lsp.buf.references,
      vim.tbl_extend("force", o, { desc = "LSP references" }))

    map("n", "K", vim.lsp.buf.hover,
      vim.tbl_extend("force", o, { desc = "LSP hover" }))

    map("i", "<C-s>", vim.lsp.buf.signature_help,
      vim.tbl_extend("force", o, { desc = "LSP signature help" }))

    map("n", "<leader>rn", vim.lsp.buf.rename,
      vim.tbl_extend("force", o, { desc = "LSP rename" }))

    map("n", "<leader>ca", vim.lsp.buf.code_action,
      vim.tbl_extend("force", o, { desc = "LSP code action" }))

    map("v", "<leader>ca", vim.lsp.buf.code_action,
      vim.tbl_extend("force", o, { desc = "LSP code action" }))

    map("n", "<leader>f", function()
      vim.lsp.buf.format({ async = false })
    end, vim.tbl_extend("force", o, { desc = "LSP format" }))

    map("n", "<leader>ih", function()
      if vim.lsp.inlay_hint then
        vim.lsp.inlay_hint.enable(
          not vim.lsp.inlay_hint.is_enabled({ bufnr = ev.buf }),
          { bufnr = ev.buf }
        )
      end
    end, vim.tbl_extend("force", o, { desc = "Toggle inlay hints" }))
  end,
})


-- Native completion
-- =================

map("i", "<C-Space>", "<C-x><C-o>", {
  desc = "Native completion",
})

-- fix: some terminals send NUL (0x00) instead of <C-Space>.
-- without this mapping, <C-Space> silently does nothing in those terminals.
map("i", "<NUL>", "<C-x><C-o>", {
  desc = "Native completion (NUL fallback)",
})


-- Terminal
-- =========

map("n", "<leader>tt", "<cmd>terminal<CR>", {
  desc = "Open terminal",
})

map("t", "<Esc>", [[<C-\><C-n>]], {
  desc = "Terminal normal mode",
})


-- Autocommands
-- =============

vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')

    if mark[1] > 0
      and mark[1] <= vim.api.nvim_buf_line_count(0)
    then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})


vim.api.nvim_create_autocmd("FileType", {
  pattern = {
    "yaml",
    "toml",
    "json",
    "html",
    "css",
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact",
    "lua",
    "markdown",
  },
  callback = function()
    vim.bo.expandtab   = true
    vim.bo.tabstop     = 2
    vim.bo.shiftwidth  = 2
    vim.bo.softtabstop = 2
  end,
})


-- Keymaps
-- =======
--
-- Native Vim:
--
--   h j k l       movement
--   w b e         word movement
--   0 ^ $         line movement
--   gg G          file movement
--   f F t T       character movement
--   %             matching bracket
--   d c y         operators
--   v V <C-v>     visual mode
--   u <C-r>       undo / redo
--   .             repeat
--   / ? n N       search
--   * #           word search
--
-- Custom:
--
--   <Esc>          clear search highlight
--
--   [d             previous diagnostic
--   ]d             next diagnostic
--   <Space>d       diagnostic
--   <Space>D       diagnostic list
--
--   gd             definition
--   gD             declaration
--   gi             implementation
--   gt             type definition
--   gr             references
--   K              hover
--   <C-s>          signature help
--
--   <Space>rn      rename
--   <Space>ca      code action
--   <Space>f       format
--   <Space>ih      toggle inlay hints
--
--   <C-Space>      LSP completion
--   <NUL>          LSP completion (terminal fallback)
--
--   <Space>tt      terminal
--   <Esc>          terminal -> normal mode
