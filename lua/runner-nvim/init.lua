local M = {}

---@class CmdInfo
---@field cmd string
---@field time integer

---@type string
local historyPath = vim.fn.stdpath("data") .. "/runner-nvim/history.json"

---@param data table<string, CmdInfo>
local function saveHistory(data)
	local jsonString = vim.json.encode(data)
	vim.fn.writefile({ jsonString }, historyPath)
end

---@return table<string, CmdInfo>
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

	local maxEntries = 100
	local count = 0

	for _ in pairs(data) do
		count = count + 1
	end

	if count > maxEntries then
		local items = {}
		for cwd, info in pairs(data) do
			table.insert(items, { cwd = cwd, time = info.time })
		end

		table.sort(items, function(a, b)
			return a.time < b.time
		end)

		local toRemove = count - maxEntries
		for i = 1, toRemove do
			local oldest = items[i]
			data[oldest.cwd] = nil
		end
	end

	saveHistory(data)
end

---@class Terminal
---@field terminalBuf integer?
---@field terminalWin integer?
---@field jobId integer?
local Terminal = {}
Terminal.__index = Terminal

---@return Terminal
function Terminal:new()
	local data = {
		terminalBuf = nil,
		terminalWin = nil,
		jobId = nil,
	}

	setmetatable(data, Terminal)

	return data
end

function Terminal:init()
	if self.terminalBuf and vim.api.nvim_buf_is_valid(self.terminalBuf) then
		vim.api.nvim_buf_delete(self.terminalBuf, {})
	end

	local shellCommand = vim.o.shell

	local jobOptions = {
		term = true,
		on_exit = function(jobId, exitCode, event)
			self:quit()
		end
	}

	self.terminalBuf = vim.api.nvim_create_buf(false, true)
	self:initWindow()
	vim.api.nvim_set_current_win(self.terminalWin)

	self.jobId = vim.fn.jobstart(shellCommand, jobOptions)
end

function Terminal:initWindow()
	local width = math.floor(vim.o.columns * 0.8)
	local height = math.floor(vim.o.lines * 0.8)
	local row = math.floor((vim.o.lines - height) / 2)
	local col = math.floor((vim.o.columns - width) / 2)

	self.terminalWin = vim.api.nvim_open_win(self.terminalBuf, true, {
		relative = "editor",
		width = width,
		height = height,
		col = col,
		row = row,
		style = "minimal",
		border = "rounded",
	})
end

function Terminal:close()
	vim.api.nvim_win_close(self.terminalWin, false)
end

function Terminal:quit()
	self:close()
	vim.api.nvim_buf_delete(self.terminalBuf, {})
end

function Terminal:open()
	if not self.terminalBuf then
		self:init()
		return
	end

	if not vim.api.nvim_buf_is_valid(self.terminalBuf) then
		self:init()
	elseif vim.api.nvim_win_is_valid(self.terminalWin) then
		vim.api.nvim_set_current_win(self.terminalWin)
	else
		self:initWindow()
	end
end

function Terminal:toggle()
	if vim.api.nvim_get_current_win() == self.terminalWin then
		self:close()
	else
		self:open()
	end
end

---@param cmd string
function Terminal:run(cmd)
	self:open()

	vim.schedule(function ()
		vim.api.nvim_chan_send(self.jobId, cmd .. "\r")
	end)

	updateHistory(cmd)
end

---@type Terminal
local terminal

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

	local augroup = "Runner: Input window " .. tostring(win)
	vim.api.nvim_create_augroup(augroup, {})
	vim.api.nvim_create_autocmd("WinClosed", {
		group = augroup,
		callback = function(args)
			if args.buf == buf then
				vim.api.nvim_buf_delete(buf, {})
			end
		end,
	})

	vim.cmd("startinsert")

	local function confirm()
		local cmd = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
		vim.api.nvim_win_close(win, true)

		callback(cmd)
	end

	vim.keymap.set("n", "<CR>", confirm, { buffer = buf })
	vim.keymap.set("i", "<CR>", confirm, { buffer = buf })
	vim.keymap.set("i", "<C-s>", confirm, { buffer = buf })
	vim.keymap.set('n', 'q', '<Cmd>close<CR>', { buffer = buf, noremap = true, silent = true })
end

function M.run()
	askCmd(function (cmd) terminal:run(cmd) end)
end

function M.runLast()
	local data = readHistory()
	local cmdInfo = data[getCwd()]

	if (cmdInfo and cmdInfo.cmd) then
		terminal:run(cmdInfo.cmd)
	else
		M.run()
	end
end

function M.toggle()
	terminal:toggle()
end

function M.setup(opts)
	terminal = Terminal:new()
	if vim.fn.filereadable(historyPath) == 0 then
		vim.fn.mkdir(vim.fn.fnamemodify(historyPath, ":h"), "p")

		saveHistory({})
	end
end

return M
