require "Scripts/Shared/Components/Timer"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
QuickArrange = class( 'QuickArrange' )

------------------------------------------------------------------------------------------------------------------------

function QuickArrange:__init(Controller)

    self.Controller = Controller
    self.TimerInterval = 20
    self.IsActive = false

end

------------------------------------------------------------------------------------------------------------------------

function QuickArrange:setTimer()

    self.Controller.Timer:setTimer(self, self.TimerInterval)

end

------------------------------------------------------------------------------------------------------------------------

function QuickArrange:resetTimer()

    self.Controller.Timer:resetTimer(self)
    NHLController:setSceneButtonMode(NI.HW.SCENE_BUTTON_MODE_DEFAULT)
    self.IsActive = false

end

------------------------------------------------------------------------------------------------------------------------

function QuickArrange:onTimer()

    self.Controller.CanToggleSceneButtonView = false
    NHLController:setSceneButtonMode(NI.HW.SCENE_BUTTON_MODE_QUICK_ARRANGE)
    self.IsActive = true

end

------------------------------------------------------------------------------------------------------------------------

function QuickArrange:isActive()

    return self.IsActive

end

------------------------------------------------------------------------------------------------------------------------
