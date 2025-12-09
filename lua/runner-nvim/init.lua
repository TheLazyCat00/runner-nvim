local M = {}

---@param callback function<string>
local function askCmd(callback)
	local buf = vim.api.nvim_create_buf(false, true)

	-- Window layout
	local width = math.floor(vim.o.columns * 0.4)
	local height = 1
	local row = math.floor((vim.o.lines - height) / 2)
	local col = math.floor((vim.o.columns - width) / 2)

	-- Create the floating window
	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		style = "minimal",
		border = "single",
	})

	-- Optional placeholder text
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "" })

	-- Map <CR> to trigger the callback
	vim.keymap.set("n", "<CR>", function()
		local cmd = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
		vim.api.nvim_win_close(win, true)

		callback(cmd)
	end, { buffer = buf })
end

function M.run(cmd)
	
end
return M
