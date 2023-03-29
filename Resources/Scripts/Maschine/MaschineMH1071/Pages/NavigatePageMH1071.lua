------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Pages/PageMaschine"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
NavigatePageMH1071 = class( 'NavigatePageMH1071', PageMaschine )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function NavigatePageMH1071:__init(Controller)

   -- init base class
   PageMaschine.__init(self, "NavigatePageMH1071", Controller)

    -- define page LEDs
    self.PageLEDs = { NI.HW.LED_VARIATION }

   self:setupScreen()

end

------------------------------------------------------------------------------------------------------------------------

function NavigatePageMH1071:setupScreen()

    -- setup screen
    self.Screen = ScreenWithGridStudio(self, {"NAVIGATE", "", "", ""}, {"<<", ">>", "<<", ">>"})
    self.Screen.ScreenButton[1]:style("NAVIGATE", "HeadPin")

    self.SlotStack = self.Controller.SharedObjects.SlotStack

end

------------------------------------------------------------------------------------------------------------------------

function NavigatePageMH1071:onShow(Show)

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

-----------------------------------------------------------------------------------------------------------------------

function NavigatePageMH1071:updateScreens(ForceUpdate)

    self.Screen.ScreenLeft.InfoBar:update(ForceUpdate)
    self.SlotStack:update(ForceUpdate)

    self.Screen:updatePadButtonsWithFunctor(
        function(Index)
            return NavigationHelper.getPageNameAndStates(Index)
        end
    )

    self:updatePadColors()

    PageMaschine.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function NavigatePageMH1071:updateScreenButtons(ForceUpdate)

    self.Screen:setArrowText(1, MaschineHelper.getFocusChannelSlotName())
    self.Screen:setArrowText(2, "BANK "..tostring(NavigationHelper.getPageBankIndex() + 1))

    self.Screen.ScreenButton[5]:setEnabled(ControlHelper.hasPrevNextSlotOrPageGroup(false, false))
    self.Screen.ScreenButton[6]:setEnabled(ControlHelper.hasPrevNextSlotOrPageGroup(true, false))

    local HasPrevPageBank, HasNextPageBank = NavigationHelper.hasPrevNextPageBank()
    self.Screen.ScreenButton[7]:setEnabled(HasPrevPageBank)
    self.Screen.ScreenButton[8]:setEnabled(HasNextPageBank)

    -- Call base class
    PageMaschine.updateScreenButtons(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function NavigatePageMH1071:onScreenButton(ButtonIdx, Pressed)

    if not Pressed then
        PageMaschine.onScreenButton(self, ButtonIdx, Pressed)
        return
    end

    if ButtonIdx == 5 or ButtonIdx == 6 then
       ControlHelper.onPrevNextSlot(ButtonIdx == 6, false)

    elseif ButtonIdx == 7 or ButtonIdx == 8 then
        NavigationHelper.setPrevNextPageBank(ButtonIdx == 8)
    end

    -- call base class for update
    PageMaschine.onScreenButton(self, ButtonIdx, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function NavigatePageMH1071:isPageNav()

    -- Used by MaschineControllerStudio (through inheritance) to prevent switching to ControlPage when the
    -- Plug-in or Channel button is pressed.
    return true

end

------------------------------------------------------------------------------------------------------------------------

function NavigatePageMH1071:onPadEvent(PadIndex, Trigger, PadValue)

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

function NavigatePageMH1071:updatePadLEDs()

    NavigationHelper.updatePadLEDsForPageNav(self.Controller.PAD_LEDS, NavigationHelper.getPageBankIndex() * 16)

end

------------------------------------------------------------------------------------------------------------------------

function NavigatePageMH1071:updatePadColors()

    NavigationHelper.updatePadColors(self.Screen.DisplayGroup, self.Screen.PadButtons)

end

------------------------------------------------------------------------------------------------------------------------

function NavigatePageMH1071:onWheelDirection(Pressed, Button)

    if Pressed then
        if Button == NI.HW.BUTTON_WHEEL_LEFT or Button == NI.HW.BUTTON_WHEEL_RIGHT then
            ControlHelper.onPrevNextSlot(Button == NI.HW.BUTTON_WHEEL_RIGHT, false)
        end
    end

    self:updateWheelButtonLEDs()

end

------------------------------------------------------------------------------------------------------------------------

function NavigatePageMH1071:updateWheelButtonLEDs()

    local CanLeft = ControlHelper.hasPrevNextSlotOrPageGroup(false, false)
    local CanRight = ControlHelper.hasPrevNextSlotOrPageGroup(true, false)
    local Color = LEDColors.WHITE

    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_WHEEL_BUTTON_UP, NI.HW.BUTTON_WHEEL_UP, false, Color)
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_WHEEL_BUTTON_DOWN, NI.HW.BUTTON_WHEEL_DOWN, false, Color)
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_WHEEL_BUTTON_LEFT, NI.HW.BUTTON_WHEEL_LEFT, CanLeft, Color)
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_WHEEL_BUTTON_RIGHT, NI.HW.BUTTON_WHEEL_RIGHT, CanRight, Color)

end

------------------------------------------------------------------------------------------------------------------------
