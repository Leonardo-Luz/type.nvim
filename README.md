## type.nvim

*A Neovim Plugin for Typing Practice*

**Features:**

* Tracks typing speed and statistics.
* Provides a dedicated interface for practice.

**Dependencies:**

* `leonardo-luz/floatwindow`

**Installation:**  Add `leonardo-luz/type.nvim` to your Neovim plugin manager (e.g., `init.lua` or `plugins/type.lua`).

```lua
{ 
    'leonardo-luz/type.nvim',
    opts = {},
    -- OR
    opts = {
        words = 20,
    },
}
```

**Usage:**

* Start practicing with the command `:Type`.
    * `<bs>`: Back over a word.
    * `<space>`: Advance to the next word.
