-- main.lua для Android
local player = { x = 100, y = 100, size = 50 }
local touchX, touchY = 0, 0

function love.load()
	love.graphics.setBackgroundColor(0.2, 0.3, 0.5)
end

function love.update(dt)
	-- Двигаемся к точке касания
	local dx = touchX - player.x
	local dy = touchY - player.y
	local dist = math.sqrt(dx * dx + dy * dy)

	if dist > 2 then
		player.x = player.x + dx * dt * 3
		player.y = player.y + dy * dt * 3
	end
end

function love.draw()
	-- Игрок
	love.graphics.setColor(1, 0.5, 0)
	love.graphics.circle("fill", player.x, player.y, player.size)

	-- Цель
	love.graphics.setColor(1, 0, 0, 0.5)
	love.graphics.circle("fill", touchX, touchY, 20)

	-- Инструкция
	love.graphics.setColor(1, 1, 1)
	love.graphics.print("Touch to move circle", 10, 10)
end

function love.touchpressed(id, x, y)
	touchX, touchY = x, y
end

function love.touchmoved(id, x, y)
	touchX, touchY = x, y
end
