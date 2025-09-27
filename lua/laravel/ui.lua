-- UI utilities for Laravel.nvim with snacks.nvim integration
local M = {}

-- Enhanced picker/select - just use vim.ui.select (snacks will override if enabled)
function M.select(items, opts, on_choice)
    opts = opts or {}

    -- Format items if they are tables
    local formatted_items = {}
    local item_map = {}

    for i, item in ipairs(items) do
        local display_item
        if type(item) == 'table' then
            display_item = item.name or item.label or tostring(item)
            item_map[display_item] = item
        else
            display_item = tostring(item)
            item_map[display_item] = item
        end
        formatted_items[i] = display_item
    end

    -- Use vim.ui.select (snacks.nvim will enhance this if picker module is enabled)
    vim.ui.select(formatted_items, {
        prompt = opts.prompt or 'Select item:',
        format_item = function(item)
            return item
        end,
    }, function(choice)
        if choice and on_choice then
            on_choice(item_map[choice])
        end
    end)
end

-- Input dialog with validation - just use vim.ui.input (snacks will override if enabled)
function M.input(opts, on_confirm)
    opts = opts or {}

    vim.ui.input({
        prompt = opts.prompt or 'Enter value: ',
        default = opts.default,
        completion = opts.completion,
    }, function(input)
        if input then
            -- Validate input if validator provided
            if opts.validate then
                local is_valid, error_msg = opts.validate(input)
                if not is_valid then
                    M.error(error_msg or 'Invalid input')
                    return
                end
            end

            if on_confirm then
                on_confirm(input)
            end
        end
    end)
end

-- Show notification - just use vim.notify (snacks will override if notifier module is enabled)
function M.notify(message, level, opts)
    level = level or vim.log.levels.INFO
    opts = opts or {}

    vim.notify(message, level, {
        title = opts.title or 'Laravel.nvim',
        timeout = opts.timeout,
    })
end

-- Show info message
function M.info(message, opts)
    M.notify(message, vim.log.levels.INFO, opts)
end

-- Show warning message
function M.warn(message, opts)
    M.notify(message, vim.log.levels.WARN, opts)
end

-- Show error message
function M.error(message, opts)
    M.notify(message, vim.log.levels.ERROR, opts)
end

-- Create a floating window (enhanced with snacks.nvim if available)
function M.create_float(opts)
    opts = opts or {}

    -- Check if user wants snacks.nvim enhancement and it's available
    local use_snacks = opts.use_snacks ~= false -- default to true unless explicitly disabled
    local has_snacks, snacks = pcall(require, 'snacks')

    if use_snacks and has_snacks and snacks.win then
        local width = opts.width or math.floor(vim.o.columns * 0.8)
        local height = opts.height or math.floor(vim.o.lines * 0.8)

        local buf = vim.api.nvim_create_buf(false, true)

        -- Set buffer options
        vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
        vim.api.nvim_buf_set_option(buf, 'filetype', opts.filetype or 'text')

        -- Set content if provided
        if opts.content then
            local lines = type(opts.content) == 'table' and opts.content or { opts.content }
            vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
        end

        local win = snacks.win({
            buf = buf,
            width = width,
            height = height,
            border = opts.border or 'rounded',
            title = opts.title,
            title_pos = 'center',
            enter = true,
            backdrop = opts.backdrop ~= false, -- default to true unless explicitly disabled
        })

        return {
            buf = buf,
            win = win.win,
            close = function() win:close() end,
        }
    else
        -- Standard floating window creation
        local width = opts.width or math.floor(vim.o.columns * 0.8)
        local height = opts.height or math.floor(vim.o.lines * 0.8)

        -- Calculate position
        local row = math.floor((vim.o.lines - height) / 2)
        local col = math.floor((vim.o.columns - width) / 2)

        -- Create buffer
        local buf = vim.api.nvim_create_buf(false, true)

        -- Set buffer options
        vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
        vim.api.nvim_buf_set_option(buf, 'filetype', opts.filetype or 'text')

        -- Create window
        local win = vim.api.nvim_open_win(buf, true, {
            relative = 'editor',
            width = width,
            height = height,
            row = row,
            col = col,
            style = 'minimal',
            border = opts.border or 'rounded',
            title = opts.title,
            title_pos = 'center',
        })

        -- Set window options
        vim.api.nvim_win_set_option(win, 'winhl', 'Normal:Normal,FloatBorder:FloatBorder')

        -- Set content if provided
        if opts.content then
            local lines = type(opts.content) == 'table' and opts.content or { opts.content }
            vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
        end

        -- Set up keymaps for closing
        local function close()
            if vim.api.nvim_win_is_valid(win) then
                vim.api.nvim_win_close(win, true)
            end
        end

        vim.keymap.set('n', 'q', close, { buffer = buf, silent = true })
        vim.keymap.set('n', '<Esc>', close, { buffer = buf, silent = true })

        return {
            buf = buf,
            win = win,
            close = close,
        }
    end
end

-- Show content in a floating window
function M.show_float(content, opts)
    opts = opts or {}
    opts.content = content

    return M.create_float(opts)
end

-- Terminal function - explicitly use snacks.nvim if requested
function M.terminal(cmd, opts)
    opts = opts or {}

    -- Only use snacks terminal if explicitly requested and available
    if opts.use_snacks and pcall(require, 'snacks') then
        local snacks = require('snacks')
        if snacks.terminal then
            snacks.terminal(cmd, opts)
            return
        end
    end

    -- Fallback to standard terminal
    vim.cmd('split')
    vim.cmd('terminal ' .. cmd)
end

return M
