------------------------------------------------------------------------------------------------------------------------
-- The base page that displays parameter values.
------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Helpers/BrowseHelper"
require "Scripts/Shared/Components/Timer"

local class = require 'Scripts/Shared/Helpers/classy'
ParameterPageBase = class( 'ParameterPageBase' )

local ENCODER_TOUCH_TIMEOUT = 20
local PERFORM_BUTTON_TIMEOUT = 15

------------------------------------------------------------------------------------------------------------------------
-- "Virtual" Functions
------------------------------------------------------------------------------------------------------------------------

function ParameterPageBase:__init(Controller)

    self.Controller = Controller

    self.FocusPage = 1
    self.NumPages = 0

    self.PageField = nil

    self.EncoderTouchedDelay = {} --countdown before releasing encoder's touch status

    self.Undoable = true

end

------------------------------------------------------------------------------------------------------------------------

function ParameterPageBase:onActivate()

    self:clearScreen()

end

------------------------------------------------------------------------------------------------------------------------

function ParameterPageBase:onDeactivate()

end

------------------------------------------------------------------------------------------------------------------------

function ParameterPageBase:setFocusPage(FocusPage)

    self:clearScreen()

    if FocusPage ~= self.FocusPage then

        self.FocusPage = FocusPage
        self.Controller.DisplayStack:removeIfScheduled(DISPLAY_MODE_VOLUME)
        self.Controller.DisplayStack:removeIfScheduled(DISPLAY_MODE_OCTAVE)
        self.Controller.DisplayStack:removeIfScheduled(DISPLAY_MODE_AUTOWRITE)

    end

end

------------------------------------------------------------------------------------------------------------------------

function ParameterPageBase:getOctaveString()

    local SignString = ""
    if self.Controller.Octave > 0 then
        SignString = "+"
    elseif self.Controller.Octave == 0 then
        SignString = " "
    end
    return "OCT" .. SignString .. self.Controller.Octave

end

------------------------------------------------------------------------------------------------------------------------

function ParameterPageBase:updateScreen()

    self:updatePagePresetDisplay()

    local Screen = NHLController:getScreen()

    for Section = 1, SCREEN.NUM_SECTIONS - 1 do
        self:updateParameterText(Section)
        self:updateParameterMeter(Section)
    end

end

------------------------------------------------------------------------------------------------------------------------

function ParameterPageBase:clearScreen()

    local Screen = NHLController:getScreen()
    if not Screen then
        return
    end
    Screen:reset()

end

------------------------------------------------------------------------------------------------------------------------

function ParameterPageBase:updatePagePresetDisplay()

    local Screen = NHLController:getScreen()
    local PageField, PresetField = self:getPagePresetText(self.Controller:getDisplayMode())

    Screen:setText(0, SCREEN.DISPLAY_FIRST_ROW, PageField or "")
    Screen:setText(0, SCREEN.DISPLAY_SECOND_ROW, PresetField or "")

    Screen:setTextAlignment(0, SCREEN.DISPLAY_FIRST_ROW, SCREEN.ALIGN_RIGHT)
    Screen:setTextAlignment(0, SCREEN.DISPLAY_SECOND_ROW, SCREEN.ALIGN_RIGHT)

end

------------------------------------------------------------------------------------------------------------------------

function ParameterPageBase:getPagePresetText(DisplayMode)

    local PageField = nil
    local PresetField = nil

    local FocusSlot = MaschineHelper.getFocusedSoundSlot()
    local Sound = NI.DATA.StateHelper.getFocusSound(App)

    if DisplayMode == DISPLAY_MODE_AUTOWRITE then

        local AutoOn = NI.DATA.WORKSPACE.isAutoWriteEnabledFromKompleteKontrol(App)
        PageField = AutoOn and "AUTO ON" or "AUTO OFF"

    elseif DisplayMode == DISPLAY_MODE_GROUPSOUND or DisplayMode == DISPLAY_MODE_GROUPSOUND_NAV then

        local StateHelper = NI.DATA.StateHelper
        local GroupLabel = NI.DATA.Group.getLabel(StateHelper.getFocusGroupIndex(App))
        local SoundIndex = StateHelper.getFocusSoundIndex(App)

        if SoundIndex == NPOS then
            PageField = "EMPTY"
        else
            PageField = GroupLabel .. "." .. SoundIndex + 1
            PresetField = Sound and Sound:getDisplayName()
        end

    elseif Sound and DisplayMode == DISPLAY_MODE_VOLUME then

        PageField = NI.UTILS.LevelScale.level2ValueString(Sound:getLevelParameter():getValue())

    elseif DisplayMode == DISPLAY_MODE_OCTAVE then

        PageField = self:getOctaveString()

    elseif DisplayMode == DISPLAY_MODE_PAGECOUNT then

        PageField = self.PageField or (self.NumPages > 0 and (self.FocusPage .. '/' .. self.NumPages)) or "EMPTY"
        PresetField = FocusSlot and NI.DATA.SlotAlgorithms.getDisplayName(FocusSlot)

    elseif DisplayMode == DISPLAY_MODE_KEYSWITCH then

        PageField = self.PageField or (self.NumPages > 0 and (self.FocusPage .. '/' .. self.NumPages)) or "EMPTY"
        PresetField = self.Controller.KeySwitchName

    end

    return PageField, PresetField

end

------------------------------------------------------------------------------------------------------------------------
-- Initialize the textual part of the display.
------------------------------------------------------------------------------------------------------------------------

function ParameterPageBase:updateParameterText(Section)

    local Screen = NHLController:getScreen()

    if Section >= SCREEN.NUM_SECTIONS then
        return
    end

    local Parameter = Section > 0 and HELPERS.getCachedParameter(App, Section - 1)
    if not Parameter then
        Screen:setText(Section, SCREEN.DISPLAY_SECOND_ROW, "")
        return
    end

    local Screen = NHLController:getScreen()

    local IsAutoWriting = self:isAutoWriting()

    -- SHOW NOTHING (Disabled due to auto-write)
    if IsAutoWriting and not Parameter:isAutomatable() then

        Screen:setText(Section, SCREEN.DISPLAY_FIRST_ROW, "")
        Screen:setTextAlignment(Section, 0, SCREEN.ALIGN_LEFT)

        -- SHOW VALUE
    elseif self:isEncoderTouched(Section) or Parameter:isKKSAlwaysShowValue() then

        local Text = NI.GUI.ParameterWidgetHelper.getValueString(Parameter, IsAutoWriting)
        Screen:setText(Section, SCREEN.DISPLAY_FIRST_ROW, Text)

        if Parameter:getTag() == NI.DATA.MaschineParameter.TAG_ENUM or Parameter:isKKSAlwaysShowValue() then
            Screen:setTextAlignment(Section, 0, SCREEN.ALIGN_LEFT)
        else
            Screen:setTextAlignment(Section, 0, SCREEN.ALIGN_RIGHT)
        end

        -- SHOW NAME
    else

        local DisplayName = Parameter:getDisplayName()
        local Name = DisplayName == "" and Parameter:getParameterInterface():getName() or DisplayName

        Screen:setText(Section, SCREEN.DISPLAY_FIRST_ROW, Name)
        Screen:setTextAlignment(Section, 0, SCREEN.ALIGN_LEFT)
    end

    local SectionName = Parameter:getSectionName()
    if self:isSectionNameInvalid(SectionName, Section - 1) then

        Screen:setText(Section, SCREEN.DISPLAY_SECOND_ROW, SectionName)
    else
        Screen:setText(Section, SCREEN.DISPLAY_SECOND_ROW, "")
    end

    Screen:setTextAlignment(Section, 1, SCREEN.ALIGN_LEFT)

end

------------------------------------------------------------------------------------------------------------------------
-- Initialize the meters on the display.
------------------------------------------------------------------------------------------------------------------------

function ParameterPageBase:updateParameterMeter(Section)

    local Screen = NHLController:getScreen()

    if Section == 0 then --todo: or not NI.DATA.ChainAlgorithms.isInstrumentPluginLoaded(App:getChain())
        Screen:setMeterActive(Section, false)
        return
    end

    if Section >= SCREEN.NUM_SECTIONS then
        return
    end

    local Parameter = HELPERS.getCachedParameter(App, Section - 1)
    if not Parameter then
        Screen:setMeterActive(Section, false)
        return
    end

    local Tag = Parameter:getTag()

    Screen:setMeterValue(Section, Parameter:getNormalizedValue())
    Screen:setMeterAlignment(Section, SCREEN.ALIGN_SINGLE)

    if self:isAutoWriting() then

        Screen:setMeterValue(Section, 0.5 * Parameter:getEncoderValueAutoWrite() + 0.5)  -- scale [-1, 1] -> [0, 1]
        Screen:setMeterAlignment(Section, SCREEN.ALIGN_CENTER)
        Screen:setMeterActive(Section, Parameter:isAutomatable())

    elseif Tag == NI.DATA.MaschineParameter.TAG_PLUGIN then

        Screen:setMeterActive(Section, Parameter:isAssigned())

    elseif Tag == NI.DATA.MaschineParameter.TAG_ENUM or
        Tag == NI.DATA.MaschineParameter.TAG_SIZE_T or
        Tag == NI.DATA.MaschineParameter.TAG_BOOL or
        Tag == NI.DATA.MaschineParameter.TAG_FLOAT then

        Screen:setMeterAlignment(Section, Parameter:isBipolar() and SCREEN.ALIGN_CENTER or SCREEN.ALIGN_SINGLE)
        Screen:setMeterActive(Section, true)

    elseif Tag == NI.DATA.MaschineParameter.TAG_INT or
        Tag == NI.DATA.MaschineParameter.TAG_DOUBLE then

        Screen:setMeterActive(Section, true)
    else
        Screen:setMeterActive(Section, false)
    end

end

------------------------------------------------------------------------------------------------------------------------

function ParameterPageBase:updateLEDs()

    -- TRANSPORT LEDS

    if not NI.APP.isStandalone() then

        LEDHelper.setLEDOnOff(HW.LED_TRANSPORT_RECORD, MaschineHelper.isRecording())

    end

    -- PAGE LEDs

    local AutoWriteEnabled = NI.DATA.WORKSPACE.isAutoWriteEnabledFromKompleteKontrol(App)

    if self.Controller:isShiftPressed() and not AutoWriteEnabled then

        LEDHelper.setLEDState(HW.LED_DISPLAY_ARROW_LEFT, LEDHelper.LS_DIM)
        LEDHelper.setLEDState(HW.LED_DISPLAY_ARROW_RIGHT, LEDHelper.LS_DIM)

    else

        if AutoWriteEnabled then

            LEDHelper.setLEDState(HW.LED_DISPLAY_ARROW_LEFT, LEDHelper.LS_BRIGHT)
            LEDHelper.setLEDState(HW.LED_DISPLAY_ARROW_RIGHT, LEDHelper.LS_BRIGHT)

        else

            LEDHelper.updateButtonLED(self.Controller, HW.LED_DISPLAY_ARROW_LEFT, HW.BUTTON_DISPLAY_ARROW_LEFT,
                self.FocusPage > 1)

            LEDHelper.updateButtonLED(self.Controller, HW.LED_DISPLAY_ARROW_RIGHT, HW.BUTTON_DISPLAY_ARROW_RIGHT,
                self.FocusPage < self.NumPages)
        end
    end

    -- PERFORM BUTTON LEDS

    if NI.APP.isStandalone() or NI.APP.FEATURE.MAS_SMART_PLAY then
        local ScaleEngineActiveParam = NI.HW.getScaleEngineActiveParameter(App)
        local ArpeggiatorActiveParam = NI.HW.getArpeggiatorActiveParameter(App)

        local ScaleEngineEnabled = ScaleEngineActiveParam and ScaleEngineActiveParam:getValue()
        local ArpeggiatorEnabled = ArpeggiatorActiveParam and ArpeggiatorActiveParam:getValue()
        local Group = NI.DATA.StateHelper.getFocusGroup(App)

        LEDHelper.setLEDState(HW.LED_PERFORM_SCALE, Group and (ScaleEngineEnabled and LEDHelper.LS_BRIGHT or LEDHelper.LS_DIM) or LEDHelper.LS_OFF)
        LEDHelper.setLEDState(HW.LED_PERFORM_ARPEGGIATOR, ArpeggiatorEnabled and LEDHelper.LS_BRIGHT or LEDHelper.LS_DIM)
    else
        LEDHelper.setLEDState(HW.LED_PERFORM_SCALE, LEDHelper.LS_OFF)
        LEDHelper.setLEDState(HW.LED_PERFORM_ARPEGGIATOR, LEDHelper.LS_OFF)
    end

    self:updateNavigationLEDs()

    -- SHIFT BUTTON

    LEDHelper.setLEDState(HW.LED_PERFORM_SHIFT, self.Controller:isShiftPressed() and LEDHelper.LS_BRIGHT or LEDHelper.LS_DIM)

end

------------------------------------------------------------------------------------------------------------------------

function ParameterPageBase:onControllerTimer()

    -- ENCODERS TOUCH COUNTDOWN PROCESS
    for Index = 1, 8 do
        local Countdown = self.EncoderTouchedDelay[Index] and self.EncoderTouchedDelay[Index] or 0

        if Countdown > 0 then

            self.EncoderTouchedDelay[Index] = Countdown - 1

            if self.EncoderTouchedDelay[Index] == 0 then
                self:updateScreen()
            end
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function ParameterPageBase:onShiftButton(Pressed)

    local OSOVisible = App:getOnScreenOverlay():getVisibleParameter():getValue()

    if Pressed  then
        if self.Controller:isWheelTouched() and not OSOVisible then
            self.Controller.DisplayStack:insert(DISPLAY_MODE_VOLUME)
        end
    else
        self.Controller.DisplayStack:scheduleRemove(DISPLAY_MODE_VOLUME, DISPLAY_MODE_TIMEOUT)
    end

    self.Controller.Timer:setTimer(self, 0)

end

------------------------------------------------------------------------------------------------------------------------

function ParameterPageBase:onWheelEvent(Value)

    local OnScreenOverlay = App:getOnScreenOverlay()

    if OnScreenOverlay:getVisibleParameter():getValue() then
        OnScreenOverlay:onWheelEvent(Value, self.Controller:isShiftPressed())
        self.Controller:updateScreen()
    elseif self.Controller:isShiftPressed() then
        local Sound = NI.DATA.StateHelper.getFocusSound(App)
        if Sound then
            local Param = Sound:getLevelParameter()
            NI.DATA.ParameterAccess.addLevelPanWheelDelta(App, Param, Value,
            false, NHLController:getControllerModel())
        end
    elseif HELPERS.getKKTransportEnabled(App) then
        if NHLController:getLoopButtonPressed() then
            if self.Controller.SwitchPressed[HW.BUTTON_NAVIGATE_ARROW_LEFT] then
                NI.DATA.TransportAccess.moveLoopBeginFromHW(App, Value)
            elseif self.Controller.SwitchPressed[HW.BUTTON_NAVIGATE_ARROW_RIGHT] then
                NI.DATA.TransportAccess.moveLoopEndFromHW(App, Value)
            else
                NI.DATA.TransportAccess.moveLoopFromHW(App, Value)
            end
        else
            NI.DATA.TransportAccess.nudgeTransportPosition(App, Value, false, false)
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function ParameterPageBase:onWheelButton(Pushed)

    if Pushed then
        local OnScreenOverlay = App:getOnScreenOverlay()
        OnScreenOverlay:onEnter(self.Controller:isShiftPressed(), true)
    end

end

------------------------------------------------------------------------------------------------------------------------

function ParameterPageBase:onWheelTouched(Touched)

    local OSOVisibleParameter = App:getOnScreenOverlay():getVisibleParameter()

    if not OSOVisibleParameter:getValue() and Touched and self.Controller:isShiftPressed() then
        self.Controller.DisplayStack:insert(DISPLAY_MODE_VOLUME)
    elseif not Touched then
        self.Controller.DisplayStack:scheduleRemove(DISPLAY_MODE_VOLUME, DISPLAY_MODE_TIMEOUT)
    end

end

------------------------------------------------------------------------------------------------------------------------

function ParameterPageBase:onNavUpDownButton(Pressed, Up)

    if not Pressed then
        return
    end

    local OnScreenOverlay = App:getOnScreenOverlay()
    if OnScreenOverlay:getVisibleParameter():getValue() then
        OnScreenOverlay:onUpDown(Up)
        return
    end

    local StateCache = App:getStateCache()

    -- nav groups
    if self.Controller:isShiftPressed() then

        local Song = NI.DATA.StateHelper.getFocusSong(App)
        local Groups = Song and Song:getGroups() or nil
        local GroupIndex = NI.DATA.StateHelper.getFocusGroupIndex(App)

        if not Groups or (GroupIndex == NPOS and not Up) then
            return
        end

        if GroupIndex == NPOS and Up and Groups:size() > 0 then
            MaschineHelper.setFocusGroup(Groups:size(), false)
            return
        end

        GroupIndex = GroupIndex + (Up and -1 or 1)

        if GroupIndex == Groups:size() then
            NI.DATA.ObjectVectorAccess.clearSelectionAndUnfocusGroup(App, Groups)
        else
            MaschineHelper.setFocusGroup(GroupIndex + 1, false)
        end

    -- nav sounds
    else
        MaschineHelper.setFocusSound(NI.DATA.StateHelper.getFocusSoundIndex(App) + (Up and -1 or 1) + 1, true) -- 1-based
    end

end

------------------------------------------------------------------------------------------------------------------------

function ParameterPageBase:onNavLeftRightButton(Pressed, Right)

    if not Pressed then
        return
    end

    local OnScreenOverlay = App:getOnScreenOverlay()
    if OnScreenOverlay:getVisibleParameter():getValue() then
        OnScreenOverlay:onLeftRight(not Right)
        return
    elseif NHLController:getLoopButtonPressed() then
        return
    end

    -- nav slots
    local Sound = NI.DATA.StateHelper.getFocusSound(App)
    local Slots = Sound and Sound:getChain():getSlots()

    if Slots then
        NI.DATA.ChainAccess.shiftSlotFocus(App, Slots, Right and 1 or -1)
    end

end

------------------------------------------------------------------------------------------------------------------------

function ParameterPageBase:onNavEnterButton(Pressed)

    if Pressed then
        local OnScreenOverlay = App:getOnScreenOverlay()
        OnScreenOverlay:onEnter(self.Controller:isShiftPressed(), false)
    end

end

------------------------------------------------------------------------------------------------------------------------

function ParameterPageBase:onNavBackButton(Pressed)

    if Pressed then

        local PerformPageParam = App:getWorkspace():getKKPerformPageParameter()

        if PerformPageParam:getValue() ~= HW.PAGE_PLUGIN then
            NI.DATA.ParameterAccess.setSizeTParameter(App, PerformPageParam, HW.PAGE_PLUGIN)
        else
            local OnScreenOverlay = App:getOnScreenOverlay()
            OnScreenOverlay:onBack(self.Controller:isShiftPressed())
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function ParameterPageBase:onNavInstanceButton(Pressed)

    if Pressed and not App:isAnyInstanceInAutoFocusHost() then
        local OnScreenOverlay = App:getOnScreenOverlay()
        OnScreenOverlay:onInstance(NHLController:getControllerModel())
    end

end

------------------------------------------------------------------------------------------------------------------------

function ParameterPageBase:onNavPresetButton(Pressed, Up)

    if Pressed then

        -- LEDs must be updated before the preset loads
        self:updateNavigationLEDs()

        if BrowseHelper.offsetResultListFocusBy(Up and -1 or 1) then
            BrowseHelper.loadFocusItem()
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function ParameterPageBase:onPageButton(Pressed, Next)

    local Left = self.Controller.SwitchPressed[HW.BUTTON_DISPLAY_ARROW_LEFT]
    local Right = self.Controller.SwitchPressed[HW.BUTTON_DISPLAY_ARROW_RIGHT]

    -- toggle autowrite on / off
    if self.Controller:isShiftPressed() then

        if Left and Right then
            self.Controller:toggleAutoWrite()
            self.Controller.DisplayStack:insert(DISPLAY_MODE_AUTOWRITE)

        elseif not Left and not Right then
            self.Controller.DisplayStack:scheduleRemove(DISPLAY_MODE_AUTOWRITE, DISPLAY_MODE_TIMEOUT)
        end

    elseif Left ~= Right then

        self.Controller.DisplayStack:removeIfScheduled(DISPLAY_MODE_VOLUME)
        self.Controller.DisplayStack:removeIfScheduled(DISPLAY_MODE_OCTAVE)
        self.Controller.DisplayStack:removeIfScheduled(DISPLAY_MODE_AUTOWRITE)

    end

end

------------------------------------------------------------------------------------------------------------------------

function ParameterPageBase:updateNavigationLEDs(Page)

    local StateCache = App:getStateCache()

    local OnScreenOverlay = App:getOnScreenOverlay()
    local IsBrowserVisible = OnScreenOverlay and OnScreenOverlay:isBrowserVisible()
    local IsInstancesVisible = OnScreenOverlay and OnScreenOverlay:isInstancesVisible()

    local PerformPage = App:getWorkspace():getKKPerformPageParameter():getValue()
    local PerformPageVisible = PerformPage == HW.PAGE_SCALE or PerformPage == HW.PAGE_ARP or PerformPage
            == HW.PAGE_TOUCHSTRIP_MODULATION or PerformPage == HW.PAGE_TOUCHSTRIP_PITCH

    local BrowserSection = IsBrowserVisible and OnScreenOverlay:getBrowserSectionParameter():getValue()
    local PreviousSection = BrowserSection and OnScreenOverlay:findPreviousSection(BrowserSection)
    local NextSection = BrowserSection and OnScreenOverlay:findNextSection(BrowserSection, false)

    local FocusItem = BrowseHelper.getResultListFocusItem()
    local NumItems = BrowseHelper.getResultListSize()

    -- Checks for NPOS prevent led flickering that is caused by FocusItem being NPOS during a DB3 search.
    local ResultsHasPrevious = FocusItem > 0 and NumItems > 0 and FocusItem ~= NPOS
    local ResultsHasNext = NumItems > 0 and (FocusItem < NumItems - 1 or FocusItem == NPOS)

    LEDHelper.setLEDState(HW.LED_NAVIGATE_BROWSE, IsBrowserVisible and LEDHelper.LS_BRIGHT or LEDHelper.LS_DIM)
    if App:isAnyInstanceInAutoFocusHost() then
        LEDHelper.setLEDState(HW.LED_NAVIGATE_INSTANCE, LEDHelper.LS_OFF)
    else
        LEDHelper.setLEDState(HW.LED_NAVIGATE_INSTANCE, IsInstancesVisible and LEDHelper.LS_BRIGHT or LEDHelper.LS_DIM)
    end

    LEDHelper.updateButtonLED(self.Controller, HW.LED_NAVIGATE_ENTER, HW.BUTTON_NAVIGATE_ENTER, IsBrowserVisible or IsInstancesVisible)
    LEDHelper.updateButtonLED(self.Controller, HW.LED_NAVIGATE_BACK, HW.BUTTON_NAVIGATE_BACK,
        (BrowserSection and BrowserSection ~= NI.DATA.DB_FILETYPES and BrowserSection ~= NI.DATA.DB_LIBRARIES) or PerformPageVisible)

    LEDHelper.updateButtonLED(self.Controller, HW.LED_NAVIGATE_PRESET_UP, HW.BUTTON_NAVIGATE_PRESET_UP, ResultsHasPrevious)
    LEDHelper.updateButtonLED(self.Controller, HW.LED_NAVIGATE_PRESET_DOWN, HW.BUTTON_NAVIGATE_PRESET_DOWN, ResultsHasNext)

    -- NAVIGATE OSO
    if IsBrowserVisible or IsInstancesVisible then

        -- ARROW UP
        LEDHelper.updateButtonLED(self.Controller, HW.LED_NAVIGATE_ARROW_UP, HW.BUTTON_NAVIGATE_ARROW_UP,
            BrowserSection and BrowserSection ~= PreviousSection)

        -- ARROW DOWN
        LEDHelper.updateButtonLED(self.Controller, HW.LED_NAVIGATE_ARROW_DOWN, HW.BUTTON_NAVIGATE_ARROW_DOWN,
            BrowserSection and BrowserSection ~= NextSection)

        -- ARROW LEFT
        LEDHelper.updateButtonLED(self.Controller, HW.LED_NAVIGATE_ARROW_LEFT, HW.BUTTON_NAVIGATE_ARROW_LEFT,
            BrowserSection and (BrowserSection >= NI.DATA.DB_FAVORITES))

        -- ARROW RIGHT
        LEDHelper.updateButtonLED(self.Controller, HW.LED_NAVIGATE_ARROW_RIGHT, HW.BUTTON_NAVIGATE_ARROW_RIGHT,
            BrowserSection and BrowserSection < NI.DATA.DB_FAVORITES)

    -- NAVIGATE MASCHINE
    else

        local GroupIndex = NI.DATA.StateHelper.getFocusGroupIndex(App)
        local SoundIndex = GroupIndex == NPOS and NPOS or NI.DATA.StateHelper.getFocusSoundIndex(App)
        local NumGroups = MaschineHelper.getFocusSongGroupCount()

        if self.Controller:isShiftPressed() then

            LEDHelper.updateButtonLED(self.Controller, HW.LED_NAVIGATE_ARROW_UP, HW.BUTTON_NAVIGATE_ARROW_UP, GroupIndex > 0 and NumGroups > 0 or GroupIndex == NPOS)
            LEDHelper.updateButtonLED(self.Controller, HW.LED_NAVIGATE_ARROW_DOWN, HW.BUTTON_NAVIGATE_ARROW_DOWN,
                GroupIndex >= 0 and GroupIndex <= NumGroups - 1)
        else
            LEDHelper.updateButtonLED(self.Controller, HW.LED_NAVIGATE_ARROW_UP, HW.BUTTON_NAVIGATE_ARROW_UP, SoundIndex > 0)
            LEDHelper.updateButtonLED(self.Controller, HW.LED_NAVIGATE_ARROW_DOWN, HW.BUTTON_NAVIGATE_ARROW_DOWN, SoundIndex >= 0 and SoundIndex < 15)
        end

        local Sound = NI.DATA.StateHelper.getFocusSound(App)
        local Slots = Sound and Sound:getChain():getSlots()
        local Slot = Slots and Slots:getFocusObject()
        local SlotIndex = Slot and Slots:calcIndex(Slot) or NPOS

        local ShiftPressed = self.Controller:isShiftPressed()
        local LoopButtonPressed = NHLController:getLoopButtonPressed()

        LEDHelper.updateButtonLED(self.Controller, HW.LED_NAVIGATE_ARROW_LEFT, HW.BUTTON_NAVIGATE_ARROW_LEFT,
            Slots and SlotIndex > 0 and Slots:size() > 0 or (LoopButtonPressed and not ShiftPressed))
        LEDHelper.updateButtonLED(self.Controller, HW.LED_NAVIGATE_ARROW_RIGHT, HW.BUTTON_NAVIGATE_ARROW_RIGHT,
            Slots and SlotIndex >= 0 and SlotIndex < Slots:size() or (LoopButtonPressed and not ShiftPressed))
    end

end

------------------------------------------------------------------------------------------------------------------------

function ParameterPageBase:onEncoderTouched(Pressed, Index)

    self.EncoderTouchedDelay[Index] = Pressed and 0 or ENCODER_TOUCH_TIMEOUT

end

------------------------------------------------------------------------------------------------------------------------

-- includes release time
function ParameterPageBase:isEncoderTouched(Encoder)

    local Releasing = self.EncoderTouchedDelay[Encoder] and self.EncoderTouchedDelay[Encoder] > 0
    return self.Controller:isEncoderTouched(Encoder) or Releasing or false

end

------------------------------------------------------------------------------------------------------------------------
-- helper
------------------------------------------------------------------------------------------------------------------------

function ParameterPageBase:isSectionNameInvalid(SectionName, ParameterIndex)

    if SectionName == "" then
        return false
    end

    -- always display first param
    if ParameterIndex == 0 then

        return true

    else
        -- display blank if prev. param has the same section name
        local PrevParameter = HELPERS.getCachedParameter(App, ParameterIndex - 1)
        if PrevParameter then
            local PrevSectionName = PrevParameter:getSectionName()
            return (PrevSectionName ~= SectionName)
        end
    end

    return true

end

------------------------------------------------------------------------------------------------------------------------

function ParameterPageBase:isAutoWriting()

    return false

end

------------------------------------------------------------------------------------------------------------------------

function ParameterPageBase:getCurrentPageSpeechAssistanceMessage()
    return NI.ACCESSIBILITY.getCurrentPageSpeechAssistanceMessage(App)
end
