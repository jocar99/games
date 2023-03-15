--[[
    GD50
    Match-3 Remake

    -- Tile Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    The individual tiles that make up our game board. Each Tile can have a
    color and a variety, with the varietes adding extra points to the matches.
]]

Tile = Class{}

function Tile:init(x, y, color, variety, shiny)
    
    -- board positions
    self.gridX = x
    self.gridY = y

    -- coordinate positions
    self.x = (self.gridX - 1) * 32
    self.y = (self.gridY - 1) * 32

    -- tile appearance/points
    self.color = color
    self.variety = variety

    --tile shiny or not
    self.shiny = shiny
    self.psystem = love.graphics.newParticleSystem(gTextures['particle'], 64)
    self.psystem:setParticleLifetime(0.5, 1)
    self.psystem:setEmissionArea('uniform', 10, 10)
    self.psystem:setEmissionRate(20)
    self.psystem:setSizes(0.4)
    self.psystem:setColors(212/255, 175/255, 55/255, 255/255, 212/255, 175/255, 55/255, 127/255)
end

function Tile:update(dt)
    self.psystem:update(dt)
end

function Tile:render(x, y)
    
    -- draw shadow
    love.graphics.setColor(34, 32, 52, 255)
    love.graphics.draw(gTextures['main'], gFrames['tiles'][self.color][self.variety],
        self.x + x + 2, self.y + y + 2)

    -- draw tile itself
    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.draw(gTextures['main'], gFrames['tiles'][self.color][self.variety],
        self.x + x, self.y + y)

    if self.shiny then
        love.graphics.setColor(212/255, 175/255, 55/255, 50/255)
        love.graphics.rectangle('fill', self.x + x, self.y + y, 32, 32, 4)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(self.psystem, self.x + 16 + x, self.y + 16 + y)
    end
end