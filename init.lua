-- NOTE: I got this config from https://github.com/nvim-lua/kickstart.nvim
-- Then, I made a couple of minor changes. It's working quite well so far, actually

--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader        = " "
vim.g.maplocalleader   = " "
vim.g.have_nerd_font   = true
vim.opt.number         = true
vim.opt.relativenumber = true
vim.opt.cursorline     = true
vim.opt.showmode       = false
vim.opt.clipboard      = "unnamedplus"
vim.opt.breakindent    = true
vim.opt.undofile       = false
vim.opt.ignorecase     = true
vim.opt.smartcase      = true
vim.opt.synmaxcol      = 300
vim.opt.wrap           = false
vim.opt.tabstop        = 4
vim.opt.signcolumn     = "yes"
vim.opt.updatetime     = 4000 -- writes to swap file less often
vim.opt.timeoutlen     = 200 -- Displays which-key popup sooner
vim.opt.splitright     = true
vim.opt.splitbelow     = true
vim.opt.list           = true
vim.opt.listchars      = { tab = " →", trail = "·", nbsp = "␣" }
vim.opt.inccommand     = "split" -- Preview substitutions live, as you type!
vim.opt.scrolloff      = 20 -- keep the cursor in the center of the screen
vim.opt.hlsearch       = false -- Set highlight on search, but clear on pressing <Esc> in normal mode

vim.keymap.set("n", "[d", vim.diagnostic.goto_prev,         { desc = "Go to previous [D]iagnostic message" })
vim.keymap.set("n", "]d", vim.diagnostic.goto_next,         { desc = "Go to next [D]iagnostic message" })
vim.keymap.set("n", "<S-F2>", vim.diagnostic.goto_prev,     { desc = "Go to previous [D]iagnostic message" })  -- intellij keybind I've gotten used to
vim.keymap.set("n", "<F2>", vim.diagnostic.goto_next,       { desc = "Go to next [D]iagnostic message" })        -- intellij keybind I've gotten used to
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show diagnostic [E]rror messages" })
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })
vim.keymap.set("n", "<C-j>", "<cmd>cnext<CR>zz",            { desc = "Move down on the quick fix list" })
vim.keymap.set("n", "<C-k>", "<cmd>cprev<CR>zz",            { desc = "Move up on the quick fix list" })

-- Highlight when yanking (copying) text
vim.api.nvim_create_autocmd("TextYankPost", {
    desc = "Highlight when yanking (copying) text",
    group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
    callback = function()
        vim.highlight.on_yank()
    end,
})

-- Install `lazy.nvim` plugin manager`
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    local lazyrepo = "https://github.com/folke/lazy.nvim.git"
    vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
end ---@diagnostic disable-next-line: undefined-field
vim.opt.rtp:prepend(lazypath)

-- Configure and install plugins
-- :Lazy - check the current status of your plugins, run
-- :Lazy update - update plugins you can run
-- opts = {} is equivelant to require("blah").setup({ ... }) 
require("lazy").setup({
  { -- Detect tabstop and shiftwidth automatically
    "tpope/vim-sleuth",
  },
  { -- Add line-comments and block comments
    "numToStr/Comment.nvim", opts = {},
  }, 
  { -- Amazing git integration. TODO: try lazygit
    "tpope/vim-fugitive",
    config = function()
      vim.api.nvim_create_user_command(
        "Diff",
        ":Gvdiffsplit! <args>",
        { desc = "View the git diff of this file vs what we have staged", nargs = 1 }
      )
      -- Needed to see the context with the changes imo
      vim.opt.diffopt:append("context:500") 
    end
  },
  { -- Adds git related signs to the gutter, as well as utilities for managing changes
    "lewis6991/gitsigns.nvim",
    opts = {
      signs = {
        add = { text = "┃" },
        change = { text = "┃" },
        delete = { text = "_" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
        untracked = { text = "┆" },
      },
      on_attach = function()
        local gitsigns = require("gitsigns")

        local function map(mode, l, r, desc)
          opts = {}
          opts.buffer = bufnrr
          opts.desc = desc
          vim.keymap.set(mode, l, r, opts)
        end

        -- Move between changes. Works even when you're not in the diff view
        map("n", "<F7>", gitsigns.next_hunk, "Next [c]ange")
        map("n", "<S-F7>", gitsigns.prev_hunk, "Previous [c]ange")

        -- TODO: consider if we still need this
        map("n", "<leader>hd", gitsigns.diffthis, "[H]unk [D]iff current")
        map("n", "<leader>hD", function() gitsigns.diffthis("~") end, "[H]unk [D]iff current")
      end,
    },
  },
  { -- Useful plugin to show you pending keybinds.
    "folke/which-key.nvim", 
    event = "VimEnter", 
    config = function()
      require("which-key").setup()

      -- Document existing key chains
      require("which-key").add({
        {"<leader>c", group = "[C]ode"}, { "<leader>c_", hidden = true },
        { "<leader>d", group = "[D]ocument" }, { "<leader>d_", hidden = true },
        { "<leader>r", group = "[R]ename" }, { "<leader>r_", hidden = true },
        { "<leader>s", group = "[S]earch" }, { "<leader>s_", hidden = true },
        { "<leader>w", group = "[W]orkspace" }, { "<leader>w_", hidden = true },
      })
    end,
  },
  { -- Fuzzy Finder (files, lsp, etc)
    "nvim-telescope/telescope.nvim",
    event = "VimEnter",
    branch = "0.1.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { -- If encountering errors, see telescope-fzf-native README for installation instructions
        "nvim-telescope/telescope-fzf-native.nvim",

        -- `build` is used to run some command when the plugin is installed/updated.
        -- This is only run then, not every time Neovim starts up.
        build = "make",

        -- `cond` is a condition used to determine whether this plugin should be
        -- installed and loaded.
        cond = function()
          return vim.fn.executable("make") == 1
        end,
      },
      { "nvim-telescope/telescope-ui-select.nvim" },

      -- Useful for getting pretty icons, but requires a Nerd Font.
      { "nvim-tree/nvim-web-devicons", enabled = vim.g.have_nerd_font },
    },
    config = function()
      require("telescope").setup({
        defaults = {
          layout_strategy = "vertical",
        },
        extensions = {
          ["ui-select"] = {
            require("telescope.themes").get_dropdown(),
          },
        },
      })

      -- Enable Telescope extensions if they are installed
      pcall(require("telescope").load_extension, "fzf")
      pcall(require("telescope").load_extension, "ui-select")

      -- See `:help telescope.builtin`
      local builtin = require("telescope.builtin")
      vim.keymap.set("n", "<leader>sh", builtin.help_tags,             { desc = "[S]earch [H]elp" })
      vim.keymap.set("n", "<leader>sk", builtin.keymaps,               { desc = "[S]earch [K]eymaps" })
      vim.keymap.set("n", "<leader>sf", builtin.find_files,            { desc = "[S]earch [F]iles" })
      vim.keymap.set("n", "<leader>ss", builtin.lsp_workspace_symbols, { desc = "[S]earch Workspace [S]ymbols" })
      vim.keymap.set("n", "<leader>sw", builtin.grep_string,           { desc = "[S]earch current [W]ord" })
      vim.keymap.set("n", "<leader>sa", builtin.live_grep,             { desc = "[S]earch in [A]ll Files" })
      vim.keymap.set("n", "<leader>sg", builtin.git_status,            { desc = "[S]earch in [G]it status list" })
      vim.keymap.set("n", "<leader>sb", builtin.git_branches,          { desc = "[S]earch Git [B]ranches" })
      vim.keymap.set("n", "<leader>sd", builtin.diagnostics,           { desc = "[S]earch [D]iagnostics" })
      vim.keymap.set("n", "<leader>sr", builtin.resume,                { desc = "[S]earch [R]esume" })
      vim.keymap.set("n", "<leader>s.", builtin.oldfiles,              { desc = '[S]earch Recent Files ("." for repeat)' })
      vim.keymap.set("n", "<leader><leader>", builtin.buffers,         { desc = "[ ] Find existing buffers" })
      -- TODO: think  of something better to put here.
      vim.keymap.set("n", "<leader>/", function()
        builtin.current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
          winblend = 10,
          previewer = false,
        }))
      end, { desc = "[/] Fuzzily search in current buffer" })
      -- Shortcut for searching your Neovim configuration files
      vim.keymap.set("n", "<leader>sn", function()
        builtin.find_files({ cwd = vim.fn.stdpath("config") })
      end, { desc = "[S]earch [N]eovim files" })
    end,
  },
  { -- LSP Configuration & Plugins
    "neovim/nvim-lspconfig",
    dependencies = {
      -- Automatically install LSPs and related tools to stdpath for Neovim
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "WhoIsSethDaniel/mason-tool-installer.nvim",
      -- Useful status updates for LSP.
      { "j-hui/fidget.nvim", opts = {} },
    },
    config = function()
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
        callback = function(event)
          local map_lsp_fn = function(keys, func, desc)
            vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
          end

          map_lsp_fn("gd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")
          -- NOTE: This is not Goto Definition, this is Goto Declaration.
          --  For example, in C this would take you to the header instead of the cpp file
          map_lsp_fn("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
          map_lsp_fn("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")
          map_lsp_fn("gI", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementation")
          map_lsp_fn("gt", require("telescope.builtin").lsp_type_definitions, "[G]oto [T]ype")
          map_lsp_fn("<leader>do", require("telescope.builtin").lsp_document_symbols, "[D]ocument [O]Symbols")
          map_lsp_fn(
            "<leader>ws",
            require("telescope.builtin").lsp_dynamic_workspace_symbols,
            "[W]orkspace [S]ymbols"
          )
          map_lsp_fn("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
          map_lsp_fn("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")
          map_lsp_fn("K", vim.lsp.buf.hover, "Hover Documentation")
        end,
      })

      -- LSP servers and clients are able to communicate to each other what features they support.
      -- By default, Neovim doesn't support everything that is in the LSP specification.
      -- When you add nvim-cmp, luasnip, etc. Neovim now has *more* capabilities.
      -- So, we create new capabilities with nvim cmp, and then broadcast that to the servers.
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())

      local servers = {
        lua_ls = {
          settings = {
            Lua = {
              completion = {
                callSnippet = "Replace",
              },
            },
          },
        },
      }

      require("mason").setup()

      local ensure_installed = vim.tbl_keys(servers or {})
      vim.list_extend(ensure_installed, {
        "stylua", -- Used to format Lua code
      })
      require("mason-tool-installer").setup({ ensure_installed = ensure_installed })
      require("mason-lspconfig").setup({
        handlers = {
          function(server_name)
            local server = servers[server_name] or {}
            -- This handles overriding only values explicitly passed
            -- by the server configuration above. Useful when disabling
            -- certain features of an LSP (for example, turning off formatting for tsserver)
            server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
            require("lspconfig")[server_name].setup(server)
          end,
          ["tsserver"] = function()
            require("lspconfig").tsserver.setup({
              commands = {
                OrganizeImports = {
                  function()
                    vim.lsp.buf.execute_command({
                      command = "_typescript.organizeImports",
                      arguments = { vim.api.nvim_buf_get_name(0) },
                      title = "",
                    })
                  end,
                  description = "Organize Imports",
                },
              },
            })
          end,
        },
      })
    end,
  },
  { -- Autoformat
    "stevearc/conform.nvim",
    lazy = false,
    keys = {
      {
        "<leader>f",
        function()
          require("conform").format({ async = true, lsp_fallback = true })
        end,
        mode = "",
        desc = "[F]ormat buffer",
      },
    },
    opts = {
      notify_on_error = false,
      format_on_save = false,
      formatters_by_ft = {
        lua = { "stylua" },
      },
    },
  },

  { -- Autocompletion
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      { -- Snippet Engine & its associated nvim-cmp source
        "L3MON4D3/LuaSnip",
        build = (function()
          -- Build Step is needed for regex support in snippets.
          -- This step is not supported in many windows environments.
          -- Remove the below condition to re-enable on windows.
          if vim.fn.has("win32") == 1 or vim.fn.executable("make") == 0 then
            return
          end
          return "make install_jsregexp"
        end)(),
        dependencies = {
          { -- `friendly-snippets` contains a variety of premade snippets.
            'rafamadriz/friendly-snippets',
            config = function()
              require('luasnip.loaders.from_vscode').lazy_load()
            end,
          },
        },
      },
      "saadparwaiz1/cmp_luasnip",
      -- Adds other completion capabilities.
      -- nvim-cmp does not ship with all sources by default. They are split
      -- into multiple repos for maintenance purposes.
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-path",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      luasnip.config.setup({})

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        completion = { 
          completeopt = "menu,menuone,noinsert"
        },

        mapping = cmp.mapping.preset.insert({
          -- Select the [n]ext item
          ["<C-n>"] = cmp.mapping.select_next_item(),
          -- Select the [p]revious item
          ["<C-p>"] = cmp.mapping.select_prev_item(),
          -- Scroll the documentation window [b]ack / [f]orward
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),

          --  This will auto-import if your LSP supports it.
          --  This will expand snippets if the LSP sent a snippet.
          ["<Tab>"] = cmp.mapping.confirm({ select = true }),

          ["<C-j>"] = cmp.mapping(function()
            if luasnip.expand_or_locally_jumpable() then
              luasnip.expand_or_jump()
            end
          end, { "i", "s" }),
          ["<C-k>"] = cmp.mapping(function()
            if luasnip.locally_jumpable(-1) then
              luasnip.jump(-1)
            end
          end, { "i", "s" }),

          -- For more advanced Luasnip keymaps (e.g. selecting choice nodes, expansion) see:
          --    https://github.com/L3MON4D3/LuaSnip?tab=readme-ov-file#keymaps
        }),
        sources = {
          -- prioritize snippets. This is what vibe-coding could have been.
          -- I'm surprized that most of the programming world hasn't zeroed in on 
          -- custom snippets
          { name = "luasnip" },  
          { name = "nvim_lsp" },
          { name = "path" },
        },
      })
    end,
  },
  { 
    -- If you want to see what colorschemes are already installed, you can use `:Telescope colorscheme`.
    -- Make sure to load this before all the other start plugins.
    priority = 1000,
    -- Having all colourschemes enabled seems to not work
    -- "folke/tokyonight.nvim",
    -- "andreasvc/vim-256noir",
    'datsfilipe/vesper.nvim',
    -- "ntk148v/komau.vim",
    -- "jaredgorski/Mies.vim",
    init = function()
      -- Load the colorscheme here.
      -- Like many other themes, this one has different styles, and you could load
      -- any other, such as 'tokyonight-storm', 'tokyonight-moon', or 'tokyonight-day'.
      -- vim.cmd.colorscheme("tokyonight-moon")
      require("vesper").setup({
        transparent = false, -- Boolean: Sets the background to transparent
        italics = {
          comments = true, -- Boolean: Italicizes comments
          keywords = false, -- Boolean: Italicizes keywords
          functions = false, -- Boolean: Italicizes functions
          strings = false,   -- Boolean: Italicizes strings
          variables = false, -- Boolean: Italicizes variables
        },
        overrides = {
          Comment = { fg = "#8EB7FF", italic = false },
        },
        palette_overrides = {}
      })
      vim.cmd.colorscheme("vesper")
      -- vim.cmd.colorscheme("Mies")
      -- vim.opt.background = "light"
      -- vim.cmd.colorscheme("binary")
      -- vim.cmd.hi("Identifier gui=none")
    end,
  },
  { -- Collection of various small independent plugins/modules
    "echasnovski/mini.nvim",
    config = function()
      -- Better Around/Inside textobjects
      require("mini.ai").setup({ n_lines = 500 })

      -- Add/delete/replace surroundings (brackets, quotes, etc.)
      --
      -- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
      -- - sd'   - [S]urround [D]elete [']quotes
      -- - sr)'  - [S]urround [R]eplace [)] [']
      require("mini.surround").setup()

      -- Simple and easy statusline.
      local statusline = require("mini.statusline")
      statusline.setup({ use_icons = vim.g.have_nerd_font })
      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_location = function()
        return "%2l:%-2v"
      end

      -- Allows moving the selection with Alt + hjkl, epic
      require("mini.move").setup()   

      -- gS to toggle all arguments on a single line, or one argument per line.
      require("mini.splitjoin").setup()   

      -- Finally, alignment. gas=
      require("mini.align").setup()   

      -- TODO highlights.
      local hipatterns = require("mini.hipatterns")
      hipatterns.setup({
        highlighters = {
          -- Highlight standalone 'FIXME', 'HACK', 'TODO', 'NOTE'
          fixme = { pattern = '%f[%w]()FIXME()%f[%W]', group = 'MiniHipatternsFixme' },
          hack  = { pattern = '%f[%w]()HACK()%f[%W]',  group = 'MiniHipatternsHack'  },
          todo  = { pattern = '%f[%w]()TODO()%f[%W]',  group = 'MiniHipatternsTodo'  },
          note  = { pattern = '%f[%w]()NOTE()%f[%W]',  group = 'MiniHipatternsNote'  },

          -- Highlight hex color strings (`#rrggbb`) using that color
          hex_color = hipatterns.gen_highlighter.hex_color(),
        },
      })
    end,
  },
  { -- Highlight, edit, and navigate code
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    opts = {
      ensure_installed = { "bash", "c", "html", "lua", "luadoc", "markdown", "vim", "vimdoc", "odin" },
      -- Autoinstall languages that are not installed
      auto_install = true,
      highlight = {
        enable = true,
        -- Some languages depend on vim's regex highlighting system (such as Ruby) for indent rules.
        --  If you are experiencing weird indenting issues, add the language to
        --  the list of additional_vim_regex_highlighting and disabled languages for indent.
        additional_vim_regex_highlighting = { "ruby" },
      },
      indent = { enable = true, disable = { "ruby" } },
    },
    config = function(_, opts)
      ---@diagnostic disable-next-line: missing-fields
      require("nvim-treesitter.configs").setup(opts)
    end,
  },
},
  -- NOTE: The import below can automatically add your own plugins, configuration, etc from `lua/custom/plugins/*.lua`
  --    This is the easiest way to modularize your config.
  --
  --  Uncomment the following line and add your plugins to `lua/custom/plugins/*.lua` to get going.
  --    For additional information, see `:help lazy.nvim-lazy.nvim-structuring-your-plugins`
  -- { import = 'custom.plugins' },
 {
    ui = {
        -- If you are using a Nerd Font: set icons to an empty table which will use the
        -- default lazy.nvim defined Nerd Font icons, otherwise define a unicode icons table
        icons = vim.g.have_nerd_font and {} or {
            cmd     = "⌘",
            config  = "🛠",
            event   = "📅",
            ft      = "📂",
            init    = "⚙",
            keys    = "🗝",
            plugin  = "🔌",
            runtime = "💻",
            require = "🌙",
            source  = "📄",
            start   = "🚀",
            task    = "📌",
            lazy    = "💤 ",
        },
    },
})

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
