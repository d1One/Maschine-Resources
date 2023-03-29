------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Pages/PageMaschine"
require "Scripts/Shared/Components/InfoBarStudio"
require "Scripts/Shared/Components/SlotStackStudio"
require "Scripts/Maschine/MaschineStudio/Screens/ScreenWithGridStudio"

require "Scripts/Shared/Helpers/ControlHelper"
require "Scripts/Shared/Helpers/LedHelper"
require "Scripts/Maschine/Helper/NavigationHelper"


------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
NavigatePagePageNavStudio = class( 'NavigatePagePageNavStudio', PageMaschine )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function NavigatePagePageNavStudio:__init(ParentPage, Controller)

    -- create page
    PageMaschine.__init(self, "NavigatePagePageNavStudio", Controller)

    -- setup screen
    self:setupScreen()

    self.ParentPage = ParentPage

    -- define page leds
    self.PageLEDs = { NI.HW.LED_NAVIGATE }

end

------------------------------------------------------------------------------------------------------------------------

function NavigatePagePageNavStudio:setupScreen()

    -- setup screen
    self.Screen = ScreenWithGridStudio(self, {"NAVIGATE", "PAGE NAV", "", ""}, {"<<", ">>", "<<", ">>"})
    self.Screen.ScreenButton[1]:style("NAVIGATE", "HeadPin")
    self.Screen.ScreenButton[2]:setSelected(true)

	self.SlotStack = self.Controller.SharedObjects.SlotStack

end

------------------------------------------------------------------------------------------------------------------------

function NavigatePagePageNavStudio:onShow(Show)

    if Show then

        self.SlotStack:insertInto(self.Screen.ScreenLeft.DisplayBar)
        self.Screen.ScreenLeft.DisplayBar:setFlex(self.SlotStack.Stack)

        NHLController:setEncoderMode(NI.HW.ENC_MODE_NONE)
        NHLController:setPadMode(NI.HW.PAD_MODE_NONE)

        LEDHelper.setLEDState(NI.HW.LED_LEFT, LEDHelper.LS_OFF)
        LEDHelper.setLEDState(NI.HW.LED_RIGHT, LEDHelper.LS_OFF)
    else

        NHLController:setPadMode(NI.HW.PAD_MODE_PAGE_DEFAULT)
    end

    -- Call Base Class
    PageMaschine.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function NavigatePagePageNavStudio:updateScreens(ForceUpdate)

    self.Screen.ScreenButton[1]:setSelected(self.ParentPage.IsPinned)

    self.Screen.ScreenLeft.InfoBar:update(ForceUpdate)
    self.SlotStack:update(ForceUpdate)

    self.Screen:updatePadButtonsWithFunctor(
    	function(Index)
            return NavigationHelper.getPageNameAndStates(Index)
        end
    )

    self:updatePadColors()

    -- call base class
    PageMaschine.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function NavigatePagePageNavStudio:updateScreenButtons(ForceUpdate)

    self.Screen:setArrowText(1, MaschineHelper.getFocusChannelSlotName())
    self.Screen:setArrowText(2, "PAGE BANK "..tostring(NavigationHelper.getPageBankIndex() + 1))

    self.Screen.ScreenButton[5]:setEnabled(ControlHelper.hasPrevNextSlotOrPageGroup(false, false))
    self.Screen.ScreenButton[6]:setEnabled(ControlHelper.hasPrevNextSlotOrPageGroup(true, false))

    local HasPrevPageBank, HasNextPageBank = NavigationHelper.hasPrevNextPageBank()
    self.Screen.ScreenButton[7]:setEnabled(HasPrevPageBank)
    self.Screen.ScreenButton[8]:setEnabled(HasNextPageBank)

    -- Call base class
    PageMaschine.updateScreenButtons(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------
-- event handling
------------------------------------------------------------------------------------------------------------------------

function NavigatePagePageNavStudio:onScreenButton(ButtonIdx, Pressed)

    if not Pressed then
    	PageMaschine.onScreenButton(self, ButtonIdx, Pressed)
    	return
    end

    if ButtonIdx == 1 then
       self.ParentPage:togglePinState()

    elseif ButtonIdx == 2 then
       self.ParentPage:switchToPage(NavigatePageStudio.VIEW)

    elseif ButtonIdx == 5 or ButtonIdx == 6 then
       ControlHelper.onPrevNextSlot(ButtonIdx == 6, false)

    elseif ButtonIdx == 7 or ButtonIdx == 8 then
        NavigationHelper.setPrevNextPageBank(ButtonIdx == 8)
    end

    -- call base class for update
    PageMaschine.onScreenButton(self, ButtonIdx, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function NavigatePagePageNavStudio:onPadEvent(PadIndex, Trigger, PadValue)

    if Trigger then
        local ParamCache = App:getStateCache():getParameterCache()
        local NumPages = ParamCache:getNumPagesOfFocusParameterOwner()
        local PageIndex = NavigationHelper.getPageBankIndex() * 16 + PadIndex

        if PageIndex >= 1 and PageIndex <= NumPages then
            ControlHelper.setPageParameter(PageIndex)
        end
    end

    return true

end

------------------------------------------------------------------------------------------------------------------------

function NavigatePagePageNavStudio:updatePadLEDs()

    NavigationHelper.updatePadLEDsForPageNav(self.Controller.PAD_LEDS, NavigationHelper.getPageBankIndex() * 16)

end

------------------------------------------------------------------------------------------------------------------------

function NavigatePagePageNavStudio:updatePadColors()

    NavigationHelper.updatePadColors(self.Screen.DisplayGroup, self.Screen.PadButtons)

end


------------------------------------------------------------------------------------------------------------------------

function NavigatePagePageNavStudio:onWheelButton(Pressed)

	-- handled: no QE
    return true
end

------------------------------------------------------------------------------------------------------------------------

function NavigatePagePageNavStudio:getAccessiblePageInfo()

    return "Page Select"

end

------------------------------------------------------------------------------------------------------------------------
