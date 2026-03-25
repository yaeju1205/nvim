--- @diagnostic disable
local api = vim.api
local cmd = vim.cmd
local fn = vim.fn
local opt = vim.opt
local env = vim.env
local schedule = vim.schedule
local system = vim.system
local log = vim.log
local lsp = vim.lsp
local notify = vim.notify
local tbl_extend = vim.tbl_extend
--- @diagnostic enable

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

local keymap = vim.keymap.set
local opts = { silent = true }

-- Window Navigation (Alt + Arrows / Alt + hjkl)
keymap('n', '<A-Right>', ':wincmd l<CR>', opts)
keymap('n', '<A-Left>',  ':wincmd h<CR>', opts)
keymap('n', '<A-Up>',    ':wincmd k<CR>', opts)
keymap('n', '<A-Down>',  ':wincmd j<CR>', opts)
keymap('n', '<A-l>',     ':wincmd l<CR>', opts)
keymap('n', '<A-h>',     ':wincmd h<CR>', opts)
keymap('n', '<A-k>',     ':wincmd k<CR>', opts)
keymap('n', '<A-j>',     ':wincmd j<CR>', opts)

-- Window Resizing
keymap('n', '<A-<>', '<C-w><', opts)
keymap('n', '<A->>', '<C-w>>', opts)

-- Navigation Shortcuts
keymap('n', '<C-Right>', 'w', opts)
keymap('n', '<C-Left>',  'b', opts)
keymap('n', '<S-Up>',    '<C-u>', opts)
keymap('n', '<S-Down>',  '<C-d>', opts)

-- Insert Mode Undo Breakpoints
keymap('i', ',', ',<C-g>u', opts)
keymap('i', '.', '.<C-g>u', opts)
keymap('i', '!', '!<C-g>u', opts)
keymap('i', '?', '?<C-g>u', opts)
keymap('i', '<CR>', '<CR><C-g>u', opts)
keymap('i', '<space>', '<space><C-g>u', opts)
keymap('i', '<C-r>', '<C-g>u<C-r>', opts)

-- Visual Mode Indentation
keymap('v', '<', '<gv', opts)
keymap('v', '>', '>gv', opts)

-- Terminal Mode Exit
keymap('t', '<ESC>', [[<C-\><C-n>]], opts)

-- Expolrer
keymap('n', '<leader>e', "<cmd>Ex<cr>")

--- @class PluginManager
--- @field plugins_directory string
local plugins = {}
plugins.plugins_directory = fn.expand(fn.stdpath("data") .. "/nvim-plugins")
plugins.username = env.USER or env.LOGNAME or env.USERNAME or "unknown"
plugins.git_host = "github.com"
plugins.git_prefix = "https://" .. plugins.git_host .. "/"

--- @type table<string, PluginManager.PluginSpec>
local plugin_specs = {}

--- @class PluginManager.PluginSpec
--- @field origin? string
--- @field name string
--- @field drive string
--- @field version? string
--- @field branch? string
--- @field requires? { origin: string, options?: PluginManager.InstallOptions }[] 

--- @class PluginManager.InstallOptions
--- @field name? string
--- @field version? string
--- @field branch? string
--- @field requires? { origin: string, options?: PluginManager.InstallOptions }[] 

--- @param origin string
--- @return string
local function get_git_normal_origin(origin)
    local host = origin:match("//([^/]+)") or origin:match("@([^:]+)")
    if not host then
        origin = plugins.git_prefix .. origin
    end
    return origin
end

--- @param origin string
--- @return string, string, string
local function get_git_origin_info(origin)
    local host = origin:match("//([^/]+)") or origin:match("@([^:]+)")
    if not host then
        host = plugins.git_host
        origin = plugins.git_prefix .. origin
    end

    origin = origin:gsub("^%w+://", ""):gsub("^git@", "")
    origin = origin:gsub(":", "/")
    origin = origin:gsub("%.git$", "")

    local slash_parts = {}
    for part in origin:gmatch("[^/]+") do
        table.insert(slash_parts, part)
    end
    local count = #slash_parts
    local owner = slash_parts[count - 1]
    local repo = slash_parts[count]
    return host, owner, repo
end

--- @param host string
--- @param owner string
--- @param name string
local function get_origin_drive(host, owner, name)
    return fn.expand(plugins.plugins_directory .. "/" .. host .. "/" .. owner .. "/" .. name)
end

--- @param origin string
--- @param options PluginManager.InstallOptions
--- @return string[], PluginManager.PluginSpec
local function get_git_origin_install_command_and_info(origin, options)
    local host, owner, name = get_git_origin_info(origin)
    local drive = get_origin_drive(host, owner, name)
    local command = { "git", "clone", "--filter=blob:none", "--depth=1" }
    if options.version then
        command[5] = "--branch"
        command[6] = options.version
        command[7] = "--single-branch"
        command[8] = get_git_normal_origin(origin)
        command[9] = drive
    elseif options.branch then
        command[5] = "--branch"
        command[6] = options.branch
        command[7] = get_git_normal_origin(origin)
        command[8] = drive
    else
        command[5] = get_git_normal_origin(origin)
        command[6] = drive
    end
    return command, tbl_extend("force", {
        name = name,
        drive = drive,
        origin = origin
    }, options)
end

--- @param spec PluginManager.PluginSpec
function plugins.load(spec)
    if spec.requires then
        for _, include in ipairs(spec.requires) do
            plugins.install_sync(include.origin, include.options)
        end
    end
    plugin_specs[spec.name] = spec
    opt.rtp:append(spec.drive)
end

--- @param origin string
--- @param options? PluginManager.InstallOptions
--- @return fun (callback?: fun(spec: PluginManager.PluginSpec))
function plugins.install(origin, options)
    local command, spec = get_git_origin_install_command_and_info(origin, options or {})
    if fn.isdirectory(spec.drive) == 1 then
        return function(callback)
            schedule(function()
                plugins.load(spec)
                if callback then
                    callback(spec)
                end
            end)
        end
    end
    return function(callback)
        if system then
            system(command, { text = true }, function(obj)
                schedule(function()
                    if obj.code ~= 0 then
                        local err_msg = (obj.stderr ~= "" and obj.stderr) or "Unknown error"
                        return notify("Install git clone error: " .. obj.code .. "):\n" .. err_msg, log.levels.ERROR)
                    end
                    plugins.load(spec)
                    if callback then
                        callback(spec)
                    end
                end)
            end)
        else
            schedule(function()
                local output = fn.system(table.concat(command, " "))
                ---@diagnostic disable-next-line
                if vim.v.shell_error ~= 0 then
                    return notify("Faild install\n" .. output, log.levels.ERROR)
                end
                plugins.load(spec)
                if callback then
                    callback(spec)
                end
            end)
        end
    end
end

--- @param origin string
--- @param options? PluginManager.InstallOptions
function plugins.install_sync(origin, options)
    local command, spec = get_git_origin_install_command_and_info(origin, options or {})
    if fn.isdirectory(spec.drive) == 1 then
        return plugins.load(spec)
    end
    if system then
        local obj = system(command, { text = true }):wait()
        if obj.code ~= 0 then
            local err_msg = (obj.stderr ~= "" and obj.stderr) or "Unknown error"
            return notify("Install git clone error: " .. obj.code .. "):\n" .. err_msg, log.levels.ERROR)
        end
    else
        local output = fn.system(table.concat(command, " "))
        ---@diagnostic disable-next-line
        if vim.v.shell_error ~= 0 then
            return notify("Faild install\n" .. output, log.levels.ERROR)
        end
    end
    plugins.load(spec)
end

--- @param name string
--- @param drive string
--- @return fun (callback?: fun(spec: PluginManager.PluginSpec))
function plugins.install_user_plugin(name, drive)
    --- @type PluginManager.PluginSpec
    local spec
    if fn.isdirectory(drive) == 1 then
        spec = {
            name = name,
            drive = drive,
        }
        plugins.load(spec)
    else
        notify("Unknown user plugin drive: " .. drive, log.levels.WARN)
    end
    return function(callback)
        schedule(function()
            if callback then
                callback(spec)
            end
        end)
    end
end

--- @param name string
--- @param drive string
function plugins.install_user_plugin_sync(name, drive)
    local spec
    if fn.isdirectory(drive) == 1 then
        spec = {
            name = name,
            drive = drive,
        }
        plugins.load(spec)
    else
        notify("Unknown user plugin drive: " .. drive, log.levels.WARN)
    end
end

--- @param plugin string
function plugins.upgrade(plugin)
    local spec = plugin_specs[plugin]
    if not spec then
        return notify("Unknown plugin: " .. plugin, log.levels.WARN)
    end
    if fn.isdirectory(spec.drive) == 1 then
        local command = { "git", "pull", "--ff-only" }
        if system then
            system(command, { cwd = spec.drive, text = true }, function(obj)
                if obj.code ~= 0 then
                    local err_msg = (obj.stderr ~= "" and obj.stderr) or "Unknown error"
                    return notify("Upgrade git pull error: " .. obj.code .. "):\n" .. err_msg, log.levels.ERROR)
                end
            end)
        else
            local old_cwd = fn.getcwd()
            local output
            fn.chdir(spec.drive)
            output = fn.system(table.concat(command, " "))
            fn.chdir(old_cwd)
            ---@diagnostic disable-next-line
            if vim.v.shell_error ~= 0 then
                return notify("Faild upgrade\n" .. output, log.levels.ERROR)
            end
        end
    else
        if not spec.origin then
            return notify("Plugin " .. spec.name .. " not has origin" .. plugin, log.levels.WARN)
        end
        --- @diagnostic  disable-next-line
        plugins.install(spec.origin, spec)
    end
end

--- @param plugin string
function plugins.remove(plugin)
    local spec = plugin_specs[plugin]
    if not spec then
        return notify("Unknown plugin: " .. plugin, log.levels.WARN)
    end
    if fn.isdirectory(spec.drive) == 1 then
        opt.rtp:remove(spec.drive)
    else
        return notify("Plugin " .. spec.name .. " not found" .. plugin, log.levels.WARN)
    end
end

--- @param plugin string
function plugins.delete(plugin)
    local spec = plugin_specs[plugin]
    if not spec then
        return notify("Unknown plugin: " .. plugin, log.levels.WARN)
    end
    plugins.remove(plugin)
    if fn.has("win32") == 1 then
        if system then
            system({ "rmdir", "/s", "/q", spec.drive })
        else
            schedule(function()
                fn.system(string.format('rmdir /s /q "%s"', spec.drive))
            end)
        end
    else
        if system then
            system({ "rm", "-r", spec.drive })
        else
            schedule(function()
                fn.system("rm -r" .. spec.drive)
            end)
        end
    end
end

plugins.install_sync("nvim-lua/plenary.nvim")

plugins.install("cranberry-clockworks/coal.nvim")(function()
    cmd("syntax on")
    cmd("colorscheme coal")
end)

plugins.install("lewis6991/satellite.nvim")(function()
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
end)

plugins.install("saghen/blink.cmp", {
    version = "v1.9.1",
})(function()
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
            default = { "lsp" }
        },
    })
end)

lsp.servers = {
    lua_ls = {},
}

plugins.install("mason-org/mason.nvim")(function()
    require("mason").setup()
end)

plugins.install("neovim/nvim-lspconfig")(function()
    lsp.config("*", {
        capabilities = require("blink.cmp").get_lsp_capabilities(),
    })
    for server, options in pairs(lsp.servers) do
        lsp.config(server, options)
        lsp.enable(server)
    end
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

plugins.install("yaeju1205/warp.nvim")(function()
    require("warp").setup()
end)
