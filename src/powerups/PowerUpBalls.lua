PowerUpBalls = Class{}

function PowerUpBalls:init()
    self.width = 16
    self.height = 16

    self.x = 0
    self.y = 0

    self.type = 'balls'
    
    self.dy = 20
end

function PowerUpBalls:update(dt)
    self.y = self.y + self.dy * dt
end

function PowerUpBalls:render()
    love.graphics.draw(gTextures['main'], gFrames['powerups'][0], self.x, self.y)
end