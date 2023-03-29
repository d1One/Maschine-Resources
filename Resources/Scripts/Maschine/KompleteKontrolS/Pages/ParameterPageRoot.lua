------------------------------------------------------------------------------------------------------------------------
-- Displays the currently selected page of Maschine parameters from the currently selected ParameterOwner.
--
-- The generic representation of a ParameterOwner page can be performed by a ParameterPageBase, but
-- for some ParameterOwners, the page must be displayed slightly customized, which is handled by different
-- ParameterPageBase-derived classes. ParameterPageRoot handles this correctly by
--
--   * selecting the correct Page object depending on the currently selected ParameterOwner
--   * forwarding all Page calls to that Page.
------------------------------------------------------------------------------------------------------------------------


require "Scripts/Maschine/KompleteKontrolS/Pages/ParameterPageArp"
require "Scripts/Maschine/KompleteKontrolS/Pages/ParameterPageBase"
require "Scripts/Maschine/KompleteKontrolS/Pages/ParameterPageScale"
require "Scripts/Maschine/KompleteKontrolS/Pages/ParameterPageSound"
require "Scripts/Maschine/KompleteKontrolS/Pages/ParameterPageTouchstrip"


local class = require 'Scripts/Shared/Helpers/classy'
ParameterPageRoot = class( 'ParameterPageRoot' )

------------------------------------------------------------------------------------------------------------------------
-- Init
------------------------------------------------------------------------------------------------------------------------

function ParameterPageRoot:__init(Controller)

    -- delegate these function calls to self.ActivePage
    self.DELEGATES = {"updateScreen", "updateLEDs", "onEncoderEvent", "onEncoderTouched", "onWheelEvent",
        "onWheelButton", "onWheelTouched", "onControllerTimer", "onShiftButton", "onPageButton", "onNavUpDownButton",
        "onNavLeftRightButton", "onNavEnterButton", "onNavBackButton", "onNavInstanceButton", "onNavPresetButton"}

    self.Controller = Controller

    -- The page objects that can handle specifically each of these parameter owners
    self.SoundPage = ParameterPageSound(Controller)
    self.ArpPage = ParameterPageArp(Controller)
    self.ScalePage = ParameterPageScale(Controller)
    self.TouchstripPitchPage = ParameterPageTouchstrip(Controller, NI.DATA.TouchstripConfiguration.TOUCHSTRIP_TAB_PITCH)
    self.TouchstripModulationPage = ParameterPageTouchstrip(Controller, NI.DATA.TouchstripConfiguration.TOUCHSTRIP_TAB_MODULATION)

    self.ActivePage = self.SoundPage

    self:selectPage(true)

end

------------------------------------------------------------------------------------------------------------------------

function ParameterPageRoot:onStateFlagsChanged()

    self:selectPage(false)

end

------------------------------------------------------------------------------------------------------------------------

function ParameterPageRoot:onActivate()

    NHLController:setEncoderMode(NI.HW.ENC_MODE_CONTROL)
    if self.ActivePage.onActivate then
        self.ActivePage:onActivate()
    end

end

------------------------------------------------------------------------------------------------------------------------

function ParameterPageRoot:selectPage(Force)

    local Workspace = App:getWorkspace()
    local PageParameter = Workspace:getKKPerformPageParameter()

    if PageParameter:isChanged() or Force then

        local FocusedParameterOwnerPage = PageParameter:getValue()

        if FocusedParameterOwnerPage == HW.PAGE_SCALE then
            self:setActivePage(self.ScalePage)
        elseif FocusedParameterOwnerPage == HW.PAGE_ARP then
            self:setActivePage(self.ArpPage)
        elseif FocusedParameterOwnerPage == HW.PAGE_TOUCHSTRIP_PITCH then
            self:setActivePage(self.TouchstripPitchPage)
        elseif FocusedParameterOwnerPage == HW.PAGE_TOUCHSTRIP_MODULATION then
            self:setActivePage(self.TouchstripModulationPage)
        else
            self:setActivePage(self.SoundPage)
        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function ParameterPageRoot:setActivePage(Page)

    self.ActivePage = Page

    -- modify self's table so that ActivePage's methods become self's methods
    for i, Delegate in pairs(self.DELEGATES) do
        self[Delegate] = function(...)
            local arg = {...}
            if Page[Delegate] then
                table.remove(arg, 1) -- remove the implicit "self" argument passed to this anonymous function
                if _VERSION == "Lua 5.1" then
                    Page[Delegate](Page, unpack(arg))
                else
                    Page[Delegate](Page, table.unpack(arg))
                end
            end
        end
    end

    if Page.onActivate then
        Page:onActivate()
    end

end
