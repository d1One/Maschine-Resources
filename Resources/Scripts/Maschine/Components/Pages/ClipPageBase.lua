
------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Components/TransactionSequenceMarker"
require "Scripts/Shared/Pages/PageMaschine"
require "Scripts/Maschine/Helper/ClipHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
ClipPageBase = class( 'ClipPageBase', PageMaschine )

------------------------------------------------------------------------------------------------------------------------
-- const
------------------------------------------------------------------------------------------------------------------------

ClipPageBase.SCREEN_PIN_TAB_BUTTON_PATTERN = 1
ClipPageBase.SCREEN_PIN_TAB_BUTTON_CLIP = 2

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function ClipPageBase:__init(Controller, Page)

    PageMaschine.__init(self, Page, Controller)

    -- setup screen
    self:setupScreen()

    self.TransactionSequenceMarker = TransactionSequenceMarker()

    -- define page leds
    self.PageLEDs = { NI.HW.LED_PATTERN }

end

------------------------------------------------------------------------------------------------------------------------

function ClipPageBase:setupScreen()

    self.Screen.ScreenButton[ClipPageBase.SCREEN_PIN_TAB_BUTTON_PATTERN]:style("PATTERN", "HeadTabLeft")
    self.Screen.ScreenButton[ClipPageBase.SCREEN_PIN_TAB_BUTTON_CLIP]:style("CLIP", "HeadPinTabRight")
    self.Screen.ScreenButton[7]:style("<", "ScreenButton")
    self.Screen.ScreenButton[8]:style(">", "ScreenButton")

end

------------------------------------------------------------------------------------------------------------------------

function ClipPageBase:updateScreens(ForceUpdate)

    -- update pad buttons
    self.Screen:updatePadButtonsWithFunctor( function (Index) return ClipHelper.ClipStateFunctor(Index, true) end)

    PageMaschine.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function ClipPageBase:updateScreenButtons(ForceUpdate)

    self.Screen.ScreenButton[ClipPageBase.SCREEN_PIN_TAB_BUTTON_CLIP]:setSelected(self.ParentPage.IsPinned)

    ClipHelper.updateClipPageScreenButtons(self.Screen, self.Controller:getShiftPressed(), true)

    PageMaschine.updateScreenButtons(self, ForceUpdate)
end

------------------------------------------------------------------------------------------------------------------------

function ClipPageBase:onShow(Show)

    if Show then
        self.TransactionSequenceMarker:reset()
    end

    PageMaschine.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function ClipPageBase:onPadEvent(PadIndex, Trigger)

    ClipHelper.onClipPagePadEvent(PadIndex, Trigger, self.Controller.SwitchPressed[NI.HW.BUTTON_TRANSPORT_ERASE])

    return true --handled

end

------------------------------------------------------------------------------------------------------------------------

function ClipPageBase:updatePadLEDs()

    ClipHelper.updatePadLEDs(self.Controller.PAD_LEDS)

end



------------------------------------------------------------------------------------------------------------------------

function ClipPageBase:onScreenButton(Idx, Pressed)

    if Pressed then

        if Idx == ClipPageBase.SCREEN_PIN_TAB_BUTTON_CLIP then
            self.ParentPage:togglePinState()
        else
            ClipHelper.onClipPageScreenButtonPressed(Idx, self.Controller:getShiftPressed(), true)
            if Idx == ClipPageBase.SCREEN_PIN_TAB_BUTTON_PATTERN then
                -- update parent (forward page) on switch to Pattern Page to show new subpage immediately
                self.ParentPage:updateScreens()
            end
        end

    end

    -- call base class for update
    PageMaschine.onScreenButton(self, Idx, Pressed)

end

------------------------------------------------------------------------------------------------------------------------
