local floatwindow = require("floatwindow")

local M = {}

local state = {
  streak = 0,
  correct_words = 0,
  wrong_words = 0,
  current_word = 1, -- All words
  total_words = 1, -- All words
  words = 20, -- All words
  text = {},
  start_timer = 0,
  end_timer = 0,
  wpm = 0,
  text_start = "",
  window_config = {
    background = {
      floating = {
        buf = -1,
        win = -1,
      },
    },
    header = {
      floating = {
        buf = -1,
        win = -1,
      },
    },
    challenge = {
      floating = {
        buf = -1,
        win = -1,
      },
    },
    input = {
      floating = {
        buf = -1,
        win = -1,
      },
    },
    footer = {
      floating = {
        buf = -1,
        win = -1,
      },
    },
  },
}

local random_words = {
  "apple",
  "banana",
  "cherry",
  "date",
  "elderberry",
  "fig",
  "grape",
  "honeydew",
  "kiwi",
  "lemon",
  "mango",
  "nectarine",
  "orange",
  "car",
  "bike",
  "house",
  "tree",
  "flower",
  "computer",
  "book",
  "pen",
  "pencil",
  "paper",
  "scissors",
  "stapler",
  "ruler",
  "eraser",
  "crayon",
  "marker",
  "paint",
  "and",
  "the",
  "a",
  "on",
  "in",
  "to",
  "of",
  "is",
  "are",
  "for",
  "run",
  "jump",
  "walk",
  "talk",
  "sing",
  "dance",
  "read",
  "write",
  "eat",
  "sleep",
}

local create_window_config = function()
  local win_width = vim.o.columns
  local win_height = vim.o.lines

  local float_width = math.floor(win_width * 0.6)
  local float_height = math.floor(win_height * 0.6)

  local row = math.floor((win_height - float_height) / 2)
  local col = math.floor((win_width - float_width) / 2)

  local header_height = 2
  local footer_height = 1
  local challenge_height = math.floor((float_height - header_height - footer_height + 3) / 2)
  local input_height = challenge_height - 5 - 1 - 3

  return {
    background = {
      floating = {
        buf = -1,
        win = -1,
      },
      opts = {
        relative = "editor",
        style = "minimal",
        zindex = 1,
        width = float_width,
        height = float_height,
        col = col,
        row = row,
        border = "rounded",
      },
      enter = false,
    },
    header = {
      floating = {
        buf = -1,
        win = -1,
      },
      opts = {
        relative = "editor",
        style = "minimal",
        zindex = 4,
        width = float_width - 2,
        height = header_height,
        col = col + 1,
        row = row + 1,
        border = { " ", " ", " ", " ", " ", " ", " ", " " },
      },
      enter = false,
    },
    challenge = {
      floating = {
        buf = -1,
        win = -1,
      },
      opts = {
        relative = "editor",
        style = "minimal",
        zindex = 3,
        width = float_width - 20,
        height = challenge_height - 1,
        col = col + 9,
        row = row + 5,
        border = { " ", " ", " ", " ", " ", " ", " ", " " },
      },
      enter = false,
    },
    input = {
      floating = {
        buf = -1,
        win = -1,
      },
      opts = {
        relative = "editor",
        style = "minimal",
        zindex = 3,
        width = float_width - 20,
        height = input_height - 2,
        col = col + 9,
        row = row + challenge_height + 6,
        border = { " ", " ", " ", " ", " ", " ", " ", "" },
      },
    },
    footer = {
      floating = {
        buf = -1,
        win = -1,
      },
      opts = {
        relative = "editor",
        style = "minimal",
        zindex = 4,
        width = float_width,
        height = footer_height,
        col = col + 1,
        row = row + float_height,
        border = "none",
      },
      enter = false,
    },
  }
end

local function generate_random_text(word_count)
  local text = {}
  state.text = {}

  for _ = 1, word_count do
    local random_index = math.random(1, #random_words)
    table.insert(text, random_words[random_index])
    table.insert(state.text, random_words[random_index])

    table.insert(text, " ")
  end
  return table.concat(text, "")
end

local set_content = function(text)
  local size = 0
  for i = 1, state.current_word do
    size = size + state.text[i]:len() + 1
  end

  local text_end = ""
  if state.current_word < state.words then
    text_end = text:sub(size, text:len())
  end

  text = state.text_start .. "`" .. state.text[state.current_word] .. "`" .. text_end

  local lines = vim.split(text, "\n")

  local footer = string.format(
    "  Current Word: %s   |   WPM:  %d   | Words Stats //  ✔ %d / ✘ %d / 🔥  %d",
    state.text[state.current_word],
    state.wpm,
    state.correct_words,
    state.wrong_words,
    state.streak
  )

  vim.api.nvim_buf_set_lines(state.window_config.footer.floating.buf, 0, -1, false, { footer })

  vim.api.nvim_buf_set_lines(state.window_config.input.floating.buf, 0, -1, true, {})

  vim.api.nvim_buf_set_lines(state.window_config.challenge.floating.buf, 0, -1, true, {})
  vim.api.nvim_buf_set_lines(state.window_config.challenge.floating.buf, 0, -1, true, lines)
end

local foreach_float = function(callback)
  for name, float in pairs(state.window_config) do
    callback(name, float)
  end
end

local exit_window = function()
  foreach_float(function(_, float)
    pcall(vim.api.nvim_win_close, float.floating.win, true)
  end)
end

local create_remaps = function()
  vim.keymap.set("n", "<ESC><ESC>", function()
    vim.api.nvim_win_close(state.window_config.input.floating.win, true)
  end, {
    buffer = state.window_config.input.floating.buf,
  })

  vim.api.nvim_create_autocmd("BufLeave", {
    buffer = state.window_config.input.floating.buf,
    callback = function()
      exit_window()
    end,
  })

  vim.api.nvim_create_autocmd("VimResized", {
    group = vim.api.nvim_create_augroup("present-resized", {}),
    callback = function()
      if
        not vim.api.nvim_win_is_valid(state.window_config.input.floating.win)
        or state.window_config.input.floating.win == nil
      then
        return
      end

      local updated = create_window_config()

      foreach_float(function(name, float)
        float.opts = updated[name].opts
        vim.api.nvim_win_set_config(float.floating.win, updated[name].opts)
      end)

      set_content()
    end,
  })
end

local start_type = function()
  math.randomseed(os.time())

  state.current_word = 1
  state.total_words = 1
  state.start_timer = os.time()

  local text = generate_random_text(state.words)

  state.window_config = create_window_config()

  foreach_float(function(_, float)
    float.floating = floatwindow.create_floating_window(float)
  end)

  local title_text = "Type Challenge"
  local padding = string.rep(" ", (state.window_config.header.opts.width - #title_text) / 2)
  local title = padding .. title_text

  vim.api.nvim_buf_set_lines(state.window_config.header.floating.buf, 0, -1, false, { title })

  vim.bo[state.window_config.challenge.floating.buf].filetype = "markdown"

  set_content(text)

  create_remaps()

  vim.keymap.set("n", "<bs>", function()
    if state.current_word > 1 then
      state.current_word = state.current_word - 1

      local footer = string.format(
        "  Current Word: %s   |   WPM:  %d   | Words Stats //  ✔ %d / ✘ %d / 🔥  %d",
        state.text[state.current_word],
        state.wpm,
        state.correct_words,
        state.wrong_words,
        state.streak
      )
      vim.api.nvim_buf_set_lines(state.window_config.footer.floating.buf, 0, -1, false, { footer })
      set_content(text)
    end
  end, { buffer = state.window_config.input.floating.buf })

  vim.keymap.set("i", "<space>", function()
    local answear = vim.api.nvim_buf_get_lines(state.window_config.input.floating.buf, 0, -1, true)

    local answear_word = answear[1]
    local target_word = state.text[state.current_word]

    state.end_timer = os.time()

    state.wpm = state.total_words / (state.end_timer - state.start_timer) * 60

    if answear_word == target_word then
      state.streak = state.streak + 1
      state.correct_words = state.correct_words + 1
    else
      state.streak = 0
      state.wrong_words = state.wrong_words + 1
    end

    if state.current_word >= state.words then
      state.current_word = 1

      state.total_words = 1
      state.start_timer = os.time()

      text = generate_random_text(state.words)
      set_content(text)
      return
    end

    state.current_word = state.current_word + 1
    state.total_words = state.total_words + 1

    vim.api.nvim_buf_set_lines(state.window_config.input.floating.buf, 0, -1, true, {})

    local footer = string.format(
      "  Current Word: %s   |   WPM:  %d   | Words Stats //  ✔ %d / ✘ %d / 🔥  %d",
      state.text[state.current_word],
      state.wpm,
      state.correct_words,
      state.wrong_words,
      state.streak
    )
    vim.api.nvim_buf_set_lines(state.window_config.footer.floating.buf, 0, -1, false, { footer })

    set_content(text)
  end, { buffer = state.window_config.input.floating.buf })
end

vim.api.nvim_create_user_command("Type", function()
  start_type()
end, {})

---@class setup.Opts
---@field words integer: Set challenge size. Default 20

---Setup type plugin
---@param opts setup.Opts
M.setup = function(opts)
  state.words = opts.words or state.words
end

return M
