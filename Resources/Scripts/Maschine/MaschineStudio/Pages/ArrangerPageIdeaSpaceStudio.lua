require "Scripts/Maschine/Components/Pages/IdeaSpaceBase"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
ArrangerPageIdeaSpaceStudio = class( 'ArrangerPageIdeaSpaceStudio', IdeaSpaceBase )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function ArrangerPageIdeaSpaceStudio:__init(ParentPage, Controller)

    IdeaSpaceBase.__init(self, "ArrangerPageIdeaSpaceStudio", Controller)

    self.ParentPage = ParentPage

    self.PageLEDs = { NI.HW.LED_ARRANGE }

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerPageIdeaSpaceStudio:onShow(Show)

    if Show then
        self.Controller:setTimer(self, 1)
    end

    IdeaSpaceBase.onShow(self, Show)
end

------------------------------------------------------------------------------------------------------------------------

function ArrangerPageIdeaSpaceStudio:updateArrangerToggleButtons()

    self.Screen.ScreenButton[1]:setSelected(true)
    self.Screen.ScreenButton[2]:setSelected(false)

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerPageIdeaSpaceStudio:updateSceneBankButtons()

    local FocusBank = self:getSceneBank() + 1
    self.Screen:setArrowText(1, "BANK "..tostring(FocusBank))
    self.Screen.ScreenButton[7]:setEnabled(FocusBank > 1)
    self.Screen.ScreenButton[8]:setEnabled(FocusBank < self.NumSceneBanks)

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerPageIdeaSpaceStudio:updateRetriggerButton()
    -- no retrigger button
end

------------------------------------------------------------------------------------------------------------------------

function ArrangerPageIdeaSpaceStudio:onTimer()

    self:updateLEDs()
    self:updateWheelButtonLEDs()

    if self.IsVisible then
        self.Controller:setTimer(self, 1)
    end

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerPageIdeaSpaceStudio:getSceneBank()

    return NHLController:getContext():getSceneBank8()

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerPageIdeaSpaceStudio:setSceneBank(Bank)

    NHLController:getContext():setSceneBank8(Bank)

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerPageIdeaSpaceStudio:updateWheelButtonLEDs()

    ScenePatternHelper.updateWheelButtonLEDs()

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerPageIdeaSpaceStudio:onWheelButton(Pressed)

    PatternHelper.removeFocusPattern()

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerPageIdeaSpaceStudio:getAccessiblePageInfo()

    return "Ideas View"

end

------------------------------------------------------------------------------------------------------------------------
