------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Helpers/LedHelper"
require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Shared/Helpers/MiscHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
TouchstripLEDs = class( 'TouchstripLEDs' )

TouchstripLEDs.TS_LED_DEFAULT = 1
TouchstripLEDs.TS_LED_MODULATED = 2
TouchstripLEDs.TS_LED_AUTOWRITE = 3

------------------------------------------------------------------------------------------------------------------------
-- update
------------------------------------------------------------------------------------------------------------------------

function TouchstripLEDs.updateLEDsPerformMode(LEDs, Group)

    local PerformFX = Group and Group:getPerformanceFX() or nil
    if not PerformFX then
        TouchstripLEDs.clearLEDs(LEDs)
        return
    end

    local TouchedParam          = PerformFX:getTouchstripOnOffParameter()
    local ShowTouchedModulation = TouchedParam:isModulated() and not TouchedParam:getValue()
    local NormalizedModValue    = MaschineHelper.getModulatedValueNormalized(TouchedParam)
    local TouchstripTouched     = ShowTouchedModulation and NormalizedModValue >= 0.5 or TouchedParam:getValue()

    local PosParam       = PerformFX:getTouchstripPosParameter()
    local ShowModulation = PosParam:isModulated() and not TouchedParam:getValue()
    local LedMode        = ShowModulation and TouchstripLEDs.TS_LED_MODULATED or TouchstripLEDs.TS_LED_DEFAULT
    local TouchstripPos  = TouchstripLEDs.getLedValue(LEDs, PosParam, LedMode)

    local ObjectColor = Group:getColorParameter():getValue()

    local WhiteLedIdFunctor = function(LedId)
        return TouchstripTouched and LedId == LEDs[TouchstripPos]
    end

    local LedStateFunctor = function(LedIndex)
        return TouchstripPos and TouchstripTouched ~= nil and
            LedIndex == (TouchstripPos - 1) or LedIndex == (TouchstripPos + 1) or LedIndex == TouchstripPos
    end

    TouchstripLEDs.updateTouchstripLEDs(LEDs, WhiteLedIdFunctor, ObjectColor, LedStateFunctor)

end

------------------------------------------------------------------------------------------------------------------------

function TouchstripLEDs.updateLEDsNotesMode(LEDs, Touched, Value, Color)

    local TSValue = Value and TouchstripLEDs.value2Led(LEDs, Value)

    for LedIndex, LedId in ipairs(LEDs) do
        local LedState = Touched and LedIndex == TSValue and LEDHelper.LS_BRIGHT or LEDHelper.LS_OFF
        LEDHelper.setLEDColorWithLUT(LedId, Color, LedState)
    end

end

------------------------------------------------------------------------------------------------------------------------

function TouchstripLEDs.clearLEDs(LEDs)

    for _, LedId in pairs(LEDs) do
        LEDHelper.setLEDColorWithLUT(LedId, LEDColors.WHITE, LEDHelper.LS_OFF)
    end

end

------------------------------------------------------------------------------------------------------------------------

function TouchstripLEDs.isLedOn(LEDs, Value, ModulatedValue, LedIndex, IsBipolar, IsInverted, IsBool, ShowSingleLED)

    if not Value      then return false end
    if ShowSingleLED  then return (LedIndex == Value) end
    if IsBool         then return TouchstripLEDs.isBoolLedOn(LEDs, Value, ModulatedValue, LedIndex) end
    if ModulatedValue then return (LedIndex == ModulatedValue) end
    if IsBipolar      then return TouchstripLEDs.isBipolarLedOn(LEDs, Value, LedIndex) end
    if IsInverted     then return LedIndex > Value end

    return LedIndex < Value

end


------------------------------------------------------------------------------------------------------------------------

function TouchstripLEDs.isBipolarLedOn(LEDs, Value, LedIndex)

    local CenterLed = TouchstripLEDs.getCenterLed(LEDs)
    return (LedIndex < Value and LedIndex >= CenterLed) or
           (LedIndex > Value and LedIndex <= CenterLed)

end

------------------------------------------------------------------------------------------------------------------------

function TouchstripLEDs.isBoolLedOn(LEDs, Value, ModulatedValue, LedIndex)

    local CenterLed = TouchstripLEDs.getCenterLed(LEDs)
    local NewValue  = (ModulatedValue ~= nil and MaschineHelper.isPlaying()) and ModulatedValue or Value
    return (NewValue == 1     and LedIndex < CenterLed) or
           (NewValue == #LEDs and LedIndex > CenterLed)

end

------------------------------------------------------------------------------------------------------------------------

function TouchstripLEDs.updateTouchstripLEDs(LEDs, WhiteLedId, Color, LedStateFunctor)

    local WhiteLedIdFunctor
    if type(WhiteLedId) == "function" then
        WhiteLedIdFunctor = WhiteLedId
    else
        WhiteLedIdFunctor = function(LedId)
            return LedId == WhiteLedId
        end
    end

    for LedIndex, LedId in pairs(LEDs) do

        local LedColor, LedState

        if WhiteLedIdFunctor(LedId) then
            LedColor = LEDColors.WHITE
            LedState = LEDHelper.LS_BRIGHT
        else
            LedState = Color and LedStateFunctor(LedIndex) and LEDHelper.LS_BRIGHT or LEDHelper.LS_OFF
            LedColor = LedState ~= LEDHelper.LS_OFF and Color or nil
        end

        LEDHelper.setLEDColorWithLUT(LedId, LedColor, LedState)

    end

end

------------------------------------------------------------------------------------------------------------------------
-- Helper
------------------------------------------------------------------------------------------------------------------------

function TouchstripLEDs.value2Led(LEDs, Value)

    return math.round(Value * (#LEDs - 1)) + 1

end

------------------------------------------------------------------------------------------------------------------------

function TouchstripLEDs.getLedValue(LEDs, Param, LedMode)

    if LedMode == TouchstripLEDs.TS_LED_MODULATED then

        return TouchstripLEDs.value2Led(LEDs, MaschineHelper.getModulatedValueNormalized(Param))

    elseif LedMode == TouchstripLEDs.TS_LED_AUTOWRITE then

        return TouchstripLEDs.value2Led(LEDs, Param:getEncoderValueAutoWrite() / 2 + 0.5)

    end

    return TouchstripLEDs.value2Led(LEDs, Param:getNormalizedValue())

end

------------------------------------------------------------------------------------------------------------------------

function TouchstripLEDs.getCenterLed(LEDs)

    return (#LEDs + 1) / 2

end

------------------------------------------------------------------------------------------------------------------------
