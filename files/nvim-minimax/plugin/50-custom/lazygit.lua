-- Lazygit in a floating terminal, bound to `<Leader>gg` (LazyVim parity —
-- there it's `Snacks.lazygit.open()` on the same key). No plugin needed:
-- `lazygit` is already on PATH (pkgs/base.nix), so this is just Neovim's
-- own floating-window + terminal-job APIs, following the same "one reusable
-- buffer, not a fresh process every time" philosophy as
-- '45_keymaps_extra.lua's `<C-/>` toggle terminal — closing the float
-- leaves lazygit running in the background, so reopening lands back on
-- whatever panel/state it was in, not a cold start.
Config.later(function()
  if vim.fn.executable('lazygit') ~= 1 then return end

  local buf, win

  local function is_buf_alive(b)
    if not (b and vim.api.nvim_buf_is_valid(b)) then return false end
    local channel = vim.bo[b].channel
    return type(channel) == 'number' and channel > 0 and pcall(vim.fn.jobpid, channel)
  end

  local function open_float(b)
    local width = math.floor(vim.o.columns * 0.9)
    local height = math.floor(vim.o.lines * 0.9)
    return vim.api.nvim_open_win(b, true, {
      relative = 'editor',
      width = width,
      height = height,
      row = math.floor((vim.o.lines - height) / 2),
      col = math.floor((vim.o.columns - width) / 2),
      style = 'minimal',
      border = 'rounded',
    })
  end

  local function lazygit_toggle()
    -- Already open: hide it (lazygit keeps running in the background).
    if win and vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, false)
      win = nil
      return
    end

    -- Hidden but still alive: reopen the same session.
    if is_buf_alive(buf) then
      win = open_float(buf)
      vim.cmd('startinsert')
      return
    end

    -- No live session: start a fresh one. `:terminal` always creates a new
    -- buffer in the current window, so open the float on a throwaway
    -- scratch buffer first, then let `:terminal` replace it there.
    win = open_float(vim.api.nvim_create_buf(false, true))
    vim.cmd('terminal lazygit')
    buf = vim.api.nvim_get_current_buf()
    vim.bo[buf].buflisted = false
    -- Quitting lazygit itself (its own `q`) should close the float too,
    -- rather than leaving a "[Process exited 0]" window behind.
    vim.api.nvim_create_autocmd('TermClose', {
      buffer = buf,
      once = true,
      callback = function()
        if win and vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
        win, buf = nil, nil
      end,
    })
    vim.cmd('startinsert')
  end

  vim.keymap.set('n', '<Leader>gg', lazygit_toggle, { desc = 'Lazygit' })
end)
