PowerUpKey = Class{}

function PowerUpKey:init()
    self.width = 16
    self.height = 16

    self.x = 0
    self.y = 0
    
    self.type = 'key'

    self.dy = 20
end

function PowerUpKey:update(dt)
    self.y = self.y + self.dy * dt
end

function PowerUpKey:render()
    love.graphics.draw(gTextures['main'], gFrames['powerups'][1], self.x, self.y)
end