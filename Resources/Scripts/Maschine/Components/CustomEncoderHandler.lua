------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
CustomEncoderHandler = class( 'CustomEncoderHandler' )

------------------------------------------------------------------------------------------------------------------------

-- This class deals with encoders that are not bound to actual parameters
-- Pages that use CustomEncoders must call CustomEncoderHandler:update in their updateParameters function
-- Pages that use CustomEncoders must call CustomEncoderHandler:onEncoderChange in their onScreenEncoder function

------------------------------------------------------------------------------------------------------------------------

function CustomEncoderHandler:__init()

    self.CustomEncoders = {}

end

------------------------------------------------------------------------------------------------------------------------
-- Add a new encoder.
-- Treshold specifies, on which knob rotation the fnOnChange function gets triggered.
-- a Treshold of 1.0 means a 360 degree rotation of the knob.
-- fnGetValue is used to retrieve the value string that has to be shown in the ParameterWidget.
-- It gets updated when CustomEncoderHandler:update() is called.
------------------------------------------------------------------------------------------------------------------------

function CustomEncoderHandler:addEncoder(Index, Name, ParameterWidget, Treshold, fnGetValue, fnOnChange, fnForceDisable)

    local NewEncoder = {}

    NewEncoder.Name             = Name
    NewEncoder.Widget           = ParameterWidget
    NewEncoder.Threshold        = Treshold
    NewEncoder.CurrentDelta     = 0
    NewEncoder.fnGetValue       = fnGetValue
    NewEncoder.fnOnChange       = fnOnChange
    NewEncoder.fnForceDisable   = fnForceDisable

    self.CustomEncoders[Index] = NewEncoder

end

------------------------------------------------------------------------------------------------------------------------

function CustomEncoderHandler:updateEncoder(Index)

    local Encoder = self.CustomEncoders[Index]

    if Encoder then
        local Value = Encoder.fnGetValue()
        local Disabled = Encoder.fnForceDisable ~= nil and Encoder.fnForceDisable()
        Value = (Value and not Disabled) and tostring(Value) or "-"  -- Value can be a number, and it needs to be a string
        Encoder.Widget:setName(Encoder.Name)
        Encoder.Widget:setValue(Value)
        Encoder.Widget:setVisible(true)
        NHLController:addAccessibilityControlData(NI.HW.ZONE_ERPS, Index, 0, 1, 0, Encoder.Name)
        NHLController:addAccessibilityControlData(NI.HW.ZONE_ERPS, Index, 0, 2, 0, Value)
    end

end

------------------------------------------------------------------------------------------------------------------------

function CustomEncoderHandler:update()

    for Index = 1, #self.CustomEncoders do
        self:updateEncoder(Index)
    end

end

------------------------------------------------------------------------------------------------------------------------

function CustomEncoderHandler:resetEncoder(Index)

    local Encoder = self.CustomEncoders[Index]
    if Encoder then
        Encoder.Widget:setName("")
        Encoder.Widget:setValue("")
        Encoder.Widget:setVisible(false)
    end

    self.CustomEncoders[Index] = nil

end

------------------------------------------------------------------------------------------------------------------------

function CustomEncoderHandler:resetEncoders()

    for Index = 1, #self.CustomEncoders do
        self:resetEncoder(Index)
    end

end

------------------------------------------------------------------------------------------------------------------------
-- onEncoderChanged will call the onChanged functor, if the CustomEncoder's value delta >= Threshold
------------------------------------------------------------------------------------------------------------------------

function CustomEncoderHandler:onEncoderChanged(Index, ValueDelta)

    local Encoder = self.CustomEncoders[Index]

    if Encoder then

        local Disabled = Encoder.fnForceDisable ~= nil and Encoder.fnForceDisable()

        if not Disabled then

            if ValueDelta * Encoder.CurrentDelta < 0 then
                Encoder.CurrentDelta = 0 -- reset the current delta if signs (knob direction) changes
                return false
            end

            Encoder.CurrentDelta = Encoder.CurrentDelta + ValueDelta

            if math.abs(Encoder.CurrentDelta) > Encoder.Threshold then

                local Delta
                if Encoder.Threshold > 0 then
                    Delta = Encoder.CurrentDelta > 0
                        and math.floor(Encoder.CurrentDelta / Encoder.Threshold)
                        or  math.ceil(Encoder.CurrentDelta / Encoder.Threshold)
                else
                    Delta = Encoder.CurrentDelta
                end

                Encoder.fnOnChange(Delta)
                Encoder.CurrentDelta = Encoder.CurrentDelta - Delta*Encoder.Threshold

                self:updateEncoder(Index)
                return true

            end

        end

    end

    return false

end

------------------------------------------------------------------------------------------------------------------------
