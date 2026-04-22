local vim_default_keymap_opts = { silent = true }
local vim_use_lsp = true
local vim_lsp_servers = { "lua_ls", "clangd", "c3_lsp" }
local vim_use_cmp = true
local vim_use_git = true

local api = vim.api
local cmd = vim.cmd
local diagnostic = vim.diagnostic
local fn = vim.fn
local opt = vim.opt
local env = vim.env
local keymap = vim.keymap
local schedule = vim.schedule
local system = vim.system
local log = vim.log
local lsp = vim.lsp
local notify = vim.notify
local tbl_extend = vim.tbl_extend

vim.loader.enable()

-- Encoding & Formats
-- 인코딩과 포멧을 설정합니다
-- 유닉스(LF) 를 사용합니다
opt.encoding = "UTF-8"
opt.fileformat = "unix"
opt.fileformats = "unix"

-- Mouse Support
-- 마우스의 모든 지원을 사용합니다
opt.mouse = "a"

-- 24Bit Terminal Colors
-- 24Bit 터미널 컬러를 사용합니다
opt.termguicolors = true

-- CursorLine & View Support
-- 줄바꿈이 되지 않게 합니다
opt.wrap = false
-- 커서라인을 사용합니다
opt.cursorline = true
-- 시점으로부터 10 칸씩 마진을 줍니다
opt.scrolloff = 10

-- Internal UpdateTime
-- 갱신 주기를 줄입니다
opt.updatetime = 500

-- Always active StatusLine
-- 항상 status line 을 활성화합니다
opt.laststatus = 2

-- Search Support
opt.incsearch = true
opt.ignorecase = true
opt.smartcase = true
opt.showmatch = true

-- Tab Support
opt.tabstop = 4
opt.shiftwidth = 4
opt.softtabstop = 4
opt.expandtab = true
opt.smartindent = true

-- NumberLine Support
opt.number = true
opt.relativenumber = true
opt.equalalways = false

-- Word Point (iskeyword)
opt.iskeyword:remove("-")

-- Whitespace chars
opt.list = true
opt.listchars = { tab = "│ ", space = " ", trail = " " }

-- Backup & Swap
opt.swapfile = false
opt.hidden = true
opt.shadafile = "NONE"

-- UI Components
opt.signcolumn = "yes"

-- Bells
opt.errorbells = false
opt.visualbell = false
opt.timeoutlen = 500

-- Clipboard
opt.clipboard = "unnamed,unnamedplus"

-- Message display
opt.shortmess:append("cI")

-- Undo Management
opt.undofile = true
opt.undodir = fn.stdpath("state") .. "/undo"

-- Ignore files in Wildmenu
opt.wildignore:append({ "*/.git/*", "*/.hg/*", "*/.svn/*", "*/.DS_Store" })

-- Set leader key
vim.g.mapleader = " "

-- Window Navigation (Alt + Arrows / Alt + hjkl)
keymap.set('n', '<A-Right>', ':wincmd l<CR>', vim_default_keymap_opts)
keymap.set('n', '<A-Left>',  ':wincmd h<CR>', vim_default_keymap_opts)
keymap.set('n', '<A-Up>',    ':wincmd k<CR>', vim_default_keymap_opts)
keymap.set('n', '<A-Down>',  ':wincmd j<CR>', vim_default_keymap_opts)
keymap.set('n', '<A-l>',     ':wincmd l<CR>', vim_default_keymap_opts)
keymap.set('n', '<A-h>',     ':wincmd h<CR>', vim_default_keymap_opts)
keymap.set('n', '<A-k>',     ':wincmd k<CR>', vim_default_keymap_opts)
keymap.set('n', '<A-j>',     ':wincmd j<CR>', vim_default_keymap_opts)

-- Window Resizing
keymap.set('n', '<A-<>', '<C-w><', vim_default_keymap_opts)
keymap.set('n', '<A->>', '<C-w>>', vim_default_keymap_opts)

-- Window Split
keymap.set('n', '\\', "<cmd>spl<cr>", vim_default_keymap_opts)
keymap.set('n', '|', "<cmd>vs<cr>", vim_default_keymap_opts)

-- Navigation Shortcuts
keymap.set('n', '<C-Right>', 'w', vim_default_keymap_opts)
keymap.set('n', '<C-Left>',  'b', vim_default_keymap_opts)
keymap.set('n', '<S-Up>',    '<C-u>', vim_default_keymap_opts)
keymap.set('n', '<S-Down>',  '<C-d>', vim_default_keymap_opts)

-- Insert Mode Undo Breakpoints
keymap.set('i', ',', ',<C-g>u', vim_default_keymap_opts)
keymap.set('i', '.', '.<C-g>u', vim_default_keymap_opts)
keymap.set('i', '!', '!<C-g>u', vim_default_keymap_opts)
keymap.set('i', '?', '?<C-g>u', vim_default_keymap_opts)
keymap.set('i', '<CR>', '<CR><C-g>u', vim_default_keymap_opts)
keymap.set('i', '<space>', '<space><C-g>u', vim_default_keymap_opts)
keymap.set('i', '<C-r>', '<C-g>u<C-r>', vim_default_keymap_opts)

-- Visual Mode Indentation
keymap.set('v', '<', '<gv', vim_default_keymap_opts)
keymap.set('v', '>', '>gv', vim_default_keymap_opts)

-- Terminal Mode Exit
keymap.set('t', '<ESC>', [[<C-\><C-n>]], vim_default_keymap_opts)

-- Expolrer
keymap.set('n', '<leader>e', "<cmd>Ex<cr>")

local nvim_plugin_manager_path = fn.expand(fn.stdpath("data") .. "/nvim-plugins/lib")
if fn.isdirectory(nvim_plugin_manager_path) == 0 then
    local out = fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/yaeju1205/nvim-plugin-manager",
        nvim_plugin_manager_path
    })
    if vim.v.shell_error ~= 0 then
        api.nvim_echo({
            { "Failed to clone nvim-plugin-manager:\n" },
	    { out }

        }, true, {})
        vim.fn.getchar()
        os.exit(1)
    end
end
opt.rtp:append(nvim_plugin_manager_path)
local plugins = require("plugin-manager")

vim.plugin.install_sync("nvim-lua/plenary.nvim")

if vim_use_git then
    plugins.install("lewis6991/gitsigns.nvim")(function()
        require("gitsigns").setup({
            signs = {
                add = { text = "┃" },
                change = { text = "┃" },
                delete = { text = "┃" },
                topdelete = { text = "┃" },
                changedelete = { text = "┃" },
                untracked = { text = "┆" },
            },
            signs_staged = {
                add = { text = "┃" },
                change = { text = "┃" },
                delete = { text = "┃" },
                topdelete = { text = "┃" },
                changedelete = { text = "┃" },
                untracked = { text = "┆" },
            },
        })
    end)
end

plugins.install("lewis6991/satellite.nvim")(function()
    --- @diagnostic disable
    require("satellite").setup({
        current_only = false,
        winblend = 0,
        handlers = {
            marks = {
                enable = false,
            },
            gitsigns = {
                enable = true,
                signs = {
                    add = "│",
                    change = "│",
                    delete = "│",
                },
            },
        },
    })
    --- @diagnostic enable
end)

plugins.install("yaeju1205/warp.nvim")(function()
    require("warp").setup()
end)

if vim_use_cmp then
    plugins.install("saghen/blink.cmp", {
        version = "v1.9.1",
        requires = {
            { origin = "folke/lazydev.nvim" },
        },
    })(function()
        require("lazydev").setup({})
        require("blink.cmp").setup({
            keymap = {
                preset = "none",
                ["<CR>"] = { "accept", "fallback" },
                ["<Tab>"] = {
                    "select_next",
                    "accept",
                    "fallback",
                },
                ["<S-Tab>"] = {
                    "select_prev",
                    "fallback",
                },
            },

            completion = {
                menu = {
                    border = "none",
                    winblend = 0,
                    scrollbar = true,
                    draw = {
                        padding = 0,
                        gap = 1,
                        columns = {
                            { "kind_icon" },
                            { "label" }
                        }
                    }
                },
                documentation = {
                    auto_show = true,
                    auto_show_delay_ms = 300,
                },
                list = {
                    selection = {
                        preselect = false,
                    },
                },
            },

            cmdline = {
                enabled = true,
                keymap = {
                    preset = "cmdline",
                    ["<Right>"] = false,
                    ["<Left>"] = false,
                },
                completion = {
                    list = {
                        selection = {
                            preselect = false
                        }
                    },
                    menu = {
                        auto_show = true,
                    },
                    ghost_text = {
                        enabled = true
                    },
                },
            },

            appearance = {
                kind_icons = {
                    Text = "",
                    Method = "",
                    Function = "",
                    Constructor = "",
                    Field = "",
                    Variable = "",
                    Class = "",
                    Interface = "",
                    Module = "",
                    Property = "",
                    Unit = "",
                    Value = "",
                    Enum = "",
                    Keyword = "",
                    Snippet = "",
                    Color = "",
                    File = "",
                    Reference = "",
                    Folder = "",
                    EnumMember = "",
                    Constant = "",
                    Struct = "",
                    Event = "",
                    Operator = "",
                    TypeParameter = "",
                },
                nerd_font_variant = "mono",
            },

            signature = {
                enabled = true,
            },

            sources = {
                default = { "lazydev", "lsp" },
                providers = {
                    lazydev = {
                        name = "LazyDev",
                        module = "lazydev.integrations.blink",
                        score_offset = 100,
                    },
                },
            },
        })
    end)
end

if vim_use_lsp then
    plugins.install("mason-org/mason.nvim")(function()
        require("mason").setup()
    end)

    plugins.install("neovim/nvim-lspconfig")(function()
        lsp.config("*", {
            capabilities = require("blink.cmp").get_lsp_capabilities(),
        })
        lsp.enable(vim_lsp_servers)
        api.nvim_create_autocmd("LspAttach", {
            callback = function(args)
                local client = lsp.get_client_by_id(args.data.client_id)

                if not client then
                    return
                end

                if client.server_capabilities.semanticTokensProvider then
                    client.server_capabilities.semanticTokensProvider = nil
                end

                if client.server_capabilities.documentHighlightProvider then
                    api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
                        buffer = args.buf,
                        callback = lsp.buf.document_highlight,
                    })

                    api.nvim_create_autocmd({ "CursorMoved", "InsertEnter" }, {
                        buffer = args.buf,
                        callback = lsp.buf.clear_references,
                    })
                end
            end,
        })
    end)
end

plugins.install("lewis6991/hover.nvim")(function()
    require('hover').config({})

    vim.keymap.set('n', 'K', function()
        require('hover').open()
    end, { desc = 'hover.nvim (open)' })

    vim.keymap.set('n', 'gK', function()
        require('hover').enter()
    end, { desc = 'hover.nvim (enter)' })

    vim.keymap.set('n', '<C-p>', function()
        require('hover').switch('previous')
    end, { desc = 'hover.nvim (previous source)' })

    vim.keymap.set('n', '<C-n>', function()
        require('hover').switch('next')
    end, { desc = 'hover.nvim (next source)' })

    vim.keymap.set('n', '<MouseMove>', function()
        require('hover').mouse()
    end, { desc = 'hover.nvim (mouse)' })

    vim.o.mousemoveevent = true
end)

plugins.install("yaeju1205/sakura.nvim", {
    requires = {
        { origin = "rktjmp/lush.nvim" }
    }
})(function()
    cmd("syntax on")
    cmd("colorscheme sakura")
end)

plugins.install("vyfor/cord.nvim")(function()
    vim.g.cord_defer_startup = true
    require("cord").setup({})
end)

api.nvim_create_autocmd("CursorHold", {
    callback = function()
        diagnostic.open_float(nil, { focus = false })
    end
})
