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

function goiferr()
	-- vim.cmd("GoIfErr")

	local win = vim.api.nvim_get_current_win()
	local pos = vim.api.nvim_win_get_cursor(win)
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	local content = table.concat(lines, "\n")
	-- local offset = vim.api.nvim_str_byteindex(content, vim.api.nvim_buf_get_offset(0, pos[1] - 1) + pos[2])
	local offset = vim.api.nvim_buf_get_offset(0, pos[1] - 1) + pos[2]

	-- local cmd = string.format("echo %s | iferr -pos %d", vim.fn.shellescape(content), offset)

	local file_path = vim.api.nvim_buf_get_name(0)
	if vim.bo.modified then
		vim.cmd("silent write")
	end
	local cmd = string.format("cat %s | iferr -pos %d", file_path, offset)
	-- print(cmd)

	-- if file_path == "" then
	-- 	return sn(nil, t("-- file must be saved to disk for iferr"))
	-- end
	--
	local output = vim.fn.system(cmd)
	-- print(output)

	-- 3. Прыгаем на одну строку вниз (внутрь созданного if)
	-- GoIfErr обычно ставит курсор на return, но если хочешь
	-- кастомную позицию, можно подправить координаты здесь:
	-- local new_cursor = { cursor[1] + 1, cursor[2] }
	local new_cursor = { pos[1], pos[2] + 0 }
	-- print(pos)
	pcall(vim.api.nvim_win_set_cursor, win, new_cursor)
end

local function run_http_request()
	local main_buf = vim.api.nvim_get_current_buf()
	local file_path = vim.api.nvim_buf_get_name(main_buf)

	-- 1. Проверяем, создано ли уже окно результата для ЭТОГО буфера
	local res_buf = vim.b[main_buf].result_buffer
	local res_win = nil

	-- Если буфера нет или он удален, создаем новый
	if not res_buf or not vim.api.nvim_buf_is_valid(res_buf) then
		res_buf = vim.api.nvim_create_buf(false, true) -- nofile, scratch
		vim.api.nvim_buf_set_name(res_buf, "Result: " .. vim.fn.fnamemodify(file_path, ":t"))
		vim.bo[res_buf].filetype = "json" -- чтоб подсвечивал ответ
		vim.b[main_buf].result_buffer = res_buf
	end

	-- 2. Ищем, открыто ли окно с этим буфером в текущем табе
	for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		if vim.api.nvim_win_get_buf(win) == res_buf then
			res_win = win
			break
		end
	end

	-- 3. Если окна нет — открываем его в вертикальном сплите справа
	if not res_win then
		vim.cmd("vsplit")
		res_win = vim.api.nvim_get_current_win()
		vim.api.nvim_win_set_buf(res_win, res_buf)
		-- Возвращаемся в основное окно
		vim.api.nvim_set_current_win(vim.api.nvim_win_get_id(0))
	end

	-- 4. ЗАПУСК ТВОЕЙ ТУЛЗЫ (пример)
	-- Здесь вызываешь свою внешнюю тулзу и пишешь ответ в res_buf
	local cmd = string.format("go run my_tool.go %s", file_path)

	-- Для примера просто запишем "Выполняю..."
	vim.api.nvim_buf_set_lines(res_buf, 0, -1, false, { "Sending request...", "Target: " .. file_path })

	-- Тут можно юзать vim.fn.jobstart для асинхронности, чтобы nvim не фризился
	vim.fn.jobstart(cmd, {
		stdout_buffered = true,
		on_stdout = function(_, data)
			if data then
				vim.api.nvim_buf_set_lines(res_buf, 0, -1, false, data)
			end
		end,
	})
end

-- Биндим
-- vim.keymap.set("n", "<leader>r", run_http_request, { desc = "Run HTTP Request" })

function M.REPL()
	-- vim.cmd("e /home/mavostrykh/code/lua_sketches/repl.lua")
	-- vim.cmd("e /home/mavostrykh/code/gosketches/repl.go")
	vim.cmd("e /home/mavostrykh/code/gosketches/show_diffs/main.go")
	vim.api.nvim_win_set_cursor(0, { 115, 4 })
	goiferr()

	--tables within tables
	if false then
		local data = {
			{ "billy", 12 },
			{ "john", 20 },
			{ "andy", 65 },
		}

		for a = 1, #data do
			print(data[a][1] .. " is " .. data[a][2] .. " years old")
		end
	end
	-- print(vim.inspect(vim.tbl_keys(vim.lsp.handlers)))
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
			if false then
				local messages = vim.fn.execute("messages")
				-- -- Создаем новое окно и вставляем туда текст
				vim.cmd("new")
				local buf = vim.api.nvim_get_current_buf()
				vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(messages, "\n"))
			end
		end)
	end,
})
