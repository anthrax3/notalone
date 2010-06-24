require "gamestate"
require "state_deus"
require "state_mortem"
require "state_play"
require "maze"
require "button"
require "input"
require "dialog"

state_title = Gamestate.new()
local st = state_title

local font1,font2
local dlgDeus, btnDeus, dlgMortem, btnMortem

local function makeDialogDeus()
    dlgDeus = Dialog.new(vector(450, 180))
    local inpPort = Input.new(dlgDeus.pos + vector(270,80), vector(270,40), "%d", font2)
    inpPort.active, inpPort.text = true, "12345"
    inpPort:centerText()

    local btnOK = Button.new("OK", dlgDeus.pos + vector(260, 150), vector(110,40), font2)
    function btnOK.onClick()
        dlgDeus:close()
        Gamestate.switch(state_deus, tonumber(inpPort.text), Maze.new(80,60))
    end

    local btnClose = Button.new("Cancel", dlgDeus.pos + vector(380, 150), vector(110,40), font2)
    function btnClose.onClick() 
        dlgDeus:close()
    end

    function dlgDeus:enter() Input.add(inpPort) end
    function dlgDeus:leave() Input.remove(inpPort) end
    function dlgDeus:draw(dt)
        love.graphics.setFont(font2)
        love.graphics.setColor(0,0,0)
        love.graphics.print('Be a god', self.pos.x+300, self.pos.y+30)
        love.graphics.print('Port:', self.pos.x+10, self.pos.y+90)
        btnOK:draw()
        btnClose:draw()
        inpPort:draw()
    end
    function dlgDeus:update(dt)
        btnOK:update(dt)
        btnClose:update(dt)
    end

    btnDeus = Button.new("Deus", vector(400,400), vector(400,40), font2)
    btnDeus.onClick = function() dlgDeus:open() end
end

local function makeDialogMortem()
    dlgMortem = Dialog.new(vector(450, 240))
    local inpIP = Input.new(dlgMortem.pos + vector(270,80), vector(270,40), "[%d.]", font2)
    inpIP.active, inpIP.text = true, "127.0.0.1"
    inpIP:centerText()
    local inpPort = Input.new(dlgMortem.pos + vector(270,140), vector(270,40), "%d", font2)
    inpPort.text = "12345"
    inpPort:centerText()

    function inpIP:ontab() inpIP.active = false inpPort.active = true end
    function inpPort:ontab() inpPort.active = false inpIP.active = true end

    local btnOK = Button.new("OK", dlgMortem.pos + vector(260, 210), vector(110,40), font2)
    function btnOK.onClick() 
        dlgMortem:close()
        Gamestate.switch(state_mortem, inpIP.text, tonumber(inpPort.text))
    end

    local btnClose = Button.new("Cancel", dlgMortem.pos + vector(380, 210), vector(110,40), font2)
    function btnClose.onClick() 
        dlgMortem:close()
    end

    function dlgMortem:enter() Input.add(inpPort, inpIP) end
    function dlgMortem:leave() Input.remove(inpPort, inpIP) end
    function dlgMortem:draw(dt)
        love.graphics.setFont(font2)
        love.graphics.setColor(0,0,0)
        love.graphics.print('You will perish', self.pos.x+220, self.pos.y+30)
        love.graphics.print('IP#:', self.pos.x+10, self.pos.y+90)
        love.graphics.print('Port:', self.pos.x+10, self.pos.y+150)
        btnOK:draw()
        btnClose:draw()
        inpIP:draw()
        inpPort:draw()
    end
    function dlgMortem:update(dt)
        btnOK:update(dt)
        btnClose:update(dt)
    end

    btnMortem = Button.new("Mortem", vector(400,450), vector(400,40), font2)
    btnMortem.onClick = function() dlgMortem:open() end
end

function st:enter()
	love.graphics.setBackgroundColor(40,80,20)
	if not font1 then
		font1 = love.graphics.newFont(12)
	end
	if not font2 then
		font2 = love.graphics.newFont(30)
	end

    if not dlgDeus then makeDialogDeus() end
	if not dlgMortem then makeDialogMortem() end
	if not btnAlone then
		btnAlone = Button.new("Yes, I Am Alone", vector(400,350), vector(400,40), font2)
		btnAlone.onClick = function()
			local grid,start = Maze.new(20,15)
			Gamestate.switch(state_play, grid, start, 20)
		end
	end

    Button.add(btnAlone, btnDeus, btnMortem)
end

function st:leave()
	Button.remove_all()
	Input.remove_all()
	love.graphics.setFont(font1)
end

function st:update(dt)
	Button.update_all(dt)
end

function st:draw()
	love.graphics.setFont(font2)
	love.graphics.setColor(0,0,0)
	love.graphics.print('You Are Not Alone In This World', 200, 100)
	Button.draw_all()
	Input.draw_all()
	love.graphics.setFont(font1)
end

function st:keypressed(key, unicode)
	Input.handleKeyPressed(unicode)
end

function st:mousereleased(x,y,btn)
	Input.handleMouseDown(x,y,btn)
end
