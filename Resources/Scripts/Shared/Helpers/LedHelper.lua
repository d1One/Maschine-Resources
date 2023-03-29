------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Helpers/LedColors"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
LEDHelper = class( 'LEDHelper' )

------------------------------------------------------------------------------------------------------------------------
-- LED STATES
------------------------------------------------------------------------------------------------------------------------

LEDHelper.LS_OFF              = 1
LEDHelper.LS_DIM              = 2
LEDHelper.LS_DIM_FLASH        = 3
LEDHelper.LS_BRIGHT           = 4
LEDHelper.LS_FLASH            = 5

------------------------------------------------------------------------------------------------------------------------
-- LED Values (NOTE: may be overwritten by a controller-specific table (i.e. Studio)
------------------------------------------------------------------------------------------------------------------------

LEDHelper.LEDValues =
{
--  LS_OFF          LS_DIM          LS_DIM_FLASH    LS_BRIGHT       LS_FLASH
    {0.0,           0.15,           0.5,            0.4,            0.5}       --  LVG_MAIN
}

LEDHelper.FlashStateCountdown = {}
LEDHelper.CachedEnabledButtonLEDs = {}
LEDHelper.CachedEnabledButtonColors = {}

------------------------------------------------------------------------------------------------------------------------
-- Update a table of LEDs with functors and a base index. ColorFunctor and FlashFunctor are optional
-- The base index is added to the respective LED-index when calling the functor
------------------------------------------------------------------------------------------------------------------------


function LEDHelper.updateLedState(LedID, Selected, Enabled, ColorIndex, Flashing, DisableFlashTimer)

    local LedState = LEDHelper.LS_OFF

    if Enabled or Selected then

        if Flashing then

            LedState = LEDHelper.LS_FLASH
            LEDHelper.FlashStateCountdown[LedID] = DisableFlashTimer and 0 or 2

        elseif LEDHelper.FlashStateCountdown[LedID] and LEDHelper.FlashStateCountdown[LedID] > 0 then

            LedState = LEDHelper.LS_FLASH
            LEDHelper.FlashStateCountdown[LedID] = LEDHelper.FlashStateCountdown[LedID] - 1

        else

            LedState = Selected and LEDHelper.LS_BRIGHT or LEDHelper.LS_DIM

        end

    else

        LEDHelper.FlashStateCountdown[LedID] = 0

    end

     -- set led color
    if NHLController:hasColorLUT() then

        local ColorIdx = ColorIndex and ColorIndex or NPOS
        local State = LedState and LedState or NPOS

        LEDHelper.setLEDColorWithLUT(LedID, ColorIdx, State)

    elseif NHLController:hasRGBLEDs() then

        local Color = ColorIndex and LEDColors[ColorIndex][LedState] or {0,0,0}
        LEDHelper.setLEDColor(LedID, Color)

    else

        LEDHelper.setLEDState(LedID, LedState)

    end

end

------------------------------------------------------------------------------------------------------------------------

function LEDHelper.updateLEDsWithFunctor(LEDs, BaseIndex, SelectedEnabledFunctor, ColorFunctor, FlashFunctor)

    if LEDs == nil then
        error ("LEDs are nil", 2)
        return
    end

    -- iterate over LEDs
    for Index, LedID in ipairs (LEDs) do

        Index = Index + BaseIndex

        -- get select and enable state from functor
        local Selected, Enabled = SelectedEnabledFunctor(Index)
        local ColorIndex = ColorFunctor and ColorFunctor(Index)
        local Flashing, DisableFlashTimer

        if FlashFunctor then
            Flashing, DisableFlashTimer = FlashFunctor(Index)
        end

        LEDHelper.updateLedState(LedID, Selected, Enabled, ColorIndex, Flashing, DisableFlashTimer)

    end

end

------------------------------------------------------------------------------------------------------------------------

function LEDHelper.updateMatrixLedsWithFunctor(LEDs, ColumnCount, RowCount, Functor)

    if LEDs == nil or Functor == nil then
        error ("LEDs or Functor nil", 2)
        return
    end

    for ColumnIndex = 1, ColumnCount do
        for RowIndex = 1, RowCount do

            local LedID = LEDs[ColumnIndex][RowIndex]
            local Selected, Enabled, ColorIndex, Flashing, DisableFlashTimer = Functor(RowIndex, ColumnIndex)
            LEDHelper.updateLedState(LedID, Selected, Enabled, ColorIndex, Flashing, DisableFlashTimer)

        end
    end

end

------------------------------------------------------------------------------------------------------------------------
-- updateScreenButtonLEDs
------------------------------------------------------------------------------------------------------------------------

function LEDHelper.updateScreenButtonLEDs(Controller, Buttons)

    for Index, Button in ipairs(Buttons) do

        -- get button state
        local Enabled   = Button and (Button:isVisible() and Button:isEnabled()) or false
        local Selected  = Button and (Button:isVisible() and Button:isSelected()) or false

        local Led = Controller.SCREEN_BUTTON_LEDS[Index]

        if Selected then
            LEDHelper.setLEDState(Led, LEDHelper.LS_BRIGHT, Button.Color)
        else
            LEDHelper.updateButtonLED(Controller, Led, Controller.SCREEN_BUTTONS[Index], Enabled, Button.Color)
        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function LEDHelper.resetButtonLED(LedID)

    LEDHelper.CachedEnabledButtonLEDs[LedID] = nil
    LEDHelper.setLEDState(LedID, LEDHelper.LS_OFF)

end

------------------------------------------------------------------------------------------------------------------------

function LEDHelper.resetButtonLEDs(LEDs)

    for _, LedID in ipairs(LEDs) do
        LEDHelper.resetButtonLED(LedID)
    end

end

------------------------------------------------------------------------------------------------------------------------

function LEDHelper.updateButtonLED(Controller, LedID, ButtonID, Enabled, ColorIndex)

    local Pressed = Controller.SwitchPressed[ButtonID]

    if Enabled then
        -- store enabled button
        LEDHelper.CachedEnabledButtonLEDs[LedID] = true
        LEDHelper.CachedEnabledButtonColors[LedID] = ColorIndex

        LEDHelper.setLEDState(LedID, Pressed and LEDHelper.LS_BRIGHT or LEDHelper.LS_DIM, ColorIndex)

    else
        -- disabled and pressed: ON only if previously stored as enabled
        if Pressed then
            LEDHelper.setLEDState(LedID, LEDHelper.CachedEnabledButtonLEDs[LedID] and LEDHelper.LS_BRIGHT
                                                                                  or LEDHelper.LS_OFF,
                                                                                  LEDHelper.CachedEnabledButtonColors[LedID])
        else
            -- clear from list if not pressed
            LEDHelper.resetButtonLED(LedID)
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function LEDHelper.updateLeftRightLEDsWithParameters(Controller, NumParameterPages, CurParameterPageIdx)

    LEDHelper.updateButtonLED(Controller, NI.HW.LED_LEFT, NI.HW.BUTTON_LEFT, CurParameterPageIdx > 1 and NumParameterPages > 1)
    LEDHelper.updateButtonLED(Controller, NI.HW.LED_RIGHT, NI.HW.BUTTON_RIGHT, CurParameterPageIdx < NumParameterPages)

end

------------------------------------------------------------------------------------------------------------------------
-- Note: Setting the LED Color turns on the LED no matter if it was off before
function LEDHelper.setLEDColor(LedID, RGB)

    NHLController:setLEDColor(LedID, RGB[1], RGB[2], RGB[3])

end

------------------------------------------------------------------------------------------------------------------------

function LEDHelper.setLEDColorWithLUT(LedID, ColorIndex, LedState)

    if not ColorIndex then
        ColorIndex = -1
    end

    if not LedState then
        LedState = LEDHelper.LS_OFF
    end

    NHLController:setLEDColorLUT(LedID, ColorIndex, LedState)

end

------------------------------------------------------------------------------------------------------------------------

function LEDHelper.setLEDState(LedID, LEDState, ColorIndex)

    if LedID == nil then
        print("Warning: trying to set unregistered LED")
        return
    end

    NHLController:setLEDLevel(LedID, LEDHelper.LEDValues[1][LEDState])

    if NHLController:hasColorLUT() then

        LEDHelper.setLEDColorWithLUT(LedID, ColorIndex, LEDState)

    elseif ColorIndex and NHLController:hasRGBLEDs() then

        LEDHelper.setLEDColor(LedID, LEDColors[ColorIndex][LEDState])

    end

end

------------------------------------------------------------------------------------------------------------------------

function LEDHelper.setLEDValue(LEDID, Value, R, G, B)

    NHLController:setLEDLevel(LEDID, Value)

    if R and G and B and NHLController:hasRGBLEDs() then
        NHLController:setLEDColor(LEDID, R, G, B)
    end

end

------------------------------------------------------------------------------------------------------------------------

function LEDHelper.setLEDOnOff(LedID, Value)

    LEDHelper.setLEDState(LedID, Value == true and LEDHelper.LS_BRIGHT or LEDHelper.LS_OFF)

end

------------------------------------------------------------------------------------------------------------------------

function LEDHelper.turnOffLEDs(LEDs)

    if not LEDs then
        error ("LEDHelper.turnOffLEDs() LEDs are nil", 2)
    end

    -- iterate over Leds
    for _, LedID in ipairs (LEDs) do
        LEDHelper.setLEDState(LedID, LEDHelper.LS_OFF)
    end

end

------------------------------------------------------------------------------------------------------------------------
-- Turn off all LEDs with index in [1, Idx]
------------------------------------------------------------------------------------------------------------------------

function LEDHelper.turnOffLowerLEDs(LEDs, Idx)

    -- iterate over Leds
    for Index, LedID in ipairs (LEDs) do
        if Index <= Idx then
            LEDHelper.setLEDState(LedID, LEDHelper.LS_OFF)
        else
            return
        end
    end

end

------------------------------------------------------------------------------------------------------------------------
