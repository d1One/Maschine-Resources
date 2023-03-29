
require "Scripts/Maschine/Jam/Helper/JamHelper"
require "Scripts/Shared/Helpers/LedColors"
require "Scripts/Shared/Helpers/LedHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
Jam16VelocityMode = class( 'Jam16VelocityMode' )

------------------------------------------------------------------------------------------------------------------------

function Jam16VelocityMode.updatePadLEDs(Controller)

    local Sound = NI.DATA.StateHelper.getFocusSound(App)
    if Sound then

        local CurVelocity = Sound:getVelocityJamParameter():getValue()
        local CurIndex    = Jam16VelocityMode.getIndexFromVelocity(CurVelocity)
        local SoundColor  = Sound:getColorParameter():getValue()

        local LEDFunctor =
            function(Idx)
                local Bright = CurVelocity > 0 and CurIndex == Idx
                return Bright, true
            end


        LEDHelper.updateLEDsWithFunctor(Controller.PAD_VELOCITY_LEDS, 0,
            LEDFunctor,
            function(Idx) return SoundColor end)
    else

        LEDHelper.updateLEDsWithFunctor(Controller.PAD_VELOCITY_LEDS, 0,
            function(Idx) return false, false end)

    end

end

------------------------------------------------------------------------------------------------------------------------

function Jam16VelocityMode.onPadButton(Column, Row, Pressed)

    if not Pressed then
        return
    end

    local Sound = NI.DATA.StateHelper.getFocusSound(App)
    local PressedIndex = Jam16VelocityMode.getIndexByColumnRow(Column, Row)
    if Sound and PressedIndex then

        local CurVelocity  = Sound:getVelocityJamParameter():getValue()
        local CurIndex     = Jam16VelocityMode.getIndexFromVelocity(CurVelocity)

        if CurVelocity > 0 and CurIndex == PressedIndex then
            NI.DATA.ParameterAccess.setSizeTParameterNoUndo(App, Sound:getVelocityJamParameter(), 0)
        else
            local NewVelocity = Jam16VelocityMode.getVelocityFromIndex(PressedIndex)
            NI.DATA.ParameterAccess.setSizeTParameterNoUndo(App, Sound:getVelocityJamParameter(), NewVelocity)
        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function Jam16VelocityMode.getIndexByColumnRow(Column, Row)

    if Row > 4 and Column <= 4 then

        local ColumnOffset = Column - 1
        local RowOffset = 8 - Row

        return RowOffset * 4 + ColumnOffset + 1

    end

end

------------------------------------------------------------------------------------------------------------------------

function Jam16VelocityMode.getIndexFromVelocity(Velocity)

    return math.ceil(Velocity * 16 / 127)

end

------------------------------------------------------------------------------------------------------------------------

function Jam16VelocityMode.getVelocityFromIndex(Index)

    return math.floor(Index * 127 / 16)

end

------------------------------------------------------------------------------------------------------------------------

