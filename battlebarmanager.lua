local battlebarmanager = {}

function battlebarmanager:load()
    self.members_to_attack = {}
    self.enemies_to_attack = {}
    self.battlebars = {}
end

function battlebarmanager:update(dt)
    for i = 1, #self.battlebars do
        if self.battlebars[i] then
            self.battlebars[i]:update(dt)
        end
    end
end

function battlebarmanager:draw()
    for i = 1, #self.battlebars do
        self.battlebars[i]:draw()
    end
end

battlebarmanager:load()

return battlebarmanager