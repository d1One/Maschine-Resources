------------------------------------------------------------------------------------------------------------------------
-- Snake Game
------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Jam/Pages/PageJam"
require "Scripts/Maschine/Jam/Helper/JamHelper"
require "Scripts/Shared/Helpers/MiscHelper"
require "Scripts/Shared/Helpers/LedHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
SnakePage = class( 'SnakePage', PageJam )

------------------------------------------------------------------------------------------------------------------------

function SnakePage:__init(Controller)

    PageJam.__init(self, "SnakePage", Controller)
    self:reset()

end

------------------------------------------------------------------------------------------------------------------------

function SnakePage:reset()

    self.CurrentSnakeDirection = 2
    self.NewSnakeDirection = 2

    self.SnakeBody = {{Row = 4, Column = 6},
                      {Row = 4, Column = 5},
                      {Row = 4, Column = 4},
                      {Row = 4, Column = 3},
                      {Row = 4, Column = 2}}

    self.FoodLocation = {}
    self:placeFood()

    self.SpeedUpDelay = 2
    self.FoodEatenCounter = 0

    self.MoveDelay = 15
    self.MoveTimer = self.MoveDelay

    self.GameOverAnimationLength = 50
    self.GameOverAnimationTimer = self.GameOverAnimationLength
    self.PlayGameOverAnimation = false

    self.SnakeColor = 1

end

------------------------------------------------------------------------------------------------------------------------

function SnakePage:updatePadLEDs()

    self:moveSnake()

    LEDHelper.updateMatrixLedsWithFunctor(JamControllerBase.PAD_LEDS,
    JamControllerBase.NUM_PAD_COLUMNS,
    JamControllerBase.NUM_PAD_ROWS,
    function(Row, Column)

        local Selected, Enabled, Flashing, Color = false, false, false, nil

        -- Play game over animation
        if self.PlayGameOverAnimation then
            Color = math.random(16)
            Selected = true
            return Selected, Enabled, Color, Flashing
        end

        -- Draw Snake
        for index, section in ipairs(self.SnakeBody) do
            if index == 1 and Row == section.Row and Column == section.Column then
                Enabled, Selected = true, true
                Color = self.SnakeColor
                return Selected, Enabled, Color, Flashing
            elseif Row == section.Row and Column == section.Column then
                Color = self.SnakeColor
                Enabled = true
                return Selected, Enabled, Color, Flashing
            end
        end

        -- Draw Food
        if Row == self.FoodLocation.Row and Column == self.FoodLocation.Column then
            Color = math.random(1, 16)
            Selected = true
            return Selected, Enabled, Color, Flashing
        end

        return Selected, Enabled, Color, Flashing
    end)

    self:updateTimers()

end

------------------------------------------------------------------------------------------------------------------------

function SnakePage:updateTimers()

    if self.MoveTimer <= 0 then
        self.MoveTimer = self.MoveDelay
    else
        self.MoveTimer = self.MoveTimer - 1
    end

    if self.GameOverAnimationTimer <= 0 then
        self.PlayGameOverAnimation = false
    elseif self.PlayGameOverAnimation then
        self.GameOverAnimationTimer = self.GameOverAnimationTimer - 1
    end

end

------------------------------------------------------------------------------------------------------------------------

function SnakePage:moveSnake()

    if self.PlayGameOverAnimation or self.MoveTimer ~= 0 then
        return
    end

    local SnakeLength = #self.SnakeBody

    -- Eat Food
    if self.SnakeBody[1].Row == self.FoodLocation.Row and self.SnakeBody[1].Column == self.FoodLocation.Column then
        self.FoodEatenCounter = self.FoodEatenCounter + 1
        self:placeFood()

        -- Extend snake
        self.SnakeBody[SnakeLength + 1] = {}
        self.SnakeBody[SnakeLength + 1].Row = self.SnakeBody[SnakeLength].Row
        self.SnakeBody[SnakeLength + 1].Column = self.SnakeBody[SnakeLength].Column

        -- Add event to current focused sound just ahead of playhead
        local Sound = NI.DATA.StateHelper.getFocusSound(App)
        local Group = NI.DATA.StateHelper.getFocusGroup(App)
        local Time = App:getTransportInfo():getPositionAsTicks() + 100
        StepHelper.toggleSoundEvent(127, Time, true, Group, Sound, 60)

        self:speedUp()
        self.SnakeColor = math.wrap(self.SnakeColor + 1, 1, 16)
    end

    -- Move snake
    self.CurrentSnakeDirection = self.NewSnakeDirection

    for i = #self.SnakeBody, 2, -1 do
        self.SnakeBody[i].Row = self.SnakeBody[i - 1].Row
        self.SnakeBody[i].Column = self.SnakeBody[i - 1].Column
    end

    if self.CurrentSnakeDirection == 1 then
        self.SnakeBody[1].Row = math.wrap(self.SnakeBody[1].Row - 1, 1, JamControllerBase.NUM_PAD_ROWS)

    elseif self.CurrentSnakeDirection == 2 then
        self.SnakeBody[1].Column = math.wrap(self.SnakeBody[1].Column + 1, 1, JamControllerBase.NUM_PAD_COLUMNS)

    elseif self.CurrentSnakeDirection == 3 then
        self.SnakeBody[1].Row = math.wrap(self.SnakeBody[1].Row + 1, 1, JamControllerBase.NUM_PAD_ROWS)

    elseif self.CurrentSnakeDirection == 4 then
        self.SnakeBody[1].Column = math.wrap(self.SnakeBody[1].Column - 1, 1, JamControllerBase.NUM_PAD_COLUMNS)
    end

    -- Game ends if head touches body
    for i = 2, SnakeLength do

        if self.SnakeBody[1].Row == self.SnakeBody[i].Row and self.SnakeBody[1].Column == self.SnakeBody[i].Column then
            self:reset()
            self.PlayGameOverAnimation = true
            return
        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function SnakePage:speedUp()

    -- Do not increase speed if at max
    if self.MoveDelay == 1 then
        return
    end

    if self.FoodEatenCounter == self.SpeedUpDelay then
        self.MoveDelay = self.MoveDelay - 1
        self.FoodEatenCounter =  0
    end

end

------------------------------------------------------------------------------------------------------------------------

function SnakePage:placeFood()

    repeat
        local foodOnSnake = false
        self.FoodLocation.Row = math.random(JamControllerBase.NUM_PAD_ROWS)
        self.FoodLocation.Column = math.random(JamControllerBase.NUM_PAD_COLUMNS)

        for _, section in ipairs(self.SnakeBody) do
            if section.Row == self.FoodLocation.Row and section.Column == self.FoodLocation.Column then
                foodOnSnake = true
                break
            end
        end
    until
        foodOnSnake == false
end

------------------------------------------------------------------------------------------------------------------------

function SnakePage:onDPadButton(Button, Pressed)

    if not Pressed then
        return
    end

    if Button == NI.HW.BUTTON_DPAD_UP then

        if self.CurrentSnakeDirection == 3 or self.CurrentSnakeDirection == 1 then
            return
        end

        self.NewSnakeDirection = 1

    elseif Button == NI.HW.BUTTON_DPAD_RIGHT then

        if self.CurrentSnakeDirection == 4 or self.CurrentSnakeDirection == 2 then
            return
        end

        self.NewSnakeDirection = 2

    elseif Button == NI.HW.BUTTON_DPAD_DOWN then

        if self.CurrentSnakeDirection == 1 or self.CurrentSnakeDirection == 3 then
            return
        end

        self.NewSnakeDirection = 3

    elseif Button == NI.HW.BUTTON_DPAD_LEFT then

        if self.CurrentSnakeDirection == 2 or self.CurrentSnakeDirection == 4 then
            return
        end

        self.NewSnakeDirection = 4

    end

end

------------------------------------------------------------------------------------------------------------------------

function SnakePage:updateDPadLEDs()

    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_DPAD_UP, NI.HW.BUTTON_DPAD_UP, true)
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_DPAD_DOWN, NI.HW.BUTTON_DPAD_DOWN, true)
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_DPAD_RIGHT, NI.HW.BUTTON_DPAD_RIGHT, true)
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_DPAD_LEFT, NI.HW.BUTTON_DPAD_LEFT, true)

end

------------------------------------------------------------------------------------------------------------------------

function SnakePage:onPadButton(Column, Row, Pressed)

    -- Overridden from base class to avoid a crash when pressing matrix buttons

end

------------------------------------------------------------------------------------------------------------------------
