require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Shared/Helpers/ScreenHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
ParameterHandler = class( 'ParameterHandler' )

-- We can't rely on #self.Parameters to get the proper size
local MAX_NUMBER_OF_PARAMS_PER_PAGE = 8
local SHOW_PAGE_NUMBER_DURATION = 20
local ATTR_EMPTY = NI.UTILS.Symbol("empty")


------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function ParameterHandler:__init()

    self.Parameters = {}
    self.CustomSections = {}
    self.CustomNames = {}
    self.CustomValues = {}

    self.ParameterWidgets = {}
    self.SectionWidgets = {}

    self.NumPages = 1
    self.PageIndex = 1

    -- global undo flag (assuming undo properties being the same for one page)
    self.Undoable = true
    self.UseNoParamsCaption = true

    self.PrevNextPageFunc = nil

    self.ForceShowPageNumberCountdown = 0
    self.NumParamsPerPage = MAX_NUMBER_OF_PARAMS_PER_PAGE

end

------------------------------------------------------------------------------------------------------------------------
-- setup
------------------------------------------------------------------------------------------------------------------------

function ParameterHandler:setup(PageNames, ParameterWidgets)

    -- parameter page name widgets
    self.SectionWidgets = PageNames

    -- parameter widgets
    self.ParameterWidgets = ParameterWidgets

    self.NumPages = 1
    self.PageIndex = 1

end

------------------------------------------------------------------------------------------------------------------------

function ParameterHandler:setCustomSections(Sections)

    self.CustomSections = Sections
end

------------------------------------------------------------------------------------------------------------------------

function ParameterHandler:setCustomSection(Index, Section)

    self.CustomSections[Index] = Section
end

------------------------------------------------------------------------------------------------------------------------

function ParameterHandler:setCustomNames(Names)

    self.CustomNames = Names
end

------------------------------------------------------------------------------------------------------------------------

function ParameterHandler:setCustomName(Index, Name)

    self.CustomNames[Index] = Name
end

------------------------------------------------------------------------------------------------------------------------

function ParameterHandler:setCustomValues(Values)

    self.CustomValues = Values

end

------------------------------------------------------------------------------------------------------------------------

function ParameterHandler:setValueAttribute(Index, Attribute, Value)

    self.ParameterWidgets[Index].Value:setAttribute(Attribute, Value)

end

------------------------------------------------------------------------------------------------------------------------

function ParameterHandler:setCustomValue(Index, Value)

    self.CustomValues[Index] = Value

end

------------------------------------------------------------------------------------------------------------------------

function ParameterHandler:setParameters(Parameters, Undoable)

    -- We need to set ShowPageNumber to true when page parameters change
    if not MaschineHelper.areParameterListsEqual(self.Parameters, Parameters or {}, MAX_NUMBER_OF_PARAMS_PER_PAGE) then
        self.ForceShowPageNumberCountdown = SHOW_PAGE_NUMBER_DURATION
    end

    -- parameters
    self.Parameters = Parameters

    self.CustomNames = {}
    self.CustomValues = {}

    -- undo flag
    if Undoable ~= nil then
        self.Undoable = Undoable
    end
end

------------------------------------------------------------------------------------------------------------------------

function ParameterHandler:getParameterInfo(Index)

    local Param = self.Parameters[Index]

    if Param and Param.getValue and (Param:getTag() ~= NI.DATA.MaschineParameter.TAG_PLUGIN or Param:isAssigned()) then
        local Info = {}
        Info.Value = Param:getValue()

        Info.SpeechSectionName = NI.APP.FEATURE.ACCESSIBILITY and self:getPreviousSectionName(Index) or ""
        Info.SpeechName = NI.APP.FEATURE.ACCESSIBILITY and NI.ACCESSIBILITY.getMessageForParameterName(Param) or ""
        Info.SpeechValue = NI.APP.FEATURE.ACCESSIBILITY and NI.ACCESSIBILITY.getMessageForParameterValue(Param) or ""

        return Info
    end

    return nil

end

------------------------------------------------------------------------------------------------------------------------

function ParameterHandler:getSectionName(Index)

    local Param = self.Parameters[Index]
    local ParamSectionName = Param and Param:getSectionName() or ""
    local CustomSectionName = self.CustomSections[Index] and self.CustomSections[Index] ~= "" and self.CustomSections[Index]
    
    return CustomSectionName or ParamSectionName

end

------------------------------------------------------------------------------------------------------------------------

function ParameterHandler:getPreviousSectionName(Index)

    for ParamIndex = Index, 1, -1 do
        local SectionName = self:getSectionName(ParamIndex)
        if SectionName ~= "" then
            return SectionName
        end
    end

    return ""

end

------------------------------------------------------------------------------------------------------------------------
-- update
------------------------------------------------------------------------------------------------------------------------

function ParameterHandler:update(ForceUpdate)

    if ForceUpdate then
        self.ForceShowPageNumberCountdown = SHOW_PAGE_NUMBER_DURATION
    end

    self:updateSectionNames()
    self:updateParamWidgets()

end

------------------------------------------------------------------------------------------------------------------------

function ParameterHandler:updateParamWidgets()

    for Index = 1, #self.ParameterWidgets do
        self:updateParamWidget(Index)
    end

end

------------------------------------------------------------------------------------------------------------------------

function ParameterHandler:updateParamWidget(Index)

    ParamWidget = self.ParameterWidgets[Index]

    if ParamWidget then

        NameText = self.CustomNames[Index] ~= "" and self.CustomNames[Index] or
            self.Parameters[Index] and NI.GUI.ParameterWidgetHelper.getParameterName(self.Parameters[Index]) or ""

        NameText = string.upper(NameText)

        ValueText, UnitText = NI.GUI.ParameterWidgetHelper.getValueUnitPair(
            self.CustomValues[Index] ~= "" and self.CustomValues[Index] or
            self.Parameters[Index] and NI.GUI.ParameterWidgetHelper.getValueString(self.Parameters[Index], MaschineHelper.isAutoWriting()) or
            "")

        ParamWidget:setName(NameText)
        ParamWidget:setValue(ValueText)
        ParamWidget:setUnit(UnitText)
        ParamWidget:setAttribute(ATTR_EMPTY, ParamWidget:isEmpty() and "true" or "false")

        if NI.APP.FEATURE.MODULATION then
            local ParamCache = App:getStateCache():getParameterCache()
            local ActualParam = self.Parameters[Index] and NI.DATA.ParameterCache.getActualParameter(self.Parameters[Index])
            ParamWidget:setModulated(ParamCache and ActualParam and ParamCache:isAutomated(ActualParam) or false)
        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function ParameterHandler:updateSectionNames()

	-- Parameter page/section name and number

    if self.ParameterWidgets[1] == nil or self.SectionWidgets[1] == nil then
        return
    end

    local EmptyPage = self.NumPages > 0
    local PreviousSectionName

    for Index = 1, self.NumParamsPerPage do

        local SectionName = self:getSectionName(Index)

        if self.SectionWidgets[Index] then
            if SectionName ~= PreviousSectionName then
                self.SectionWidgets[Index]:setText(SectionName)
                PreviousSectionName = SectionName
            else
                self.SectionWidgets[Index]:setText("")
            end
        end

        if self.Parameters[Index] or (self.CustomNames[Index] and self.CustomNames[Index] ~= "") then
            EmptyPage = false
        end
    end

    if EmptyPage and self.UseNoParamsCaption then
        self.SectionWidgets[1]:setText("NO PARAMETERS")
    end

    local LastParam = self.Parameters[self.NumParamsPerPage]
    local LastSection = self.CustomSections[self.NumParamsPerPage] or LastParam and LastParam:getSectionName()
    local ShowPageNumbers = self.NumPages > 1 and (LastSection == nil or LastSection == "" or self.ForceShowPageNumberCountdown > 0)

    -- DISPLAY PAGE
    if ShowPageNumbers then

        local PageNumber = tostring(self.PageIndex) .. "/" .. tostring(self.NumPages)
        self.SectionWidgets[self.NumParamsPerPage]:setText(PageNumber)

    -- DISPLAY LAST SECTION NAME
    elseif LastSection then
        self.SectionWidgets[self.NumParamsPerPage]:setText(LastSection)
    end

    -- deals with expanding section widgets to empty neighbours
    ScreenHelper.setWidgetSpan(self.SectionWidgets, 1, 4, self.NumParamsPerPage == 4 and ShowPageNumbers)
    ScreenHelper.setWidgetSpan(self.SectionWidgets, 5, 8, self.NumParamsPerPage == 8 and ShowPageNumbers)
end

------------------------------------------------------------------------------------------------------------------------

function ParameterHandler:onControllerTimer()

    if self.ForceShowPageNumberCountdown > 0 then
        self.ForceShowPageNumberCountdown = self.ForceShowPageNumberCountdown - 1
        if self.ForceShowPageNumberCountdown == 0 then
            self:update(false)
        end
    end
end

------------------------------------------------------------------------------------------------------------------------
-- event handling
------------------------------------------------------------------------------------------------------------------------

function ParameterHandler:onScreenEncoder(KnobIdx, EncoderInc, FineResolution)

    if NHLController:getEncoderMode() ~= NI.HW.ENC_MODE_NONE then
        return
    end

    -- We need to search for the param because KnobIdx and ParamIdx
    -- can differ (since RangeParameters need two knobs)

    local ParamIndex = 1
    local RangeParamMin = false
    local Param = nil

    -- Recognize if parameter is a RangeParameter and if it's the first of the two parameters in RangeParameter
    for Index = 1, KnobIdx do

        Param = self.Parameters[ParamIndex]

        if Param and Param:getTag() == NI.DATA.MaschineParameter.TAG_RANGE and not RangeParamMin then
            RangeParamMin = true
        else
            RangeParamMin = false
            ParamIndex = ParamIndex + 1
        end

    end

    -- get respective parameter from RangeParameter
    if Param and Param:getTag() == NI.DATA.MaschineParameter.TAG_RANGE then
        Param = RangeParamMin and Param:getMinParameter() or Param:getMaxParameter()
    end

    -- Set new value to parameter
    if Param then
        if NI.APP.FEATURE.UNDO_REDO then
            NI.DATA.ParameterAccess.addParameterEncoderDelta(App, Param, EncoderInc, FineResolution, self.Undoable)
        else
            NI.DATA.ParameterAccess.addParameterEncoderDelta(App, Param, EncoderInc, FineResolution)
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function ParameterHandler:onPrevNextParameterPage(Increment)

    if self.PrevNextPageFunc then
        self.PrevNextPageFunc(Increment)
    else
        self.PageIndex = math.bound(self.PageIndex + Increment, 1, self.NumPages)
    end

end

------------------------------------------------------------------------------------------------------------------------

function ParameterHandler:enableCropModeForName(Index)

    NI.GUI.enableCropModeForLabel(self.ParameterWidgets[Index].Name)

end

------------------------------------------------------------------------------------------------------------------------

