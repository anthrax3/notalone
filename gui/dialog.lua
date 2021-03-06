Dialog = {}
Dialog.__index = Dialog

Dialog.bgcolor     = Color.rgb(30,30,30, 120)
Dialog.bordercolor = Color.rgb(80,80,80, 120)
Dialog.textcolor   = Color.rgb(255,255,255, 120)

function Dialog.new(size)
	local dialog = {}
	local center = vector(love.graphics.getWidth()/2, love.graphics.getHeight()/2)
	dialog.center = center
	dialog.size = size
	dialog.pos  = center - size/2
	return setmetatable(dialog, Dialog)
end

function Dialog:open()
	self.__draw = love.draw
	love.draw = function()
		self.__draw()
		love.graphics.setColor(0,0,0,100)
		love.graphics.rectangle('fill', 0,0, love.graphics.getWidth(), love.graphics.getHeight())

		Dialog.bgcolor:set()
		love.graphics.rectangle('fill', self.pos.x, self.pos.y, self.size:unpack())
		Dialog.bordercolor:set()
		love.graphics.rectangle('line', self.pos.x, self.pos.y, self.size:unpack())
		Dialog.textcolor:set()
		self:draw()
	end

	self.__update = love.update
	love.update = function(dt)
		self:update(dt)
	end

	self.__keypressed = love.keypressed
	love.keypressed = function(key, unicode)
		return self.onKeyPressed and self:onKeyPressed(key, unicode)
	end

	return self.enter and self:enter()
end

function Dialog:close()
	love.draw = self.__draw
	self.__draw = nil

	love.update = self.__update
	self.__update = nil

	love.keypressed = self.__keypressed
	self.__keypressed = nil

	return self.leave and self:leave()
end

function MessageBox(title, text, onOK)
	local dlg = Dialog.new(vector(400,300))
	local btn = Button.new("OK", dlg.center + vector(0,100), vector(100,40))
	function btn:onClick()
        playsound(click_sound)
		dlg:close()
		if onOK then
			onOK()
		end
	end
	btn.active = true

	function dlg:draw()
		Dialog.textcolor:set()
		love.graphics.print(title, dlg.pos.x + 10, dlg.pos.y + 30)
		love.graphics.printf(text, dlg.pos.x + 15, dlg.pos.y + 60, 285)
		btn:draw()
	end

	function dlg:update(dt)
		btn:update(dt)
	end

	dlg:open()
end
