------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Components/TransportSection"
require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Shared/Helpers/PadModeHelper"
require "Scripts/Shared/Helpers/LedHelper"
require "Scripts/Shared/Helpers/StepHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
Page = class( 'Page' )

------------------------------------------------------------------------------------------------------------------------

function Page:__init(Name, Controller)

    -- init name
    self.Name = Name

    -- Controller
    self.Controller = Controller

    -- LEDs related to this page
    self.PageLEDs = {}

    self.IsVisible = false
    self.IsPinned  = false

end

------------------------------------------------------------------------------------------------------------------------

function Page:updateScreens(ForceUpdate)
end

------------------------------------------------------------------------------------------------------------------------

function Page:updateGroupLEDs()

    local GroupBank = MaschineHelper.getFocusGroupBank(self)

    if GroupBank >= 0 then
        LEDHelper.updateLEDsWithFunctor(self.Controller.GROUP_LEDS,
                                        GroupBank * 8,
                                        function (Index) return MaschineHelper.getLEDStatesGroupSelectedByIndex(Index, true) end,
                                        function (Index) return MaschineHelper.getGroupColorByIndex(Index, true) end,
                                        MaschineHelper.getFlashStateGroupsNoteOn)

    end

end

------------------------------------------------------------------------------------------------------------------------

function Page:updatePadLEDs()

   PadModeHelper.updatePadLEDs(self.Controller)

end

------------------------------------------------------------------------------------------------------------------------
-- updatePageLEDs: Override to have other related page LEDs set on/off
------------------------------------------------------------------------------------------------------------------------

function Page:updatePageLEDs(LEDState)

    -- Turn on/off page LEDs
    for Index, LedID in ipairs (self.PageLEDs) do
        LEDHelper.setLEDState(LedID, LEDState)
    end

end

------------------------------------------------------------------------------------------------------------------------
-- Show / Hide Page
------------------------------------------------------------------------------------------------------------------------

function Page:onShow(Show)

    self.IsVisible = Show

    if Show == true then

        -- show screen
        NHLController:getHardwareDisplay():getPageStack():setTop(self.Screen.RootBar)

        -- update
        self:updateScreens(true)

    elseif NI.HW.FEATURE.PADS then

        NHLController:setPadMode(NI.HW.PAD_MODE_PAGE_DEFAULT)

    end

end

------------------------------------------------------------------------------------------------------------------------

function Page:setPinned(PinState)

    self.IsPinned = PinState

end

------------------------------------------------------------------------------------------------------------------------

function Page:togglePinState()

    local PageID = self.Controller.PageManager:getPageID(self)
    local ButtonID = self.Controller:getModPageControlID(PageID)
    local PageStack = NHLController:getPageStack()

    if PageID then
        self:setPinned(not self.IsPinned)
        NHLController:getPageStack():setPagePinState(PageID, self.IsPinned)
    else
        print("WARNING: Page not found on Page:togglePinState.")
        return
    end

    if self.IsPinned == false then

        if not self.Controller.SwitchPressed[ButtonID] then
            -- close the page if the button for it isn't being held down and the page is not pinned anymore
            PageStack:popPage()
        end

    else

        -- remove all other modifier pages in the stack
        local RemovePages = {}
        for i = 1, PageStack:getNumPages()-2 do
            local PID = PageStack:getPageAt(i)

            if self.Controller:isModifierPageByID(PID) then
                RemovePages[#RemovePages + 1] = PID
            end
        end

        for i, PID in ipairs(RemovePages) do
            PageStack:removePage(PID)
        end

    end

    self:updateScreens(false)

end

------------------------------------------------------------------------------------------------------------------------
-- event handling
------------------------------------------------------------------------------------------------------------------------

function Page:onPadEvent(PadIndex, Trigger, PadValue)

    if NHLController:getPadMode() == NI.HW.PAD_MODE_STEP then

        StepHelper.onPadEvent(PadIndex, Trigger, PadValue)

    elseif Trigger and self:canFocusSoundOnPadTrigger() then

        PadModeHelper.FocusedSoundIndex = PadIndex
        MaschineHelper.setFocusSound(PadIndex, false)

    end

end

------------------------------------------------------------------------------------------------------------------------
-- onWheel: MK2 and Mikro wheel event
------------------------------------------------------------------------------------------------------------------------

function Page:onWheel(Value)
end

------------------------------------------------------------------------------------------------------------------------
-- onWheelButton: MK2 and Mikro wheel event
------------------------------------------------------------------------------------------------------------------------

function Page:onWheelButton(Pressed)
end

------------------------------------------------------------------------------------------------------------------------
-- Handler for page button events. Called by self.Controller before pages are changed so that individual
-- pages have a chance to override default functionality and can block changing the page; return true for handled.
------------------------------------------------------------------------------------------------------------------------

function Page:onPageButton(Button, PageID, Pressed)

	return false

end

------------------------------------------------------------------------------------------------------------------------

function Page:onControlButton(Pressed)

    self.Controller:onPageButton(NI.HW.BUTTON_CONTROL, NI.HW.PAGE_CONTROL, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function Page:onLeftRightButton(Right, Pressed)
end

------------------------------------------------------------------------------------------------------------------------

function Page:onEnterButton(Pressed)
end

------------------------------------------------------------------------------------------------------------------------

function Page:onBackButton(Pressed)
end

------------------------------------------------------------------------------------------------------------------------

function Page:onScreenButton(ButtonIdx, Pressed)
end

------------------------------------------------------------------------------------------------------------------------

function Page:onNavigateButton(Pressed)
end

------------------------------------------------------------------------------------------------------------------------

function Page:onWheelDirection(Pressed, Button)
end

------------------------------------------------------------------------------------------------------------------------
-- Transport Buttons
------------------------------------------------------------------------------------------------------------------------

function Page:onPlayButton(Pressed)
end

------------------------------------------------------------------------------------------------------------------------

function Page:onStopButton(Pressed)
end

------------------------------------------------------------------------------------------------------------------------

function Page:onRecordButton(Pressed)
end

------------------------------------------------------------------------------------------------------------------------

function Page:onLoopButton(Pressed)
end

------------------------------------------------------------------------------------------------------------------------

function Page:onEraseButton(Pressed)
end

------------------------------------------------------------------------------------------------------------------------

function Page:onPrevNextButton(Pressed, Next)
end

------------------------------------------------------------------------------------------------------------------------

function Page:onShiftButton(Pressed)

    self.Controller.TransportSection:onShift(Pressed)
	self:updateScreens(false)

end

------------------------------------------------------------------------------------------------------------------------

function Page:canFocusSoundOnPadTrigger()

    return PadModeHelper.canFocusSoundOnPadTrigger()

end

------------------------------------------------------------------------------------------------------------------------

function Page:onDB3ModelChanged(Model)
end

------------------------------------------------------------------------------------------------------------------------
