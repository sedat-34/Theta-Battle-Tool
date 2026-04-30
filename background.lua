Background = Object:extend()

function Background:new(name, length, FPS)

    self.sheet = love.graphics.newImage("sprites/"..name..".png")
    
    local sheetarr
    local sheetjson = io.open("sprites/"..name..".json", "r")
    if sheetjson then
        local tempsheetarr = sheetjson:read("*a")
        sheetarr = json.decode(tempsheetarr)
        sheetjson:close()
    end

    self.sheetarr = sheetarr

    local sheetwidth, sheetheight = self.sheetarr.meta.size.w, self.sheetarr.meta.size.h

    self.quadrants = {}

    for i = 1,length do
        local filename = name..i..".png"
        local quaddata = self.sheetarr.frames[filename].frame
        self.quadrants[i] = love.graphics.newQuad(quaddata.x, quaddata.y, quaddata.w, quaddata.h, sheetwidth, sheetheight)
    end

    self.length = length
    self.currentFrame = 1
    self.fps = FPS

end

function Background:update(dt)

    self.currentFrame = self.currentFrame + dt*self.fps

    if math.floor(self.currentFrame) > self.length then

        self.currentFrame = 1

    end

end

function Background:draw()

    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(self.sheet, self.quadrants[math.floor(self.currentFrame)],0,0,0,2,2)

end