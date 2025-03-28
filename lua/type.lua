local floatwindow = require("floatwindow")

local Path = require("plenary.path")

local M = {}

local state = {
  data_file = Path:new(vim.fn.stdpath("config") .. "/json", "words.json"),
  streak = 0,
  correct_words = 0,
  wrong_words = 0,
  wrong_count = 0,
  current_word = 1,
  total_words = 1,
  words = 20,
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
  "fig",
  "grape",
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
        height = 1,
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

local function read_data()
  if state.data_file:exists() then
    local file_content = state.data_file:read()
    return vim.json.decode(file_content)
  else
    return {}
  end
end

local function generate_random_text(word_count)
  local data = read_data()

  if #data > 0 then
    random_words = data
  end

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
  state.wrong_count = 0
  state.start_timer = os.time()

  local text = generate_random_text(state.words)

  state.window_config = create_window_config()

  foreach_float(function(_, float)
    float.floating = floatwindow.create_floating_window(float)
    vim.bo[float.floating.buf].filetype = "markdown"
  end)

  local title_text = "`Type Challenge`"
  local padding = "#" .. string.rep(" ", (state.window_config.header.opts.width - #title_text - 1) / 2)
  local title = padding .. title_text

  vim.api.nvim_buf_set_lines(state.window_config.header.floating.buf, 0, -1, false, { title })


  set_content(text)

  create_remaps()

  vim.keymap.set("i", "<bs>", function()
    local buf = state.window_config.input.floating.buf
    local line_count = vim.api.nvim_buf_line_count(buf)
    local is_empty = line_count == 1 and vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] == ""

    if is_empty and state.current_word > 1 then
      state.current_word = state.current_word - 1
      local footer = string.format(
        "Current Word: %s | WPM: %d | Words Stats // ✔ %d / ✘ %d / 🔥 %d",
        state.text[state.current_word],
        state.wpm,
        state.correct_words,
        state.wrong_words,
        state.streak
      )
      vim.api.nvim_buf_set_lines(state.window_config.footer.floating.buf, 0, -1, false, { footer })
      set_content(text)
    else
      local current_pos = vim.api.nvim_win_get_cursor(0)
      if current_pos[1] > 0 and not is_empty then
        vim.api.nvim_buf_set_text(buf, current_pos[1] - 1, current_pos[2] - 1, current_pos[1] - 1, current_pos[2], {})
        vim.api.nvim_win_set_cursor(0, { current_pos[1], current_pos[2] - 1 })
      end
    end
  end, { buffer = state.window_config.input.floating.buf })

  local function check_response()
    local answear = vim.api.nvim_buf_get_lines(state.window_config.input.floating.buf, 0, -1, true)

    local answear_word = answear[1]
    local target_word = state.text[state.current_word]

    state.end_timer = os.time()

    local diffCount = 0
    local len = math.min(#answear_word, #target_word)
    for i = 1, len do
      if answear_word:sub(i, i) ~= target_word:sub(i, i) then
        diffCount = diffCount + 1
      end
    end
    diffCount = diffCount + math.abs(#answear_word - #target_word)

    state.wrong_count = state.wrong_count + diffCount

    state.wpm = (state.total_words / (state.end_timer - state.start_timer) * 60) - state.wrong_count

    if state.wpm < 0 then
      state.wpm = 0
    end

    if answear_word == target_word then
      state.streak = state.streak + 1
      state.correct_words = state.correct_words + 1
    else
      state.streak = 0
      state.wrong_words = state.wrong_words + 1
    end

    if state.current_word >= state.words then
      state.current_word = 1
      state.wrong_count = 0

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
  end

  vim.keymap.set("i", "<space>", check_response, { buffer = state.window_config.input.floating.buf })
  vim.keymap.set("i", "<enter>", check_response, { buffer = state.window_config.input.floating.buf })
  vim.keymap.set("n", "<leader>r", function()
    state.current_word = 1
    state.wrong_count = 0
    state.total_words = 1
    state.correct_words = 0
    state.wrong_words = 0
    state.streak = 0
    state.wpm = 0

    state.total_words = 1
    state.start_timer = os.time()

    text = generate_random_text(state.words)
    set_content(text)
  end, { buffer = state.window_config.input.floating.buf })
end

vim.api.nvim_create_user_command("Type", function()
  if not vim.api.nvim_win_is_valid(state.window_config.input.floating.win) then
    start_type()
  else
    vim.api.nvim_win_close(state.window_config.input.floating.win, true)
  end
end, {})

---@class setup.Opts
---@field words integer: Set challenge size. Default 20

---Setup type plugin
---@param opts setup.Opts
M.setup = function(opts)
  state.words = opts.words or state.words
end

return M
