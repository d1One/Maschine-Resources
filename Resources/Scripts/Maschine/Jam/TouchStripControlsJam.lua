------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Shared/Helpers/QuickEditHelper"
require "Scripts/Maschine/Helper/TouchstripLEDs"
require "Scripts/Maschine/Jam/Helper/JamHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
TouchstripControlsJam = class( 'TouchstripControlsJam' )


TouchstripControlsJam.TOUCHSTRIP_LEDS =
{
    {NI.HW.LED_TS_A01, NI.HW.LED_TS_A02, NI.HW.LED_TS_A03, NI.HW.LED_TS_A04, NI.HW.LED_TS_A05, NI.HW.LED_TS_A06, NI.HW.LED_TS_A07, NI.HW.LED_TS_A08, NI.HW.LED_TS_A09, NI.HW.LED_TS_A10, NI.HW.LED_TS_A11},
    {NI.HW.LED_TS_B01, NI.HW.LED_TS_B02, NI.HW.LED_TS_B03, NI.HW.LED_TS_B04, NI.HW.LED_TS_B05, NI.HW.LED_TS_B06, NI.HW.LED_TS_B07, NI.HW.LED_TS_B08, NI.HW.LED_TS_B09, NI.HW.LED_TS_B10, NI.HW.LED_TS_B11},
    {NI.HW.LED_TS_C01, NI.HW.LED_TS_C02, NI.HW.LED_TS_C03, NI.HW.LED_TS_C04, NI.HW.LED_TS_C05, NI.HW.LED_TS_C06, NI.HW.LED_TS_C07, NI.HW.LED_TS_C08, NI.HW.LED_TS_C09, NI.HW.LED_TS_C10, NI.HW.LED_TS_C11},
    {NI.HW.LED_TS_D01, NI.HW.LED_TS_D02, NI.HW.LED_TS_D03, NI.HW.LED_TS_D04, NI.HW.LED_TS_D05, NI.HW.LED_TS_D06, NI.HW.LED_TS_D07, NI.HW.LED_TS_D08, NI.HW.LED_TS_D09, NI.HW.LED_TS_D10, NI.HW.LED_TS_D11},
    {NI.HW.LED_TS_E01, NI.HW.LED_TS_E02, NI.HW.LED_TS_E03, NI.HW.LED_TS_E04, NI.HW.LED_TS_E05, NI.HW.LED_TS_E06, NI.HW.LED_TS_E07, NI.HW.LED_TS_E08, NI.HW.LED_TS_E09, NI.HW.LED_TS_E10, NI.HW.LED_TS_E11},
    {NI.HW.LED_TS_F01, NI.HW.LED_TS_F02, NI.HW.LED_TS_F03, NI.HW.LED_TS_F04, NI.HW.LED_TS_F05, NI.HW.LED_TS_F06, NI.HW.LED_TS_F07, NI.HW.LED_TS_F08, NI.HW.LED_TS_F09, NI.HW.LED_TS_F10, NI.HW.LED_TS_F11},
    {NI.HW.LED_TS_G01, NI.HW.LED_TS_G02, NI.HW.LED_TS_G03, NI.HW.LED_TS_G04, NI.HW.LED_TS_G05, NI.HW.LED_TS_G06, NI.HW.LED_TS_G07, NI.HW.LED_TS_G08, NI.HW.LED_TS_G09, NI.HW.LED_TS_G10, NI.HW.LED_TS_G11},
    {NI.HW.LED_TS_H01, NI.HW.LED_TS_H02, NI.HW.LED_TS_H03, NI.HW.LED_TS_H04, NI.HW.LED_TS_H05, NI.HW.LED_TS_H06, NI.HW.LED_TS_H07, NI.HW.LED_TS_H08, NI.HW.LED_TS_H09, NI.HW.LED_TS_H10, NI.HW.LED_TS_H11}
}

------------------------------------------------------------------------------------------------------------------------

function TouchstripControlsJam:__init(Controller)

    self.Controller = Controller

    -- Cache for group colors and levels for easy access
    self.CachedValues = {
        [NI.HW.TS_MODE_LEVEL] = {},
        [NI.HW.TS_MODE_PAN] = {},
        [NI.HW.TS_MODE_AUX1] = {},
        [NI.HW.TS_MODE_AUX2] = {}
    }

    -- initialize touchstrip states and cached values
    self:onCustomProcess(true)

end

------------------------------------------------------------------------------------------------------------------------

function TouchstripControlsJam.getNumTouchstrips()

    return #TouchstripControlsJam.TOUCHSTRIP_LEDS

end

------------------------------------------------------------------------------------------------------------------------

function TouchstripControlsJam:onCustomProcess(ForceUpdate)

    self:updateCachedValues()

end

------------------------------------------------------------------------------------------------------------------------

function TouchstripControlsJam:updateCachedValues()

    local LevelTab = MaschineHelper.getLevelTab()
    local ObjectVector = nil

    if LevelTab == NI.DATA.LEVEL_TAB_SOUND then

        local FocusGroup = NI.DATA.StateHelper.getFocusGroup(App)
        ObjectVector = FocusGroup and FocusGroup:getSounds()

    elseif LevelTab == NI.DATA.LEVEL_TAB_GROUP then

        local Song = NI.DATA.StateHelper.getFocusSong(App)
        ObjectVector = Song and Song:getGroups()

    end

    if ObjectVector then

        local NumObjects = ObjectVector:size()

        for ObjectIdx = 1, NumObjects do

            local Object = ObjectVector:at(ObjectIdx - 1)
            local LEDs = self.TOUCHSTRIP_LEDS[1]
            if Object then
                self.CachedValues[NI.HW.TS_MODE_LEVEL][ObjectIdx] =
                    TouchstripLEDs.getLedValue(LEDs, Object:getLevelParameter(), TouchstripLEDs.TS_LED_DEFAULT)
                self.CachedValues[NI.HW.TS_MODE_PAN][ObjectIdx] =
                    TouchstripLEDs.getLedValue(LEDs, Object:getPanParameter(), TouchstripLEDs.TS_LED_DEFAULT)
                self.CachedValues[NI.HW.TS_MODE_AUX1][ObjectIdx] =
                    TouchstripLEDs.getLedValue(LEDs, Object:getAux1LevelParameter(), TouchstripLEDs.TS_LED_DEFAULT)
                self.CachedValues[NI.HW.TS_MODE_AUX2][ObjectIdx] =
                    TouchstripLEDs.getLedValue(LEDs, Object:getAux2LevelParameter(), TouchstripLEDs.TS_LED_DEFAULT)
            end

        end

    end

end

------------------------------------------------------------------------------------------------------------------------
-- Helper
------------------------------------------------------------------------------------------------------------------------

function TouchstripControlsJam.getObjectColorFromTSMixingLayer()

    local LevelTab = MaschineHelper.getLevelTab()

    if LevelTab == NI.DATA.LEVEL_TAB_SONG then
        return LEDColors.WHITE
    elseif LevelTab == NI.DATA.LEVEL_TAB_GROUP then
        local Group = NI.DATA.StateHelper.getFocusGroup(App)
        return Group and Group:getColorParameter():getValue()
    elseif LevelTab == NI.DATA.LEVEL_TAB_SOUND then
        local Sound = NI.DATA.StateHelper.getFocusSound(App)
        return Sound and Sound:getColorParameter():getValue()
    end

end

------------------------------------------------------------------------------------------------------------------------
-- update LEDs
------------------------------------------------------------------------------------------------------------------------

function TouchstripControlsJam:updateLEDs()

    local TouchstripMode = JamHelper.getTouchstripMode()

    for TouchstripIdx = 1, self.getNumTouchstrips() do

        if JamHelper.isStepModulationModeEnabled() then

            if TouchstripMode == NI.HW.TS_MODE_QUICK_EDIT then
                self:updateLEDsQuickEditMode(TouchstripIdx)
            else
                self:updateLEDsStepModMode(TouchstripIdx)
            end

        elseif TouchstripMode == NI.HW.TS_MODE_PERFORM then

            self:updateLEDsPerformMode(TouchstripIdx)

        elseif self.isOutputMode(TouchstripMode) then

            self:updateLEDsOutputMode(TouchstripIdx)

        elseif TouchstripMode == NI.HW.TS_MODE_CONTROL or TouchstripMode == NI.HW.TS_MODE_MACRO then

            self:updateLEDsControlMacroMode(TouchstripIdx, TouchstripMode == NI.HW.TS_MODE_MACRO)

        elseif TouchstripMode == NI.HW.TS_MODE_NOTES then

            self:updateLEDsNotesMode(TouchstripIdx)

        elseif TouchstripMode == NI.HW.TS_MODE_TUNE or TouchstripMode == NI.HW.TS_MODE_SWING then

            self:updateLEDsTuneSwingMode(TouchstripIdx)
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function TouchstripControlsJam:updateLEDsStepModMode(TouchstripIndex)

    local TSMode = JamHelper.getTouchstripMode()
    local StepPage = self.Controller.PageManager:getPage(NI.HW.PAGE_STEP)
    local LEDs = self.TOUCHSTRIP_LEDS[TouchstripIndex]
    local Parameter, ParameterTag = nil
    local TouchstripPos, ModulatedPos = nil
    local ObjectColor = nil
    local WhiteLedId = nil
    if StepPage then

        Parameter = StepPage.StepEdit:getStepModParamFromTouchID(TouchstripIndex)

        if Parameter then

            local Song = NI.DATA.StateHelper.getFocusSong(App)
            local Pattern = NI.DATA.StateHelper.getFocusEventPattern(App)
            ParameterTag = Parameter:getTag()

            if Song and Pattern then

                local StepModValue = StepPage.StepEdit:getStepModulationValue(Parameter)

                if self.isOutputMode(TSMode) or TSMode == NI.HW.TS_MODE_TUNE or TSMode == NI.HW.TS_MODE_SWING then
                    local ParamValue = Parameter:getNormalizedValue()
                    TouchstripPos = TouchstripLEDs.value2Led(LEDs, ParamValue)
                    WhiteLedId = LEDs[TouchstripPos] or nil
                elseif not StepModValue and (TSMode == NI.HW.TS_MODE_CONTROL or TSMode == NI.HW.TS_MODE_MACRO) then
                    self:updateLEDsControlMacroMode(TouchstripIndex, TSMode == NI.HW.TS_MODE_MACRO)
                    return
                end

                if StepModValue then
                    if ParameterTag == NI.DATA.MaschineParameter.TAG_ENUM then
                        StepModValue = 1 - StepModValue
                    end
                    ModulatedPos = TouchstripLEDs.value2Led(LEDs, StepModValue)
                    TouchstripPos = ModulatedPos
                    WhiteLedId = nil
                end

                ObjectColor = self.getObjectColorFromTSMixingLayer()
            end
        end
    end

    local LedStateFunctor = function(LedIndex)
        if Parameter then
            local IsBipolar = Parameter:isBipolar()
            local IsInverted = ParameterTag == NI.DATA.MaschineParameter.TAG_ENUM
            local IsBool = ParameterTag == NI.DATA.MaschineParameter.TAG_BOOL
            local ShowSingleLED = TSMode == NI.HW.TS_MODE_LEVEL
            return TouchstripLEDs.isLedOn(LEDs, TouchstripPos, ModulatedPos, LedIndex, IsBipolar, IsInverted, IsBool, ShowSingleLED)
        end
    end

    TouchstripLEDs.updateTouchstripLEDs(LEDs, WhiteLedId, ObjectColor, LedStateFunctor)

end

------------------------------------------------------------------------------------------------------------------------

function TouchstripControlsJam:updateLEDsQuickEditMode(TouchstripIndex)

    local TopPageId = NHLController:getPageStack():getTopPage()
    if TopPageId ~= NI.HW.PAGE_STEP then
        return
    end

    local LEDs = self.TOUCHSTRIP_LEDS[TouchstripIndex]
    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Group = NI.DATA.StateHelper.getFocusGroup(App)

    local WhiteLedIdx
    local MaxLedIdx
    local Color
    local Value

    if Song and Group then

        local QEMode = JamHelper.getQuickEditMode()

        if QEMode == NI.HW.QUICK_EDIT_VELOCITY then
            -- Level
            Value = NI.DATA.EventPatternTools.getSelectedNoteEventsVelocity(Song, Group, true)
            Value = Value > 0 and (Value / 127) or 0
        elseif QEMode == NI.HW.QUICK_EDIT_PITCH then
            -- Tune
            Value = NI.DATA.EventPatternTools.getSelectedNoteEventsPitch(Song, Group, true)
            Value = Value > 0 and (Value / 127) or 0
            MaxLedIdx = #LEDs+1
        elseif QEMode == NI.HW.QUICK_EDIT_POSITION then
            -- Swing: TS display is off. position is displayed on matrix buttons
        elseif QEMode == NI.HW.QUICK_EDIT_LENGTH then
            -- Length: TS display is OFF. length is displayed by pulsing matrix buttons
        end

        local Sound = NI.DATA.StateHelper.getFocusSound(App)
        Color = Sound and Sound:getColorParameter():getValue()
        WhiteLedIdx = QEMode ~= NI.HW.QUICK_EDIT_LENGTH and QEMode ~= NI.HW.QUICK_EDIT_POSITION and TouchstripIndex == 1
            and TouchstripLEDs.value2Led(LEDs, Value) or nil

        MaxLedIdx = not MaxLedIdx and WhiteLedIdx or MaxLedIdx
    end

    local LedStateFunctor = function(LedIndex)
        return TouchstripIndex == 1 and WhiteLedIdx and LedIndex < MaxLedIdx or false
    end

    TouchstripLEDs.updateTouchstripLEDs(LEDs, LEDs[WhiteLedIdx], Color, LedStateFunctor)

end

------------------------------------------------------------------------------------------------------------------------

function TouchstripControlsJam:updateLEDsPerformMode(TouchstripIndex)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local GroupIdx = TouchstripIndex + JamHelper.getGroupOffset()
    local Group = Song and Song:getGroups():at(GroupIdx - 1) or nil

    TouchstripLEDs.updateLEDsPerformMode(self.TOUCHSTRIP_LEDS[TouchstripIndex], Group)

end

------------------------------------------------------------------------------------------------------------------------

function TouchstripControlsJam:updateLEDsOutputMode(TouchstripIndex)

    local LEDs = self.TOUCHSTRIP_LEDS[TouchstripIndex]
    local ObjectIdx, Object, ObjectColor = self.getMixingLayerData(TouchstripIndex)
    local TSMode = JamHelper.getTouchstripMode()

    local Param
    if Object then
        if TSMode == NI.HW.TS_MODE_LEVEL then
            Param = Object:getLevelParameter()
        elseif TSMode == NI.HW.TS_MODE_PAN then
            Param = Object:getPanParameter()
        elseif TSMode == NI.HW.TS_MODE_AUX1 then
            Param = Object:getAux1LevelParameter()
        elseif TSMode == NI.HW.TS_MODE_AUX2 then
            Param = Object:getAux2LevelParameter()
        end
    end

    local GetCachedValueAndModulatedValue = function()
        local CachedValue = Object and self.CachedValues[TSMode][ObjectIdx]
        local ModValue = Param and Param:isModulated() and TouchstripLEDs.getLedValue(LEDs, Param, TouchstripLEDs.TS_LED_MODULATED)
        return CachedValue, ModValue
    end

    local CurrentValue, ModulatedValue = GetCachedValueAndModulatedValue()

    local LevelMean = 0
    if TSMode == NI.HW.TS_MODE_LEVEL and Object then
        local LevelL = NI.UTILS.LevelScale.convertLevelTodBNormalized(Object:getLevelNoDecay(0), -60, 10)
        local LevelR = NI.UTILS.LevelScale.convertLevelTodBNormalized(Object:getLevelNoDecay(1), -60, 10)
        LevelMean = ((math.bound(LevelL, 0, 1) + math.bound(LevelR, 0, 1)) / 2) * #LEDs
    end

    local WhiteLedId = CurrentValue and LEDs[CurrentValue] or nil

    local Value = TSMode == NI.HW.TS_MODE_LEVEL and LevelMean or CurrentValue

    local LedStateFunctor = function (LedIndex)
        return TouchstripLEDs.isLedOn(LEDs, Value, ModulatedValue, LedIndex, TSMode == NI.HW.TS_MODE_PAN, false, false, false)
    end

    TouchstripLEDs.updateTouchstripLEDs(LEDs, WhiteLedId, ObjectColor, LedStateFunctor)

end

------------------------------------------------------------------------------------------------------------------------

function TouchstripControlsJam:updateLEDsControlMacroMode(TouchstripIndex, IsMacro)

    local ObjectColor
    local ParamCache = App:getStateCache():getParameterCache()
    local LEDs = self.TOUCHSTRIP_LEDS[TouchstripIndex]

    local Param = nil
    if IsMacro then
        local ParameterOwner = ParamCache:getFocusParameterOwner()
        local PageGroupParameter = App:getWorkspace():getPageGroupParameter()
        local PageParameter = ParamCache:getPageParameter()
        if ParameterOwner and PageGroupParameter and PageParameter then
            local PageValue = ParamCache:getValidPageParameterValue()
            local Parameter = ParameterOwner:getParameter(3, PageValue, TouchstripIndex - 1)
            Param = NI.DATA.ParameterCache.getActualParameter(Parameter)
        end
    else
        Param = ParamCache:getGenericParameter(TouchstripIndex - 1, true)
    end
    local CurrentValue = nil
    local ModulatedValue = nil
    local IsBipolar = false
    local IsInverted = false

    -- TAG_FORWARD is used in macros mainly
    if Param and Param:getTag() == NI.DATA.MaschineParameter.TAG_FORWARD then
        Param = Param:getParameter()
    end

    local Tag
    if Param ~= nil then
        Tag = Param:getTag()

        local IsSongLevelParameter = ParamCache:isSongLevel(Param)

        local HideParameter =
            (self.Controller:isShiftPressed() and not JamHelper.hasFineResolutionOnTouchstrip(Param))
            or (JamHelper.isAutoWriteEnabled() == true and (not Param:isAutomatable() or IsSongLevelParameter))
            or (Tag == NI.DATA.MaschineParameter.TAG_PLUGIN and not Param:isAssigned())

        if not HideParameter then

            if Tag == NI.DATA.MaschineParameter.TAG_BOOL then
                CurrentValue = Param:getValue() == true and #LEDs or 1
            elseif Tag == NI.DATA.MaschineParameter.TAG_ENUM then
                CurrentValue = TouchstripLEDs.value2Led(LEDs, 1 - Param:getNormalizedValue())
                IsInverted = true
            elseif MaschineHelper.isRoutingParam(Param) then
                local NumEntries = Param:getListSize()
                if NumEntries ~= 0 then
                    local NormalizedValue = Param:getValueAsIndex() / (NumEntries - 1)
                    CurrentValue = TouchstripLEDs.value2Led(LEDs, 1 - NormalizedValue)
                    IsInverted = true
                end
            else
                IsBipolar = Param:isBipolar()
                CurrentValue = TouchstripLEDs.getLedValue(LEDs, Param, TouchstripLEDs.TS_LED_DEFAULT)
            end

            ModulatedValue = Param:isModulated() and not IsSongLevelParameter and
                TouchstripLEDs.value2Led(LEDs,
                    IsInverted and (1 - MaschineHelper.getModulatedValueNormalized(Param)) or
                        MaschineHelper.getModulatedValueNormalized(Param))
        end
    end

    local WhiteLedId
    if Tag == NI.DATA.MaschineParameter.TAG_BOOL then
        WhiteLedId = function(LedId)
            local CenterLed = TouchstripLEDs.getCenterLed(LEDs)
            local LastLed   = #LEDs
            return CurrentValue and
                (LedId == LEDs[1] or
                     LedId == LEDs[CenterLed] or
                     LedId == LEDs[LastLed])
        end
    else
        WhiteLedId = CurrentValue and self.TOUCHSTRIP_LEDS[TouchstripIndex][CurrentValue] or nil
    end

    ObjectColor = self.getObjectColorFromTSMixingLayer()

    local LedStateFunctor = function(LedIndex)
        local IsBool = Tag == NI.DATA.MaschineParameter.TAG_BOOL
        return TouchstripLEDs.isLedOn(LEDs, CurrentValue, ModulatedValue, LedIndex, IsBipolar, IsInverted, IsBool, false)
    end

    TouchstripLEDs.updateTouchstripLEDs(LEDs, WhiteLedId, ObjectColor, LedStateFunctor)

end

------------------------------------------------------------------------------------------------------------------------

function TouchstripControlsJam:updateLEDsNotesMode(TouchstripIndex)

    local LEDs = self.TOUCHSTRIP_LEDS[TouchstripIndex]
    local Sound = NI.DATA.StateHelper.getFocusSound(App)
    local LedColor = Sound and Sound:getColorParameter():getValue()

    local Touched = self.Controller.TouchstripStates.Touched[TouchstripIndex]
    local Value = self.Controller.TouchstripStates.Value[TouchstripIndex]

    TouchstripLEDs.updateLEDsNotesMode(LEDs, Touched, Value, LedColor)
end

------------------------------------------------------------------------------------------------------------------------

function TouchstripControlsJam:updateLEDsTuneSwingMode(TouchstripIndex)

    local _, Object, ObjectColor = self.getMixingLayerData(TouchstripIndex, true)
    local Param = Object and self.getTuneOrSwingParameter(Object) or nil
    local LEDs  = self.TOUCHSTRIP_LEDS[TouchstripIndex]

    local ParamVisible = Param and (not JamHelper.isAutoWriteEnabled() or Param:isAutomatable())

    local CurrentValue = ParamVisible and TouchstripLEDs.getLedValue(LEDs, Param, TouchstripLEDs.TS_LED_DEFAULT) or nil
    local ModulatedValue = ParamVisible and Param:isModulated()
        and TouchstripLEDs.getLedValue(LEDs, Param, TouchstripLEDs.TS_LED_MODULATED) or nil

    local WhiteLedId = CurrentValue and LEDs[CurrentValue] or nil

    local LedStateFunctor = function(LedIndex)
        local IsBipolar =  Param and Param:isBipolar()
        return TouchstripLEDs.isLedOn(LEDs, CurrentValue, ModulatedValue, LedIndex, IsBipolar, false, false, false)
    end

    TouchstripLEDs.updateTouchstripLEDs(LEDs, WhiteLedId, ObjectColor, LedStateFunctor)

end

------------------------------------------------------------------------------------------------------------------------
-- Object needs to be a Group or a Sound
function TouchstripControlsJam.getTuneOrSwingParameter(Object)

    if JamHelper.getTouchstripMode() == NI.HW.TS_MODE_SWING then
        return Object:getSwingAmountParameter()
    elseif MaschineHelper.getLevelTab() == NI.HW.LEVEL_TAB_SOUND then
        return QuickEditHelper.getSoundTuneParam(Object)
    else
        return Object:getTuneOffsetParameter()
    end

end

------------------------------------------------------------------------------------------------------------------------

function TouchstripControlsJam.getMixingLayerData(TouchstripIndex, GroupOnly)

    local ObjectIdx, Object

    local LevelTab = MaschineHelper.getLevelTab()

    if LevelTab == NI.DATA.LEVEL_TAB_GROUP then

        ObjectIdx = TouchstripIndex + JamHelper.getGroupOffset()
        Object = MaschineHelper.getGroupAtIndex(ObjectIdx - 1)

    elseif LevelTab == NI.DATA.LEVEL_TAB_SOUND then

        ObjectIdx = TouchstripIndex + JamHelper.getSoundOffset()
        local FocusGroup = NI.DATA.StateHelper.getFocusGroup(App)
        Object = FocusGroup and FocusGroup:getSounds() and FocusGroup:getSounds():at(ObjectIdx - 1) or nil

    end

    return ObjectIdx, Object, Object and Object:getColorParameter():getValue()

end

------------------------------------------------------------------------------------------------------------------------

function TouchstripControlsJam:onTimer()

end

------------------------------------------------------------------------------------------------------------------------

function TouchstripControlsJam:onPress(TouchID, TouchType, Value)

end

------------------------------------------------------------------------------------------------------------------------

function TouchstripControlsJam.isLeftRightButtonsActive()

    local TSMode = JamHelper.getTouchstripMode()
    local LevelTab = MaschineHelper.getLevelTab()

    return (LevelTab == NI.DATA.LEVEL_TAB_SOUND and
                TSMode ~= NI.HW.TS_MODE_PERFORM and
                TSMode ~= NI.HW.TS_MODE_NOTES
                and not JamHelper.isStepModulationModeEnabled()) or
        TSMode == NI.HW.TS_MODE_CONTROL or
        TSMode == NI.HW.TS_MODE_MACRO

end


------------------------------------------------------------------------------------------------------------------------

function TouchstripControlsJam.isOutputMode(Mode)

    return Mode == NI.HW.TS_MODE_LEVEL or Mode == NI.HW.TS_MODE_PAN or
           Mode == NI.HW.TS_MODE_AUX1 or Mode == NI.HW.TS_MODE_AUX2

end

------------------------------------------------------------------------------------------------------------------------

function TouchstripControlsJam.canSongFocus()

    local TouchstripMode = JamHelper.getTouchstripMode()
    return TouchstripMode == NI.HW.TS_MODE_CONTROL or TouchstripMode == NI.HW.TS_MODE_MACRO

end


------------------------------------------------------------------------------------------------------------------------

function TouchstripControlsJam:onLeftRightButton(Right, Pressed)

    if self.isLeftRightButtonsActive() then

        if Pressed then

            local TouchstripMode = JamHelper.getTouchstripMode()
            if TouchstripMode == NI.HW.TS_MODE_CONTROL or TouchstripMode == NI.HW.TS_MODE_MACRO then

                local ParamCache = App:getStateCache():getParameterCache()
                local PageParam = ParamCache:getPageParameter()

                if PageParam then
                    local NumPages = ParamCache:getNumPagesOfFocusParameterOwner()
                    local NewIndex =
                        math.bound(ParamCache:getValidPageParameterValue() + (Right and 1 or -1), 0, NumPages - 1)

                    if NewIndex >= 0 then
                        NI.DATA.ParameterAccess.setSizeTParameter(App, PageParam, NewIndex)
                    end
                end

            else

                local SoundOffset = JamHelper.getSoundOffset()

                if Right then
                    if SoundOffset == 0 then
                        JamHelper.setSoundOffset(self.getNumTouchstrips())
                    end
                else
                    if SoundOffset == self.getNumTouchstrips() then
                        JamHelper.setSoundOffset(0)
                    end
                end

            end

        end

        return true

    end

    return false

end

------------------------------------------------------------------------------------------------------------------------
