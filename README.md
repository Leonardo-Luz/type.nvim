# type.nvim

*A Neovim Plugin for Typing Practice*

## **Features:**

* Tracks typing speed and statistics.
* Provides a dedicated interface for practice.

## **Dependencies:**

* `leonardo-luz/floatwindow`

## **Installation:**  Add `leonardo-luz/type.nvim` to your Neovim plugin manager (e.g., `init.lua` or `plugins/type.lua`).

```lua
{ 
    'leonardo-luz/type.nvim',
    opts = {
        --- Quantity of words that are used for each practice. default: 20
        words = 20,
    },
}
```

* To use custom words instead of the defaults, create a `words.json` file in your Neovim configuration directory (e.g., `~/.config/nvim/json/words.json`) and add your desired words.

## **Usage:**

* Start practicing with the command `:Type`.
    * insert mode, `<bs>`: Back over a word.
    * insert mode, `<space>` or `enter`: Advance to the next word.
    * normal mode, `<leader>r`: Reset
