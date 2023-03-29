------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Pages/PageMaschine"
require "Scripts/Maschine/Maschine/Screens/ScreenWithGrid"
require "Scripts/Maschine/Helper/GridHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
GridPageBase = class( 'GridPageBase', PageMaschine )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function GridPageBase:__init(Page, Controller)

    PageMaschine.__init(self, Page, Controller)

    -- define page leds
    self.PageLEDs = { NI.HW.LED_TRANSPORT_GRID }

    self.GridMode = GridHelper.PERFORM -- modes are: GridHelper.PERFORM, GridHelper.PATGRID, GridHelper.STEP
    self.Grid = { 1, 5, 9, 13, 2, 6, 10, 14, 3, 7, 11, 15, 4, 8, 12, 16 }  -- 4x4 matrix transpose helper

end

------------------------------------------------------------------------------------------------------------------------
-- update
------------------------------------------------------------------------------------------------------------------------

function GridPageBase:updateScreens(ForceUpdate)

    if ForceUpdate then
        LEDHelper.setLEDState(NI.HW.LED_LEFT, LEDHelper.LS_OFF)
        LEDHelper.setLEDState(NI.HW.LED_RIGHT, LEDHelper.LS_OFF)

        self.ParameterHandler.NumParamsPerPage = 4
    end

    -- screen buttons
    self.Screen.ScreenButton[2]:setSelected(self.GridMode == GridHelper.PERFORM)
    self.Screen.ScreenButton[3]:setSelected(self.GridMode == GridHelper.ARRANGER)
    self.Screen.ScreenButton[4]:setSelected(self.GridMode == GridHelper.STEP)

    -- enable button 7 only for step grid
    self.Screen.ScreenButton[7]:setEnabled(self.GridMode == GridHelper.STEP)

    -- update on-screen pad grid
    self.Screen:updatePadButtonsWithFunctor(
        function(Index)
            return GridPageBase.getPadButtonState(self, Index, ForceUpdate)
        end
    )

    -- call base class
    PageMaschine.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function GridPageBase:updateParameters(ForceUpdate)

    local CustomSections = {}
    local CustomNames = {}
    local CustomValues = {}
    local Parameters = {}

    if self.GridMode == GridHelper.STEP then
        Parameters[4] = GridHelper.getNudgeSnapParameter()

    elseif self.GridMode == GridHelper.ARRANGER then
        CustomSections[4] = "Pattern"
        CustomNames[4] = "QUICK"
        CustomValues[4] = GridHelper.getQuickEnabledAsString(self.GridMode)
    end

    self.ParameterHandler:setParameters(Parameters, true)
    self.ParameterHandler.CustomSections = CustomSections
    self.ParameterHandler.CustomNames = CustomNames
    self.ParameterHandler.CustomValues = CustomValues

    PageMaschine.updateParameters(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------
--Functor: Visible, Enabled, Selected, Focused, Text

function GridPageBase:getPadButtonState(Index, ForceUpdate)

    local StateCache = App:getStateCache()
    local SnapParameter = GridHelper.getSnapParameter(self.GridMode)
    local SnapEnabledParameter = GridHelper.getSnapEnabledParameter(self.GridMode)
    local SnapEnabledChanged = SnapEnabledParameter and SnapEnabledParameter:isChanged() or false

    ForceUpdate = ForceUpdate or StateCache:isFocusSongChanged()

    -- got the parameter, now update according to its values
    if SnapParameter then

        -- Perform is the only Enum that contains an "OFF" value, therefore SnapMax is 1 less than the size
        -- of the Enum
        local SnapMax = SnapParameter:getMax() - (self.GridMode == GridHelper.PERFORM and 1 or 0)
        local SnapIsOn = GridHelper.isSnapEnabled(self.GridMode)
        local SnapValue = SnapParameter:getValue() + (self.GridMode == GridHelper.PERFORM and 0 or 1)

        local MappedIndex = self.Grid[Index]

        if MappedIndex == 16 then

            -- special case for the snap on/off parameter
            return true, true, false, SnapIsOn == false, "OFF"

        else

            local IsEnabled = MappedIndex - 1 <= SnapMax
            local Name = IsEnabled and SnapParameter:getAsString(
                MappedIndex - (self.GridMode == GridHelper.PERFORM and 0 or 1)) or ""

            return true, IsEnabled, false, (MappedIndex == SnapValue and SnapIsOn == true), Name

        end

    end

    return true, false, false, false, ""

end

------------------------------------------------------------------------------------------------------------------------

function GridPageBase:updatePadLEDs()

    local StateCache = App:getStateCache()
    local SnapParameter = GridHelper.getSnapParameter(self.GridMode)

    if SnapParameter then

        local Snap = SnapParameter:getValue() + (self.GridMode == GridHelper.PERFORM and 0 or 1)
        local SnapMax = SnapParameter:getMax() - (self.GridMode == GridHelper.PERFORM and 1 or 0)
        local SnapEnabled = GridHelper.isSnapEnabled(self.GridMode)

        for Index = 1, 16 do

            local MappedIndex = self.Grid[Index]
            local IsEnabled = MappedIndex - 1 <= SnapMax
            local LedState

            -- Pad 16 is Snap toggle
            if MappedIndex == 16 then
                LedState = SnapEnabled and LEDHelper.LS_DIM or LEDHelper.LS_BRIGHT
            elseif not IsEnabled then
                LedState = LEDHelper.LS_OFF
            else
                LedState = MappedIndex == Snap and SnapEnabled and LEDHelper.LS_BRIGHT or LEDHelper.LS_DIM
            end

            LEDHelper.setLEDState(HardwareControllerBase.PAD_LEDS[Index], LedState, LEDColors.WHITE)

        end

    end

end

------------------------------------------------------------------------------------------------------------------------
-- event handling
------------------------------------------------------------------------------------------------------------------------

function GridPageBase:setMode(Mode)

    self.GridMode = Mode
    self:updateScreens(true)

end

------------------------------------------------------------------------------------------------------------------------

function GridPageBase:onPadEvent(PadIndex, Trigger)

    if not Trigger then
        return
    end

    local MappedIndex = self.Grid[PadIndex]

    -- Pad 16 is Snap toggle
    if MappedIndex == 16 then

        GridHelper.toggleSnapEnabled(self.GridMode)
        return
    else

        local SnapParameter = GridHelper.getSnapParameter(self.GridMode)

        if SnapParameter then

            local Snap = SnapParameter:getValue() + (self.GridMode == GridHelper.STEP and 1 or 0)
            local SnapMax = SnapParameter:getMax() - (self.GridMode == GridHelper.PERFORM and 1 or 0)
            local SnapEnabled = GridHelper.isSnapEnabled(self.GridMode)
            local IsEnabled = MappedIndex - 1 <= SnapMax

            if not IsEnabled then
                return
            end

            local NewValue = MappedIndex - (self.GridMode == GridHelper.PERFORM and 0 or 1)

            NI.DATA.ParameterAccess.setEnumParameterNoUndo(App, SnapParameter, NewValue)

            local ToggleEnable =
                self.GridMode ~= GridHelper.PERFORM and GridHelper.isSnapEnabled(self.GridMode) == false

            if ToggleEnable then
                GridHelper.toggleSnapEnabled(self.GridMode)
            end
        end
    end

    return true

end

------------------------------------------------------------------------------------------------------------------------

function GridPageBase:onCycleButton(Column)

    local ValueIdx = GridHelper.isSnapEnabled(self.GridMode)
        and GridHelper.getSnapParameter(self.GridMode):getValue() + (self.GridMode == GridHelper.PERFORM and 0 or 1)
        or  16

    local Index = Column

    for i = Column + 4, Column + 12, 4 do  -- iterate over Pad indices in Column
        if ValueIdx == self.Grid[i] then
            break
        end
        Index = i
    end

    if self.GridMode == GridHelper.PERFORM then

        if Column == 2 then

            Index = math.min(Index, 6)

        elseif Column > 2 then

            GridHelper.toggleSnapEnabled(self.GridMode)
            return

        end

    elseif self.GridMode == GridHelper.ARRANGER then

        if Column == 2 then
            Index = math.min(Index, 2)

        elseif Column > 2 then

            GridHelper.toggleSnapEnabled(self.GridMode)
            return

        end

    end

    self:onPadEvent(Index, true)

end

------------------------------------------------------------------------------------------------------------------------

function GridPageBase:onScreenButton(ButtonIdx, Pressed)

    if Pressed then
        if ButtonIdx == 2 then
            self:setMode(GridHelper.PERFORM)

        elseif ButtonIdx == 3 then
            self:setMode(GridHelper.ARRANGER)

        elseif ButtonIdx == 4 then
            self:setMode(GridHelper.STEP)

        elseif ButtonIdx >= 5 and ButtonIdx <= 8 then
            self:onCycleButton(ButtonIdx - 4)

        end
    end

    -- call base class for update
    PageMaschine.onScreenButton(self, ButtonIdx, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function GridPageBase:onScreenEncoder(KnobIdx, EncoderInc)

    if KnobIdx == 4 then

        local ArrangeWithSnap = self.GridMode == GridHelper.ARRANGER and GridHelper.isSnapEnabled(self.GridMode)
        if ArrangeWithSnap and MaschineHelper.onScreenEncoderSmoother(KnobIdx, EncoderInc, .1) ~= 0 then
            GridHelper.setQuickEnabled(EncoderInc > 0 and true or false)
        end

    end

    -- call base class for update
    PageMaschine.onScreenEncoder(self, KnobIdx, EncoderInc)

end

------------------------------------------------------------------------------------------------------------------------
