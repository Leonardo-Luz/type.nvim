local questionnaire = require("templates.questionnaire")

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

local function generate_random_text(word_count)
  local text = {}
  for i = 1, word_count do
    local random_index = math.random(1, #random_words)
    table.insert(text, random_words[random_index])
    table.insert(state.text, random_words[random_index])

    if i % 10 == 0 then
      table.insert(text, "\n")
    else
      table.insert(text, " ")
    end
  end
  return table.concat(text, "")
end

local setup_type = function()
  state.text = {}

  local text = generate_random_text(state.words)

  local lines = vim.split(text, "\n")

  local footer = string.format(
    "  current word: %s   |   wpm  %d   |   ✔ %d / ✘ %d   |   🔥  %d  ",
    state.text[state.current_word],
    state.wpm,
    state.correct_words,
    state.wrong_words,
    state.streak
  )

  vim.api.nvim_buf_set_lines(questionnaire.state.window_style.footer.floating.buf, 0, -1, false, { footer })

  vim.api.nvim_buf_set_lines(questionnaire.state.window_style.answear.floating.buf, 0, -1, true, {})

  vim.api.nvim_buf_set_lines(questionnaire.state.window_style.question.floating.buf, 0, -1, true, {})
  vim.api.nvim_buf_set_lines(questionnaire.state.window_style.question.floating.buf, 0, -1, true, lines)
end

local start_type = function()
  math.randomseed(os.time())

  state.start_timer = os.time()

  questionnaire.state.title = "Type Test"
  questionnaire.window_setup()

  setup_type()

  vim.keymap.set("n", "<bs>", function()
    if state.current_word > 1 then
      state.current_word = state.current_word - 1

      local footer = string.format(
        "  current word: %s   |   wpm  %d   |   ✔ %d / ✘ %d   |   🔥  %d  ",
        state.text[state.current_word],
        state.wpm,
        state.correct_words,
        state.wrong_words,
        state.streak
      )
      vim.api.nvim_buf_set_lines(questionnaire.state.window_style.footer.floating.buf, 0, -1, false, { footer })
    end
  end, { buffer = questionnaire.state.window_style.answear.floating.buf })

  vim.keymap.set("i", "<space>", function()
    local answear = vim.api.nvim_buf_get_lines(questionnaire.state.window_style.answear.floating.buf, 0, -1, true)

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
      setup_type()
      return
    end

    state.current_word = state.current_word + 1
    state.total_words = state.total_words + 1

    vim.api.nvim_buf_set_lines(questionnaire.state.window_style.answear.floating.buf, 0, -1, true, {})

    local footer = string.format(
      "  current word: %s   |   wpm  %d   |   ✔ %d / ✘ %d   |   🔥  %d  ",
      state.text[state.current_word],
      state.wpm,
      state.correct_words,
      state.wrong_words,
      state.streak
    )
    vim.api.nvim_buf_set_lines(questionnaire.state.window_style.footer.floating.buf, 0, -1, false, { footer })
  end, { buffer = questionnaire.state.window_style.answear.floating.buf })
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
