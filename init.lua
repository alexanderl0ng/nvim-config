-- Bootstrap Lazyvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    local lazyrepo = "https://github.com/folke/lazy.nvim.git"
    local out = vim.fn.system({"git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
    if vim.v.shell_error ~= 0 then
        vim.api.nvim_echo({
            {"Failed to clone lazy.nvim:\n", "ErrorMsg" },
            { out, "WarningMsg"},
            {"\nPress any key to exit..."},
        }, true, {})
        vim.fn.getchar()
        os.exit(1)
    end
end
vim.opt.rtp:prepend(lazypath)

-- Plugins
require("lazy").setup({
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        config = function()
            require("nvim-treesitter").setup({
                ensure_installed = { "c", "cpp", "lua", "rust", "vim", "vimdoc", "query", "markdown", "markdown_inline", "bash", "html", "haskell", "python" },
                highlight = { enable = true },
                indent = { enable = true },
            })
        end,
    },
    {
        "catppuccin/nvim",
        name = "catppuccin",
        priority = 1000,
        config = function()
            require("catppuccin").setup({
                flavour = "mocha",
            })
            vim.cmd("colorscheme catppuccin")
        end,
    },
    {
        "mason-org/mason.nvim",
        config = function()
            require("mason").setup()

            local registry = require("mason-registry")
            local ensure_installed = { "lua-language-server", "clangd", "rust-analyzer", "html-lsp", "haskell-language-server", "pyright" }

            registry.refresh(function ()
                for _, name in ipairs(ensure_installed) do
                    local ok, pkg = pcall(registry.get_package, name)
                    if ok and not pkg:is_installed() then
                        pkg.install()
                    end
                end
            end)
        end,
    },
})

-- Native LSP (Neovim 0.12+)
vim.lsp.config("lua_ls", {})
vim.lsp.config("clangd", {})
vim.lsp.config("rust_analyzer", {})
vim.lsp.config("html", {})
vim.lsp.config("hls", {})
vim.lsp.config("pyright", {})
vim.lsp.enable({ "lua_ls", "clangd", "rust_analyzer", "html", "hls", "pyright" })

-- Native insert-mode autocomplete
vim.opt.autocomplete = true
vim.opt.completeopt = { "menuone", "noselect", "popup" }

-- Options
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.undofile = true

-- External Dependency Check (for LSP servers Mason can't fully self install)
local function check_external_deps()
    local deps = {
        { cmd = "node", reason = "required by html-lsp and pyright" },
        { cmd = "ghc", reason = "required by haskell-language-server" },
        { cmd = "cabal", alt = "stack", reason = "required by haskell-language-server (either one)" },
    }

    local missing = {}
    for _, dep in ipairs(deps) do
        local primary_missing = vim.fn.executable(dep.cmd) == 0
        local alt_missing = not dep.alt or vim.fn.executable(dep.alt) == 0

        if primary_missing and alt_missing then
            local label = dep.alt and (dep.cmd .. " or " .. dep.alt) or dep.cmd
            table.insert(missing, string.format("  - %s (%s)", label, dep.reason))
        end
    end

    if #missing > 0 then
        vim.notify(
            "Missing external dependencies - some LSPs will not work correctly:\n" .. table.concat(missing, "\n"),
            vim.log.levels.WARN,
            { title = "nvim-config" }
        )
    end
end

vim.api.nvim_create_autocmd("VimEnter", {callback = check_external_deps, })
    
