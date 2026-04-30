-- Custom find buffers function.
--
-- nvim -c "source /home/mor/code/lua_sketches/repl.lua" -c "autocmd VimEnter * lua M.find_buffers()"
-- nvim -S /home/mor/code/lua_sketches/repl.lua
-- nvim -S ~/code/lua_sketches/repl/repl.lua

-- run nvim without any plugins
-- nvim -u NONE
-- nvim -u NONE -S ~/code/lua_sketches/repl/repl.lua
--
-- local M = {}
M = {}

vim.g.mapleader = ","
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

vim.cmd([[
  filetype plugin indent on
  syntax enable
]])

vim.g.python3_host_prog = vim.fn.expand("$ZLOPATH/venv/bin/python3.11")
vim.opt.rtp:append(vim.fn.stdpath("data") .. "/lazy/toggleterm.nvim")
vim.opt.rtp:append(vim.fn.stdpath("data") .. "/lazy/nvim-treesitter")
vim.opt.rtp:append(vim.fn.stdpath("data") .. "/lazy/fzf")
vim.opt.rtp:append(vim.fn.stdpath("data") .. "/lazy/fzf.nvim")
vim.cmd("runtime plugin/fzf.vim")
-- vim.opt.rtp:append(vim.fn.stdpath("data") .. "/lazy/fzf-lua")

function _G.set_terminal_keymaps()
	local opts = { buffer = 0 }
	vim.keymap.set("t", "jk", [[<C-\><C-n>]], opts)
	vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], opts)
end

-- Применять эти правила только когда открыт терминал
vim.cmd("autocmd! TermOpen term://* lua set_terminal_keymaps()")

vim.cmd("colorscheme pablo")

-------------------------------------------------------------------------------------------------------
--- REPL !!!!!!!!!!!!!!!!!!!!!!!
-------------------------------------------------------------------------------------------------------
---

local function feed(codes)
	local termcodes = vim.api.nvim_replace_termcodes(codes, true, false, true)
	vim.api.nvim_feedkeys(termcodes, "n", false) -- 'n' значит noremove (как norm!)
end

local Terminal = require("toggleterm.terminal").Terminal

local M = {}

-- local state = {
-- 	floating = {
-- 		buf = -1,
-- 		win = -1,
-- 	},
-- }

local main_term = Terminal:new({
	cmd = vim.o.shell,
	-- direction = "horizontal",
	direction = "float", -- открываем в плавающем окне
	hidden = true,
})

-- local fastfingers = Terminal:new({
-- 	cmd = "fastfingers",
-- 	hidden = true,
-- 	direction = "float", -- открываем в плавающем окне
-- 	float_opts = {
-- 		border = "double",
-- 	},
-- 	-- закрывать терминал при выходе из программы
-- 	close_on_exit = true,
-- })

function M.setup()
	vim.cmd.py3([[
import logging
from pyzlo.helpers.nvim.meta_sender import MetaSender
from pyzlo.helpers.nvim.menu_factory import MenuFactory
from pyzlo.helpers.nvim.menu_factory import select_from_vim
from pyzlo.helpers.nvim.hackvector_factory import HackvectorFactory
from pyzlo.helpers.nvim.hackvector_factory import select_from_vim as hackvector_select_from_vim

from pyzlo.settings import NVIM_LOGGING_FILENAME
from setuptools import depends

logging.basicConfig(
    filename=NVIM_LOGGING_FILENAME,
    encoding='utf-8',
    level=logging.INFO,
	# level=logging.DEBUG,
    force=True,
)

logger = logging.getLogger(__name__)
]])

	vim.keymap.set("n", "<leader>rt", function()
		main_term:toggle()
	end, { desc = "Toggle Main Terminal" })

	vim.keymap.set("n", "<leader>rh", function()
		M.run_http_request()
	end, { desc = "Run http request" })
	vim.keymap.set("n", "<M-g>", function()
		M.run_http_request()
	end, { desc = "Run http request" })

	-- Передаем саму функцию, а не строку с вызовом
	vim.keymap.set("v", "<leader>ee", function()
		-- Чтобы получить правильные метки '< и '>,
		-- нужно сначала выйти из Visual mode программно
		-- vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)

		-- Теперь вызываем логику
		-- M.process_visual_selection()
		M.py_hackvector_menu_list()
	end)
end

-- function M.fastfingers_toggle()
-- 	fastfingers:toggle()
-- end

--TODO:
function M.get_res_buffer(main_buf)
	-- 1. Инициализация буфера результата
	local res_buf = vim.b[main_buf].result_buffer
	if not res_buf or not vim.api.nvim_buf_is_valid(res_buf) then
		res_buf = vim.api.nvim_create_buf(false, true)
		-- vim.bo[res_buf].filetype = "json"
		vim.bo[res_buf].filetype = "http"
		vim.b[main_buf].result_buffer = res_buf

		local ctx = M.get_or_create_tab_context()
		-- ГВОЗДЬ ПРОГРАММЫ: следим за закрытием ОКНА запроса
		vim.api.nvim_create_autocmd("WinClosed", {
			pattern = tostring(ctx.main_win),
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
end

-- Хранилище контекстов для каждой вкладки
local tabs_context = {}

function M.get_or_create_tab_context()
	local tid = vim.api.nvim_get_current_tabpage()

	-- 1. Инициализация контекста
	if not tabs_context[tid] then
		tabs_context[tid] = {
			main_win = vim.api.nvim_get_current_win(),
			res_buf = nil,
			res_win = nil, -- Храним само окно!
		}
	end
	local ctx = tabs_context[tid]

	if not ctx.res_win or not vim.api.nvim_win_is_valid(ctx.res_win) then
		-- Создаем временный буфер, если его нет
		if not ctx.res_buf or not vim.api.nvim_buf_is_valid(ctx.res_buf) then
			ctx.res_buf = vim.api.nvim_create_buf(false, true)
			vim.bo[ctx.res_buf].filetype = "http"
		end

		vim.cmd("rightbelow vsplit")
		ctx.res_win = vim.api.nvim_get_current_win()
		vim.api.nvim_win_set_buf(ctx.res_win, ctx.res_buf)
		vim.api.nvim_win_set_width(ctx.res_win, 50)

		-- Возвращаемся в главное
		vim.api.nvim_set_current_win(ctx.main_win)
	end
	return ctx
end

function M.run_http_request()
	-- TODO: func get_or_create_tab_context use it!!!!
	local tid = vim.api.nvim_get_current_tabpage()

	-- 1. Инициализация контекста
	if not tabs_context[tid] then
		tabs_context[tid] = {
			main_win = vim.api.nvim_get_current_win(),
			res_buf = nil,
			res_win = nil, -- Храним само окно!
		}
	end
	local ctx = tabs_context[tid]

	-- 2. Проверяем окно результата
	-- Если окна нет или оно закрыто — создаем
	if not ctx.res_win or not vim.api.nvim_win_is_valid(ctx.res_win) then
		-- Создаем временный буфер, если его нет
		if not ctx.res_buf or not vim.api.nvim_buf_is_valid(ctx.res_buf) then
			ctx.res_buf = vim.api.nvim_create_buf(false, true)
			vim.bo[ctx.res_buf].filetype = "http"
		end

		vim.cmd("rightbelow vsplit")
		ctx.res_win = vim.api.nvim_get_current_win()
		vim.api.nvim_win_set_buf(ctx.res_win, ctx.res_buf)
		vim.api.nvim_win_set_width(ctx.res_win, 50)

		-- Возвращаемся в главное
		vim.api.nvim_set_current_win(ctx.main_win)
	end

	local current_file_name
	vim.api.nvim_win_call(ctx.main_win, function()
		current_file_name = vim.fn.resolve(vim.fn.expand("%"))
	end)
	-- 3. В колбэке используем ctx.res_win напрямую
	M.send_and_capture("clear; pyzlo meta_sender " .. current_file_name, function(output, exit_code)
		vim.schedule(function()
			if ctx.res_win and vim.api.nvim_win_is_valid(ctx.res_win) then
				local resp_file = ""
				vim.api.nvim_win_call(ctx.main_win, function()
					resp_file = M.py_response_filename()
				end)

				vim.api.nvim_win_call(ctx.res_win, function()
					vim.cmd("e! " .. vim.fn.fnameescape(resp_file))
					vim.api.nvim_win_set_cursor(0, { 1, 0 })
				end)
			end
		end)
	end)
end

-- Вспомогательная функция для поиска окна результата в конкретном табе
function M.get_res_win(tid)
	local ctx = tabs_context[tid]
	if not ctx or not ctx.res_buf then
		return nil
	end

	for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tid)) do
		if vim.api.nvim_win_get_buf(win) == ctx.res_buf then
			return win
		end
	end
	return nil
end

-- local Terminal = require("toggleterm.terminal").Terminal

-- Функция для красивого отображения результата в отдельном плавающем буфере
local function show_pretty_output(lines, is_error)
	local buf = vim.api.nvim_create_buf(false, true)
	local width = math.floor(vim.o.columns * 0.7)
	local height = math.floor(vim.o.lines * 0.7)

	-- Настраиваем окно по центру
	vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		col = math.floor((vim.o.columns - width) / 2),
		row = math.floor((vim.o.lines - height) / 2),
		style = "minimal",
		border = is_error and "double" or "rounded", -- Двойная рамка, если ошибка
	})

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].filetype = "json" -- Или другой тип для подсветки
	vim.api.nvim_buf_set_keymap(buf, "n", "q", ":q<CR>", { noremap = true, silent = true })
end

-- 1. Создаем тот самый ЕДИНСТВЕННЫЙ терминал

-- 2. Пути для обмена данными
local main_term_out_file = "/tmp/nvim_out"
local main_term_code_file = "/tmp/nvim_code"

local function read_file(path)
	local f = io.open(path, "r")
	if not f then
		return nil
	end
	local content = f:read("*a")
	f:close()
	return content
end

-- 3. Функция-шпион
M.send_and_capture = function(cmd, result_cb, timeout_cb)
	-- Очищаем старые метки
	os.remove(main_term_code_file)
	os.remove(main_term_out_file)

	if not main_term:is_open() then
		main_term:open()
		main_term:toggle()
	end

	-- Шлем команду в zsh с перенаправлением и записью кода выхода
	local ctrl_u = string.char(21)

	main_term:send(ctrl_u)
	main_term:send(ctrl_u)
	main_term:send(ctrl_u)
	main_term:send(ctrl_u)
	main_term:send(ctrl_u)
	local wrapped_cmd =
		string.format("%s | tee %s 2>&1; echo $? > %s\n\n", cmd, main_term_out_file, main_term_code_file)
	main_term:send(wrapped_cmd)

	-- Запускаем проверку готовности (опрос каждые 200мс)
	local timer = vim.loop.new_timer()
	local timeout_ms = 60000 -- 1 минута
	local elapsed = 0
	local check_interval = 30

	timer:start(
		check_interval,
		check_interval,
		vim.schedule_wrap(function()
			elapsed = elapsed + check_interval
			local exit_code = read_file(main_term_code_file)

			-- 1. Если дождались завершения
			if exit_code then
				timer:stop()
				timer:close()
				local output = read_file(main_term_out_file) or ""
				-- show_pretty_output(vim.split(output, "\n"), tonumber(exit_code) ~= 0)
				-- print("✅ Finished: " .. exit_code)
				if result_cb then
					result_cb(output, exit_code)
				end
				-- 2. Если вышли за лимит времени
			elseif elapsed >= timeout_ms then
				timer:stop()
				timer:close()

				-- Опционально: можно послать Ctrl+C в терминал, чтобы убить процесс
				-- main_term:send(string.char(3))
				-- print("⏰ Timeout: команда выполнялась дольше минуты")

				-- Показываем то, что успело накопиться в файле к этому моменту
				local partial_output = read_file(main_term_out_file) or "No output yet..."
				-- show_pretty_output(vim.split(partial_output, "\n"), true)
				timeout_cb = timeout_cb
					or function(output)
						if result_cb then
							result_cb(output, "timeout_error")
						else
							print("Timeout!")
						end
					end

				timeout_cb(partial_output)
			end
		end)
	)
end

function M.py_response_filename()
	local current_file_name = vim.fn.resolve(vim.fn.expand("%"))
	local _filename_resp = vim.fn.py3eval(string.format('MetaSender("%s")._filename_resp', current_file_name))
	return _filename_resp
end

function M.py_menu_list()
	-- local current_file_name = vim.fn.resolve(vim.fn.expand("%"))
	-- local _filename_resp = vim.fn.py3eval(string.format('MetaSender("%s")._filename_resp', current_file_name))
	-- return _filename_resp

	-- local res = vim.fn.py3eval("MenuFactory.keys()")
	-- vim.print(res)

	-- local items = vim.fn.py3eval("MenuFactory.keys()")

	-- Оборачиваем в fzf#wrap для применения стилей (границы, превью и т.д.)
	local opts = vim.fn["fzf#wrap"]("PyMenu", {
		source = vim.fn.py3eval("MenuFactory.keys()"),
		sink = function(selected)
			-- Тут логика после выбора, например, вызов python-метода
			-- vim.fn.py3eval(string.format("MenuFactory.execute('%s')", selected))

			local ctx = M.get_or_create_tab_context()

			local current_file_name
			vim.api.nvim_win_call(ctx.main_win, function()
				current_file_name = vim.fn.resolve(vim.fn.expand("%"))
			end)

			local menu_context = {
				["current_file_name"] = current_file_name,
				-- file = vim.fn.expand("%:p"),
				-- bufnr = vim.api.nvim_get_current_buf(),
				-- cwd = vim.fn.getcwd(),
			}
			-- Сериализуем в JSON и отдаем Питону
			local json_menu_ctx = vim.fn.json_encode(menu_context)
			-- print(string.format("select_from_vim('%s', '%s')", selected, json_ctx))
			local res = vim.fn.py3eval(string.format("select_from_vim('%s', '%s')", selected, json_menu_ctx))
			vim.print(res)
		end,
		-- Параметры внешнего вида окна
		window = {
			width = 0.8,
			height = 0.6,
			border = "sharp", -- или 'rounded', 'double', 'single'
		},
		-- Дополнительные флаги fzf (цвета, подсказки)
		options = '--prompt "➤ " --header "Select Action: " --layout=reverse --info=inline',
	})

	vim.fn["fzf#run"](opts)
end

function M.py_hackvector_process_visual_selection()
	-- 1. Сначала выходим из визуального режима в нормальный,
	-- чтобы метки '< и '> обновились
	--
	vim.cmd([[execute "normal! \<Esc>"]])
	-- 1. Получаем координаты выделения ('<' и '>')
	local _, s_row, s_col, _ = unpack(vim.fn.getpos("'<"))
	local _, e_row, e_col, _ = unpack(vim.fn.getpos("'>"))

	-- Коррекция индексов (API использует 0-based строки)
	local start_row = s_row - 1
	local start_col = s_col - 1
	local end_row = e_row - 1
	local end_col = e_col -- getpos для '>' возвращает последний символ включительно

	local lines = vim.api.nvim_buf_get_text(0, start_row, start_col, end_row, end_col, {})
	local separator = (vim.bo.fileformat == "dos") and "\r\n" or "\n"

	local full_text = table.concat(lines, separator)
	-- TODO: only base64 do it for all menu
	local cmd = string.format([[HackvectorFactory.get_by_tag_name("base64")().decode(b'%s')]], full_text)
	local result = vim.fn.py3eval(cmd)

	-- local result_lines = vim.split(result, "[\r\n]+")
	local result_lines = vim.split(result, separator)
	vim.api.nvim_buf_set_text(0, start_row, start_col, end_row, end_col, result_lines)
end

function M.py_hackvector_menu_list()
	local opts = vim.fn["fzf#wrap"]("PyHackvectorMenu", {
		source = vim.fn.py3eval("HackvectorFactory.keys()"),
		sink = function(selected)
			M.py_hackvector_process_visual_selection()
			-- local res = vim.fn.py3eval(string.format("select_from_vim('%s', '%s')", selected, json_menu_ctx))
			-- vim.print(res)
		end,
		-- Параметры внешнего вида окна
		window = {
			width = 0.8,
			height = 0.6,
			border = "sharp", -- или 'rounded', 'double', 'single'
		},
		-- Дополнительные флаги fzf (цвета, подсказки)
		options = '--prompt "➤ " --header "Select Action: " --layout=reverse --info=inline',
	})

	vim.fn["fzf#run"](opts)
end

function M.REPL()
	M.setup()
	-- vim.cmd("e /home/mavostrykh/hack/notes/s3/repeater/blablbalba.http")
	-- vim.cmd("e /home/mavostrykh/hack/notes/s3/repeater/blablbalba_1.http")
	vim.cmd("e /home/mavostrykh/hack/notes/budget/repeater/asfdasdf.http")
	-- M.py_menu_list()

	-- vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("gg<down>v$", true, false, true), "t", false)
	-- M.process_visual_selection()

	-- M.py_hackvector_menu_list()
	-- vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("edit meta<Enter>", true, false, true), "t", false)
	-- vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("copy as curl<Enter>", true, false, true), "t", false)

	--TODO
	-- vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("mitm addon<Enter>", true, false, true), "t", false)
	-- vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("nuclei<Enter>", true, false, true), "t", false)
	----

	if false then
	end
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

return M
