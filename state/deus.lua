require "gamestate"
require "maze"
require "net/pipes"
require "net/protocol"
require "util/camera"
require "gui/dialog"

Inventory = { selected = 1, items = {} }
-- circle selection in specified direction
function Inventory.select(direction)
	Inventory.selected = Inventory.selected - direction
	if Inventory.selected < 1 then
		Inventory.selected = #Inventory.items
	elseif Inventory.selected > #Inventory.items then
		Inventory.selected = 1
	end
end

function Inventory.add(item, ...)
	if not item then return end
	Inventory.items[#Inventory.items+1] = item
	Inventory.add(...)
end

function Inventory.remove(k)
	table.remove(Inventory.items, k)
end

function Inventory.draw()
	local ITEMSIZE, PADDING, SELECTIONSIZE = 32, 5, 40
	local scale = SELECTIONSIZE / ITEMSIZE
	local invsize = #Inventory.items * (ITEMSIZE + PADDING) + (SELECTIONSIZE - ITEMSIZE) - PADDING
	local x = (love.graphics.getWidth() - invsize) / 2
	for i,item in ipairs(Inventory.items) do
		item:draw(x, love.graphics.getHeight() - ITEMSIZE - PADDING, 0, scale, scale)
	end
end

Gamestate.deus = Gamestate.new()
local st = Gamestate.deus

local substate, world, playerpos, level, pipe

local wait_for_client = {alpha = 155, t = 0}
local send_world = {}
local play = {cam = Camera.new(vector(0,0),1)}
local selected_pos = vector(0,0)
--
-- handshake state
--
function wait_for_client:draw()
	love.graphics.setColor(255,255,255,self.alpha)
	love.graphics.print("Waiting for mortem",100,100)
end

function wait_for_client:update(dt)
	self.t = self.t + dt
	self.alpha = 155 + math.sin(self.t) * 100
	assert(coroutine.resume(self.handshake, Deus.pipe))
	if coroutine.status(self.handshake) == "dead" then
		substate = send_world
	end
end
--
-- world sending state
--
function send_world:draw()
	love.graphics.setColor(255,255,255)
	love.graphics.print(string.format("Sending world..."),100,100)
end

function send_world:update(dt)
	assert(coroutine.resume(self.sendworld, world, playerpos))
	if coroutine.status(self.sendworld) == "dead" then
		level = Level.new(world)
		camera = Camera.new(
			vector(#world[1]+2, #world+2) * TILESIZE / 2,
			math.min(love.graphics.getWidth()  / ((#world[1]+1)*TILESIZE),
					 love.graphics.getHeight() / ((#world+1)*TILESIZE)))
		substate = play
		selected_pos = vector(math.floor(#world[1]/2), math.floor(#world/2))
	end
end
--
-- play state
--
local time, time_since_last_sync = 0,0
local keydelay = 0
local min, max = math.min, math.max
local actions = {
	modifier_none = {
		up    = function() selected_pos.y = max(selected_pos.y - 1, 0) end,
		down  = function() selected_pos.y = min(selected_pos.y + 1, #world) end,
		left  = function() selected_pos.x = max(selected_pos.x - 1, 0) end,
		right = function() selected_pos.x = min(selected_pos.x + 1, #world[1]) end,
	},
	modifier_zoom = {
		up    = function() --[[ increase zoom level --]] end,
		down  = function() --[[ decrease zoom level --]] end,
		left  = function() --[[ select other item --]] end,
		right = function() --[[ select other item --]] end,
	},
}

function play:update(dt)
	time = time + dt
	time_since_last_sync = time_since_last_sync + dt

	player:update(dt)

	if time_since_last_sync > .5 then
		Deus.sendClock(time)
		time_since_last_sync = 0
	end

	local message = getMessage(Deus.pipe)
	if message and message[1] == "moveo" then
		player.pos = vector(tonumber(message[2]), tonumber(message[3]))
	end


	if keydelay <= 0 then
		keydelay = .15

		-- TODO: select keymap
		local keyaction = actions.modifier_none
		for key, fun in pairs(keyaction) do
			if love.keyboard.isDown(key) then
				fun()
			end
		end

	else
		keydelay = keydelay - dt
	end
end

function play:draw()
	camera:predraw()
	level:draw()
	player.draw()
	-- selection:draw()
	love.graphics.setColor(255,255,255)
	love.graphics.rectangle('fill', playerpos.x*TILESIZE, playerpos.y*TILESIZE, 32,32)
	love.graphics.setColor(255,160,0,100)
	love.graphics.rectangle('fill', selected_pos.x*TILESIZE, selected_pos.y*TILESIZE, 32,32)
	camera:postdraw()
	Inventory.draw()
	-- time:draw()
end

--
-- Main gamestate. Forwards to substates
--
local camera
function st:enter(pre, port, grid, startpos, exit)
	Deus.pipe = NetPipe.new(port)
	love.graphics.setBackgroundColor(0,0,0)
	world, playerpos = maze, startpos
	substate = wait_for_client

	wait_for_client.handshake = coroutine.create(Deus.handshake)
	send_world.sendworld = coroutine.create(Deus.sendworld)

	player.init(startpos, 20)
	function player.ondie()
		Deus.killPlayer()
	end

	level = Level.new(grid)
	local levelsize = vector(#grid[1], #grid) * TILESIZE
	local zoom = math.min(love.graphics.getWidth() / levelsize.x,
	                      love.graphics.getHeight() / levelsize.y)
	camera = Camera.new(levelsize / 2, zoom)

	Inventory.selected = 1
	Inventory.items = {
		wrapDraw(love.graphics.newImage('images/left.png')),
		wrapDraw(love.graphics.newImage('images/right.png')),
		wrapDraw(love.graphics.newImage('images/up.png')),
		wrapDraw(love.graphics.newImage('images/down.png')),
		wrapDraw(love.graphics.newImage('images/deadend.png')),
	}
end

function st:draw()
	substate:draw()
end

function st:update(dt)
	local all_ok, error = pcall(function() substate:update(dt) end)
	if not all_ok then
		MessageBox("Error occured", error, function() Gamestate.switch(Gamestate.title) end)
	end
end

function st:mousereleased(x,y,btn)
	if substate.mousereleased then
		substate:mousereleased(x,y,btn)
	end
end

function st:keypressed(key,unicode)
	if substate.keypressed then
		substate:keypressed(key,unicode)
	end
end
