--only here as I design the code
local bullets = {}

Bullet = Object:extend()

function Bullet:new(image, x, y, moveTypeX, moveTypeY, targetX, targetY, time, width, height)

    self = {

        image = image,
        x = x,
        y = y,
        moveTypeX = moveTypeX,
        moveTypeY = moveTypeY,
        targetX = targetX,
        targetY = targetY,
        time = time,
        width = width,
        height = height,

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

function Bullet:update()
    if

    Sole.x + 18 * Sole.size > self.x
    and self.x + self.width > Sole.x
    and self.y + self.height > Sole.y
    and Sole.y + 18 * Sole.size > self.y

    then

        local selfpos

        for i = #bullets, 1, -1 do
            if bullets[i] == self then selfpos = i end
        end

        table.remove(bullets, selfpos)

    end
end