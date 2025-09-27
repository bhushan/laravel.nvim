-- Job utility for running async commands with optional snacks.nvim integration
local M = {}

-- Run a command asynchronously
function M.run(cmd, opts)
    opts = opts or {}

    -- Use snacks.nvim terminal if explicitly requested and available
    if opts.interactive and opts.use_snacks then
        local has_snacks, snacks = pcall(require, 'snacks')
        if has_snacks and snacks.terminal then
            snacks.terminal(cmd, {
                cwd = opts.cwd,
                env = opts.env,
                win = opts.win_opts,
            })
            return nil
        end
    end

    local output = {}
    local error_output = {}

    local function on_stdout(_, data)
        if data then
            for _, line in ipairs(data) do
                if line ~= '' then
                    table.insert(output, line)
                end
            end
        end
    end

    local function on_stderr(_, data)
        if data then
            for _, line in ipairs(data) do
                if line ~= '' then
                    table.insert(error_output, line)
                end
            end
        end
    end

    local function on_exit(_, exit_code)
        local success = exit_code == 0
        local result = table.concat(output, '\n')
        local error_result = table.concat(error_output, '\n')

        if opts.on_complete then
            if success then
                opts.on_complete(true, result)
            else
                opts.on_complete(false, error_result ~= '' and error_result or result)
            end
        end
    end

    -- Start the job
    local job_id = vim.fn.jobstart(cmd, {
        on_stdout = on_stdout,
        on_stderr = on_stderr,
        on_exit = on_exit,
        stdout_buffered = true,
        stderr_buffered = true,
        cwd = opts.cwd,
        env = opts.env,
    })

    if job_id <= 0 then
        if opts.on_complete then
            opts.on_complete(false, 'Failed to start job')
        end
    end

    return job_id
end

-- Run a command interactively in terminal
function M.run_interactive(cmd, opts)
    opts = opts or {}
    opts.interactive = true
    return M.run(cmd, opts)
end

-- Run a command synchronously with timeout
function M.run_sync(cmd, timeout)
    timeout = timeout or 5000

    local output = vim.fn.system(cmd)
    local success = vim.v.shell_error == 0

    return success, output
end

return M
