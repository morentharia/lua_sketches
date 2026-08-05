-- Custom find buffers function.
--
-- nvim -c "source /home/mor/code/lua_sketches/repl.lua" -c "autocmd VimEnter * lua M.find_buffers()"
-- nvim -S /home/mor/code/lua_sketches/repl.lua

-- run nvim without any plugins
-- nvim -u NONE
--
-- local M = {}
M = {}

vim.opt.laststatus = 3 -- 3 = глобальный статуслайн (один на весь nvim), 2 = для каждого окна
function M.my_statusline()
	return table.concat({
		-- нужна для /home/mor/code/pyzlodeistva/src/pyzlo/commands/tmux/automate_scripts/vimplugin_lua.py
		-- что бы тмукс плагин мой палил это окошко вима или нет
		"vim_lua_repl_yeah_ITS_VIM_FLAG",
		-- " %f ",                -- Путь к файлу
		-- " %m%r",               -- Флаги изменения/чтения
		-- "%=",                  -- Разделитель (всё после него уйдет вправо)
		-- " %y ",                -- Тип файла
		-- " %l:%c ",             -- Строка:Колонка
		-- " %P "                 -- Процент прокрутки
	})
end
vim.opt.statusline = "%!v:lua.M.my_statusline()"

-------------------------------------------------------------------------------------------------------
--- REPL !!!!!!!!!!!!!!!!!!!!!!!
-------------------------------------------------------------------------------------------------------
---
local function feed(codes)
	local termcodes = vim.api.nvim_replace_termcodes(codes, true, false, true)
	vim.api.nvim_feedkeys(termcodes, "n", false) -- 'n' значит noremove (как norm!)
end

local Terminal = require("toggleterm.terminal").Terminal

vim.cmd.py3([[
from pyzlo.helpers.nvim.meta_sender import MetaSender
]])

local M = {}

local state = {
	floating = {
		buf = -1,
		win = -1,
	},
}

local fastfingers = Terminal:new({
	cmd = "fastfingers",
	hidden = true,
	direction = "float", -- открываем в плавающем окне
	float_opts = {
		border = "double",
	},
	-- закрывать терминал при выходе из программы
	close_on_exit = true,
})

-- Создаем экземпляр обычного шелла
local shell_term = Terminal:new({
	cmd = vim.o.shell, -- берет твой zsh/bash из настроек системы
	direction = "horizontal", -- можно сменить на "float" или "vertical"
	hidden = true, -- не открывать сразу при запуске nvim
	on_open = function(term)
		-- Чтобы было удобнее выходить из терминала по esc
		vim.api.nvim_buf_set_keymap(term.bufnr, "t", "<Esc>", [[<C-\><C-n>]], { noremap = true, silent = true })
	end,
})

-- Функция просто для открытия/закрытия этого терминала
function M.toggle_shell()
	vim.keymap.set("n", "<leader>tf", "<cmd>lua toggle_shell()<CR>", { silent = true, desc = "Toggle Shell" })
	shell_term:toggle()
end
--
function M.fastfingers_toggle()
	fastfingers:toggle()
end

function run_http_request()
	local main_win = vim.api.nvim_get_current_win()
	local main_buf = vim.api.nvim_get_current_buf()

	-- 1. Инициализация буфера результата
	local res_buf = vim.b[main_buf].result_buffer
	if not res_buf or not vim.api.nvim_buf_is_valid(res_buf) then
		res_buf = vim.api.nvim_create_buf(false, true)
		vim.bo[res_buf].filetype = "json"
		vim.b[main_buf].result_buffer = res_buf

		-- ГВОЗДЬ ПРОГРАММЫ: следим за закрытием ОКНА запроса
		vim.api.nvim_create_autocmd("WinClosed", {
			pattern = tostring(main_win),
			callback = function()
				-- schedule откладывает выполнение, чтобы избежать ошибки E855
				vim.schedule(function()
					-- 1. Закрываем все окна с результатом
					local wins = vim.api.nvim_list_wins()
					for _, w in ipairs(wins) do
						if vim.api.nvim_win_is_valid(w) and vim.api.nvim_win_get_buf(w) == res_buf then
							vim.api.nvim_win_close(w, true)
						end
					end
					-- 2. Удаляем буфер результата
					if res_buf and vim.api.nvim_buf_is_valid(res_buf) then
						vim.api.nvim_buf_delete(res_buf, { force = true })
					end
				end)
			end,
		})
	end

	-- 2. Поиск/создание окна результата (справа)
	local res_win = nil
	for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		if vim.api.nvim_win_get_buf(win) == res_buf then
			res_win = win
			break
		end
	end

	if not res_win or not vim.api.nvim_win_is_valid(res_win) then
		vim.cmd("rightbelow vsplit")
		res_win = vim.api.nvim_get_current_win()
		vim.api.nvim_win_set_buf(res_win, res_buf)
		-- Опционально: зафиксируем ширину, чтобы не прыгала
		vim.api.nvim_win_set_width(res_win, 60)
	end

	vim.api.nvim_set_current_win(main_win)
	vim.api.nvim_buf_set_lines(res_buf, 0, -1, false, { "[+] Status: Sending...", "" })
end

function M.REPL()
	vim.print("yeah")
	-- vim.cmd("e /home/mavostrykh/hack/notes/s3/repeater/hahatest.new_http")
	--
	--
	--
	local lsp_restart_group = vim.api.nvim_create_augroup("LspAutoRestart", { clear = true })

	vim.api.nvim_create_autocmd({ "VimEnter", "FocusGained" }, {
		group = lsp_restart_group,
		pattern = "*",
		callback = function()
			-- Просто выводим сообщение на экран
			-- Получаем текущее время в формате ЧЧ:ММ:СС
			local current_time = os.date("%H:%M:%S")

			-- Выводим сообщение с временной меткой
			vim.notify("[" .. current_time .. "] Ты вернулся в окно Neovim!", vim.log.levels.INFO)
			-- vim.print(vim.lsp.)
		end,
	})
end

vim.api.nvim_create_autocmd("VimEnter", {
	callback = function()
		-- Задержка в 0 мс через schedule гарантирует, что
		-- UI (окна и плагины) полностью отрисовались

		vim.schedule(function()
			-- vim.schedule(function()
			M.REPL()
			-- vim.api.nvim_feedkeys(
			-- 	vim.api.nvim_replace_termcodes("search_text<C-\\><C-n>", true, false, true),
			-- 	"t",
			-- 	false
			-- )
			--
			-- vim.cmd("messages")
			-- vim.fn.input(messages)
			-- Захватываем вывод команды messages
			if false then
				local messages = vim.fn.execute("messages")
				-- -- Создаем новое окно и вставляем туда текст
				vim.cmd("new")
				local buf = vim.api.nvim_get_current_buf()
				vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(messages, "\n"))
			end
			-- end)
		end)
	end,
})
