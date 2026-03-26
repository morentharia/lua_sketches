-- Custom find buffers function.
--
-- nvim -c "source /home/mor/code/lua_sketches/repl.lua" -c "autocmd VimEnter * lua M.find_buffers()"
-- nvim -S /home/mor/code/lua_sketches/repl.lua

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
function M.find_buffers()
	local results = {}
	local buffers = vim.api.nvim_list_bufs()

	for _, buffer in ipairs(buffers) do
		if vim.api.nvim_buf_is_loaded(buffer) then
			local filename = vim.api.nvim_buf_get_name(buffer)
			table.insert(results, filename)
		end
	end

	vim.ui.select(results, { prompt = "Find buffer:" }, function(selected)
		if selected then
			vim.api.nvim_command("buffer " .. selected)
		end
	end)
end

function M.REPL()
	--tables within tables
	local data = {
		{ "billy", 12 },
		{ "john", 20 },
		{ "andy", 65 },
	}

	for a = 1, #data do
		print(data[a][1] .. " is " .. data[a][2] .. " years old")
	end
end

vim.api.nvim_create_autocmd("VimEnter", {
	callback = function()
		-- Задержка в 0 мс через schedule гарантирует, что
		-- UI (окна и плагины) полностью отрисовались

		vim.schedule(function()
			-- M.find_buffers()
			-- vim.api.nvim_feedkeys("search_text", "t", false)

			M.REPL()
			-- vim.cmd("messages")
			-- print("vim_lua_repl_yeah_ITS_VIM_FLAG")
			-- local messages = vim.fn.execute("messages")
			-- vim.fn.input(messages)
			-- Захватываем вывод команды messages
			local messages = vim.fn.execute("messages")
			-- -- Создаем новое окно и вставляем туда текст
			vim.cmd("new")
			local buf = vim.api.nvim_get_current_buf()
			vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(messages, "\n"))
		end)
	end,
})
