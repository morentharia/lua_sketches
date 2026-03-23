local r1, r2
local myImage
local x = 0

function love.load()
	myImage = love.graphics.newImage("sheep.png")
	Object = require("classic")
	Rectangle = require("rectangle")

	r1 = Rectangle(100, 100, 200, 50)
	r2 = Rectangle(350, 80, 25, 140)
end

function love.update(dt)
	r1:update(dt)
	r2:update(dt)
end

function love.keypressed(key)
	love.graphics.print("hohohohohoho" .. key, 50, 100)
	print("hohoho" .. key)
	x = x + 10
end

function love.draw()
	r1:draw()
	r2:draw()
	local width = myImage:getWidth()
	local height = myImage:getHeight()
	love.graphics.draw(myImage, 100, 100, 0, 1, 2, width / 2, height / 2)
	love.graphics.setColor(x / 255, 200 / 255, 40 / 255, 127 / 255)
	-- love.graphics.setColor(1, 0.78, 0.15, 0.5)
	-- Or ...
	love.graphics.draw(myImage, 100, 100)
	-- Not passing an argument for alpha automatically sets it to 1 again.
	love.graphics.setColor(1, 1, 1)
	love.graphics.draw(myImage, 200, 100)
	-- love.graphics.draw(myImage, 100, 100, 0, 2, 2, 39, 50 + x)
	-- love.graphics.draw(myImage, 100, 100)
	-- -- love.graphics.draw(myImage, 100, 300, 0, 2, 2, 39, 50 + x)
	-- love.graphics.draw(myImage, 100, 300, 0, 2, 2, 39, 50)
	-- love.graphics.draw(myImage, 100, 300, 0, 2, 2, 39 + x, 100)
end
