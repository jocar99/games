PauseState = Class{__includes = BaseState}

function PauseState:enter(params)
    gSavedState = params.savedState
    gIsSaved = true
    sounds['pause']:play()
    sounds['music']:pause()
end

function PauseState:exit()
    sounds['music']:play()
end

function PauseState:update(dt)
    if love.keyboard.wasPressed('p') then
        gStateMachine:change('countdown')
    end  
end


function PauseState:render()
    love.graphics.setFont(hugeFont)
    love.graphics.printf("Game Paused", 0, 120, VIRTUAL_WIDTH, 'center')
end