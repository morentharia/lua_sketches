-- https://codeforces.com/problemset/problem/2211/H
--
-- https://openrouter.ai/workspaces/default/keys?utm_source=signup-success
-- apikey: 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
--
local function generate_solver_from_url(url)
	-- local url = vim.fn.input("Enter Problem URL: ")
	-- if url == "" then
	-- 	return
	-- end

	local api_key = "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" -- Вставь сюда ключ
	local prompt = "Generate a Python script for this competitive programming problem: "
		.. url
		.. ". Only output the code, no explanations. Use fast I/O (sys.stdin.readline)."

	print("\nThinking...")

	-- Формируем JSON для запроса
	local data = vim.fn.json_encode({
		model = "mistralai/mistral-7b-instruct:free", -- Бесплатная модель
		messages = { { role = "user", content = prompt } },
	})

	-- Вызываем curl асинхронно
	local command = string.format(
		"curl -s https://openrouter.ai/api/v1/chat/completions"
			.. "-H 'Content-Type: application/json' "
			.. "-H 'Authorization: Bearer %s' "
			.. "-d %s",
		api_key,
		-- data
		vim.fn.shellescape(data)
	)

	print(command)
	local result = vim.fn.system(command)
	-- print(result)
	local decoded = vim.fn.json_decode(result)

	if decoded and decoded.choices and decoded.choices[1] then
		local code = decoded.choices[1].message.content
		-- Убираем markdown-обертки ```python ... ``` если они есть
		code = code:gsub("```python", ""):gsub("```", "")

		-- Вставляем в текущий файл
		local lines = vim.split(code, "\n")
		vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
		print("Done!")
	else
		print("Error: Could not get response from AI")
	end
end

vim.api.nvim_create_autocmd("VimEnter", {
	callback = function()
		-- Задержка в 0 мс через schedule гарантирует, что
		-- UI (окна и плагины) полностью отрисовались

		vim.schedule(function()
			-- M.find_buffers()
			-- vim.api.nvim_feedkeys("search_text", "t", false)

			generate_solver_from_url("https://codeforces.com/problemset/problem/2211/H")
			-- vim.cmd("messages")
			-- print("vim_lua_repl_yeah_ITS_VIM_FLAG")
			-- local messages = vim.fn.execute("messages")
			-- vim.fn.input(messages)
			-- Захватываем вывод команды messages
			if true then
				local messages = vim.fn.execute("messages")
				-- -- Создаем новое окно и вставляем туда текст
				vim.cmd("new")
				local buf = vim.api.nvim_get_current_buf()
				vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(messages, "\n"))
			end
		end)
	end,
})
