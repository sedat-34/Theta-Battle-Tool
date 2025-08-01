Bullet = Object:extend()

function Bullet:new(image, x, y, moveTypeX, moveTypeY, targetX, targetY, time)

    self = {

        image = image,
        x = x,
        y = y,
        moveTypeX = moveTypeX,
        moveTypeY = moveTypeY,
        targetX = targetX,
        targetY = targetY,
        time = time,

    }

    if self.moveTypeX then
        flux.to(self, time, {x = self.targetX}):ease(self.moveTypeX)
    end
    if self.moveTypeY then
        flux.to(self, time, {y = self.targetY}):ease(self.moveTypeY)
    end

end

function Bullet:draw()
    love.graphics.draw(self.image, self.x, self.y)
end