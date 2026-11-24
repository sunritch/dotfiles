vim.opt.expandtab = true
vim.opt.undofile = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.modeline = false
vim.opt.diffopt:append({ "iwhite", "algorithm:histogram" })
vim.opt.completeopt = { "menu", "menuone", "noselect", "popup" }
vim.opt.path:append("**")
vim.opt.wildmode = { "longest:full", "full" }
vim.opt.wildignore:append({ ".hg", ".svn", "*~", "*.png", "*.jpg", "*.gif", "*.min.js", "*.swp", "*.o", "vendor", "dist", "_site" })
vim.o.winborder = "rounded"
for _, g in ipairs({ "Normal", "NormalNC", "SignColumn", "EndOfBuffer", "MsgArea", "FloatBorder", "NormalFloat" }) do
    vim.api.nvim_set_hl(0, g, { bg = "none" })
end

-- restore last cursor position
vim.api.nvim_create_autocmd("BufReadPost", {
    command = [[if &filetype !~# 'commit' | silent! exe 'normal! g`"zv' | endif]],
})

vim.g.mapleader = " "
vim.keymap.set("n", "<leader>le", "<cmd>Lexplore<CR>", { desc = "Toggle Netrw Explorer" })
vim.diagnostic.config({ virtual_text = { spacing = 2 }, severity_sort = true, float = { source = "always" } })

-- lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
    local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable",
                                "https://github.com/folke/lazy.nvim.git", lazypath })
    if vim.v.shell_error ~= 0 then error("Failed to clone lazy.nvim:\n" .. out) end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
    {
        "Julian/lean.nvim",
        ft = "lean",
        dependencies = { "nvim-lua/plenary.nvim" },
        opts = { mappings = true },
    },
    {
        -- Rust (Neovim 0.12+)
        "mrcjkb/rustaceanvim",
        version = "^9",
        lazy = false,
        init = function()
            vim.g.rustaceanvim = {
                server = {
                    on_attach = function(client, bufnr)
                        -- popup on trigger characters; <Tab> cycles, or triggers after a word
                        vim.lsp.completion.enable(true, client.id, bufnr, { autotrigger = true })
                        local function feed(keys) vim.api.nvim_feedkeys(vim.keycode(keys), "n", false) end
                        vim.keymap.set("i", "<Tab>", function()
                            if vim.fn.pumvisible() == 1 then
                                feed("<C-n>")
                            elseif vim.api.nvim_get_current_line():sub(1, vim.fn.col(".") - 1):match("[%w_]$") then
                                vim.lsp.completion.get()
                            else
                                feed("<Tab>")
                            end
                        end, { buffer = bufnr })
                        for lhs, cmd in pairs({ rr = "runnables", rt = "testables", re = "explainError" }) do
                            vim.keymap.set("n", "<leader>" .. lhs, function() vim.cmd.RustLsp(cmd) end,
                                           { buffer = bufnr, desc = "Rust " .. cmd })
                        end
                    end,
                },
            }
        end,
    },
    {
        "MeanderingProgrammer/render-markdown.nvim",
        ft = "markdown",
        opts = { enabled = false, render_modes = { "n", "c" } },
        keys = { { "<leader>mp", "<cmd>RenderMarkdown toggle<cr>", ft = "markdown", desc = "Toggle Markdown preview" } },
    },
})



