------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/MaschineStudio/Pages/StepPageStudio"
require "Scripts/Shared/Helpers/StepHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
StepPageMK3 = class( 'StepPageMK3', StepPageStudio )

------------------------------------------------------------------------------------------------------------------------

function StepPageMK3:__init(Controller)

    EventsPageBase.__init(self, "StepPageMK3", Controller)

    -- define page leds
    self.PageLEDs = { NI.HW.LED_STEP }
    self:setPinned()

    StepHelper.PatternSegment = 0

    -- Used to keep track of what pad velocities were on pad-down events, because the notes
    -- are added only on pad-release, iff the pad wasn't held long enough to go into the StepModPage.
    self.PadVelocities = {}

end

------------------------------------------------------------------------------------------------------------------------

function StepPageMK3:setPinned(PinState)

    self.IsPinned = true -- always pinned

end

------------------------------------------------------------------------------------------------------------------------

function StepPageMK3:setupScreen()

    StepPageStudio.setupScreen(self)

    self.Screen.ScreenButton[4]:setText("KEYBOARD")

end

------------------------------------------------------------------------------------------------------------------------

function StepPageMK3:updateScreens(ForceUpdate)

    self:updateWheelButtonLEDs()

    StepPageStudio.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function StepPageMK3:updateScreenButtons(ForceUpdate)

    self.Screen.ScreenButton[3]:setVisible(NI.DATA.StateHelper.isSongEntityFocused(App, NI.DATA.FOCUS_ENTITY_PATTERN))
    self.Screen.ScreenButton[4]:setSelected(PadModeHelper.getKeyboardMode())
    self.Screen.ScreenButton[5]:setSelected(StepHelper.FollowModeOn)

    EventsPageBase.updateScreenButtons(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function StepPageMK3:onTimer()

    self:onTimerStepMode()
    Events4DWheel.onControllerTimer(self.Controller, PadModeHelper.getKeyboardMode())

    PageMaschine.onTimer(self)

    if self.IsVisible then
        self.Controller:setTimer(self, 1)
    end

end

------------------------------------------------------------------------------------------------------------------------

function StepPageMK3:onScreenButton(Index, Pressed)

    if Pressed then
        if Index == 3 and NI.DATA.StateHelper.isSongEntityFocused(App, NI.DATA.FOCUS_ENTITY_PATTERN) then
            local Pattern = NI.DATA.StateHelper.getFocusEventPattern(App)
            if Pattern then
                NI.DATA.EventPatternAccess.doublePattern(App, Pattern)
            end

        elseif Index == 4 then
            PadModeHelper.toggleKeyboardMode()

        elseif Index == 5 then
            StepHelper.FollowModeOn = not StepHelper.FollowModeOn
        end
    end

    EventsPageBase.onScreenButton(self, Index, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function StepPageMK3:onPadEvent(PadIndex, Trigger, PadValue)

    if self.Controller:getShiftPressed() then
        return
    end

    StepPageStudio.onPadEvent(self, PadIndex, Trigger, PadValue)

end

------------------------------------------------------------------------------------------------------------------------

function StepPageMK3:onWheel(Inc)

    if NHLController:getJogWheelMode() == NI.HW.JOGWHEEL_MODE_DEFAULT then
        return Events4DWheel.onWheel(self.Controller, Inc)
    end

end

------------------------------------------------------------------------------------------------------------------------

function StepPageMK3:updateWheelButtonLEDs()

    --handled, do not execute default implementation
end

------------------------------------------------------------------------------------------------------------------------

function StepPageMK3:onWheelDirection(Pressed, DirectionButton)

    Events4DWheel.onWheelDirection(self.Controller, Pressed, PadModeHelper.getKeyboardMode())

end

------------------------------------------------------------------------------------------------------------------------

function StepPageMK3:getAccessibleLeftRightButtonText()

    if not NHLController:isExternalAccessibilityRunning() then
        return
    end
    return "Select left event", "Select right event"
end

------------------------------------------------------------------------------------------------------------------------

function StepPageMK3:getAccessiblePageInfo()

    return "Step Page"

end

------------------------------------------------------------------------------------------------------------------------
