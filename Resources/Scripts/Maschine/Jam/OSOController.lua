require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Shared/Helpers/BrowseHelper"
require "Scripts/Shared/Helpers/LedHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
OSOController = class( 'OSOController' )

------------------------------------------------------------------------------------------------------------------------

function OSOController:__init(Controller)

    self.Controller = Controller

end

------------------------------------------------------------------------------------------------------------------------

function OSOController:onCustomProcess(ForceUpdate)
    if NI.APP.isHeadless() then
        return

    end

    self:updateOSOButtonLEDs()

end

------------------------------------------------------------------------------------------------------------------------

function OSOController:onWheelEvent(Inc)
    if NI.APP.isHeadless() then
        return false

    end

    if MaschineHelper.isOnScreenOverlayVisible() then

        local OnScreenOverlay = App:getOnScreenOverlay()
        OnScreenOverlay:onWheelEvent(Inc, self.Controller:isShiftPressed())

        return true

    end

    return false

end

------------------------------------------------------------------------------------------------------------------------

function OSOController:onDPadButton(Button, Pressed)
    if NI.APP.isHeadless() then
        return

    end

    if not MaschineHelper.isOnScreenOverlayVisible() then
        return false
    end

    if Pressed then

        local OnScreenOverlay = App:getOnScreenOverlay()
        local ShiftPressed = self.Controller:isShiftPressed()

        if Button == NI.HW.BUTTON_DPAD_UP or Button == NI.HW.BUTTON_DPAD_DOWN then

            if ShiftPressed then
                -- LEDs must be updated before the preset loads
                self:updateDPadLEDs()

                if BrowseHelper.offsetResultListFocusBy(Button == NI.HW.BUTTON_DPAD_UP and -1 or 1) then
                    BrowseHelper.loadFocusItem()
                end
            else
                OnScreenOverlay:onUpDown(Button == NI.HW.BUTTON_DPAD_UP)
            end

        elseif Button == NI.HW.BUTTON_DPAD_LEFT or Button == NI.HW.BUTTON_DPAD_RIGHT then

            if ShiftPressed and Button == NI.HW.BUTTON_DPAD_LEFT then

                OnScreenOverlay:onBack(true)

            elseif ShiftPressed and Button == NI.HW.BUTTON_DPAD_RIGHT then

                if JamHelper.canQuickBrowse() then
                    NI.DATA.QuickBrowseAccess.restoreFocusSlotOrSampleQuickBrowse(App)
                    OnScreenOverlay:setBrowserSection(NI.DATA.KEY_RIGHT) -- focus result list
                end

            else

                OnScreenOverlay:onLeftRight(Button == NI.HW.BUTTON_DPAD_LEFT)

            end

        end
    end

    return true

end

------------------------------------------------------------------------------------------------------------------------

function OSOController:onWheelButton(Pressed)
    if NI.APP.isHeadless() then
        return false

    end

    if not MaschineHelper.isOnScreenOverlayVisible() then
        return false
    end

    if Pressed then

        local OnScreenOverlay = App:getOnScreenOverlay()
        OnScreenOverlay:onEnter(self.Controller:isShiftPressed(), true)

    end

    return true

end

------------------------------------------------------------------------------------------------------------------------

function OSOController:onBrowseButton(Pressed)
    if NI.APP.isHeadless() then
        return

    end

    if Pressed then

        local OnScreenOverlay = App:getOnScreenOverlay()
        local OSOVisibleParameter = OnScreenOverlay:getVisibleParameter()
        local ShowOSO = true

        if self.Controller:isShiftPressed() then
            NI.DATA.QuickBrowseAccess.restoreQuickBrowse(App)
            ShowOSO = not OSOVisibleParameter:getValue()
        end

        if ShowOSO then
            OnScreenOverlay:onBrowse(NHLController:getControllerModel())
        end

    end

    self:updateOSOButtonLEDs()

end

------------------------------------------------------------------------------------------------------------------------

function OSOController:updateOSOButtonLEDs()
    if NI.APP.isHeadless() then
        return

    end

    local BrowserVisible = App:getOnScreenOverlay():isBrowserVisible()
    LEDHelper.setLEDState(NI.HW.LED_BROWSE, BrowserVisible and LEDHelper.LS_BRIGHT or LEDHelper.LS_OFF)

end

------------------------------------------------------------------------------------------------------------------------

function OSOController:onInstanceButton(Pressed)
    if NI.APP.isHeadless() then
        return

    end

    if Pressed then

        local OnScreenOverlay = App:getOnScreenOverlay()
        OnScreenOverlay:onInstance(NHLController:getControllerModel())
        self:updateOSOButtonLEDs()

    end

end

------------------------------------------------------------------------------------------------------------------------

function OSOController:updateDPadLEDs()
    if NI.APP.isHeadless() then
        return

    end

    local OnScreenOverlay = App:getOnScreenOverlay()
    local IsBrowserVisible = OnScreenOverlay and OnScreenOverlay:isBrowserVisible()

    local BrowserSection = IsBrowserVisible and OnScreenOverlay:getBrowserSectionParameter():getValue()
    local PreviousSection = BrowserSection and OnScreenOverlay:findPreviousSection(BrowserSection)
    local NextSection = BrowserSection and OnScreenOverlay:findNextSection(BrowserSection, false)

    local FocusItem = BrowseHelper.getResultListFocusItem()
    local NumItems = BrowseHelper.getResultListSize()

    local ResultsHasPrevious = FocusItem > 0 and NumItems > 0
    local ResultsHasNext = FocusItem < NumItems - 1 and NumItems > 0

    if self.Controller:isShiftPressed() then

        LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_DPAD_UP, NI.HW.BUTTON_DPAD_UP, ResultsHasPrevious)

        LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_DPAD_DOWN, NI.HW.BUTTON_DPAD_DOWN, ResultsHasNext)

        LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_DPAD_LEFT, NI.HW.BUTTON_DPAD_LEFT,
                                  BrowserSection and BrowserSection ~= NI.DATA.DB_FILETYPES and BrowserSection ~= NI.DATA.DB_LIBRARIES)

        LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_DPAD_RIGHT, NI.HW.BUTTON_DPAD_RIGHT, JamHelper.canQuickBrowse())

    else

        LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_DPAD_UP, NI.HW.BUTTON_DPAD_UP,
                                  BrowserSection and BrowserSection ~= PreviousSection)

        LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_DPAD_DOWN, NI.HW.BUTTON_DPAD_DOWN,
                                  BrowserSection and BrowserSection ~= NextSection)

        LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_DPAD_LEFT, NI.HW.BUTTON_DPAD_LEFT,
                                  BrowserSection and BrowserSection >= NI.DATA.DB_FAVORITES)

        LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_DPAD_RIGHT, NI.HW.BUTTON_DPAD_RIGHT,
                                  BrowserSection and BrowserSection < NI.DATA.DB_FAVORITES)
    end

end

------------------------------------------------------------------------------------------------------------------------
