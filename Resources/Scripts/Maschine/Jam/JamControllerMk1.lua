------------------------------------------------------------------------------------------------------------------------
-- Jam MK1 Controller Class
------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Helpers/ArrangerHelper"
require "Scripts/Shared/Helpers/ControlHelper"
require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Shared/Helpers/MiscHelper"
require "Scripts/Shared/Helpers/SnapshotsHelper"
require "Scripts/Maschine/Jam/JamControllerBase"
require "Scripts/Maschine/Jam/LevelMeterControls"
require "Scripts/Maschine/Jam/LevelMeterControlsLooper"
require "Scripts/Shared/Components/Looper"
require "Scripts/Maschine/Jam/TouchStripControlsJam"


------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
JamControllerMK1 = class( 'JamControllerMK1', JamControllerBase )

------------------------------------------------------------------------------------------------------------------------

JamControllerMK1.DOUBLE_TOUCH_COUNTDOWN = 10

------------------------------------------------------------------------------------------------------------------------

function JamControllerMK1:__init()

    -- contruct base class
    JamControllerBase.__init(self)

    self.TouchstripControls = TouchstripControlsJam(self)

    self.DoubleTouchCountdown = {}
    self.BlockTouchEvents = {}
    self.Looper = Looper(
        function() self:onLooperEnabled() end,
        function() self:onLooperDisabled() end)

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerMK1:setupButtonHandlers()

    JamControllerBase.setupButtonHandlers(self)

    self.SwitchHandler[NI.HW.BUTTON_IN1] = function(Pressed) self:onIN1Button(Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_CUE] = function(Pressed) self:onLevelSourceButton(NI.HW.BUTTON_CUE, Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_MST] = function(Pressed) self:onLevelSourceButton(NI.HW.BUTTON_MST, Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_GRP] = function(Pressed) self:onLevelSourceButton(NI.HW.BUTTON_GRP, Pressed) end

    self.SwitchHandler[NI.HW.BUTTON_MACRO]   = function(Pressed) self:onMacroButton(Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_LEVEL]   = function(Pressed) self:onLevelButton(Pressed, false) end
    self.SwitchHandler[NI.HW.BUTTON_AUX]     = function(Pressed) self:onAuxButton(Pressed, false) end
    self.SwitchHandler[NI.HW.BUTTON_CONTROL] = function(Pressed) self:onControlButton(Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_AUTO]    = function(Pressed) self:onAutoButton(Pressed) end

    self.SwitchHandler[NI.HW.BUTTON_PERFORM] = function(Pressed) self:onPerformButton(Pressed, false) end
    self.SwitchHandler[NI.HW.BUTTON_TUNE]    = function(Pressed) self:onTuneButton(Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_SWING]   = function(Pressed) self:onSwingButton(Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_LOCK]    = function(Pressed) self:onLockButton(Pressed) end

    self.SwitchHandler[NI.HW.BUTTON_ARROW_LEFT]  = function(Pressed) self:onLeftRightButton(false, Pressed) end
    self.SwitchHandler[NI.HW.BUTTON_ARROW_RIGHT] = function(Pressed) self:onLeftRightButton(true, Pressed) end

    self:setModifierSwitchHandler(NI.HW.BUTTON_SHIFT, NI.HW.BUTTON_PERFORM,
                                  function(Pressed) self:onPerformButton(Pressed, true) end)

    self:setModifierSwitchHandler(NI.HW.BUTTON_SHIFT, NI.HW.BUTTON_LEVEL,
                                  function(Pressed) self:onLevelButton(Pressed, true) end)

    self:setModifierSwitchHandler(NI.HW.BUTTON_SHIFT, NI.HW.BUTTON_AUX,
                                  function(Pressed) self:onAuxButton(Pressed, true) end)

    self:setModifierSwitchHandler(NI.HW.BUTTON_SHIFT, NI.HW.BUTTON_MUTE,
        function(Pressed) self:onChoke(Pressed) end)

    self.SwitchHandler[NI.HW.FOOT_TIP] = function(Pressed) self:onFootswitchTip(Pressed) end
    self.SwitchHandler[NI.HW.FOOT_RING] = function(Pressed) self:onFootswitchRing(Pressed) end

    self.hidePerformFXOSO = false

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerMK1:onCustomProcess(ForceUpdate)

    self.TouchstripControls:onCustomProcess(ForceUpdate)

    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    if JamHelper.isJamOSOVisible(NI.HW.OSO_PERFORM_FX) and Group and not Group:getPerformanceFX() then
        self.hidePerformFXOSO = true
    end

    JamControllerBase.onCustomProcess(self, ForceUpdate)

end


------------------------------------------------------------------------------------------------------------------------

function JamControllerMK1:onControllerTimer()

    self.TouchstripControls:updateLEDs()

    self:updateRadioButtonLEDs()
    self:updateLeftRightLEDs()

    if self.hidePerformFXOSO then
        self.hidePerformFXOSO = false
        App:getJamParameterOverlay():setOSOType(NI.HW.OSO_NONE)
    end

    JamControllerBase.onControllerTimer(self)
    if self.Looper.Enabled then
        self.Looper:onTimer()
    end

    for Key, _ in pairs(self.DoubleTouchCountdown) do
        self.DoubleTouchCountdown[Key] = self.DoubleTouchCountdown[Key] - 1
        if self.DoubleTouchCountdown[Key] < 1 then
            self.DoubleTouchCountdown[Key] = nil
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerMK1:updateRadioButtonLEDs()

    local TouchstripMode = JamHelper.getTouchstripMode()
    local QuickEditMode = JamHelper.getQuickEditMode()

    local LEDStatePerform = TouchstripMode == NI.HW.TS_MODE_PERFORM
    LEDHelper.setLEDState(NI.HW.LED_PERFORM, LEDStatePerform and LEDHelper.LS_BRIGHT or LEDHelper.LS_OFF)

    local LEDStateNotes = TouchstripMode == NI.HW.TS_MODE_NOTES
    LEDHelper.setLEDState(NI.HW.LED_NOTES, LEDStateNotes and LEDHelper.LS_BRIGHT or LEDHelper.LS_OFF)

    local LEDStateMacro = TouchstripMode == NI.HW.TS_MODE_MACRO
    LEDHelper.setLEDState(NI.HW.LED_MACRO, LEDStateMacro and LEDHelper.LS_BRIGHT or LEDHelper.LS_OFF)

    local LEDStateLevel = TouchstripMode == NI.HW.TS_MODE_LEVEL or TouchstripMode == NI.HW.TS_MODE_PAN
        or QuickEditMode == NI.HW.QUICK_EDIT_VELOCITY
    LEDHelper.setLEDState(NI.HW.LED_LEVEL, LEDStateLevel and LEDHelper.LS_BRIGHT or LEDHelper.LS_OFF)

    local LEDStateAux = TouchstripMode == NI.HW.TS_MODE_AUX1 or TouchstripMode == NI.HW.TS_MODE_AUX2
    LEDHelper.setLEDState(NI.HW.LED_AUX, LEDStateAux and LEDHelper.LS_BRIGHT or LEDHelper.LS_OFF)

    local LEDStateControl = TouchstripMode == NI.HW.TS_MODE_CONTROL
    LEDHelper.setLEDState(NI.HW.LED_CONTROL, LEDStateControl and LEDHelper.LS_BRIGHT or LEDHelper.LS_OFF)

    local LEDStateTune = TouchstripMode == NI.HW.TS_MODE_TUNE or QuickEditMode == NI.HW.QUICK_EDIT_PITCH
    LEDHelper.setLEDState(NI.HW.LED_TUNE, LEDStateTune and LEDHelper.LS_BRIGHT or LEDHelper.LS_OFF)

    local LEDStateSwing = TouchstripMode == NI.HW.TS_MODE_SWING or QuickEditMode == NI.HW.QUICK_EDIT_POSITION
    LEDHelper.setLEDState(NI.HW.LED_SWING, LEDStateSwing and LEDHelper.LS_BRIGHT or LEDHelper.LS_OFF)

    local LEDStateAuto = NHLController:isAutoWriteEnabled()
    LEDHelper.updateButtonLED(self, NI.HW.LED_AUTO, NI.HW.BUTTON_AUTO, LEDStateAuto)

    if NHLController:getPageStack():isTopPage(NI.HW.PAGE_SNAPSHOTS) then
        LEDHelper.setLEDState(NI.HW.LED_LOCK, LEDHelper.LS_BRIGHT)
    elseif NHLController:getPageStack():isPageInStack(NI.HW.PAGE_SNAPSHOTS) then
        LEDHelper.setLEDState(NI.HW.LED_LOCK, LEDHelper.LS_DIM)
    else
        local LockActive = NI.DATA.ParameterSnapshotsAccess.isSnapshotActiveHW(App)
        LEDHelper.updateButtonLED(self, NI.HW.LED_LOCK, NI.HW.BUTTON_LOCK, LockActive)
    end

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerMK1:updateLeftRightLEDs()

    if self:isShiftPressed() then
        return
    end

    local LeftRightActive = TouchstripControlsJam.isLeftRightButtonsActive()

    local LEDStateLeft = false
    local LEDStateRight = false

    local TouchstripMode = JamHelper.getTouchstripMode()

    if TouchstripMode == NI.HW.TS_MODE_CONTROL or TouchstripMode == NI.HW.TS_MODE_MACRO then
        local ParamCache = App:getStateCache():getParameterCache()
        local PageParam = ParamCache:getPageParameter()

        if PageParam then
            local NumPages = ParamCache:getNumPagesOfFocusParameterOwner()
            local CurrentPage = PageParam:getValue()

            LEDStateLeft = LeftRightActive and CurrentPage ~= NPOS and CurrentPage > 0
            LEDStateRight = LeftRightActive and CurrentPage ~= NPOS and CurrentPage < NumPages - 1
        end
    else
        LEDStateLeft = LeftRightActive and JamHelper.getSoundOffset() ~= 0
        LEDStateRight = LeftRightActive and JamHelper.getSoundOffset() == 0
    end

    LEDHelper.updateButtonLED(self, NI.HW.LED_ARROW_LEFT, NI.HW.BUTTON_ARROW_LEFT, LEDStateLeft)
    LEDHelper.updateButtonLED(self, NI.HW.LED_ARROW_RIGHT, NI.HW.BUTTON_ARROW_RIGHT, LEDStateRight)

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerMK1:getShiftPageID(Button, CurPageID, Pressed)

    if Button == NI.HW.BUTTON_SOLO then
        return NI.HW.PAGE_PATTERN_LENGTH
    elseif Button == NI.HW.BUTTON_LOCK then
        return NI.HW.PAGE_SNAPSHOTS
    end

    return JamControllerBase.getShiftPageID(self, Button, CurPageID, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerMK1:getButtonFromPage(PageID)

    if PageID == NI.HW.PAGE_PATTERN_LENGTH then
        return NI.HW.BUTTON_SOLO
    elseif PageID == NI.HW.PAGE_SNAPSHOTS then
        return NI.HW.BUTTON_LOCK
    end

    return JamControllerBase.getButtonFromPage(self, PageID)

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerMK1:onLevelButton(Pressed, ShiftPressed)

    if Pressed and JamHelper.isQuickEditModeEnabled() then

        local QEMode = NI.DATA.JamControllerContext.getQuickEditModeByTouchstripMode(NI.HW.TS_MODE_LEVEL)
        JamHelper.setQuickEditMode(QEMode)
        return

    elseif Pressed and JamHelper.isStepModulationModeEnabled() then

        JamHelper.setTouchstripMode(NI.HW.TS_MODE_LEVEL)
        return

    elseif Pressed then

        JamHelper.setTouchstripMode(ShiftPressed and NI.HW.TS_MODE_PAN or NI.HW.TS_MODE_LEVEL)
        NI.DATA.ParameterPageAccess.setFocusPageOnOutputPageGroup(App, NI.HW.MIXING_LAYER_PAGE_AUDIO) -- page level

    end

    self:onPageButton(NI.HW.BUTTON_LEVEL, NI.HW.PAGE_MIXING_LAYER_SELECT, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerMK1:onAuxButton(Pressed, ShiftPressed)

    if Pressed then

        JamHelper.setTouchstripMode(ShiftPressed and NI.HW.TS_MODE_AUX2 or NI.HW.TS_MODE_AUX1)

        NI.DATA.ParameterPageAccess.setFocusPageOnOutputPageGroup(App, NI.HW.MIXING_LAYER_PAGE_AUX) -- page aux

    end

    self:onPageButton(NI.HW.BUTTON_AUX, NI.HW.PAGE_MIXING_LAYER_SELECT, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerMK1:onControlButton(Pressed)

    if Pressed then

        JamHelper.setTouchstripMode(NI.HW.TS_MODE_CONTROL)
        ControlHelper.setPluginMode(true)

    end

    self:onPageButton(NI.HW.BUTTON_CONTROL, NI.HW.PAGE_MIXING_LAYER_SELECT, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerMK1:onAutoButton(Pressed)

    local Enabled = NHLController:isAutoWriteEnabled()
    local Pinned = NHLController:isAutoWritePinned()

    if Pressed then

        Enabled = not Pinned or not Enabled

    elseif not Pinned then

        Enabled = false

    end

    NHLController:setAutoWriteEnabled(Enabled)

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerMK1:onIN1Button(Pressed)

    if not self.Looper.Enabled and Pressed then
        self.LevelMeterControls = LevelMeterControlsLooper(self, self.Looper, self.LevelMeter)
    end

    self.LevelMeterControls:onLevelSourceButton(NI.HW.BUTTON_IN1, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerMK1:onLooperEnabled()

    ArrangerHelper.enterIdeaSpaceView()

    if self.Looper:isPinned() then
        NHLController:getPageStack():popToBottomPage()
    else
        NHLController:getPageStack():pushPage(NI.HW.PAGE_MAIN)
    end
    self:updatePageSync(true)

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerMK1:onLooperDisabled()

    NHLController:getPageStack():popPage()
    self:updatePageSync(true)

    self.LevelMeterControls = LevelMeterControls(self, self.LevelMeter)

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerMK1:onMacroButton(Pressed)

    if Pressed then

        JamHelper.setTouchstripMode(NI.HW.TS_MODE_MACRO)
        NI.DATA.ParameterPageAccess.setMacroPageActive(App)

    end

    self:onPageButton(NI.HW.BUTTON_MACRO, NI.HW.PAGE_MIXING_LAYER_SELECT, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerMK1:onPerformButton(Pressed, ShiftPressed)

    if Pressed then

        JamHelper.setTouchstripMode(NI.HW.TS_MODE_PERFORM)

        if ShiftPressed and not JamHelper.isJamOSOVisible(NI.HW.OSO_PERFORM_FX) then
            NI.DATA.SongAccess.loadPerformanceFX(App, false)
            self.ParameterHandler:showOSO(NI.HW.OSO_PERFORM_FX)
        else
            self.ParameterHandler:hideOSO()
            NI.DATA.ParameterPageAccess.setFocusPerformFXSlot(App)
        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerMK1:onLockButton(Pressed)

    if self:isShiftPressed() or NHLController:getPageStack():isTopPage(NI.HW.PAGE_SNAPSHOTS) then
        self:onPageButton(NI.HW.BUTTON_LOCK, NI.HW.PAGE_SNAPSHOTS, Pressed)
    elseif Pressed then
        SnapshotsHelper.toggleLock()
    end

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerMK1:onLeftRightButton(Right, Pressed)

    if not self:isShiftPressed() and self.TouchstripControls:onLeftRightButton(Right, Pressed) then
        return
    end

    JamControllerBase.onLeftRightButton(self, Right, Pressed)
end

------------------------------------------------------------------------------------------------------------------------

function JamControllerMK1:onChoke(Pressed)

    if Pressed then
        NI.DATA.MaschineAccess.chokeAll(App)
    end

    local LedState = (Pressed or NHLController:getPageStack():isTopPage(NI.HW.PAGE_MUTE))
        and LEDHelper.LS_BRIGHT or LEDHelper.LS_OFF

    LEDHelper.setLEDState(NI.HW.LED_MUTE, LedState)

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerMK1:onPinButton(Pressed)

    if self:isButtonPressed(NI.HW.BUTTON_AUTO) then
        if Pressed then
            local Pinned = NHLController:isAutoWritePinned()
            NHLController:setAutoWritePinned(not Pinned)
        end
        self:setPinButtonLed(Pressed)
        return true
    elseif self:isButtonPressed(NI.HW.BUTTON_IN1) then
        if Pressed then
            self.Looper:togglePinned()
            if self.Looper.Enabled then
                NHLController:getPageStack():popToBottomPage()
                self:updatePageSync(true)
            end
        end
        return true
    else
        return JamControllerBase.onPinButton(self, Pressed)
    end

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerMK1:onTuneButton(Pressed)

    if Pressed then
        if JamHelper.isQuickEditModeEnabled() then
            local QEMode = NI.DATA.JamControllerContext.getQuickEditModeByTouchstripMode(NI.HW.TS_MODE_TUNE)
            JamHelper.setQuickEditMode(QEMode)
        else
            JamHelper.setTouchstripMode(NI.HW.TS_MODE_TUNE)
        end
    end

    if not JamHelper.isStepModulationModeEnabled() then
        self:onPageButton(NI.HW.BUTTON_TUNE, NI.HW.PAGE_MIXING_LAYER_SELECT, Pressed)
    end


end

------------------------------------------------------------------------------------------------------------------------

function JamControllerMK1:onSwingButton(Pressed)

    if Pressed then
        if JamHelper.isQuickEditModeEnabled() then
            local QEMode = NI.DATA.JamControllerContext.getQuickEditModeByTouchstripMode(NI.HW.TS_MODE_SWING)
            JamHelper.setQuickEditMode(QEMode)
        else
            JamHelper.setTouchstripMode(NI.HW.TS_MODE_SWING)
            NI.DATA.ParameterPageAccess.setGroovePageActive(App)
        end
    end

    if not JamHelper.isStepModulationModeEnabled() then
        self:onPageButton(NI.HW.BUTTON_SWING, NI.HW.PAGE_MIXING_LAYER_SELECT, Pressed)
    end


end

------------------------------------------------------------------------------------------------------------------------

function JamControllerMK1:onWheelEvent(WheelID, Inc)

    -- if the Looper OSO is showing, make sure wheel events get forwarded to it and not e.g. the LevelMeter
    if JamHelper.isJamOSOVisible(NI.HW.OSO_LOOP_RECORD) then
        return self.ParameterHandler:onWheelEvent(Inc)
    else
        return JamControllerBase.onWheelEvent(self, WheelID, Inc)
    end

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerMK1:onFootswitchTip(Pressed)

    if self.Looper.Enabled then
        self.Looper:onFootswitch(Pressed)
    else
        self:onPlayButton(Pressed)
    end
end

------------------------------------------------------------------------------------------------------------------------

function JamControllerMK1:onFootswitchRing(Pressed)

    if self.Looper.Enabled then
        self.Looper:onFootswitch(Pressed)
    else
        self:onRecordButton(Pressed)
    end

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerMK1:onTouchEvent(TouchID, TouchType, Value)

    -- make index 1-based in order to make table.contains work properly
    local LuaTouchID = TouchID + 1
    local Touched = TouchType == self.TOUCH_EVENT_TOUCHED
    local Delta = 0

    if TouchType == self.TOUCH_EVENT_MOVED and self.TouchstripStates.Value[LuaTouchID] and Value then
        Delta = Value - self.TouchstripStates.Value[LuaTouchID]
    end

    if Touched then
        self.BlockTouchEvents[LuaTouchID] = self.DoubleTouchCountdown[LuaTouchID] ~= nil
            and self:isButtonPressed(NI.HW.BUTTON_TUNE)
        self.DoubleTouchCountdown[LuaTouchID] = self.DOUBLE_TOUCH_COUNTDOWN
    end

    local TouchedOrMoved = Touched or TouchType == self.TOUCH_EVENT_MOVED

    if TouchedOrMoved and not self.BlockTouchEvents[LuaTouchID] and not JamHelper.isStepModulationModeEnabled() then

        local TSMode = JamHelper.getTouchstripMode()
        local LevelTab = MaschineHelper.getLevelTab()
        local AutoWriteEnabled = NHLController:isAutoWriteEnabled() and MaschineHelper.isPlaying()

        if not AutoWriteEnabled and TSMode == NI.HW.TS_MODE_TUNE and LevelTab == NI.DATA.LEVEL_TAB_GROUP then

            local GroupIndex = JamHelper.getGroupOffset() + TouchID
            local Song = NI.DATA.StateHelper.getFocusSong(App)
            local Group = Song and Song:getGroups():at(GroupIndex)

            if Group then
                local ParamDiff = 0
                if self:isShiftPressed() then
                    if self.TouchstripStates.Touched[LuaTouchID] then
                        ParamDiff = Delta * 0.1;
                    end
                else
                    local OldValue = Group:getTuneOffsetParameter():getValue()
                    local NewValue = Value * 2.0 - 1.0 -- map to range of -1.0 to 1.0
                    ParamDiff = NewValue - OldValue
                end
                NI.DATA.GroupAccess.offsetSoundsTuneParam(App, Group, ParamDiff, false)
            end
        end

    end

    self.TouchstripStates.Touched[LuaTouchID] = TouchedOrMoved
    self.TouchstripStates.Value[LuaTouchID] = Value
    self.TouchstripStates.Delta[LuaTouchID] = Delta

    if not TouchedOrMoved
       and not self:anyTouchstripTouched()
       and (JamHelper.isJamOSOVisible(NI.HW.OSO_TUNE) or JamHelper.isJamOSOVisible(NI.HW.OSO_SWING)) then

        self.ParameterHandler:startOSOTimeout()
    end

     if self.ActivePage then
        self.ActivePage:onTouchEvent(TouchID, TouchType, Value)
    end

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerMK1:anyTouchstripTouched()

    return table.contains(self.TouchstripStates.Touched, true)

end

------------------------------------------------------------------------------------------------------------------------

function JamControllerMK1:onGroupChange()

end

------------------------------------------------------------------------------------------------------------------------


-- The Instance
ControllerScriptInterface = JamControllerMK1()

------------------------------------------------------------------------------------------------------------------------
