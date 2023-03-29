------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
TransportSection = class( 'TransportSection' )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function TransportSection:__init(Controller)

    -- Controller
    self.Controller = Controller

    -- Loop Helpers
    self.IsInLoopEditMode = false
    self.WaitingToShowLoopScreen = false

    self.OnWheelFunctor = function(Inc) self:defaultOnWheelFunctor(Inc) end

end

------------------------------------------------------------------------------------------------------------------------

function TransportSection:defaultOnWheelFunctor(Inc)

    local ShiftPressed = self.Controller:getShiftPressed()
    local ErasePressed = self.Controller:getErasePressed()

    local UseStepGrid = ShiftPressed or NHLController:getWheelPressed()
    NI.DATA.TransportAccess.nudgeTransportPosition(App, Inc, UseStepGrid, ErasePressed)

end

------------------------------------------------------------------------------------------------------------------------

function TransportSection:doToggleMetronomeOnShiftPlay()

    return self.Controller.HWModel == NI.HW.MASCHINE_CONTROLLER_MK1
        or self.Controller.HWModel == NI.HW.MASCHINE_CONTROLLER_MK2
        or self.Controller.HWModel == NI.HW.MASCHINE_CONTROLLER_MIKRO_MK1
        or self.Controller.HWModel == NI.HW.MASCHINE_CONTROLLER_MIKRO_MK2

end

------------------------------------------------------------------------------------------------------------------------
-- Event Handlers
------------------------------------------------------------------------------------------------------------------------

function TransportSection:onTimer()

    if self.WaitingToShowLoopScreen then

        self.WaitingToShowLoopScreen = false

        if self.Controller:getShiftPressed() then
            -- change loop
            self.IsInLoopEditMode = true
            NHLController:setTempJogWheelMode(NI.HW.JOGWHEEL_MODE_DEFAULT)

            -- show loop screen
            NHLController:getPageStack():pushPage(NI.HW.PAGE_LOOP)
        end

    else
        -- show pattern length preset screen
        NHLController:getPageStack():pushPage(NI.HW.PAGE_PATTERN_LENGTH)
    end

end

------------------------------------------------------------------------------------------------------------------------

function TransportSection:onPlay(Pressed)

    if not Pressed then
        return
    end

    if NI.DATA.TransportAccess.canControlTransport(App) then
        -- Play LED should flash until next timer updateTransportLEDs call (i.e. next timer event)
        LEDHelper.setLEDState(NI.HW.LED_TRANSPORT_PLAY, LEDHelper.LS_FLASH)
    end

    if self.Controller:getShiftPressed() then

        if self.Controller:isButtonPressed(NI.HW.BUTTON_TRANSPORT_RECORD) then

            -- Rec + (Erase) + Shift + Play starts count-in recording with restart from begin
            NI.DATA.TransportAccess.startEventRecording(App, true, self.Controller:getErasePressed())

        elseif self:doToggleMetronomeOnShiftPlay() then

            MaschineHelper:toggleMetronome()

        end

    else
        -- toggle play parameter
        NI.DATA.TransportAccess.togglePlay(App)
    end

end

------------------------------------------------------------------------------------------------------------------------

function TransportSection:onStop(Pressed)

    if Pressed and MaschineHelper.isPlaying() then
        NI.DATA.TransportAccess.togglePlay(App)
    end

end

------------------------------------------------------------------------------------------------------------------------

function TransportSection:onLoop(Pressed)

    if Pressed then

        if self.Controller:getShiftPressed() then

            -- start loop screen timer
            self.WaitingToShowLoopScreen = true
            self.Controller:setTimer(self, 20)

        else

            -- restart transport
            NI.DATA.TransportAccess.restartTransport(App)

        end

    elseif self.IsInLoopEditMode then

        self.IsInLoopEditMode = false
        NHLController:resetJogWheelMode()

        -- reset timer
        self.Controller:setTimer(self, 0)
        self.WaitingToShowLoopScreen = false

    else

        -- toggle loop
        if self.WaitingToShowLoopScreen then
            NI.DATA.TransportAccess.toggleLoop(App)
            if self.Controller:getInfoBar() then
                self.Controller:getInfoBar():setTempMode("Loop")
            end
        end

        -- reset timer
        self.Controller:setTimer(self, 0)
        self.WaitingToShowLoopScreen = false
    end

    self:updateTransportLEDs()

end

------------------------------------------------------------------------------------------------------------------------

function TransportSection:onRecord(Pressed, EnableRecordScreen)

    if EnableRecordScreen == nil then
        EnableRecordScreen = true
    end

    if Pressed then
        local ShiftPressed = self.Controller:getShiftPressed()
        local ErasePressed = self.Controller:getErasePressed()

        if MaschineHelper.isRecording() then
            if ShiftPressed then
                -- if shift pressed we always want to start count-in recording
                NI.DATA.TransportAccess.startEventRecording(App, ShiftPressed, ErasePressed)
            else
                if ErasePressed then
                    -- enable erase record
                    local ReplaceParameter = App:getWorkspace():getReplaceRecordingParameter()
                    NI.DATA.ParameterAccess.setBoolParameterNoUndo(App, ReplaceParameter, true)
                else
                    -- toggle record parameter
                    NI.DATA.TransportAccess.stopEventRecording(App)
                end
            end
        else
            NI.DATA.TransportAccess.startEventRecording(App, ShiftPressed, ErasePressed)

            if EnableRecordScreen then
                -- show pattern length preset screen / set timer
    	        self.Controller:setTimer(self, 20)
    	    end
        end
    else
        -- reset timer
        self.Controller:setTimer(self, 0)
    end

end

------------------------------------------------------------------------------------------------------------------------

function TransportSection:onErase(Pressed)

    if Pressed then
        NHLController:setTempJogWheelMode(NI.HW.JOGWHEEL_MODE_DEFAULT)

        -- switch off replace recording (if activated)
        local ReplaceParameter = App:getWorkspace():getReplaceRecordingParameter()
        local ReplaceRecording = ReplaceParameter:getValue()

        -- if record pressed and not replace recording, then enable replace recording
        if self.Controller:isButtonPressed(NI.HW.BUTTON_TRANSPORT_RECORD) and not ReplaceRecording then
            NI.DATA.TransportAccess.startEventRecording(App, false, true)
        -- if in replace record then disable recording
        elseif MaschineHelper.isRecording() and ReplaceRecording then
            NI.DATA.TransportAccess.stopReplaceRecording(App)
        end
    else
        NHLController:resetJogWheelMode()
    end

    self:updateTransportLEDs()

end

------------------------------------------------------------------------------------------------------------------------

function TransportSection:onShift(Pressed)

    -- leave loop edit mode when releasing shift
    if not Pressed and self.IsInLoopEditMode then

        self.IsInLoopEditMode = false
        NHLController:resetJogWheelMode()

    end

end

------------------------------------------------------------------------------------------------------------------------

function TransportSection:onWheel(Inc)

    if self.IsInLoopEditMode then

        local PrevPressed = self.Controller:isButtonPressed(NI.HW.BUTTON_TRANSPORT_PREV) or
            self.Controller:isButtonPressed(NI.HW.BUTTON_WHEEL_LEFT)
        local NextPressed = self.Controller:isButtonPressed(NI.HW.BUTTON_TRANSPORT_NEXT) or
            self.Controller:isButtonPressed(NI.HW.BUTTON_WHEEL_RIGHT)

        if PrevPressed and not NextPressed then
            NI.DATA.TransportAccess.moveLoopBeginFromHW(App, Inc)
        elseif NextPressed and not PrevPressed then
            NI.DATA.TransportAccess.moveLoopEndFromHW(App, Inc)
        else
            NI.DATA.TransportAccess.moveLoopFromHW(App, Inc)
        end

    else

        self.OnWheelFunctor(Inc)

    end

end

------------------------------------------------------------------------------------------------------------------------

function TransportSection:onPrevNext(Pressed, DoNext)

    if Pressed then

        if  not self.IsInLoopEditMode or
            NHLController:isMikro() or
            self.Controller.HWModel == NI.HW.MASCHINE_CONTROLLER_MK1 then

            local ErasePressed = self.Controller:getErasePressed()
            local ShiftPressed = self.Controller:getShiftPressed()

            NI.DATA.TransportAccess.nudgeTransportPosition(App, DoNext and 1 or -1, ShiftPressed, ErasePressed)

        end

    end

    self:updateTransportLEDs()

end

------------------------------------------------------------------------------------------------------------------------
-- Update LEDs
------------------------------------------------------------------------------------------------------------------------

function TransportSection:updateTransportLEDs()

    local Workspace    = App:getWorkspace()

    local LoopPressed  = self.Controller.SwitchPressed[NI.HW.BUTTON_TRANSPORT_LOOP] == true
    local ShiftPressed = self.Controller:getShiftPressed()
    local ErasePressed = self.Controller:getErasePressed()

    local PrevPressed  = self.Controller.SwitchPressed[NI.HW.BUTTON_TRANSPORT_PREV] == true
    local NextPressed  = self.Controller.SwitchPressed[NI.HW.BUTTON_TRANSPORT_NEXT] == true

    local LoopActive = NI.DATA.TransportAccess.isLoopActive(App)
    local ShowLoopDimmed = LoopActive or ShiftPressed
    local IsPlaying = MaschineHelper.isPlaying()

    ---- RESTART LED
    LEDHelper.setLEDState(NI.HW.LED_TRANSPORT_LOOP,
        LoopPressed and LEDHelper.LS_BRIGHT or
        ShowLoopDimmed and LEDHelper.LS_DIM or LEDHelper.LS_OFF)

    ---- PLAY LED
    LEDHelper.setLEDOnOff(NI.HW.LED_TRANSPORT_PLAY, IsPlaying)

    ---- RECORD LED
    LEDHelper.setLEDOnOff(NI.HW.LED_TRANSPORT_RECORD, MaschineHelper.isRecording())

    ---- ERASE LED (On some controller, the browse page overtakes the LED feedback)
    local ActivePage = self.Controller.ActivePage
    local ActivePageID = self.Controller.PageManager:getPageID(ActivePage)

    if not (ActivePageID == NI.HW.PAGE_BROWSE and ActivePage.canDeleteFiles and ActivePage:canDeleteFiles()) then
        LEDHelper.setLEDOnOff(NI.HW.LED_TRANSPORT_ERASE, ErasePressed or Workspace:getReplaceRecordingParameter():getValue())

    end

    if NHLController:getJogWheelMode() == NI.HW.JOGWHEEL_MODE_DEFAULT then

	    local HasWheel = not NHLController:isMikro() and self.Controller.HWModel ~= NI.HW.MASCHINE_CONTROLLER_MK1
        local ModifierOn = (HasWheel and self.IsInLoopEditMode) or (ErasePressed and not IsPlaying and NI.APP.isStandalone())

        ---- PREV LED
        LEDHelper.setLEDState(NI.HW.LED_TRANSPORT_PREV,
            PrevPressed and LEDHelper.LS_BRIGHT or
            (ModifierOn and LEDHelper.LS_DIM or LEDHelper.LS_OFF))

        ---- NEXT LED
        LEDHelper.setLEDState(NI.HW.LED_TRANSPORT_NEXT,
            NextPressed and LEDHelper.LS_BRIGHT or
            (ModifierOn and LEDHelper.LS_DIM or LEDHelper.LS_OFF))

    elseif NHLController:getJogWheelMode() ~= NI.HW.JOGWHEEL_MODE_CUSTOM then

        ---- PREV LED
        LEDHelper.setLEDState(NI.HW.LED_TRANSPORT_PREV, PrevPressed and LEDHelper.LS_BRIGHT or LEDHelper.LS_OFF)

        ---- NEXT LED
        LEDHelper.setLEDState(NI.HW.LED_TRANSPORT_NEXT, NextPressed and LEDHelper.LS_BRIGHT or LEDHelper.LS_OFF)

    end

    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_TRANSPORT_STOP, NI.HW.BUTTON_TRANSPORT_STOP, IsPlaying)

end

------------------------------------------------------------------------------------------------------------------------

