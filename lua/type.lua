local questionnaire = require("templates.questionnaire")
local ai = require("textgen")

local M = {}

local state = {
  streak = 0,
  correct_answears = 0,
  wrong_answears = 0,
}

M.setup_type = function()
  local text = ai.generate_text({
    prompt = "Generate a medium size text with a random size of a range of 8 to 16, with random words related to code and programming, send just the text.",
  }).generated_text

  local lines = vim.split(text, "\n")

  local footer =
    string.format("  🔥 %d   |   %d ✔ / %d ✘", state.streak, state.correct_answears, state.wrong_answears)

  vim.api.nvim_buf_set_lines(questionnaire.state.window_style.footer.floating.buf, 0, -1, false, { footer })

  vim.api.nvim_buf_set_lines(questionnaire.state.window_style.answear.floating.buf, 0, -1, true, {})
  vim.api.nvim_buf_set_lines(questionnaire.state.window_style.question.floating.buf, 0, -1, true, lines)
end

local start_type = function()
  questionnaire.state.title = "Type Test"
  questionnaire.window_setup()

  M.setup_type()

  vim.keymap.set("n", "<cr>", function()
    local answear = vim.api.nvim_buf_get_lines(questionnaire.state.window_style.answear.floating.buf, 0, -1, true)
    local question = vim.api.nvim_buf_get_lines(questionnaire.state.window_style.question.floating.buf, 0, -1, true)

    local a = table.concat(answear, "\n")
    local b = table.concat(question, "\n")

    if a == b then
      state.streak = state.streak + 1
      state.correct_answears = state.correct_answears + 1
    else
      state.streak = 0
      state.wrong_answears = state.wrong_answears + 1
    end

    M.setup_type()
  end, { buffer = questionnaire.state.window_style.answear.floating.buf })
end

vim.api.nvim_create_user_command("Type", function()
  start_type()
end, {})

return M
