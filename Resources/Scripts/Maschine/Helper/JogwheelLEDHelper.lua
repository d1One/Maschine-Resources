------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
JogwheelLEDHelper = class( 'JogwheelLEDHelper' )


JogwheelLEDHelper.Counter = 0

------------------------------------------------------------------------------------------------------------------------

function JogwheelLEDHelper.updateAllOff(LEDs)

    local NumLEDs = #LEDs

    for Index = 1, NumLEDs do
        LEDHelper.setLEDValue(LEDs[Index], 0)
    end

end

------------------------------------------------------------------------------------------------------------------------

function JogwheelLEDHelper.updateAllOn(LEDs)

    local NumLEDs = #LEDs

    for Index = 1, NumLEDs do
        LEDHelper.setLEDValue(LEDs[Index], 0.7)
    end

end

------------------------------------------------------------------------------------------------------------------------

function JogwheelLEDHelper.updateGlow(LEDs)

    local NumLEDs = #LEDs

    local SinPhase = JogwheelLEDHelper.incSinPhase()

    for Index = 1, NumLEDs do
        LEDHelper.setLEDValue(LEDs[Index], 0.5 + SinPhase * 0.5)
    end

end

------------------------------------------------------------------------------------------------------------------------

function JogwheelLEDHelper.updateTempoEdit(LEDs)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    if Song then

   		JogwheelLEDHelper.Counter = JogwheelLEDHelper.Counter + (Song:getTempoParameter():getValue() * Song:getTicksPerBeat() / (60*25))

        local Position = JogwheelLEDHelper.Counter

        local TicksPerBeat = Song:getTicksPerBeat()
        local Beat = math.floor(Position / TicksPerBeat)
        local Phase = (Position - Beat * TicksPerBeat) / TicksPerBeat

        JogwheelLEDHelper.updateLinearPhase(LEDs, Phase, false, Beat%2 == 0, 0.5)

    end
end

------------------------------------------------------------------------------------------------------------------------

function JogwheelLEDHelper.updateClick(LEDs, Pressed)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    if Song then
        local Position = App:getTransportInfo():getPositionAsTicks()

        local TicksPerBeat = Song:getTicksPerBeat()
        local Beat = math.floor(Position / TicksPerBeat)
        local Phase = (Position - Beat * TicksPerBeat) / TicksPerBeat

        JogwheelLEDHelper.updateLinearPhase(LEDs, Phase, Pressed, Beat%2 == 0, 0.5)

    end
end

------------------------------------------------------------------------------------------------------------------------

function JogwheelLEDHelper.updateLinearPhase(LEDs, Phase, Pressed, Inverted, Brightness)

    local NumLEDs = #LEDs

    local Brightness = Brightness or 1 --fully lit by default
    local SemiLitAmount = Phase * NumLEDs - math.floor(Phase * NumLEDs)

    for Index = 1, NumLEDs do
        local LedAmount = 0

        if Pressed or Index < math.floor(Phase * NumLEDs) + 1 then
            LedAmount = 1

        elseif SemiLitAmount and Index == math.floor(Phase * NumLEDs) + 1 then
            LedAmount = SemiLitAmount
        end

        LEDHelper.setLEDValue(LEDs[Index], (Inverted and 1-LedAmount or LedAmount) * Brightness)

    end

end

------------------------------------------------------------------------------------------------------------------------

function JogwheelLEDHelper.updateKnobPhase(LEDs, Phase, Pressed)

    local NumLEDs = #LEDs

    Phase = Phase * 0.6

    local SemiLitAmount = Phase * NumLEDs - math.floor(Phase * NumLEDs)

    for Index = 1, NumLEDs do
        local LedAmount = 0

        if Pressed or Index < math.floor(Phase * NumLEDs) + 1 then
            LedAmount = 1

        elseif SemiLitAmount and Index == math.floor(Phase * NumLEDs) + 1 then
            LedAmount = SemiLitAmount
        end

        local Led = (Index + NumLEDs - 5) % NumLEDs + 1
        LEDHelper.setLEDValue(LEDs[Led], LedAmount * (Phase+0.4) )

    end

end

------------------------------------------------------------------------------------------------------------------------

function JogwheelLEDHelper.updateBipolarKnobPhase(LEDs, Phase, Pressed)

    local NumLEDs = #LEDs

    local LED = math.abs(Phase) * NumLEDs * 0.4
    local SemiLitAmount = LED - math.floor(LED)

    for Index = 1, NumLEDs do
        local BipolarIndex = Phase < 0 and ((NumLEDs-(Index-1))%NumLEDs)+1 or Index

        -- ON
        if (Pressed or Index < math.floor(LED) + 1) or Index == 1 then
            LEDHelper.setLEDValue(LEDs[BipolarIndex],  1)

        -- OFF
        elseif Index > math.floor(LED) + 1 then
            LEDHelper.setLEDValue(LEDs[BipolarIndex], 0)

        -- SEMILIT
        else
            LEDHelper.setLEDValue(LEDs[BipolarIndex], SemiLitAmount)
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function JogwheelLEDHelper.updateList(LEDs, Item, Count, Pressed)

    local NumLEDs = #LEDs

    local SinPhase = JogwheelLEDHelper.incSinPhase()
    local LED = (Item / (Count-1)) * NumLEDs
    local SemiLitAmount = LED - math.floor(LED)

    for Index = 1, NumLEDs do

        -- ON
        if (Count > 0 and Pressed) or Index < math.floor(LED)+1 then
            LEDHelper.setLEDValue(LEDs[Index], 1)

        -- OFF
        elseif Count <= 1 or Index > math.floor(LED)+1 then
            LEDHelper.setLEDValue(LEDs[Index], Count == 0 and 0 or SinPhase * .1)

        -- SEMILIT
        else --Index == LED
            LEDHelper.setLEDValue(LEDs[Index], SemiLitAmount * .9 + SinPhase * .1)
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function JogwheelLEDHelper.incSinPhase()

    local SinPhase = (math.sin(((JogwheelLEDHelper.Counter % 60) / 60) * 2 * 3.1416) + 1) / 2
    JogwheelLEDHelper.Counter = JogwheelLEDHelper.Counter + 1

    return SinPhase

end