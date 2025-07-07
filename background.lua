Background = Object:extend()

function Background:new(name, length, FPS)

    self.frames = {} --Initialize 

    for i = 1,length do
        self.frames[i] = love.graphics.newImage("sprites/bgframes/"..name..i..".png")
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
    love.graphics.draw(self.frames[math.floor(self.currentFrame)],0,0,0,2,2)

end