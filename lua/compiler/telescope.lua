--- ### Frontend for compiler.nvim

local M = {}

function M.show()
  -- If working directory is home, don't open telescope.
  if vim.loop.os_homedir() == vim.loop.cwd() then
    vim.notify("You must :cd your project dir first.\nHome is not allowed as working dir.", vim.log.levels.WARN, {
      title = "Compiler.nvim"
    })
    return
  end

  -- Dependencies
  local conf = require("telescope.config").values
  local actions = require "telescope.actions"
  local state = require "telescope.actions.state"
  local pickers = require "telescope.pickers"
  local finders = require "telescope.finders"
  local utils = require("compiler.utils")

  local buffer = vim.api.nvim_get_current_buf()
  local filetype = vim.api.nvim_buf_get_option(buffer, "filetype")

  -- Programatically require the backend for the current language.
  -- On unsupported languages, allow "Run Makefile".
  local language = utils.require_language(filetype)
  if not language then language = require("compiler.languages.make") end

  --- On option selected → Run action depending of the language
  local function on_option_selected(prompt_bufnr)
    actions.close(prompt_bufnr) -- Close Telescope on selection
    local selection = state.get_selected_entry()
    if selection.value == "" then return end -- Ignore separators
    _G.compiler_redo = selection.value       -- Save redo
    _G.compiler_redo_filetype = filetype     -- Save redo
    if selection then language.action(selection.value) end
  end

  --- Show telescope
  local function open_telescope()
    pickers
      .new({}, {
        prompt_title = "Compiler",
        results_title = "Options",
        finder = finders.new_table {
          results = language.options,
          entry_maker = function(entry)
            return {
              display = entry.text,
              value = entry.value,
              ordinal = entry.text,
            }
          end,
        },
        sorter = conf.generic_sorter(),
        attach_mappings = function(_, map)
          map(
            "i",
            "<CR>",
            function(prompt_bufnr) on_option_selected(prompt_bufnr) end
          )
          map(
            "n",
            "<CR>",
            function(prompt_bufnr) on_option_selected(prompt_bufnr) end
          )
          return true
        end,
      })
      :find()
  end
  open_telescope() -- Entry point
end

return M
