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

vim.cmd.py3([[
from pyzlo.helpers.nvim.meta_sender import MetaSender
]])

local M = {}

function M.REPL()
	-- vim.cmd("e /home/mavostrykh/hack/notes/s3/repeater/hahatest.new_http")
	vim.cmd("e /home/mavostrykh/hack/notes/budget/repeater/asfdasdf.http")
	-- vim.cmd("e /home/mavostrykh/hack/notes/crm_dwh/src/public_crm/dwh-service/package-lock.json")

	-- run_http_request()
	-- run_http_request()
	-- run_http_request()
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
