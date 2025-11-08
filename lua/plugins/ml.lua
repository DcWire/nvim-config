-- ~/.config/nvim/lua/plugins/ml.lua
-- ML/Data Science plugins for LazyVim

return {
  -- Python LSP Configuration
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- Pyright for type checking and intellisense
        pyright = {
          settings = {
            python = {
              analysis = {
                typeCheckingMode = "basic",
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
                diagnosticMode = "workspace",
              },
            },
          },
        },
        -- Ruff for fast linting
        ruff_lsp = {
          on_attach = function(client, bufnr)
            -- Disable hover in favor of Pyright
            client.server_capabilities.hoverProvider = false
          end,
        },
      },
    },
  },

  -- Enhanced Python support
  {
    "linux-cultist/venv-selector.nvim",
    dependencies = {
      "neovim/nvim-lspconfig",
      "nvim-telescope/telescope.nvim",
      "mfussenegger/nvim-dap-python",
    },
    opts = {
      name = { "venv", ".venv", "env", ".env" },
    },
    event = "VeryLazy",
    keys = {
      { "<leader>cv", "<cmd>VenvSelect<cr>", desc = "Select VirtualEnv" },
    },
  },

  -- Debugging Support (DAP)
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      -- Python adapter
      {
        "mfussenegger/nvim-dap-python",
        config = function()
          -- Update this path to your Python installation
          require("dap-python").setup("python3")
        end,
      },
      -- UI for debugging
      {
        "rcarriga/nvim-dap-ui",
        dependencies = { "nvim-neotest/nvim-nio" },
        config = function()
          local dap, dapui = require("dap"), require("dapui")
          dapui.setup()

          -- Auto open/close DAP UI
          dap.listeners.after.event_initialized["dapui_config"] = function()
            dapui.open()
          end
          dap.listeners.before.event_terminated["dapui_config"] = function()
            dapui.close()
          end
          dap.listeners.before.event_exited["dapui_config"] = function()
            dapui.close()
          end
        end,
      },
      -- Virtual text for debugging
      {
        "theHamsta/nvim-dap-virtual-text",
        opts = {},
      },
    },
    keys = {
      { "<leader>db", "<cmd>DapToggleBreakpoint<cr>", desc = "Toggle Breakpoint" },
      { "<leader>dc", "<cmd>DapContinue<cr>", desc = "Continue" },
      { "<leader>di", "<cmd>DapStepInto<cr>", desc = "Step Into" },
      { "<leader>do", "<cmd>DapStepOver<cr>", desc = "Step Over" },
      { "<leader>dO", "<cmd>DapStepOut<cr>", desc = "Step Out" },
      { "<leader>dr", "<cmd>DapToggleRepl<cr>", desc = "Toggle REPL" },
      { "<leader>dl", "<cmd>DapShowLog<cr>", desc = "Show Log" },
      { "<leader>dt", "<cmd>DapTerminate<cr>", desc = "Terminate" },
      {
        "<leader>du",
        function()
          require("dapui").toggle()
        end,
        desc = "Toggle DAP UI",
      },
    },
  },

  -- Jupyter/Notebook support with Jupytext
  {
    "GCBallesteros/jupytext.nvim",
    config = function()
      require("jupytext").setup({
        style = "percent",
        output_extension = "auto",
        force_ft = nil,
      })
    end,
    lazy = false,
  },
  -- Molten: Jupyter notebooks in Neovim with inline output
  {
    "benlubas/molten-nvim",
    version = "^1.0.0",
    build = ":UpdateRemotePlugins",
    dependencies = { "3rd/image.nvim" },
    lazy = false, -- Add this to ensure it loads
    init = function()
      -- Settings
      vim.g.molten_output_win_max_height = 20
      vim.g.molten_auto_open_output = false
      vim.g.molten_image_provider = "image.nvim"
      vim.g.molten_wrap_output = true
      vim.g.molten_virt_text_output = true
      vim.g.molten_virt_lines_off_by_1 = true
    end,
    keys = {
      { "<leader>mi", "<cmd>MoltenInit<cr>", desc = "Initialize Molten" },
      { "<leader>me", "<cmd>MoltenEvaluateOperator<cr>", desc = "Evaluate operator", mode = "n" },
      { "<leader>ml", "<cmd>MoltenEvaluateLine<cr>", desc = "Evaluate line" },
      { "<leader>mr", "<cmd>MoltenReevaluateCell<cr>", desc = "Re-evaluate cell" },
      { "<leader>mv", ":<C-u>MoltenEvaluateVisual<cr>gv", desc = "Evaluate visual", mode = "v" },
      { "<leader>md", "<cmd>MoltenDelete<cr>", desc = "Delete Molten cell" },
      { "<leader>mo", "<cmd>MoltenShowOutput<cr>", desc = "Show output" },
      { "<leader>mh", "<cmd>MoltenHideOutput<cr>", desc = "Hide output" },
      { "[c", "<cmd>MoltenPrev<cr>", desc = "Previous cell" },
      { "]c", "<cmd>MoltenNext<cr>", desc = "Next cell" },
    },
  }, -- Image support for inline plots
  {
    "3rd/image.nvim",
    opts = {
      backend = "kitty",
      integrations = {
        markdown = {
          enabled = true,
          clear_in_insert_mode = false,
          download_remote_images = true,
          only_render_image_at_cursor = false,
        },
      },
      max_width = 100,
      max_height = 12,
      max_height_window_percentage = math.huge,
      max_width_window_percentage = math.huge,
      window_overlap_clear_enabled = true,
      window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },
    },
  },

  -- Interactive REPL (iron.nvim)
  {
    "Vigemus/iron.nvim",
    keys = {
      { "<leader>rs", "<cmd>IronRepl<cr>", desc = "Start REPL" },
      { "<leader>rr", "<cmd>IronRestart<cr>", desc = "Restart REPL" },
      { "<leader>rf", "<cmd>IronFocus<cr>", desc = "Focus REPL" },
      { "<leader>rh", "<cmd>IronHide<cr>", desc = "Hide REPL" },
    },
    config = function()
      local iron = require("iron.core")
      iron.setup({
        config = {
          scratch_repl = true,
          repl_definition = {
            python = {
              command = { "ipython", "--no-autoindent" },
              format = require("iron.fts.common").bracketed_paste_python,
            },
          },
          repl_open_cmd = require("iron.view").split.vertical.botright(60),
        },
        keymaps = {
          send_motion = "<space>sc",
          visual_send = "<space>sc",
          send_line = "<space>sl",
          send_paragraph = "<space>sp",
          send_until_cursor = "<space>su",
          send_mark = "<space>sm",
          mark_motion = "<space>mc",
          mark_visual = "<space>mc",
          remove_mark = "<space>md",
          cr = "<space>s<cr>",
          interrupt = "<space>s<space>",
          exit = "<space>sq",
          clear = "<space>cl",
        },
        highlight = {
          italic = true,
        },
        ignore_blank_lines = true,
      })

      vim.keymap.set("v", "<space>sc", function()
        require("iron.core").visual_send()
      end, { desc = "Send to REPL" })

      vim.keymap.set("n", "<space>sl", function()
        require("iron.core").send_line()
      end, { desc = "Send line to REPL" })
    end,
  },

  -- Better syntax highlighting for data files
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        vim.list_extend(opts.ensure_installed, {
          "python",
          "ninja",
          "rst",
          "toml",
          "json",
          "yaml",
          "csv",
        })
      end
    end,
  },

  -- Markdown preview for documentation
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown" },
    build = "cd app && npm install",
    keys = {
      { "<leader>mp", "<cmd>MarkdownPreviewToggle<cr>", desc = "Markdown Preview" },
    },
  }, -- CSV support
  {
    "chrisbra/csv.vim",
    ft = "csv",
  },

  -- Git integration improvements
  {
    "kdheepak/lazygit.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    keys = {
      { "<leader>gg", "<cmd>LazyGit<cr>", desc = "LazyGit" },
    },
  },

  -- Test runner for Python
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "antoinemadec/FixCursorHold.nvim",
      "nvim-treesitter/nvim-treesitter",
      "nvim-neotest/neotest-python",
    },
    opts = {
      adapters = {
        ["neotest-python"] = {
          dap = { justMyCode = false },
          runner = "pytest",
        },
      },
    },
    keys = {
      {
        "<leader>tt",
        function()
          require("neotest").run.run()
        end,
        desc = "Run nearest test",
      },
      {
        "<leader>tf",
        function()
          require("neotest").run.run(vim.fn.expand("%"))
        end,
        desc = "Run file tests",
      },
      {
        "<leader>td",
        function()
          require("neotest").run.run({ strategy = "dap" })
        end,
        desc = "Debug nearest test",
      },
      {
        "<leader>ts",
        function()
          require("neotest").summary.toggle()
        end,
        desc = "Toggle summary",
      },
      {
        "<leader>to",
        function()
          require("neotest").output.open({ enter = true })
        end,
        desc = "Show output",
      },
    },
  },

  -- AI assistance (optional - requires API key)
  -- Uncomment if you want to use AI completion
  -- {
  --   "github/copilot.vim",
  -- },
}
