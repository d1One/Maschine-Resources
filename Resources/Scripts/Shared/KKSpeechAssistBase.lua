------------------------------------------------------------------------------------------------------------------------
-- KKSpeechAssist class which triggers the speech synthesizer
------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
KKSpeechAssistBase = class( 'KKSpeechAssistBase' )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

BUTTON_DOUBLE_CLICK_TIMEOUT = 20

function KKSpeechAssistBase:__init(Controller)

    self.ShiftInfoKey = "_SHIFT"
    self.Controller = Controller

    self.EncoderDelayCounter = 0
    self.EncoderDelayPeriodInTimerTicks = 20
    self.LastSpokenSectionNameMessage = ""
    self.LastTouchedEncoder = NI.HW.BUTTON__NONE
    self.ShiftDoubleClickCounter = 0

    self.ButtonInfos = {}

    local ButtonInfos = {}


    ButtonInfos[NI.HW.BUTTON_PERFORM_SHIFT] = {
        SpeechName = "Shift",
        SpeakValueInNormalMode = false,
        SpeakValueInTrainingMode = false,
        PerformInTrainingMode = true,
        Handler = self:MakeButtonPressHandler(self.onShiftButton)
    }
    ButtonInfos[NI.HW.BUTTON_TRANSPORT_REWIND]          = { SpeechName = "Rewind" }
    ButtonInfos[NI.HW.BUTTON_TRANSPORT_FAST_FORWARD]    = { SpeechName = "Fast forward" }
    ButtonInfos[NI.HW.BUTTON_TRANSPORT_RECORD]          = { SpeechName = "Record" }
    ButtonInfos[NI.HW.BUTTON_TRANSPORT_PLAY]            = { SpeechName = "Play", SpeakNameInNormalMode=false }
    ButtonInfos[NI.HW.BUTTON_TRANSPORT_STOP]            = { SpeechName = "Stop", SpeakNameInNormalMode=false }

    ButtonInfos[NI.HW.BUTTON_NAVIGATE_BROWSE]           = { Handler = self:MakeButtonPressHandler(self.onBrowseButton) }
    ButtonInfos[NI.HW.BUTTON_NAVIGATE_PRESET_UP]        = { Handler = self:MakeButtonPressHandler(self.onNavPresetButton, true) }
    ButtonInfos[NI.HW.BUTTON_NAVIGATE_PRESET_DOWN]      = { Handler = self:MakeButtonPressHandler(self.onNavPresetButton, false) }

    ButtonInfos[NI.HW.BUTTON_TRANSPOSE_OCTAVE_PLUS]     = {
                                                            Handler = self:MakeButtonPressHandler(self.onOctaveButton, true)
                                                        }
    ButtonInfos[NI.HW.BUTTON_TRANSPOSE_OCTAVE_MINUS]    = {
                                                            Handler = self:MakeButtonPressHandler(self.onOctaveButton, false)
                                                        }
    ButtonInfos[NI.HW.BUTTON_PERFORM_ARPEGGIATOR]       = {
                                                            SpeechName = "Arp",
                                                            SpeakValueInTrainingMode = false,
                                                            SpeechValue  = function()
                                                                local ArpActiveParameter = NI.HW.getArpeggiatorActiveParameter(App)
                                                                IsActive = ArpActiveParameter and ArpActiveParameter:getValue() or false
                                                                return IsActive and "On" or "Off"
                                                            end,
                                                            [self.ShiftInfoKey] = {
                                                                SpeechName = "Arp Edit",
                                                                SpeakValueInTrainingMode = false,
                                                                SpeakValueInNormalMode = false,
                                                            }
                                                        }
    ButtonInfos[NI.HW.BUTTON_PERFORM_SCALE]             = {
                                                            SpeechName = "Scale",
                                                            SpeakValueInTrainingMode = false,
                                                            SpeechValue  = function()
                                                                local ScaleActiveParameter = NI.HW.getScaleEngineActiveParameter(App)
                                                                IsActive = ScaleActiveParameter and ScaleActiveParameter:getValue() or false
                                                                return IsActive and "On" or "Off"
                                                            end,
                                                            [self.ShiftInfoKey] = {
                                                                SpeechName = "Scale Edit",
                                                                SpeakValueInTrainingMode = false,
                                                                SpeakValueInNormalMode = false,
                                                            }
                                                        }

    for Index = 0,7 do
        ButtonInfos[NI.HW.BUTTON_CAP_1 + Index] = {
            Handler = function(Touched) self:onEncoderTouched(Index + 1, Touched) end,
        }
    end

    self:DefineButtonInfos(ButtonInfos)

end

------------------------------------------------------------------------------------------------------------------------

function KKSpeechAssistBase:MakeButtonPressHandler(func, ...)
    local wrappedFunc = func
    local arg = {...}
    return (
        function(Pressed)
            if Pressed then
                if _VERSION == "Lua 5.1" then
                    return wrappedFunc(self, unpack(arg))
                else
                    return wrappedFunc(self, table.unpack(arg))
                end
            end
        end
    )
end

------------------------------------------------------------------------------------------------------------------------

function KKSpeechAssistBase:DefineButtonInfos(buttonInfos)
    -- Store info in ButtonInfos. If info already exists, merge over the top of it.
    for ButtonID, info in pairs(buttonInfos) do

        local StoredInfo = self.ButtonInfos[ButtonID] or {}

        for key, value in pairs(info) do
            if key == self.ShiftInfoKey then
                if StoredInfo[key] == nil then StoredInfo[key] = {} end
                for shiftKey, shiftValue in pairs(value) do
                    StoredInfo[key][shiftKey] = shiftValue
                end
            else
                StoredInfo[key] = value
            end
        end

        self.ButtonInfos[ButtonID] = StoredInfo
    end
end

------------------------------------------------------------------------------------------------------------------------

function KKSpeechAssistBase:GetButtonInfo(button)
    -- Start with a default Info, and merge it with settings specified in ButtonInfos

    local Info = self.ButtonInfos[button] or {}

    local Result = {
        SpeechName = "",
        SpeechValue = "",
        SpeakNameInNormalMode = true,
        SpeakValueInNormalMode = true,
        SpeakNameInTrainingMode = true,
        SpeakValueInTrainingMode = false,
        PerformInTrainingMode = false,
        Handler = nil,
    }

    function Result:GetName()
        if type(self.SpeechName) == "function" then
            return self.SpeechName()
        else
            return self.SpeechName
        end
    end
    function Result:GetValue()
        if type(self.SpeechValue) == "function" then
            return self.SpeechValue()
        else
            return self.SpeechValue
        end
    end

    for key, value in pairs(Info) do
        if key ~= self.ShiftInfoKey then
            Result[key] = value
        end
    end

    if Info[self.ShiftInfoKey] ~= nil and self.Controller:getShiftPressed() then
        local Shift = Info[self.ShiftInfoKey]
        for key, value in pairs(Shift) do
            Result[key] = value
        end
    end

    return Result
end

------------------------------------------------------------------------------------------------------------------------

function KKSpeechAssistBase:onTimer()

    if self.EncoderDelayCounter > 0 then

        self.EncoderDelayCounter = self.EncoderDelayCounter - 1

    end

    if self.ShiftDoubleClickCounter > 0 then

        self.ShiftDoubleClickCounter = self.ShiftDoubleClickCounter - 1

    end

end

------------------------------------------------------------------------------------------------------------------------

function KKSpeechAssistBase:onStateFlagsChanged()

    if self.Controller:getActivePageID() == NI.HW.PAGE_BROWSE then
        local Scanning = App:getWorkspace():getDatabaseScanInProgressParameter()
        if Scanning:isChanged() then
            self:scheduleMessage("Browser Scan " .. (Scanning:getValue() and "started" or "stopped"), "")
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function KKSpeechAssistBase:onDB3ModelChanged()

    local DatabaseFrontend = App:getDatabaseFrontend()
    if self.GetDeferredBrowserParameterValueFunc and DatabaseFrontend and DatabaseFrontend:getBrowserModel():isSearchDoneSetStateFlag() then

        local Msg = self.GetDeferredBrowserParameterValueFunc()
        self:scheduleMessage(Msg, "")

    end

end

------------------------------------------------------------------------------------------------------------------------

function KKSpeechAssistBase:onSwitchEvent(ButtonID, Pressed)

    local ButtonInfo = self:GetButtonInfo(ButtonID)
    local Handler = ButtonInfo.Handler

    if Handler then
        Handler(Pressed)
    else
        self:speakButtonName(ButtonID, Pressed)
    end

end

------------------------------------------------------------------------------------------------------------------------


function KKSpeechAssistBase:speakButtonName(ButtonID, Pressed)

    local ButtonInfo = self:GetButtonInfo(ButtonID)
    if Pressed == true or Pressed == nil then
        local SpeakName = ButtonInfo.SpeakNameInNormalMode
        local SpeakValue = ButtonInfo.SpeakValueInNormalMode
        if (self:isTrainingMode()) then
            SpeakName = ButtonInfo.SpeakNameInTrainingMode
            SpeakValue = ButtonInfo.SpeakValueInTrainingMode
        end

        local Msg = ""
        if SpeakName then Msg = ButtonInfo:GetName() end
        if SpeakValue then Msg = Msg .. " " .. ButtonInfo:GetValue() end

        if Msg then
            self:scheduleMessage(Msg, "")
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function KKSpeechAssistBase:onShiftButton()

    if self.ShiftDoubleClickCounter == 0 then

        self.ShiftDoubleClickCounter = BUTTON_DOUBLE_CLICK_TIMEOUT
        self:onShiftButtonSingleClick()

    else

        self.ShiftDoubleClickCounter = 0
        self:toggleTrainingModeEnabled()

    end

end

------------------------------------------------------------------------------------------------------------------------

function KKSpeechAssistBase:toggleEnabled()

    local IsAccessibilityEnabled = App:getSpeechSynthesizer():getEnabled()

    -- We're just about to disable accessibility. Schedule message before it's disabled.
    if IsAccessibilityEnabled then
        self:scheduleMessage("Accessibility Off", "")
    end

    NI.DATA.WORKSPACE.setAccessibilityEnabled(App, not IsAccessibilityEnabled)

    -- We've just enabled accessibility. Schedule message after it's enabled.
    if not IsAccessibilityEnabled then
        self:scheduleMessage("Accessibility On", "")
    end

end

------------------------------------------------------------------------------------------------------------------------

function KKSpeechAssistBase:toggleTrainingModeEnabled()

    if App:getSpeechSynthesizer():getEnabled() then

        local IsTrainingMode = NI.DATA.WORKSPACE.getAccessibilityTrainingMode(App)
        NI.DATA.WORKSPACE.setAccessibilityTrainingMode(App, not IsTrainingMode)

        local state = not IsTrainingMode and "On" or "Off"
        self:scheduleMessage("Training Mode " .. state, "")

    end

end

------------------------------------------------------------------------------------------------------------------------

function KKSpeechAssistBase:scheduleMessage(ShortMsg, LongMsg)

    self.GetDeferredBrowserParameterValueFunc = nil

    if ShortMsg and ShortMsg ~= '' and ShortMsg ~= ' ' then
        print("Saying \"" .. ShortMsg .. "\"")
        App:getSpeechSynthesizer():scheduleMessage(ShortMsg, LongMsg)
    else
        print('Ignored empty message.')
    end

end

------------------------------------------------------------------------------------------------------------------------

function KKSpeechAssistBase:onBrowseButton()

    if self:isTrainingMode() then

        self:scheduleMessage("Browser", "")

    else

        local Msg = self:getHWDisplayPageMsg()
        if App:getWorkspace():getDatabaseScanInProgressParameter():getValue() then
            Msg = Msg .. ". Scan in progress"
        end
        self:scheduleMessage(Msg, "")

    end

end

------------------------------------------------------------------------------------------------------------------------

function KKSpeechAssistBase:onNavPresetButton(Up)

    if self:isTrainingMode() then

        local Direction = Up and "Up" or "Down"
        local Msg = "Preset " .. Direction
        self:scheduleMessage(Msg, "")

    end

end

------------------------------------------------------------------------------------------------------------------------

function KKSpeechAssistBase:getCurrentOctaveMessage()

    local Octave = NI.HW.getCurrentOctave(App)
    local Msg = "Octave "

    if Octave > 0 then
        Msg = Msg .. "plus "
    end

    return Msg .. Octave

end

------------------------------------------------------------------------------------------------------------------------

function KKSpeechAssistBase:isTrainingMode()

    local IsAccessibilityEnabled = App:getSpeechSynthesizer():getEnabled()
    return IsAccessibilityEnabled and NI.DATA.WORKSPACE.getAccessibilityTrainingMode(App)

end

------------------------------------------------------------------------------------------------------------------------

function KKSpeechAssistBase:getCommonHWButtonID(EncoderID)

    return EncoderID - 1 + NI.HW.BUTTON_CAP_1

end

------------------------------------------------------------------------------------------------------------------------

function KKSpeechAssistBase:canScheduleEncoderTouchedMessage(ButtonID)

    return ButtonID ~= self.LastTouchedEncoder or self.EncoderDelayCounter == 0

end

------------------------------------------------------------------------------------------------------------------------
-- Overriden by child classes
------------------------------------------------------------------------------------------------------------------------

function KKSpeechAssistBase:getHWDisplayPageMsg()
    return ""
end

------------------------------------------------------------------------------------------------------------------------

function KKSpeechAssistBase:onShiftButtonSingleClick()
    self:speakButtonName(NI.HW.BUTTON_PERFORM_SHIFT)
end

------------------------------------------------------------------------------------------------------------------------

function KKSpeechAssistBase:onEncoderTouched(EncoderID, Touched)

end

------------------------------------------------------------------------------------------------------------------------

function KKSpeechAssistBase:onOctaveButton(Plus)

end

------------------------------------------------------------------------------------------------------------------------

function KKSpeechAssistBase:onWheelEvent()

    local PageOrOverlay = self.Controller:getActivePageOrOverlay()
    local ValidPages = self.Controller:getActivePageID() ~= NI.HW.PAGE_BROWSE and self.Controller:getActivePageID() ~= NI.HW.PAGE_MIXER

    if PageOrOverlay.getWheelParameterValueString then

        local WheelMsg = PageOrOverlay:getWheelParameterValueString()
        self:scheduleMessage(WheelMsg, "")
    end
    if self.Controller:getShiftPressed() and not self:isTrainingMode() 
    and ValidPages then
        local Msg = self:getVolumeMessage()
        self:scheduleMessage(Msg, "Volume, " .. Msg)
    end

end

------------------------------------------------------------------------------------------------------------------------

function KKSpeechAssistBase:onBusyDialogOpened()

    if App:getBusyState() == NI.HW.BUSY_SEE_SW or App:getBusyState() == NI.HW.BUSY_YES_NO then
        self:scheduleMessage("A dialog box has opened in the software", "")
    end

end

------------------------------------------------------------------------------------------------------------------------

function KKSpeechAssistBase:onOctaveButton(Plus)

    local Msg = self:getCurrentOctaveMessage()

    local Semitone = NHLController:getSemitoneOffset()
    if self.Controller:getShiftPressed() or Semitone ~= 0 then
        Msg = Msg .. ", Semitone Offset "

        if Semitone > 0 then
            Msg = Msg .. "Plus "
        end
        Msg = Msg .. Semitone
    end

    self:scheduleMessage(Msg, "")

end

------------------------------------------------------------------------------------------------------------------------

function KKSpeechAssistBase:onTempoButton()

    self:speakButtonName(NI.HW.BUTTON_TRANSPORT_TEMPO)

end

------------------------------------------------------------------------------------------------------------------------

function KKSpeechAssistBase:onPlayButton()

    if self:isTrainingMode() then

        if self.Controller:getShiftPressed() then
            self:scheduleMessage("Restart", "")
        else
            self:speakButtonName(NI.HW.BUTTON_TRANSPORT_PLAY)
        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function KKSpeechAssistBase:onRecordButton()

    if self:isTrainingMode() then

        if self.Controller:getShiftPressed() then
            self:scheduleMessage("Count In", "")
        else
            self:speakButtonName(NI.HW.BUTTON_TRANSPORT_RECORD)
        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function KKSpeechAssistBase:onPluginButton()

    if self:isTrainingMode() then

        self:scheduleMessage("Plug-In", "")

    else

        self:scheduleMessage(self:getHWDisplayPageMsg(), "")

    end

end

------------------------------------------------------------------------------------------------------------------------

function KKSpeechAssistBase:onEncoderEvent(EncoderID, ValueChanged)

    if ValueChanged then

        if (not self.Controller.ActiveOverlay or not self.Controller.ActiveOverlay:isVisible())
            and self.Controller:getActivePageID() == NI.HW.PAGE_BROWSE and EncoderID == 8
            and not NI.DATA.WORKSPACE.getAccessibilitySpeakPreset(App) then
            -- special case for preset when browsing - the speech can be turned on and off via the workspace parameter
            App:getSpeechSynthesizer():cancelScheduledMessage()
        else
            local PageOrOverlay = self.Controller:getActivePageOrOverlay()
            local Info = PageOrOverlay:getScreenEncoderInfo(EncoderID)

            if Info then
                local Name = Info.SpeechName
                local Msg = Info.SpeechValue

                self:scheduleMessage(Msg, Name .. ", " .. Msg)
            end
        end

        -- Else it was handled in C++
    end

end

------------------------------------------------------------------------------------------------------------------------

function KKSpeechAssistBase:onEncoderTouched(EncoderID, Touched)

    local CommonHWButtonID = self:getCommonHWButtonID(EncoderID)

    if Touched then
        if self:canScheduleEncoderTouchedMessage(CommonHWButtonID) then

            local PageOrOverlay = self.Controller:getActivePageOrOverlay()
            local Info = PageOrOverlay:getScreenEncoderInfo(EncoderID)

            if Info and string.len(Info.SpeechName) >=1 and string.len(Info.SpeechValue) >=1 then
                local SectionName = Info.SpeechSectionName
                local Name = Info.SpeechName
                local Value = Info.SpeechValue

                local ShortMsg = ""

                if self:isTrainingMode() then
                    ShortMsg = Name
                else
                    ShortMsg = Name .. ", " .. Value
                end

                local LongMsg = SectionName .. ", " .. ShortMsg

                if self.LastSpokenSectionNameMessage ~= SectionName then

                    self.LastSpokenSectionNameMessage = SectionName
                    ShortMsg = SectionName .. ", " .. ShortMsg

                end

                self:scheduleMessage(ShortMsg, LongMsg)
            end

        end
    else
        self.LastTouchedEncoder = CommonHWButtonID
        self.EncoderDelayCounter = self.EncoderDelayPeriodInTimerTicks
    end

end

------------------------------------------------------------------------------------------------------------------------

function KKSpeechAssistBase:onWheelTouched(Touched)

    local CommonHWButtonID = NI.HW.BUTTON_WHEEL_TOUCH

    if Touched and NI.DATA.WORKSPACE.getAccessibilitySpeakPreset(App) then
        if self:canScheduleEncoderTouchedMessage(CommonHWButtonID) then
            if self.Controller:getActivePageID() == NI.HW.PAGE_BROWSE then
                local Name = self.Controller.PageList[NI.HW.PAGE_BROWSE]:getWheelParameterName()
                local Value = self.Controller.PageList[NI.HW.PAGE_BROWSE]:getWheelParameterValueString()
                local Msg = Name .. ", " .. Value
                self:scheduleMessage(Msg, "")

            elseif self.Controller:getShiftPressed() then

                local Msg = self:getVolumeMessage()
                self:scheduleMessage("Master Volume, " .. Msg, "")

            end
        end
    else

        self.LastTouchedEncoder = CommonHWButtonID
        self.EncoderDelayCounter = self.EncoderDelayPeriodInTimerTicks

    end

end

------------------------------------------------------------------------------------------------------------------------

function KKSpeechAssistBase:shouldSpeakValue(Info)

    if self:isTrainingMode() then
        return Info.SpeakValueInTrainingMode
    else
        return Info.SpeakValueInNormalMode
    end

end

------------------------------------------------------------------------------------------------------------------------

function KKSpeechAssistBase:shouldSpeakName(Info)

    if self:isTrainingMode() then
        return Info.SpeakNameInTrainingMode
    else
        return Info.SpeakNameInNormalMode
    end

end

------------------------------------------------------------------------------------------------------------------------

function KKSpeechAssistBase:onScreenButton(ButtonIdx, ActivePageOrOverlay, isButtonDisabled)

    local Info = ActivePageOrOverlay:getScreenButtonInfo(ButtonIdx)

    if isButtonDisabled and not self:isTrainingMode() then
        return
    end

    if Info then
        local NameMsg = self:shouldSpeakName(Info) and Info.SpeechName or nil
        local ValueMsg = self:shouldSpeakValue(Info) and Info.SpeechValue or nil

        if ((NameMsg == nil or NameMsg == "") and (ValueMsg == nil or ValueMsg == "")) then return end

        ValueMsg = isButtonDisabled and ", BUTTON INACTIVE" or ValueMsg

        local Msg = ""
        if NameMsg and NameMsg ~= "" then
            Msg = Msg .. NameMsg
        end
        if ValueMsg and ValueMsg ~= "" then
            if Msg:len() > 0 then Msg = Msg .. " " end
            Msg = Msg .. ValueMsg
        end

        if Msg ~= "" then
            self:scheduleMessage(Msg, "")
        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function KKSpeechAssistBase:onPageButton(Right)

    if self.Controller:getActivePageID() == NI.HW.PAGE_BROWSE then

        local ProductIndex = BrowseHelper.getFocusProductIndex()

        if ProductIndex ~= BrowseHelper.getProductCount() then
            local Msg = ""

            if ProductIndex ~= NPOS then
                Msg = BrowseHelper.getParamContent(PARAM_BC1, BrowseHelper.getParamIndex(PARAM_BC1))
            else
                Msg = "All Products"
            end

            self:scheduleMessage(Msg, "")
        end

    else

        local Msg = NI.ACCESSIBILITY.getCurrentPageSpeechAssistanceMessage(App)
        if self:isTrainingMode() and Msg == "" then
            Msg = (Right and "Page Right," or "Page Left,")
        end
        self:scheduleMessage(Msg, "")

    end

end

------------------------------------------------------------------------------------------------------------------------

function KKSpeechAssistBase:getHWDisplayPageMsg()

    local PageID = self.Controller:getActivePageID()

    if PageID == NI.HW.PAGE_BROWSE then

        return "Browser"

    elseif PageID == NI.HW.PAGE_SCALE then

        return "Scale Edit"

    elseif PageID == NI.HW.PAGE_ARP then

        return "Arp Edit"

    elseif PageID == NI.HW.PAGE_CONTROL then

        local Msg = "Plug-in"

        local PluginLoaded = true
        if NI.DATA.ChainAlgorithms and not NI.DATA.ChainAlgorithms.isInstrumentLoaded(App:getChain()) then
            PluginLoaded = false
        elseif NI.DATA.StateHelper then
            local Slots = NI.DATA.StateHelper.getFocusChainSlots(App)
            if Slots:size() == 0 then
                PluginLoaded = false
            end
        end
        if not PluginLoaded then
            Msg = Msg .. ". No Plug-in Loaded"
        end
        return Msg

    end

    return ""

end

------------------------------------------------------------------------------------------------------------------------

function KKSpeechAssistBase.getVolumeAsString(Volume)
    if Volume ~= nil then
        return Volume <= 0 and "Minus Infinity" or NI.UTILS.LevelScale.level2ValueString(Volume)
    else 
        return ""
    end
end