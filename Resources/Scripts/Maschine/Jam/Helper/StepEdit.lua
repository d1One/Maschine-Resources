require "Scripts/Shared/Helpers/LedHelper"
require "Scripts/Shared/Helpers/PadModeHelper"
require "Scripts/Shared/Helpers/MiscHelper"
require "Scripts/Shared/Helpers/QuickEditHelper"
require "Scripts/Maschine/Jam/Helper/JamHelper"
require "Scripts/Maschine/Jam/Helper/JamStepHelper"

------------------------------------------------------------------------------------------------------------------------
-- StepEdit: Is responsible for the Step Modulation and Step Quick-Edit features
------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
StepEdit = class( 'StepEdit' )

------------------------------------------------------------------------------------------------------------------------

function StepEdit:__init(Controller)

    self.Controller = Controller

    self.HoldingPads = {}
    self.ModTimeDeltaMap = TickFloatMap()

end

------------------------------------------------------------------------------------------------------------------------

function StepEdit:reset()

    self.ModTimeDeltaMap:clear()
    MiscHelper.resetTable(self.HoldingPads)

end

------------------------------------------------------------------------------------------------------------------------

function StepEdit:updateHoldingPads(Row, Column, StepTime, Pressed)

    local PadInfo = {Row, Column, StepTime, StepTime}   -- 4th value is time's end (Hawking was wrong)
    MiscHelper.updateTable(self.HoldingPads, JamControllerBase.PAD_BUTTONS[Row][Column], PadInfo, Pressed)

    self:updateHoldingPadsTimeEnd()

end

------------------------------------------------------------------------------------------------------------------------

function StepEdit:updateHoldingPadsTimeEnd()

    local Sequence = NI.DATA.StateHelper.getFocusSoundSequence(App)
    if not Sequence then
        return
    end

    local Grid = StepHelper.getPatternEditorSnapInTicks()

    for PadId, PadInfo in pairs(self.HoldingPads) do
        local EventTime = StepHelper.getEventTimeFromStepTime(PadInfo[3])
        local Length = NI.DATA.SequenceAlgorithms.getMaxSelectedNoteEventEndPosInRange(Sequence, EventTime,
            EventTime + Grid - 1)

        PadInfo[4] = Length -- time end
        self.HoldingPads[PadId] = PadInfo
    end

end

------------------------------------------------------------------------------------------------------------------------

function StepEdit:getHoldingPadsSize()

    return MiscHelper.getTableSize(self.HoldingPads)

end

------------------------------------------------------------------------------------------------------------------------

function StepEdit:setStepModulationMode(Enable)

    local StepModulationParameter = NHLController:getContext():getStepModulationModeParameter()
    NI.DATA.ParameterAccess.setBoolParameterNoUndo(App, StepModulationParameter, Enable)

    if not Enable then
        self:reset()
    end

end

------------------------------------------------------------------------------------------------------------------------

function StepEdit:getRowFromHoldingPads()

    for _, PadInfo in pairs(self.HoldingPads) do
        return PadInfo[1]
    end

    return -1

end

------------------------------------------------------------------------------------------------------------------------

function StepEdit:enableQuickEditMode(Enable, ExplicitMode)

    local TouchstripMode = JamHelper.getTouchstripMode()
    local StepModMode = JamHelper.isStepModulationModeEnabled()
    local QEMode = NI.HW.QUICK_EDIT_NONE

    if Enable then
        QEMode = ExplicitMode ~= nil
            and ExplicitMode
            or  NI.DATA.JamControllerContext.getQuickEditModeByTouchstripMode(TouchstripMode)
    end

    JamHelper.setQuickEditMode(QEMode)

    self:updateHoldingPadsTimeEnd()

    return QEMode ~= NI.HW.QUICK_EDIT_NONE

end

------------------------------------------------------------------------------------------------------------------------

function StepEdit:onWheelEvent(Inc)

    if JamHelper.isQuickEditModeEnabled() then

        -- do quick edit mode function
        local QEMode = JamHelper.getQuickEditMode()
        local JogwheelMode = JamStepHelper.QuickEditModeToJogwheelMode(QEMode)

        if JogwheelMode ~= NI.HW.JOGWHEEL_MODE_OFF then
            if JogwheelMode == NI.HW.JOGWHEEL_MODE_LENGTH then
                EventsHelper.modifySelectedNoteEvents(Inc > 0 and 1 or -1, 0, 0, false)
                self:updateHoldingPadsTimeEnd()
            else
                NI.DATA.EventPatternAccess.modifySelectedNotesByJogWheel(App, JogwheelMode, Inc)
            end
            return true
        end

    end

    return false

end

------------------------------------------------------------------------------------------------------------------------

function StepEdit:onTouchEvent(TouchID, TouchType, Value)

    if not JamHelper.isStepModulationModeEnabled() then
        return false
    end

    if TouchType == JamControllerBase.TOUCH_EVENT_TOUCHED or TouchType == JamControllerBase.TOUCH_EVENT_MOVED then

        local Parameter = self:getStepModParamFromTouchID(TouchID + 1)

        if Parameter and Parameter:isAutomatable() then

            local ValueMapped = 0

            if self.Controller:isShiftPressed() then

                local StepValue = self:getStepModulationValue(Parameter) or Parameter:getNormalizedValue()
                local Diff = self.Controller.TouchstripStates.Delta[TouchID + 1]

                Diff = Diff and Diff or 0
                ValueMapped = (StepValue + Diff * 0.1) * 2 - 1

            else
                if Parameter:getTag() == NI.DATA.MaschineParameter.TAG_ENUM then
                    Value = 1 - Value
                end
                ValueMapped = Value * 2 - 1  --map touchstrip range 0..1 to mod range -1..1
            end

            self.ModTimeDeltaMap:clear()

            local StepRangeWidth = StepHelper.getStepRangeWidth()

            for _, PadInfo in pairs(self.HoldingPads) do
                local StepTime = PadInfo[3]
                if StepTime ~= nil and StepTime < StepRangeWidth then
                    local EventTime = StepHelper.getEventTimeFromStepTime(StepTime)
                    STLHelper.setKeyValue(self.ModTimeDeltaMap, EventTime, ValueMapped)
                end
            end

            NI.DATA.ModulationEditingAccess.setModulationStep(App, self.ModTimeDeltaMap, Parameter, true)
        end

    end

    return true

end

------------------------------------------------------------------------------------------------------------------------

function StepEdit:getStepModParamFromTouchID(TouchID)

    local LevelTab = MaschineHelper.getLevelTab()
    local TouchstripMode = JamHelper.getTouchstripMode()
    local ParamCache = App:getStateCache():getParameterCache()
    local Parameter, Object = nil

    if TouchstripMode ~= NI.HW.TS_MODE_CONTROL and TouchstripMode ~= NI.HW.TS_MODE_MACRO then
        if TouchID > 1 then
            return nil
        else
            if LevelTab == NI.DATA.LEVEL_TAB_GROUP then
                Object = NI.DATA.StateHelper.getFocusGroup(App)
            elseif LevelTab == NI.DATA.LEVEL_TAB_SOUND then
                Object = NI.DATA.StateHelper.getFocusSound(App)
            end
        end
    else
        _, Object, _ = TouchstripControlsJam.getMixingLayerData(TouchID)
    end

    if TouchstripMode == NI.HW.TS_MODE_CONTROL then

        Parameter = ParamCache:getGenericParameter(TouchID - 1, true)

    elseif TouchstripMode == NI.HW.TS_MODE_MACRO then

        local ParameterOwner = ParamCache:getFocusParameterOwner()
        local PageGroupParameter = App:getWorkspace():getPageGroupParameter()
        local PageParameter = ParamCache:getPageParameter()

        if ParameterOwner and PageGroupParameter and PageParameter then
            local PageValue = ParamCache:getValidPageParameterValue()
            local Param = ParameterOwner:getParameter(3, PageValue, TouchID - 1)
            Parameter = NI.DATA.ParameterCache.getActualParameter(Param)
        end

    elseif TouchstripMode == NI.HW.TS_MODE_TUNE then

        if LevelTab == NI.DATA.LEVEL_TAB_SOUND then
            Parameter = QuickEditHelper.getSoundTuneParam(Object)
        end

    elseif TouchstripMode == NI.HW.TS_MODE_SWING then

        Parameter = Object and Object:getSwingAmountParameter() or nil

    elseif TouchstripMode == NI.HW.TS_MODE_LEVEL then

        Parameter = Object and Object:getLevelParameter() or nil

    elseif TouchstripMode == NI.HW.TS_MODE_PAN then

        Parameter = Object and Object:getPanParameter() or nil

    elseif TouchstripMode == NI.HW.TS_MODE_AUX1 then

         Parameter = Object and Object:getAux1LevelParameter() or nil

    elseif TouchstripMode == NI.HW.TS_MODE_AUX2 then

        Parameter = Object and Object:getAux2LevelParameter() or nil

    end

    if Parameter then
        Tag = Parameter:getTag()
        if (self.Controller:isShiftPressed()
           and (Tag == NI.DATA.MaschineParameter.TAG_BOOL or Tag == NI.DATA.MaschineParameter.TAG_ENUM))
           or not Parameter:isAutomatable() then
            Parameter = nil
        end
    end

    return Parameter

end

------------------------------------------------------------------------------------------------------------------------

function StepEdit:getStepModulationValue(Parameter)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Pattern = NI.DATA.StateHelper.getFocusEventPattern(App)

    if Song and Pattern then

        local LevelTab = MaschineHelper.getLevelTab()
        local Sequence = nil
        local StepRangeWidth = StepHelper.getStepRangeWidth()

        if LevelTab == NI.DATA.LEVEL_TAB_SOUND then
            local Sound = NI.DATA.StateHelper.getFocusSound(App)
            Sequence = Sound and Pattern:getSoundSequence(Sound) or nil
        elseif LevelTab == NI.DATA.LEVEL_TAB_GROUP then
            local Group = NI.DATA.StateHelper.getFocusGroup(App)
            Sequence = Group and Pattern:getGroupSequence() or nil
        end

        local ModEventTime = nil
        local LastStepPadIdx = 0

        for PadIdx, PadInfo in pairs(self.HoldingPads) do
            local StepTime = PadInfo[3]
            if PadIdx > LastStepPadIdx and StepTime < StepRangeWidth then
                LastStepPadIdx = PadIdx
                ModEventTime = StepHelper.getEventTimeFromStepTime(StepTime)
            end
        end

        local ParamEvent = Parameter and Sequence and ModEventTime
            and NI.DATA.ModulationEditingAccess.getModulationParamEvent(Sequence, ModEventTime, Parameter)
            or nil

        return ParamEvent and (ParamEvent:getModulationDelta() / 2 + 0.5) or nil
    end
end

------------------------------------------------------------------------------------------------------------------------

function StepEdit:getPadInfo(Row, Column)

    for _, PadInfo in pairs(self.HoldingPads) do
        if PadInfo[1] == Row and PadInfo[2] == Column then
            return PadInfo
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function StepEdit:isPadHeld(Row, Column)

    return self:getPadInfo(Row, Coumn) and true or false

end

------------------------------------------------------------------------------------------------------------------------

function StepEdit:isPadInRowHeld(Row)

    for _, PadInfo in pairs(self.HoldingPads) do
        if PadInfo[1] == Row then
            return true
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function StepEdit:isPadHeldAndInPattern(Row, Column)

    local StepRangeWidth = StepHelper.getStepRangeWidth()

    local PadInfo = self:getPadInfo(Row, Column)
    return (PadInfo and PadInfo[3] < StepRangeWidth)

end

------------------------------------------------------------------------------------------------------------------------

