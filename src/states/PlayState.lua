--[[
    GD50
    Breakout Remake

    -- PlayState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Represents the state of the game in which we are actively playing;
    player should control the paddle, with the ball actively bouncing between
    the bricks, walls, and the paddle. If the ball goes below the paddle, then
    the player should lose one point of health and be taken either to the Game
    Over screen if at 0 health or the Serve screen otherwise.
]]

PlayState = Class{__includes = BaseState}

--[[
    We initialize what's in our PlayState via a state table that we pass between
    states as we go from playing to serving.
]]
function PlayState:enter(params)
    self.paddle = params.paddle
    self.bricks = params.bricks
    self.health = params.health
    self.score = params.score
    self.highScores = params.highScores
    self.ball = params.ball
    self.level = params.level

    --We track all the powerups curently on screen
    self.powerups = {}

    self.recoverPoints = params.recoverPoints

    self.widerPaddlePoints = params.widerPaddlePoints

    --Tracks if there are locked bricks
    self.locked = 0

    -- give ball random starting velocity
    self.ball.speed = 100
    self.ball.angle = math.random(20, 160)
    self.ball.dx = math.cos(self.ball.angle * math.pi / 180) * self.ball.speed
    self.ball.dy = -math.sin(self.ball.angle * math.pi / 180) * self.ball.speed

    --Adding multiple balls
    self.balls = {}
    table.insert(self.balls, self.ball)

    --Check if there are locked bricks
    for k, brick in pairs(self.bricks) do
        if brick.locked == 1 then
            self.locked = 1
            break
        end
    end
end

function PlayState:update(dt)
    if self.paused then
        if love.keyboard.wasPressed('space') then
            self.paused = false
            gSounds['pause']:play()
        else
            return
        end
    elseif love.keyboard.wasPressed('space') then
        self.paused = true
        gSounds['pause']:play()
        return
    end

    -- update positions based on velocity
    self.paddle:update(dt)

    for k, ball in pairs(self.balls) do
        ball:update(dt)
    end

    for k, powerup in pairs(self.powerups) do
        powerup:update(dt)
    end

    for k=#self.powerups, 1, -1 do
        if self.powerups[k].y > VIRTUAL_HEIGHT then
            table.remove(self.powerups, k)
        end
    end

    for k, ball in pairs(self.balls) do
        if ball:collides(self.paddle) then
            -- raise ball above paddle in case it goes below it, then reverse dy
            ball.y = self.paddle.y - 8
            
            -- speed up the ball
            if ball.speed < 150 then
                ball.speed = ball.speed * 1.02
            end

            -- get new angle depending on where the ball was hit

            ball.angle = 160 - ((ball.x - self.paddle.x + 8) / (self.paddle.width + 8)) * 140
            ball.dx = math.cos(ball.angle * math.pi / 180) * ball.speed
            ball.dy = -math.sin(ball.angle * math.pi / 180) * ball.speed

            gSounds['paddle-hit']:play()
        end
    end

    -- detect collision across all bricks with the ball
    for l, ball in pairs(self.balls) do
        for k, brick in pairs(self.bricks) do

            -- only check collision if we're in play
            if brick.inPlay and ball:collides(brick) then

                -- add to score
                if brick.locked == 0 then
                    self.score = self.score + (brick.tier * 200 + brick.color * 25)
                end
                -- trigger the brick's hit function, which removes it from play
                brick:hit()
                
                --sometimes spawn a powerup
                local chance = math.random(1, 100)
                if chance > 90 then
                    powerup = PowerUpBalls()
                    powerup.x = brick.x + 8
                    powerup.y = brick.y
                    table.insert(self.powerups, powerup)
                else
                    if chance > 85 and self.locked == 1 then
                        powerup = PowerUpKey()
                        powerup.x = brick.x + 8
                        powerup.y = brick.y
                        table.insert(self.powerups, powerup)
                    end
                end

                --make the paddle wider if needed and possible
                if self.score > self.widerPaddlePoints then
                    if self.paddle.size < 4 then
                        self.paddle.size = self.paddle.size + 1
                        self.paddle.width = self.paddle.size * 32
                    end
                    if self.paddle.size < 4 then
                        self.widerPaddlePoints = self.score + self.paddle.size * 5000
                    end
                end

                -- if we have enough points, recover a point of health
                if self.score > self.recoverPoints then
                    -- can't go above 3 health
                    self.health = math.min(3, self.health + 1)

                    -- multiply recover points by 2
                    self.recoverPoints = math.min(100000, self.recoverPoints * 2)

                    -- play recover sound effect
                    gSounds['recover']:play()
                end

                -- go to our victory screen if there are no more bricks left
                if self:checkVictory() then
                    gSounds['victory']:play()

                    gStateMachine:change('victory', {
                        level = self.level,
                        paddle = self.paddle,
                        health = self.health,
                        score = self.score,
                        highScores = self.highScores,
                        ball = self.ball,
                        recoverPoints = self.recoverPoints
                    })
                end

                --
                -- collision code for bricks
                --
                -- we check to see if the opposite side of our velocity is outside of the brick;
                -- if it is, we trigger a collision on that side. else we're within the X + width of
                -- the brick and should check to see if the top or bottom edge is outside of the brick,
                -- colliding on the top or bottom accordingly 
                --

                -- left edge; only check if we're moving right, and offset the check by a couple of pixels
                -- so that flush corner hits register as Y flips, not X flips
                if ball.x + 2 < brick.x and ball.dx > 0 then
                    
                    -- flip x velocity and reset position outside of brick
                    ball.dx = -ball.dx
                    ball.x = brick.x - 8
                
                -- right edge; only check if we're moving left, , and offset the check by a couple of pixels
                -- so that flush corner hits register as Y flips, not X flips
                elseif ball.x + 6 > brick.x + brick.width and ball.dx < 0 then
                    
                    -- flip x velocity and reset position outside of brick
                    ball.dx = -ball.dx
                    ball.x = brick.x + 32
                
                -- top edge if no X collisions, always check
                elseif ball.y < brick.y then
                    
                    -- flip y velocity and reset position outside of brick
                    ball.dy = -ball.dy
                    ball.y = brick.y - 8
                
                -- bottom edge if no X collisions or top collision, last possibility
                else
                    
                    -- flip y velocity and reset position outside of brick
                    ball.dy = -ball.dy
                    ball.y = brick.y + 16
                end

                -- only allow colliding with one brick, for corners
                break
            end
        end
    end

    -- if ball goes below bounds, revert to serve state and decrease health
    for k=#self.balls, 1, -1 do
        if self.balls[k].y >= VIRTUAL_HEIGHT then
            table.remove(self.balls, k)
        end
    end

    if #self.balls == 0 then
        if self.paddle.size > 1 then
            self.paddle.size = self.paddle.size - 1
            self.paddle.width = self.paddle.size * 32
        end
        self.widerPaddlePoints = self.score + self.paddle.size * 5000
        self.health = self.health - 1
        gSounds['hurt']:play()

        if self.health == 0 then
            gStateMachine:change('game-over', {
                score = self.score,
                highScores = self.highScores
            })
        else
            gStateMachine:change('serve', {
                paddle = self.paddle,
                bricks = self.bricks,
                health = self.health,
                score = self.score,
                highScores = self.highScores,
                level = self.level,
                recoverPoints = self.recoverPoints,
                widerPaddlePoints = self.widerPaddlePoints
            })
        end
    end

    for k=#self.powerups, 1, -1 do
        if self.paddle:collides(self.powerups[k]) then     
            if self.powerups[k].type == 'key' then
                self.locked = 0
                for k, brick in pairs(self.bricks) do
                    brick.locked = 0
                end
            else
                --spawn new balls and give them a direction
                self.balls[1].angle = math.random(0,360)
                self.balls[1].dx = math.cos(self.balls[1].angle * math.pi / 180) * self.balls[1].speed
                self.balls[1].dy = -math.sin(self.balls[1].angle * math.pi / 180) * self.balls[1].speed

                ball1 = Ball()
                ball1.skin = math.random(7)
                ball1.x = self.balls[1].x
                ball1.y = self.balls[1].y
                ball1.angle = (self.balls[1].angle + 120) % 360
                ball1.speed = self.balls[1].speed
                ball1.dx = math.cos(ball1.angle * math.pi / 180) * ball1.speed
                ball1.dy = -math.sin(ball1.angle * math.pi / 180) * ball1.speed
                table.insert(self.balls, ball1)
                ball2 = Ball()
                ball2.skin = math.random(7)
                ball2.x = self.balls[1].x
                ball2.y = self.balls[1].y
                ball2.angle = (self.balls[1].angle + 240) % 360
                ball2.speed = self.balls[1].speed
                ball2.dx = math.cos(ball2.angle * math.pi / 180) * ball2.speed
                ball2.dy = -math.sin(ball2.angle * math.pi / 180) * ball2.speed
                table.insert(self.balls, ball2)
            end
            --remove powerup
            table.remove(self.powerups, k)
        end
    end

    -- for rendering particle systems
    for k, brick in pairs(self.bricks) do
        brick:update(dt)
    end

    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end
end

function PlayState:render()
    -- render bricks
    for k, brick in pairs(self.bricks) do
        brick:render()
    end

    -- render all particle systems
    for k, brick in pairs(self.bricks) do
        brick:renderParticles()
    end

    for k, powerup in pairs(self.powerups) do
        powerup:render()
    end

    self.paddle:render()

    for k, ball in pairs(self.balls) do
        ball:render()
    end
    --self.ball:render()

    renderScore(self.score)
    renderHealth(self.health)

    -- pause text, if paused
    if self.paused then
        love.graphics.setFont(gFonts['large'])
        love.graphics.printf("PAUSED", 0, VIRTUAL_HEIGHT / 2 - 16, VIRTUAL_WIDTH, 'center')
    end
end

function PlayState:checkVictory()
    for k, brick in pairs(self.bricks) do
        if brick.inPlay then
            return false
        end 
    end

    return true
end