------------------------------------------------------------------------------------------------------------------------
-- KK2SpeechAssist class which triggers the speech synthesizer
------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/KKSpeechAssistBase"

local class = require 'Scripts/Shared/Helpers/classy'
KK2SpeechAssist = class( 'KK2SpeechAssist', KKSpeechAssistBase )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function KK2SpeechAssist:__init(Controller)

    KKSpeechAssistBase.__init(self, Controller)

    self.SchedulePresetLoadedMsg = false

    local ButtonInfos = {}

    ButtonInfos[NI.HW.BUTTON_TRANSPORT_METRONOME]   = {
                                                        SpeechName = "Metronome",
                                                        SpeechValue = function() return App:getMetronome():getEnabledParameter():getValue() and "on" or "off" end,
                                                      }
    ButtonInfos[NI.HW.BUTTON_TRANSPORT_LOOP]        = {
                                                        SpeechName = "Loop",
                                                        SpeechValue = function() return NI.DATA.TransportAccess.isLoopActive(App) and "on" or "off" end,
                                                        SpeakValueInNormalMode = true
                                                    }
    ButtonInfos[NI.HW.BUTTON_FIXED_VEL]             = { SpeechName = "Fixed Velocity" }
    ButtonInfos[NI.HW.BUTTON_MIX]                   = { SpeechName = "Mixer" }
    ButtonInfos[NI.HW.BUTTON_INSTANCE]              = { SpeechName = "Instance" }
    ButtonInfos[NI.HW.BUTTON_MIDI]                  = { SpeechName = "MIDI" }
    ButtonInfos[NI.HW.BUTTON_SETUP]                 = { SpeechName = "Set Up" }
    ButtonInfos[NI.HW.BUTTON_SONG]                  = { SpeechName = "Scene" }
    ButtonInfos[NI.HW.BUTTON_PATTERN]               = { SpeechName = "Pattern" }
    ButtonInfos[NI.HW.BUTTON_TRACK]                 = {
                                                        SpeechName = "Track Overlay",
                                                        PerformInTrainingMode = true
                                                      }
    ButtonInfos[NI.HW.BUTTON_CLEAR]                 = { SpeechName = "Clear" }
    ButtonInfos[NI.HW.BUTTON_MUTE]                  = {
                                                        SpeechName = "Mute",
                                                        Handler = self:MakeButtonPressHandler(self.onMuteSoloButton, true),
                                                        PerformInTrainingMode = true
                                                      }
    ButtonInfos[NI.HW.BUTTON_SOLO]                  = {
                                                        SpeechName = "Solo",
                                                        Handler = self:MakeButtonPressHandler(self.onMuteSoloButton, false),
                                                        PerformInTrainingMode = true
                                                      }
    ButtonInfos[NI.HW.BUTTON_AUTOWRITE]             = {
                                                        SpeechName = "Automation",
                                                        SpeechValue = function() return NI.DATA.WORKSPACE.isAutoWriteEnabledFromKompleteKontrol(App) and "on" or "off" end
                                                      }
    ButtonInfos[NI.HW.BUTTON_QUANTIZE]              = {
                                                        SpeechName = "Quantize Overlay",
                                                        PerformInTrainingMode = true
                                                      }
    ButtonInfos[NI.HW.BUTTON_LEFT]                  = {
                                                        SpeechName = "Page Left",
                                                        Handler = self:MakeButtonPressHandler(self.onPageButton, false),
                                                        PerformInTrainingMode = true
                                                      }
    ButtonInfos[NI.HW.BUTTON_RIGHT]                 = {
                                                        SpeechName = "Page Right",
                                                        Handler = self:MakeButtonPressHandler(self.onPageButton, true),
                                                        PerformInTrainingMode = true
                                                      }

    ButtonInfos[NI.HW.BUTTON_CONTROL]               = { Handler = self:MakeButtonPressHandler(self.onPluginButton) }
    ButtonInfos[NI.HW.BUTTON_UNDO]                  = {
                                                        SpeechName = "Undo",
                                                        [self.ShiftInfoKey] = {
                                                            SpeechName = "Redo"
                                                        }
                                                      }
    ButtonInfos[NI.HW.BUTTON_TRANSPORT_PLAY]        = { Handler = self:MakeButtonPressHandler(self.onPlayButton) }
    ButtonInfos[NI.HW.BUTTON_TRANSPORT_RECORD]      = {
                                                        SpeechName = "Record",
                                                        SpeechValue = function() return MaschineHelper.isRecording() and "Armed" or "Off" end,
                                                        [self.ShiftInfoKey] = {
                                                            SpeechName = "Count In"
                                                        }
                                                      }
    ButtonInfos[NI.HW.BUTTON_TRANSPORT_TEMPO]       = {
                                                        SpeechName = "Tempo Overlay",
                                                        PerformInTrainingMode = true
                                                      }
    ButtonInfos[NI.HW.BUTTON_KEYMODE]               = {
                                                        SpeakNameInNormalMode = false,
                                                        SpeechName = "Key Mode",
                                                        SpeechValue = function()
                                                            local Group = NI.DATA.StateHelper.getFocusGroup(App)
                                                            if Group then
                                                                return "Key Mode" .. (Group:getMidiInputKitMode():getValue() == NI.DATA.KitMode.DRUMKIT
                                                                    and "On" or "Off")
                                                            end
                                                        end
                                                    }
    ButtonInfos[NI.HW.BUTTON_WHEEL_TOUCH]           = {
                                                        Handler = function(Touched) self:onWheelTouched(Touched) end,
                                                        PerformInTrainingMode = true
                                                    }
    ButtonInfos[NI.HW.BUTTON_WHEEL_UP]              = { Handler = self:MakeButtonPressHandler(self.onWheelDirection, NI.HW.BUTTON_WHEEL_UP) }
    ButtonInfos[NI.HW.BUTTON_WHEEL_DOWN]            = { Handler = self:MakeButtonPressHandler(self.onWheelDirection, NI.HW.BUTTON_WHEEL_DOWN) }
    ButtonInfos[NI.HW.BUTTON_WHEEL_LEFT]            = { Handler = self:MakeButtonPressHandler(self.onWheelDirection, NI.HW.BUTTON_WHEEL_LEFT) }
    ButtonInfos[NI.HW.BUTTON_WHEEL_RIGHT]           = { Handler = self:MakeButtonPressHandler(self.onWheelDirection, NI.HW.BUTTON_WHEEL_RIGHT) }
    ButtonInfos[NI.HW.BUTTON_WHEEL]                 = { Handler = self:MakeButtonPressHandler(self.onWheelPush) }

    for Index = 0,7 do
        ButtonInfos[NI.HW.BUTTON_SCREEN_1 + Index] = { PerformInTrainingMode = true }
    end

    self:DefineButtonInfos(ButtonInfos)
end

------------------------------------------------------------------------------------------------------------------------

function KK2SpeechAssist:onMuteSoloButton(Mute)

    local Msg = (Mute and "Mute" or "Solo")
    if self.Controller:getActivePageID() == NI.HW.PAGE_MIXER then
        Msg = Msg .. " Overlay"
    end
    self:scheduleMessage(Msg, "")

end

--------------------------------------------------------------------------------------------------------------------

function KK2SpeechAssist:onWheelDirection(Direction)

    local PageOrOverlay = self.Controller:getActivePageOrOverlay()
    if PageOrOverlay.getWheelDirectionInfo then
        local Msg = ""
        local WheelInfo = PageOrOverlay:getWheelDirectionInfo(Direction)
        if self:isTrainingMode() then
            Msg = WheelInfo.TrainingMode
        else
            Msg = WheelInfo.NormalMode
        end
        self:scheduleMessage(Msg, "")
    end

end

--------------------------------------------------------------------------------------------------------------------

function KK2SpeechAssist:toggleTrainingModeEnabled()

    KKSpeechAssistBase:toggleTrainingModeEnabled()

end

--------------------------------------------------------------------------------------------------------------------

function KK2SpeechAssist:onWheelPush()

    local PageOrOverlay = self.Controller:getActivePageOrOverlay()
    if PageOrOverlay.getWheelPushInfoString then
        self:scheduleMessage(PageOrOverlay:getWheelPushInfoString(), "")
    end

end

--------------------------------------------------------------------------------------------------------------------

function KK2SpeechAssist:onWheelTouched(Touched)

    local CommonHWButtonID = NI.HW.BUTTON_WHEEL_TOUCH

    if Touched and NI.DATA.WORKSPACE.getAccessibilitySpeakPreset(App) then
        if self:canScheduleEncoderTouchedMessage(CommonHWButtonID) then
            if self.Controller:getActivePageID() == NI.HW.PAGE_CONTROL then
                local Msg = self.Controller.PageList[NI.HW.PAGE_CONTROL]:getWheelParameterValueString()
               self:scheduleMessage(Msg, "")
               KKSpeechAssistBase.onWheelTouched(self, Touched)
               KK2SpeechAssist.getVolumeMessage()
            end
        end
    else

        self.LastTouchedEncoder = CommonHWButtonID
        self.EncoderDelayCounter = self.EncoderDelayPeriodInTimerTicks

    end

end

--------------------------------------------------------------------------------------------------------------------

function KK2SpeechAssist.getVolumeMessage()
    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Volume = Song:getLevelParameter():getValue()
    local VolumeMsg = KKSpeechAssistBase.getVolumeAsString(Volume)
    return VolumeMsg

end
