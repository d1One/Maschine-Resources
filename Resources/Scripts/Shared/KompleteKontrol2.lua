require "Scripts/Shared/Components/CapacitiveOverlayList"
require "Scripts/Shared/Components/PageOverlay"
require "Scripts/Shared/Components/SlotStackStudio"
require "Scripts/Shared/Components/Timer"

require "Scripts/Shared/Helpers/WidgetHelper"

require "Scripts/Shared/Pages/BusyPageStudio"
require "Scripts/Shared/Pages/MacroPageStudio"
require "Scripts/Shared/Pages/ScaleChordPage"


local class = require 'Scripts/Shared/Helpers/classy'
KompleteKontrol2 = class( 'KompleteKontrol2' )

KompleteKontrol2.SCREEN_BUTTON_LEDS =
{

    NI.HW.LED_SCREEN_BUTTON_1,
    NI.HW.LED_SCREEN_BUTTON_2,
    NI.HW.LED_SCREEN_BUTTON_3,
    NI.HW.LED_SCREEN_BUTTON_4,
    NI.HW.LED_SCREEN_BUTTON_5,
    NI.HW.LED_SCREEN_BUTTON_6,
    NI.HW.LED_SCREEN_BUTTON_7,
    NI.HW.LED_SCREEN_BUTTON_8
}

KompleteKontrol2.SCREEN_BUTTONS =
{
    NI.HW.BUTTON_SCREEN_1,
    NI.HW.BUTTON_SCREEN_2,
    NI.HW.BUTTON_SCREEN_3,
    NI.HW.BUTTON_SCREEN_4,
    NI.HW.BUTTON_SCREEN_5,
    NI.HW.BUTTON_SCREEN_6,
    NI.HW.BUTTON_SCREEN_7,
    NI.HW.BUTTON_SCREEN_8
}


local INVALID_NOTE = 128

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2:__init(Controller)

    self.HWModel = NHLController:getControllerModel()
    self.KeySwitchNote = INVALID_NOTE
    self.KeySwitchNoteName = ""
    self.OctaveOffset = 0
    self.SemitoneOffset = 0

    self.Timer = Timer()

    self.SwitchPressed = {}
    self.EncoderHandler = {}
    self.SwitchHandler = {}
    self.PageList = {}
    self.SharedObjects = {}

    self.ActivePage = nil
    self.ActivePageID = nil

    self.CapacitiveList = CapacitiveOverlayList(self)

    self.Overlays = {}

    self:setupButtonHandler()
    self:setupEncoderHandler()
    self:createSharedObjects()

    self:createPages()

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2:setTimer(Page, Interval, Param)

    self.Timer:setTimer(Page, Interval, Param)

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2:onTimer()

	self.ActivePage:onTimer()
end

------------------------------------------------------------------------------------------------------------------------
-- setup screen button handler
------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2:setupEncoderHandler()

    self.EncoderHandler[NI.HW.ENCODER_SCREEN_1] = function(EncoderInc) self:onScreenEncoder(1, EncoderInc) end
    self.EncoderHandler[NI.HW.ENCODER_SCREEN_2] = function(EncoderInc) self:onScreenEncoder(2, EncoderInc) end
    self.EncoderHandler[NI.HW.ENCODER_SCREEN_3] = function(EncoderInc) self:onScreenEncoder(3, EncoderInc) end
    self.EncoderHandler[NI.HW.ENCODER_SCREEN_4] = function(EncoderInc) self:onScreenEncoder(4, EncoderInc) end
    self.EncoderHandler[NI.HW.ENCODER_SCREEN_5] = function(EncoderInc) self:onScreenEncoder(5, EncoderInc) end
    self.EncoderHandler[NI.HW.ENCODER_SCREEN_6] = function(EncoderInc) self:onScreenEncoder(6, EncoderInc) end
    self.EncoderHandler[NI.HW.ENCODER_SCREEN_7] = function(EncoderInc) self:onScreenEncoder(7, EncoderInc) end
    self.EncoderHandler[NI.HW.ENCODER_SCREEN_8] = function(EncoderInc) self:onScreenEncoder(8, EncoderInc) end
end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2:setupButtonHandler()

    self.SwitchHandler[NI.HW.BUTTON_SCREEN_1] = function(Pressed) self:onScreenButton(1, Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_SCREEN_2] = function(Pressed) self:onScreenButton(2, Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_SCREEN_3] = function(Pressed) self:onScreenButton(3, Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_SCREEN_4] = function(Pressed) self:onScreenButton(4, Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_SCREEN_5] = function(Pressed) self:onScreenButton(5, Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_SCREEN_6] = function(Pressed) self:onScreenButton(6, Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_SCREEN_7] = function(Pressed) self:onScreenButton(7, Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_SCREEN_8] = function(Pressed) self:onScreenButton(8, Pressed) end

    self.SwitchHandler[NI.HW.BUTTON_CAP_1] = function(Touched) self:onCapTouched(1, Touched) end
    self.SwitchHandler[NI.HW.BUTTON_CAP_2] = function(Touched) self:onCapTouched(2, Touched) end
    self.SwitchHandler[NI.HW.BUTTON_CAP_3] = function(Touched) self:onCapTouched(3, Touched) end
    self.SwitchHandler[NI.HW.BUTTON_CAP_4] = function(Touched) self:onCapTouched(4, Touched) end
    self.SwitchHandler[NI.HW.BUTTON_CAP_5] = function(Touched) self:onCapTouched(5, Touched) end
    self.SwitchHandler[NI.HW.BUTTON_CAP_6] = function(Touched) self:onCapTouched(6, Touched) end
    self.SwitchHandler[NI.HW.BUTTON_CAP_7] = function(Touched) self:onCapTouched(7, Touched) end
    self.SwitchHandler[NI.HW.BUTTON_CAP_8] = function(Touched) self:onCapTouched(8, Touched) end

    self.SwitchHandler[NI.HW.BUTTON_PERFORM_SCALE] = function(Pressed) self:onScaleButton(Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_PERFORM_ARPEGGIATOR] = function(Pressed) self:onArpButton(Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_CONTROL] = function(Pressed) self:onControlButton(Pressed, NI.HW.BUTTON_CONTROL) end

    self.SwitchHandler[NI.HW.BUTTON_LEFT]  = function(Pressed) self:onLeftRightButton(false, Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_RIGHT] = function(Pressed) self:onLeftRightButton(true, Pressed) end

    self.SwitchHandler[NI.HW.BUTTON_NAVIGATE_PRESET_UP]     = function(Pressed) self:onNavPresetButton(Pressed, true) end
    self.SwitchHandler[NI.HW.BUTTON_NAVIGATE_PRESET_DOWN]   = function(Pressed) self:onNavPresetButton(Pressed, false) end

    self.SwitchHandler[NI.HW.BUTTON_WHEEL_UP]  = function(Pressed) self:onWheelDirection(Pressed, NI.HW.BUTTON_WHEEL_UP) end
    self.SwitchHandler[NI.HW.BUTTON_WHEEL_DOWN]  = function(Pressed) self:onWheelDirection(Pressed, NI.HW.BUTTON_WHEEL_DOWN) end
    self.SwitchHandler[NI.HW.BUTTON_WHEEL_LEFT]  = function(Pressed) self:onWheelDirection(Pressed, NI.HW.BUTTON_WHEEL_LEFT) end
    self.SwitchHandler[NI.HW.BUTTON_WHEEL_RIGHT]  = function(Pressed) self:onWheelDirection(Pressed, NI.HW.BUTTON_WHEEL_RIGHT) end
    self.SwitchHandler[NI.HW.BUTTON_WHEEL] = function(Pressed) self:onWheelButton(Pressed) end

    self.SwitchHandler[NI.HW.BUTTON_TRANSPOSE_OCTAVE_MINUS] = function(Pressed) self:onOctaveButton(Pressed, false) end
    self.SwitchHandler[NI.HW.BUTTON_TRANSPOSE_OCTAVE_PLUS]  = function(Pressed) self:onOctaveButton(Pressed, true) end

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2:createSharedObjects()
    -- slot stack: used in the Control Pages, navigate, Module Browser and StepMod Page
    local GetPictureColor = function() return 0 end
	self.SharedObjects.SlotStack = SlotStackStudio(GetPictureColor)

    -- insert all shared objects in the root stack - here they remain before their first use
	for Idx, Object in pairs(self.SharedObjects) do
		Object:insertInto(NHLController:getHardwareDisplay():getSharedRoot())
	end
end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2:updateArpScaleLEDs()

    local ScaleEngineActive = NI.HW.getScaleEngineActiveParameter(App)
    local ArpActive = NI.HW.getArpeggiatorActiveParameter(App)

    local ScaleOn = ScaleEngineActive and ScaleEngineActive:getValue() or false
    local ArpOn = ArpActive:getValue() or false

    LEDHelper.setLEDState(NI.HW.LED_PERFORM_ARPEGGIATOR, ArpOn and LEDHelper.LS_BRIGHT or LEDHelper.LS_DIM)
    LEDHelper.setLEDState(NI.HW.LED_PERFORM_SCALE, ScaleOn and LEDHelper.LS_BRIGHT or LEDHelper.LS_DIM)
end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2:updateJoycoderLEDs()

    if self.ActiveOverlay and self.ActiveOverlay:isVisible() or
        self:getShiftPressed() or
        self.ActivePage.updateWheelButtonLEDs == nil then

        --turn JC LEDs off (default) or ON (change master volume)
        local State = self:getShiftPressed() and LEDHelper.LS_BRIGHT or LEDHelper.LS_OFF

        LEDHelper.setLEDState(NI.HW.LED_WHEEL_BUTTON_UP, State)
        LEDHelper.setLEDState(NI.HW.LED_WHEEL_BUTTON_DOWN, State)
        LEDHelper.setLEDState(NI.HW.LED_WHEEL_BUTTON_LEFT, State)
        LEDHelper.setLEDState(NI.HW.LED_WHEEL_BUTTON_RIGHT, State)

    elseif self.ActivePage.updateWheelButtonLEDs then
        self.ActivePage:updateWheelButtonLEDs()
    end
end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2:updateLEDs()

    if App:isBusy() then

        if NI.APP.isStandalone() then

            NHLController:resetAllLEDs()
        else
            LEDHelper.turnOffLEDs({
                NI.HW.LED_PERFORM_ARPEGGIATOR,
                NI.HW.LED_PERFORM_SCALE,
                NI.HW.LED_CLEAR,
                NI.HW.LED_NAVIGATE_PRESET_UP,
                NI.HW.LED_NAVIGATE_PRESET_DOWN,
                NI.HW.LED_LEFT,
                NI.HW.LED_RIGHT,
                NI.HW.LED_BROWSE,
                NI.HW.LED_CONTROL
                })
        end
    else
        for PageID, Page in pairs(self.PageList) do
            self.PageList[PageID]:updatePageLEDs(LEDHelper.LS_DIM)
        end

        self.ActivePage:updatePageLEDs(LEDHelper.LS_BRIGHT)

        self:updateArpScaleLEDs()
        self:updateJoycoderLEDs()
        self:updatePresetButtonLEDs()

        if self.ActiveOverlay and self.ActiveOverlay:isVisible() then
            LEDHelper.turnOffLEDs({ NI.HW.LED_LEFT, NI.HW.LED_RIGHT })
            self.ActiveOverlay:updateLEDs()

        else
            if self.ActivePage.updateLEDs then
                self.ActivePage:updateLEDs()
            end
        end
    end

    LEDHelper.setLEDState(NI.HW.BUTTON_PERFORM_SHIFT, self:getShiftPressed() and LEDHelper.LS_BRIGHT or LEDHelper.LS_DIM)

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2:getActivePageOrOverlay()

    return self.ActiveOverlay and self.ActiveOverlay:isVisible() and self.ActiveOverlay or self.ActivePage

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2:updateScreenButtonLEDs(ScreenButtons)

    if not self.ActiveOverlay or not self.ActiveOverlay:isVisible() then
        LEDHelper.updateScreenButtonLEDs(self, ScreenButtons)
    end

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2:onPageButton(Button, Pressed)
    if self.ActivePage.onPageButton then
        self.ActivePage:onPageButton(Button, self.ActivePageID, Pressed)
    end
end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2:onControlButton(Pressed, Button)
    if Pressed and self.ActivePageID ~= NI.HW.PAGE_CONTROL then
        self:changePage(NI.HW.PAGE_CONTROL)
    end

    self:onPageButton(Button, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2:onScaleButton(Pressed)

    local ScaleEngine = NI.DATA.getScaleEngine(App)

    if ScaleEngine and Pressed then
        if self:getShiftPressed() and self.ActivePageID ~= NI.HW.PAGE_SCALE then
            self:changePage(NI.HW.PAGE_SCALE)

        -- engine toggle
        elseif not self:getShiftPressed() then
            local ActiveParam = NI.HW.getScaleEngineActiveParameter(App)
            if ActiveParam then
                NI.DATA.ParameterAccess.toggleBoolParameter(App, ActiveParam)
            end
        end
    end

    self:onPageButton(NI.HW.PAGE_SCALE, Pressed)
end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2:onArpButton(Pressed)

    local Arp = NI.DATA.getArpeggiator(App)

    if Pressed and Arp then
        if self:getShiftPressed() and self.ActivePageID ~= NI.HW.PAGE_ARP then
            self:changePage(NI.HW.PAGE_ARP)

        -- engine toggle
        elseif not self:getShiftPressed() then
            local ArpParam = NI.HW.getArpeggiatorActiveParameter(App)
            NI.DATA.ParameterAccess.toggleBoolParameter(App, ArpParam)
        end
    end

    self:onPageButton(NI.HW.PAGE_ARP, Pressed)
end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2:changePage(PageID)

    if self.PageList[PageID] then

        self.CapacitiveList:reset()

        if self.ActivePage then
            self.ActivePage:onShow(false)
        end

        self.ActivePage = self.PageList[PageID]
        self.ActivePageID = PageID

        self:onPageChange()

        self.ActivePage:onShow(true)
    end
end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2:onPageChange()
end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2:createPages()

    self.PageList[NI.HW.PAGE_MACRO]   = MacroPageStudio(self)
    self.PageList[NI.HW.PAGE_BUSY] = BusyPageStudio(self)
    self.PageList[NI.HW.PAGE_SCALE]   = ScaleChordPage(self)

    self:updatePageSync(true)
end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2:onLeftRightButton(Right, Pressed)

    if self.ActiveOverlay and self.ActiveOverlay:isVisible() then
        self.ActiveOverlay:onLeftRightButton(Right, Pressed)
        return
    end

    if self.ActivePage then
        self.ActivePage:onLeftRightButton(Right, Pressed)
    end

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2:showTempPage(Page)

    self:changePage(Page)
end

------------------------------------------------------------------------------------------------------------------------
-- C++ callbacks
------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2:onStateFlagsChanged()

    self:updatePageSync()
    self.ActivePage:updateScreens()

    if self.ActiveOverlay and self.ActiveOverlay:isVisible() then
        self.ActiveOverlay:update(self.ActivePage)
    end

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2:onDB3ModelChanged(Model)

    self.ActivePage:onDB3ModelChanged(Model)
end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2:onControllerTimer()

    self.Timer:onControllerTimer()
    self:updateKeySwitchDisplay()

    local InfoBarLeft, InfoBarRight = self:getInfoBars()
    if InfoBarLeft then
        InfoBarLeft:onTimer()
    end
    if InfoBarRight then
        InfoBarRight:onTimer()
    end

    if self.ActivePage then

        if self.ActivePage.ParameterHandler then
            self.ActivePage.ParameterHandler:onControllerTimer()
        end

        if self.ActivePage.onControllerTimer then
            self.ActivePage:onControllerTimer()
        end

    end

    self:updateLEDs()

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2:onDisplayTimer()

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2:onScreenButton(Index, Pressed)

    if self.ActiveOverlay and self.ActiveOverlay:isVisible() then
        self.ActiveOverlay:onScreenButton(Index, Pressed)
    else
        self.ActivePage:onScreenButton(Index, Pressed)
    end

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2:onNavPresetButton(Pressed, Up)

    if self.ActivePage and self.ActivePage.onNavPresetButton then
        self.ActivePage:onNavPresetButton(Pressed, Up)

    elseif Pressed then
        NI.DATA.QuickBrowseAccess.loadPrevNextPreset(App, Up and true or false)
    end

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2:onSwitchEvent(SwitchID, Pressed)

    -- save pressed state
    self.SwitchPressed[SwitchID] = Pressed

    if App:isBusy() then
        return
    end

    self:handleSwitchEvent(SwitchID, Pressed)

    self.ActivePage:updateScreens()

    if self.ActiveOverlay and self.ActiveOverlay:isVisible() then
        self.ActiveOverlay:update(self.ActivePage)
    end
end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2:handleSwitchEvent(SwitchID, Pressed)

    local Handler = self.SwitchHandler[SwitchID]
    if Handler then
        Handler(Pressed)
    end

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2:onEncoderEvent(EncoderID, Value)

    if App:isBusy() then
        return
    end

    local Handler = self.EncoderHandler[EncoderID]
    if Handler then
        Handler(Value)
    end

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2:onCapTouched(Cap, Touched)

    if App:isBusy() then
        return
    end

	CapacitiveHelper.onCapTouched(Cap, Touched)

    if self.ActiveOverlay and self.ActiveOverlay:isVisible() then
        self.ActiveOverlay:onCapTouched(Cap, Touched)

    elseif self.ActivePage.onCapTouched then
        self.ActivePage:onCapTouched(Cap, Touched)
    end

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2:onScreenEncoder(Index, EncoderInc)
    -- returns true if value has changed

    if App:isBusy() then
        return false
    end

    local PageOrOverlay = self:getActivePageOrOverlay()

    local Info = PageOrOverlay:getScreenEncoderInfo(Index)
    local PrevValue = Info and Info.Value

    PageOrOverlay:onScreenEncoder(Index, EncoderInc)

    Info = PageOrOverlay:getScreenEncoderInfo(Index)
    local Value = Info and Info.Value

    return Value ~= PrevValue

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2:onWheelButton(Pressed)

    if App:isBusy() then
        return
    end

    if self.ActiveOverlay and self.ActiveOverlay:isVisible() then
        self.ActiveOverlay:onWheelButton(Pressed)
        return
    end

    if self.ActivePage.onWheelButton then
        self.ActivePage:onWheelButton(Pressed)
    end
end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2:onWheelDirection(Pressed, Button)

    if self.ActiveOverlay and self.ActiveOverlay:isVisible() then
        self.ActiveOverlay:onWheelDirection(Pressed, Button)
        return
    end

    if self.ActivePage.onWheelDirection then
        self.ActivePage:onWheelDirection(Pressed, Button)
    end

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2:isModifierPage()
	return false
end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2:getShiftPressed()
	return self.SwitchPressed[NI.HW.BUTTON_PERFORM_SHIFT] == true
end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2:getInfoBars()

	if not self.ActivePage then
		return nil
	end

	local Page = self.ActivePage.CurrentPage or self.ActivePage

    local InfoBarScreenLeft = Page and Page.Screen and Page.Screen.ScreenLeft and Page.Screen.ScreenLeft.InfoBar
    local InfoBarScreenRight = Page and Page.Screen and Page.Screen.ScreenRight and Page.Screen.ScreenRight.InfoBar

	return InfoBarScreenLeft, InfoBarScreenRight

end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2:openBusyDialog()

    self.PageList[NI.HW.PAGE_BUSY]:setMessage(App:getGenericBusyMessage())

    self.CapacitiveList:setEnabled(false)
    local OverlayRoot = NHLController:getHardwareDisplay():getOverlayRoot()
    OverlayRoot:setVisible(false)

    self.ActivePage:onShow(false)
    self.PageList[NI.HW.PAGE_BUSY]:onShow(true)
end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2:closeBusyDialog()

    self.PageList[NI.HW.PAGE_BUSY]:onShow(false)
    self.ActivePage:onShow(true)

    self.CapacitiveList:setEnabled(true)
end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2:updateKeySwitchDisplay()

    local KeySwitchNote = NI.DATA.getKeySwitchNote(App)
    if KeySwitchNote and KeySwitchNote ~= self.KeySwitchNote then

        self.KeySwitchNote = KeySwitchNote

        if KeySwitchNote ~= INVALID_NOTE then
            self.KeySwitchNoteName = NI.DATA.getKeySwitchNoteName(App, self.KeySwitchNote)

            local InfoBar = self:getInfoBars()
            if InfoBar then
                InfoBar:setTempMode("KeySwitch")
            end

        end
    end
end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2:onWheelEvent(WheelID, Value)

    if self.ActiveOverlay and self.ActiveOverlay:isVisible() then
        self.ActiveOverlay:onWheel(Value)
        return
    end

    local Handled = self.ActivePage.onWheel and self.ActivePage:onWheel(Value)

    if not Handled and self:getShiftPressed() then
        NI.DATA.addMasterVolumeWheelDelta(App, Value)

        local InfoBar = self:getInfoBars()
        if InfoBar then
            InfoBar:setTempMode("MasterLevelMeter")
        end
    end
end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2:onOctaveButton(Pressed, Plus)

    if Pressed then
        self.OctaveOffset = NI.HW.getCurrentOctave(App)
        self.SemitoneOffset = NHLController:getSemitoneOffset()

        local InfoBar = self:getInfoBars()
        if InfoBar then
            InfoBar:setTempMode("NoteShift")
        end
    end
end

------------------------------------------------------------------------------------------------------------------------

function KompleteKontrol2:onOverlayButton(Button, Pressed)

    for _, Overlay in pairs (self.Overlays) do
        Overlay:setVisible(false)
    end

    if Pressed then
        self.ActiveOverlay = self.Overlays[Button]
        self.ActiveOverlay:setVisible(true)
        self.ActiveOverlay:update()
    else
        self.ActivePage:onShow(true)
    end

    self.CapacitiveList:setEnabled(self.ActiveOverlay and not self.ActiveOverlay:isVisible())

end

------------------------------------------------------------------------------------------------------------------------
