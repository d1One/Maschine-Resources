
require "Scripts/Shared/Pages/PageMaschine"
require "Scripts/Shared/Components/TransportSection"
require "Scripts/Shared/Helpers/LedHelper"

------------------------------------------------------------------------------------------------------------------------
-- ForwardPageMaschine: Should be used as Controller-Page if your Page has many Subpages
------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
ForwardPageMaschine = class( 'ForwardPageMaschine', PageMaschine )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function ForwardPageMaschine:__init(Name, Controller)

    PageMaschine.__init(self, Name, Controller)

    self.SubPages = {}

    self.DefaultPage = nil
    self.CurrentPage = nil

end

------------------------------------------------------------------------------------------------------------------------

function ForwardPageMaschine:updateScreens(ForceUpdate)

    if self.CurrentPage then
        self.CurrentPage:updateScreens(ForceUpdate)
    else
        error("ForwardPageMaschine:updateScreens() CurrentPage nil")
    end

end

------------------------------------------------------------------------------------------------------------------------

function ForwardPageMaschine:updateScreenButtons(ForceUpdate)

    if self.CurrentPage then
        self.CurrentPage:updateScreenButtons(ForceUpdate)
    else
        error("ForwardPageMaschine:updateScreenButtons() CurrentPage nil")
    end

end

------------------------------------------------------------------------------------------------------------------------

function ForwardPageMaschine:updateGroupLEDs()

    if self.CurrentPage then
        self.CurrentPage:updateGroupLEDs()
    else
        error("ForwardPageMaschine:updateGroupLEDs() CurrentPage nil")
    end

end

------------------------------------------------------------------------------------------------------------------------

function ForwardPageMaschine:updatePadLEDs()

    if self.CurrentPage then
        self.CurrentPage:updatePadLEDs()
    else
        error("ForwardPageMaschine:updatePadLEDs() CurrentPage nil")
    end

end

------------------------------------------------------------------------------------------------------------------------

function ForwardPageMaschine:updateParameters(ForceUpdate)

    if self.CurrentPage then
        self.CurrentPage:updateParameters(ForceUpdate)
    else
        error("ForwardPageMaschine:updateParameters() CurrentPage nil")
    end

end

------------------------------------------------------------------------------------------------------------------------
-- Show / Hide Page
------------------------------------------------------------------------------------------------------------------------

function ForwardPageMaschine:onShow(Show)

    self.IsVisible = Show

    if Show == true then

        -- reset overlays before showing the page, if available
        -- older controllers like Mk2 don't have capacitive features
        if self.Controller.CapacitiveList then
            self.Controller.CapacitiveList:reset()
        end

        if self.Controller.CapacitiveNavIcons then
            self.Controller.CapacitiveNavIcons:reset()
        end

        if self.CurrentPage then
            self.CurrentPage:onShow(true)
        elseif self.DefaultPage then
            self:switchToDefaultSubPage()
        else
            error("ForwardPageMaschine:onShow() CurrentPage And DefaultPage nil")
        end

    else
        if self.CurrentPage then
            self.CurrentPage:onShow(false)
        else
            error("ForwardPageMaschine:onShow() CurrentPage nil")
        end
    end

end

------------------------------------------------------------------------------------------------------------------------
-- event handling
------------------------------------------------------------------------------------------------------------------------

function ForwardPageMaschine:onPadEvent(PadIndex, Trigger, PadValue)

    if self.CurrentPage then
        return self.CurrentPage:onPadEvent(PadIndex, Trigger, PadValue)
    else
        error("ForwardPageMaschine:onPadEvent() CurrentPage nil")
    end

end

------------------------------------------------------------------------------------------------------------------------
-- onScreenEncoder handler
------------------------------------------------------------------------------------------------------------------------

function ForwardPageMaschine:onScreenEncoder(KnobIdx, EncoderInc)

    if self.CurrentPage then
        self.CurrentPage:onScreenEncoder(KnobIdx, EncoderInc)
    else
        error("ForwardPageMaschine:onScreenEncoder() CurrentPage nil")
    end

end

------------------------------------------------------------------------------------------------------------------------

function ForwardPageMaschine:onWheel(Inc)

    if self.CurrentPage then
        return self.CurrentPage:onWheel(Inc)
    else
        error("ForwardPageMaschine:onWheel() CurrentPage nil")
    end

end

------------------------------------------------------------------------------------------------------------------------

function ForwardPageMaschine:onWheelButton(Pressed)

    if self.CurrentPage then
        return self.CurrentPage:onWheelButton(Pressed)
    else
        error("ForwardPageMaschine:onWheelButton() CurrentPage nil")
    end

end


------------------------------------------------------------------------------------------------------------------------

function ForwardPageMaschine:onVolumeEncoder(EncoderInc)

    if self.CurrentPage then
        return self.CurrentPage:onVolumeEncoder(EncoderInc)
    else
         error("ForwardPageMaschine:onVolumeEncoder() CurrentPage nil")
    end

end

------------------------------------------------------------------------------------------------------------------------

function ForwardPageMaschine:onTempoEncoder(EncoderInc)

    if self.CurrentPage then
        return self.CurrentPage:onTempoEncoder(EncoderInc)
    else
         error("ForwardPageMaschine:onTempoEncoder() CurrentPage nil")
    end

end

------------------------------------------------------------------------------------------------------------------------

function ForwardPageMaschine:onSwingEncoder(EncoderInc)

    if self.CurrentPage then
        return self.CurrentPage:onSwingEncoder(EncoderInc)
    else
         error("ForwardPageMaschine:onSwingEncoder() CurrentPage nil")
    end

end

------------------------------------------------------------------------------------------------------------------------
-- Handler for page button events
------------------------------------------------------------------------------------------------------------------------

function ForwardPageMaschine:onPageButton(Button, Page, Pressed)

    if self.CurrentPage then
        return self.CurrentPage:onPageButton(Button, Page, Pressed)
    else
         error("ForwardPageMaschine:onPageButton() CurrentPage nil")
         return false
    end

end

------------------------------------------------------------------------------------------------------------------------

function ForwardPageMaschine:onControlButton(Pressed)

    if self.CurrentPage then
        self.CurrentPage:onControlButton(Pressed)
    else
         error("ForwardPageMaschine:onControlButton() CurrentPage nil")
    end

end

------------------------------------------------------------------------------------------------------------------------

function ForwardPageMaschine:onLeftRightButton(Right, Pressed)

    if self.CurrentPage then
        self.CurrentPage:onLeftRightButton(Right, Pressed)
    else
         error("ForwardPageMaschine:onLeftRightButton() CurrentPage nil")
    end

end

------------------------------------------------------------------------------------------------------------------------

function ForwardPageMaschine:onWheelDirection(Pressed, DirectionButton)

    if self.CurrentPage and self.CurrentPage.onWheelDirection then
        self.CurrentPage:onWheelDirection(Pressed, DirectionButton)
    end

end

------------------------------------------------------------------------------------------------------------------------

function ForwardPageMaschine:onCapTouched(Cap, Touched)

    if self.CurrentPage and self.CurrentPage.onCapTouched then
        self.CurrentPage:onCapTouched(Cap, Touched)
    end

end

------------------------------------------------------------------------------------------------------------------------

function ForwardPageMaschine:onEnterButton(Pressed)

    if self.CurrentPage then
        self.CurrentPage:onEnterButton(Pressed)
    else
         error("ForwardPageMaschine:onEnterButton() CurrentPage nil")
    end

end

------------------------------------------------------------------------------------------------------------------------

function ForwardPageMaschine:onScreenButton(ButtonIdx, Pressed)

    if self.CurrentPage then
        self.CurrentPage:onScreenButton(ButtonIdx, Pressed)
    else
        error("ForwardPageMaschine:onScreenButton() CurrentPage nil")
    end

end

------------------------------------------------------------------------------------------------------------------------

function ForwardPageMaschine:onGroupButton(ButtonIdx, Pressed)

    if self.CurrentPage then
        self.CurrentPage:onGroupButton(ButtonIdx, Pressed)
    else
        error("ForwardPageMaschine:onGroupButton() CurrentPage nil")
    end

end

------------------------------------------------------------------------------------------------------------------------

function ForwardPageMaschine:onShiftButton(Pressed)

    if self.CurrentPage then
        self.CurrentPage:onShiftButton(Pressed)
    else
         error("ForwardPageMaschine:onShiftButton() CurrentPage nil")
    end

end

------------------------------------------------------------------------------------------------------------------------

function ForwardPageMaschine:onBackButton(Pressed)

    if self.CurrentPage then
        self.CurrentPage:onBackButton(Pressed)
    else
         error("ForwardPageMaschine:onBackButton() CurrentPage nil")
    end

end

------------------------------------------------------------------------------------------------------------------------

function ForwardPageMaschine:onControllerTimer()

    if self.CurrentPage and self.CurrentPage.onControllerTimer then
        self.CurrentPage:onControllerTimer()
    end
end

------------------------------------------------------------------------------------------------------------------------

function ForwardPageMaschine:updateWheelButtonLEDs()

    if self.CurrentPage and self.CurrentPage.updateWheelButtonLEDs then
        self.CurrentPage:updateWheelButtonLEDs()
    end
end

------------------------------------------------------------------------------------------------------------------------

function ForwardPageMaschine:updateLeftRightLEDs()

    if self.CurrentPage and self.CurrentPage.updateLeftRightLEDs then
        self.CurrentPage:updateLeftRightLEDs()
    end
end

------------------------------------------------------------------------------------------------------------------------

function ForwardPageMaschine:getAccessiblePageInfo()

    if self.CurrentPage and self.CurrentPage.getAccessiblePageInfo then
        return self.CurrentPage:getAccessiblePageInfo()
    end

    return PageMaschine.getAccessiblePageInfo(self)

end

------------------------------------------------------------------------------------------------------------------------
-- Helper for comfy switching between Sub-Pages
------------------------------------------------------------------------------------------------------------------------

function ForwardPageMaschine:addSubPage(PageID, SubPage)

    if SubPage then
        self.SubPages[PageID] = SubPage
    end

end

------------------------------------------------------------------------------------------------------------------------

function ForwardPageMaschine:switchToSubPage(PageID)

    if self.SubPages[PageID] ~= nil then

        self.CurrentPage:onShow(false)
        self.CurrentPage = self.SubPages[PageID]
        self.PageLEDs = self.CurrentPage.PageLEDs and self.CurrentPage.PageLEDs or self.PageLEDs
        self:onShow(true)
    end
end

------------------------------------------------------------------------------------------------------------------------

function ForwardPageMaschine:switchToDefaultSubPage()

    if self.DefaultPage then
        self:switchToSubPage(self:getSubPageID(self.DefaultPage))
    else
        error("ForwardPageMaschine:switchToDefaultSubPage() DefaultPage nil")
    end

end

------------------------------------------------------------------------------------------------------------------------

function ForwardPageMaschine:setDefaultSubPage(PageID)

    if self.SubPages[PageID] then
        self.DefaultPage = self.SubPages[PageID]
        if self.CurrentPage == nil then
            self.CurrentPage = self.DefaultPage
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function ForwardPageMaschine:getSubPageID(Subpage)

    for ID, Page in ipairs(self.SubPages) do
        if Page.Name == Subpage.Name then
            return ID
        end
    end

    error("Subpage not found in getSubPageID")

end

------------------------------------------------------------------------------------------------------------------------

function ForwardPageMaschine:getCurrentPageID()

    for ID, Page in ipairs(self.SubPages) do
        if Page.Name == self.CurrentPage.Name then
            return ID
        end
    end

    error("Page not found in getCurrentPageID")

end

------------------------------------------------------------------------------------------------------------------------

