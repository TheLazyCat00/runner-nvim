local M = {}

---@class CmdInfo
---@field cmd string
---@field time integer

local historyPath = vim.fn.stdpath("data") .. "/runner-nvim/history.json"

---@param data CmdInfo[]
local function saveHistory(data)
	local jsonString = vim.json.encode(data)
	vim.fn.writefile({ jsonString }, historyPath)
end

---@return CmdInfo[]
local function readHistory()
	local jsonString = vim.fn.readfile(historyPath)

	return vim.json.decode(jsonString[1])
end

---@return string
local function getCwd()
	local cwd = vim.fn.getcwd()
	local result = string.gsub(cwd, '\\', '/')

	return result
end

---@param cmd string
local function updateHistory(cmd)
	local data = readHistory()

	data[getCwd()] = { cmd = cmd, time = os.time() }
	saveHistory(data)
end

---@param callback function<string>
local function askCmd(callback)
	local buf = vim.api.nvim_create_buf(false, true)

	local width = math.floor(vim.o.columns * 0.4)
	local height = 1
	local row = math.floor((vim.o.lines - height) / 2)
	local col = math.floor((vim.o.columns - width) / 2)

	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		style = "minimal",
		border = "single",
	})

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "" })

	vim.keymap.set("n", "<CR>", function()
		local cmd = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
		vim.api.nvim_win_close(win, true)

		callback(cmd)
	end, { buffer = buf })
end

---@param cmd string
local function run(cmd)
	local terminalBuffer = vim.api.nvim_create_buf(false, true)

	local currentUi = vim.api.nvim_list_uis()[1]
	local windowWidth = math.floor(currentUi.width * 0.8)
	local windowHeight = math.floor(currentUi.height * 0.8)
	local windowCol = math.floor((currentUi.width - windowWidth) / 2)
	local windowRow = math.floor((currentUi.height - windowHeight) / 2)

	local floatingWindow = vim.api.nvim_open_win(terminalBuffer, true, {
		relative = "editor",
		width = windowWidth,
		height = windowHeight,
		col = windowCol,
		row = windowRow,
		style = "minimal",
		border = "rounded"
	})

	vim.api.nvim_set_current_win(floatingWindow)

	local shellCommand = vim.o.shell

	local jobOptions = {
		term = true,
		on_exit = function(jobId, exitCode, event)
			vim.api.nvim_win_close(floatingWindow, false)
			vim.api.nvim_buf_delete(terminalBuffer, {})
		end
	}

	local jobId = vim.fn.jobstart(shellCommand, jobOptions)

	vim.defer_fn(function()
		vim.api.nvim_chan_send(jobId, cmd .. "\r")
	end, 50)

	vim.cmd("startinsert")
	updateHistory(cmd)
	vim.keymap.set('n', 'q', '<Cmd>close<CR>', { buffer = terminalBuffer, noremap = true, silent = true })
end

function M.run()
	askCmd(run)
end

function M.runLast()
	local data = readHistory()
	local cmdInfo = data[getCwd()]

	if (cmdInfo and cmdInfo.cmd) then
		run(cmdInfo.cmd)
		return
	end

	M.run()
end

function M.setup(opts)
	if vim.fn.filereadable(historyPath) == 0 then
		vim.fn.mkdir(vim.fn.fnamemodify(historyPath, ":h"), "p")

		saveHistory({})
	end
end

return M
