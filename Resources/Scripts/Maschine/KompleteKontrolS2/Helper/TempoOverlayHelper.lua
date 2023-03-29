require "Scripts/Shared/Helpers/MaschineHelper"

local class = require 'Scripts/Shared/Helpers/classy'
TempoOverlayHelper = class( 'TempoOverlayHelper' )

------------------------------------------------------------------------------------------------------------------------

function TempoOverlayHelper.getParameterData(Index)

    local Data = {}

    if Index == 1 then

        Data.GroupName = "Tempo"
        Data.Name = "BPM"

        local Song = NI.DATA.StateHelper.getFocusSong(App)
        local TempoParam = Song and Song:getTempoParameter()
        Data.Value = TempoParam and TempoParam:getValueString() or ""

    end

    return Data
end

------------------------------------------------------------------------------------------------------------------------

function TempoOverlayHelper.onWheel(Value)

    TempoOverlayHelper.onScreenEncoder(1, Value)

end

------------------------------------------------------------------------------------------------------------------------

function TempoOverlayHelper.updateLEDs()

    LEDHelper.setLEDState(NI.HW.LED_CLEAR, LEDHelper.LS_OFF)

end

------------------------------------------------------------------------------------------------------------------------

function TempoOverlayHelper.onScreenEncoder(Index, EncoderInc)

    if MaschineHelper.onScreenEncoderSmoother(Index, EncoderInc, .1) ~= 0 then

        local Value = EncoderInc > 0 and 1 or -1

        if Index == 1 then

            local Song = NI.DATA.StateHelper.getFocusSong(App)
            local TempoParam = Song and Song:getTempoParameter()

            if TempoParam then
                NI.DATA.ParameterAccess.setFloatParameter(App, TempoParam, TempoParam:getValue() + Value)
            end

        end
    end
end

------------------------------------------------------------------------------------------------------------------------

function TempoOverlayHelper.getScreenEncoderInfo(Index)

    local Info = {}
    Info.SpeechSectionName = ""
    Info.SpeechName = ""
    Info.SpeechValue = ""
    Info.SpeakNameInNormalMode = true
    Info.SpeakValueInNormalMode = true
    Info.SpeakNameInTrainingMode = true
    Info.SpeakValueInTrainingMode = true

    if Index == 1 then
        local Song = NI.DATA.StateHelper.getFocusSong(App)
        local TempoParam = Song and Song:getTempoParameter()
        if TempoParam then
            Info.SpeechSectionName = "Tempo"
            Info.SpeechName =  "BPM"
            Info.SpeechValue = TempoParam:getAsString(TempoParam:getValue())
        end
    end

    return Info

end

------------------------------------------------------------------------------------------------------------------------
