require "Scripts/Maschine/Helper/GridHelper"
require "Scripts/Shared/Helpers/MaschineHelper"

local class = require 'Scripts/Shared/Helpers/classy'
QuantizeOverlayHelper = class( 'QuantizeOverlayHelper' )

------------------------------------------------------------------------------------------------------------------------

local function quantize(Fifty)

    if MaschineHelper.isDrumkitMode() then
        NI.DATA.EventPatternTools.quantizeNoteEvents(App, Fifty)
    else
        NI.DATA.EventPatternTools.quantizeNoteEventsInFocusedSound(App, Fifty)
    end

end

------------------------------------------------------------------------------------------------------------------------

function QuantizeOverlayHelper.getParameterData(Index)

    local Data = {}
    local CapListValues = {}

    if Index == 1 then

        Data.GroupName = "Grid"
        Data.Name = "ACTIVE"
        Data.Value = GridHelper.isSnapEnabled(GridHelper.STEP) and "On" or "Off"

    elseif Index == 2 then

        if GridHelper.isSnapEnabled(GridHelper.STEP) then

            Data.Name = "VALUE"
            local SnapParameter = GridHelper.getSnapParameter(GridHelper.STEP)
            Data.Value = SnapParameter:getValueString()

            for Index = 0,14 do
                CapListValues[Index+1] = SnapParameter:getAsString(Index)
            end

            Data.CapListIndex  = SnapParameter:getValue()
            Data.CapListValues = CapListValues

        end

    end

    return Data
end

------------------------------------------------------------------------------------------------------------------------

function QuantizeOverlayHelper.getButtonData(Index)

    local Data = {}
    local HasEvents = ScenePatternHelper.isIdeaSpace()
        and (MaschineHelper.isDrumkitMode() and ActionHelper.hasGroupEvents() or ActionHelper.hasSoundEvents())

    if Index == 1 then
        Data.Text = "QUANTIZE"
        Data.Enabled = HasEvents and GridHelper.isSnapEnabled(GridHelper.STEP)
        Data.Visible = true
        Data.Selected = false

    elseif Index == 2 then
        Data.Text = "QUANT 50%"
        Data.Enabled = HasEvents and GridHelper.isSnapEnabled(GridHelper.STEP)
        Data.Visible = true
        Data.Selected = false

    end

    return Data

end

------------------------------------------------------------------------------------------------------------------------

function QuantizeOverlayHelper.onScreenEncoder(Index, EncoderInc)

    if MaschineHelper.onScreenEncoderSmoother(Index, EncoderInc, .1) ~= 0 then

        local Value = EncoderInc > 0 and 1 or -1

        if Index == 1 then

            local SnapEnabled = GridHelper.isSnapEnabled(GridHelper.STEP)

            if (SnapEnabled == true and Value == -1) or (SnapEnabled == false and Value == 1) then
                GridHelper.toggleSnapEnabled(GridHelper.STEP)
            end

        elseif Index == 2 and GridHelper.isSnapEnabled(GridHelper.STEP) then

            local SnapParameter = GridHelper.getSnapParameter(GridHelper.STEP)
            local NewValue = SnapParameter:getValue() + Value
            NI.DATA.ParameterAccess.setEnumParameter(App, SnapParameter, NewValue < 0 and 0 or NewValue)

        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function QuantizeOverlayHelper.onWheel(Value)

    QuantizeOverlayHelper.onScreenEncoder(2, Value)
end

------------------------------------------------------------------------------------------------------------------------

function QuantizeOverlayHelper.onWheelButton(Pressed)

    QuantizeOverlayHelper.onScreenButton(1, Pressed)
end

------------------------------------------------------------------------------------------------------------------------

function QuantizeOverlayHelper.updateLEDs()

    LEDHelper.setLEDState(NI.HW.LED_CLEAR, LEDHelper.LS_OFF)

end

------------------------------------------------------------------------------------------------------------------------

function QuantizeOverlayHelper.onScreenButton(Index, Pressed)

    if Pressed and ScenePatternHelper.isIdeaSpace() and (Index == 1 or Index == 2) then
        quantize(Index == 2)
    end

end

------------------------------------------------------------------------------------------------------------------------

function QuantizeOverlayHelper.getScreenButtonInfo(Index)

    local Info = {}
    Info.SpeechSectionName = ""
    Info.SpeechName = ""
    Info.SpeechValue = ""
    Info.SpeakNameInNormalMode = true
    Info.SpeakNameInTrainingMode = true

    if Index == 1 then
        Info.SpeechName = "Quantize"
    elseif Index == 2 then
        Info.SpeechName = "Quantize 50%"
    end

    return Info

end

------------------------------------------------------------------------------------------------------------------------

function QuantizeOverlayHelper.getScreenEncoderInfo(Index)

    local Info = {}
    Info.SpeechSectionName = ""
    Info.SpeechName = ""
    Info.SpeechValue = ""
    Info.SpeakNameInNormalMode = true
    Info.SpeakValueInNormalMode = true
    Info.SpeakNameInTrainingMode = true
    Info.SpeakValueInTrainingMode = true

    local SnapEnabled = GridHelper.isSnapEnabled(GridHelper.STEP)

    if Index == 1 then
        Info.SpeechSectionName = "Grid"
        Info.SpeechName = "Active"
        Info.SpeechValue = SnapEnabled and "On" or "Off"
    elseif Index == 2 and SnapEnabled then
        Info.SpeechSectionName = "Grid"
        Info.SpeechName = "Value"

        local SnapParam = GridHelper.getSnapParameter(GridHelper.STEP)
        Info.SpeechValue = SnapParam:getAsString(SnapParam:getValue())
    end

    return Info

end

------------------------------------------------------------------------------------------------------------------------

