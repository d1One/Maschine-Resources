
local class = require 'Scripts/Shared/Helpers/classy'
ParameterHelper = class( 'ParameterHelper' )

----------------------------------------------------------------------------------------------------

function ParameterHelper.setupFocusModuleParameters(ParameterHandler)

    local Params = {}
    ParameterHandler.NumPages = 0
    ParameterHandler.PageIndex = 0

    local Level = MaschineHelper.getLevelTab()

    local ParamOwner = NI.DATA.StateHelper.getFocusSong(App)

    if Level == NI.DATA.LEVEL_TAB_GROUP then
        ParamOwner = NI.DATA.StateHelper.getFocusGroup(App)
    elseif Level == NI.DATA.LEVEL_TAB_SOUND then
        ParamOwner = NI.DATA.StateHelper.getFocusSound(App)
    end

    local FocusSlot = ParamOwner:getChain():getSlots():getFocusObject()
    local Module = FocusSlot and FocusSlot:getModule()
    if Module then

        local Plugin = FocusSlot:getPluginHost()
        local PageParameter = Plugin and Plugin:getPageParameter() or App:getWorkspace():getModulePageParameter(Module)
        local PageIndex = PageParameter and PageParameter:getValue() or 0

        ParameterHandler.PageIndex = PageIndex + 1
        ParameterHandler.NumPages = Module:getNumPages(0)

        for Index = 1, 8 do
            Params[Index] = Module:getParameter(0, PageIndex, Index-1)
            NI.HW.setCachedParameter(App, Index-1, Params[Index])
        end

        ParameterHandler.PrevNextPageFunc =
            function (Inc)
                NI.DATA.ParameterAccess.setSizeTParameter(App, PageParameter, PageParameter:getValue() + Inc)
            end
    end

    ParameterHandler:setParameters(Params, true)

    return Params
end

----------------------------------------------------------------------------------------------------

function ParameterHelper.setupMaschineScaleParameters(ParameterHandler)

    local Params = {}

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local ScaleEngine = NI.DATA.getScaleEngine(App)
    local Group = NI.DATA.StateHelper.getFocusGroup(App)

    if ScaleEngine and Group then

        Params =
        {
            ScaleEngine:getRootNoteParameter(),
            not ScaleEngine:getChordModeIsChordSet() and ScaleEngine:getScaleBankParameter() or nil,
            not ScaleEngine:getChordModeIsChordSet() and ScaleEngine:getScaleParameter() or nil,
            not ScaleEngine:getChordModeIsChordSet() and NI.HW.getScaleEngineKeyModeParameter(App) or nil,
            ScaleEngine:getChordModeParameter(),
            ScaleEngine:getChordModeParameter():getValue() ~= 0 and ScaleEngine:getChordTypeAutomationParameter() or nil,
            ScaleEngine:getChordModeParameter():getValue() ~= 0 and ScaleEngine:getChordPositionParameter() or nil
        }

    end

    ParameterHandler:setParameters(Params, true)

    for Index = 1, 8 do
        NI.HW.setCachedParameter(App, Index-1, Params[Index])
    end

    return Params
end

----------------------------------------------------------------------------------------------------

function ParameterHelper.setupMaschineArpParameters(ParameterHandler)

    local Params = {}
    local Sections = {}

    local Arpeggiator = NI.DATA.getArpeggiator(App)
    if not Arpeggiator then
        return {}
    end

    if not MaschineHelper.isDrumkitMode() then
        ParameterHandler.NumPages = 2

        if ParameterHandler.PageIndex == 1 then

            -- Group names
            Sections[2] = "Main"
            Sections[3] = "Rhythm"
            Sections[6] = "Other"

            -- Parameters
            Params[2] = Arpeggiator:getTypeParameter()
            Params[3] = NI.DATA.getArpeggiatorRateParameter(App)
            Params[4] = NI.DATA.getArpeggiatorRateUnitParameter(App)
            Params[5] = Arpeggiator:getSequenceParameter()
            Params[6] = Arpeggiator:getOctavesParameter()
            Params[7] = Arpeggiator:getDynamicParameter()
            Params[8] = Arpeggiator:getGateParameter()
        else
            -- Group names
            Sections[1] = "Advanced"
            Sections[5] = "Range"

            -- Parameters
            Params[1] = Arpeggiator:getRetriggerParameter()
            Params[2] = Arpeggiator:getRepeatParameter()
            Params[3] = Arpeggiator:getOffsetParameter()
            Params[4] = Arpeggiator:getInversionParameter()
            Params[5] = Arpeggiator:getMinKeyParameter()
            Params[6] = Arpeggiator:getMaxKeyParameter()
        end

        Sections[8] = ""

    else
        ParameterHandler.NumPages = 1

        -- Group names
        Sections[3] = "Rhythm"
        Sections[8] = "Other"

        -- Parameters
        Params[3] = NI.DATA.getArpeggiatorRateParameter(App)
        Params[4] = NI.DATA.getArpeggiatorRateUnitParameter(App)
        Params[8] = Arpeggiator:getGateParameter()

    end

    ParameterHandler:setParameters(Params, true)
    ParameterHandler:setCustomSections(Sections)

    for Index = 1, 8 do
        NI.HW.setCachedParameter(App, Index-1, Params[Index])
    end

    return Params
end
