local ParameterHelper = {
    FOCUSED_OWNER_PLUGIN = "FOCUSED_OWNER_PLUGIN",
    FOCUSED_OWNER_PERFORM_SCALE = "FOCUSED_OWNER_PERFORM_SCALE",
    FOCUSED_OWNER_PERFORM_ARP = "FOCUSED_OWNER_PERFORM_ARP"
}

------------------------------------------------------------------------------------------------------------------------

function ParameterHelper.getDisplayName(Parameter)

    if not Parameter then
        return ""
    end

    local ParameterDisplayName = Parameter:getDisplayName() or ""
    return ParameterDisplayName == "" and Parameter:getParameterInterface():getName() or ParameterDisplayName

end

------------------------------------------------------------------------------------------------------------------------

function ParameterHelper.getDisplayValueUnitPair(Parameter)

    if not Parameter then
        return "", ""
    end

    local DisplayValue = Parameter.CustomValue ~= "" and Parameter.CustomValue
        or NI.GUI.ParameterWidgetHelper.getValueString(Parameter, MaschineHelper.isAutoWriting())
        or ""

    return NI.GUI.ParameterWidgetHelper.getValueUnitPair(DisplayValue)

end

------------------------------------------------------------------------------------------------------------------------

function ParameterHelper.getDisplayStrings(Parameter)

    local ParameterDisplayName = ParameterHelper.getDisplayName(Parameter)
    local ValueText, UnitText = ParameterHelper.getDisplayValueUnitPair(Parameter)
    return ParameterDisplayName, ValueText, UnitText

end

------------------------------------------------------------------------------------------------------------------------


function ParameterHelper.getSectionNames(getSectionNameForParameterAtPosition)

    local SectionNames = {}

    for ParamPos = 1, NI.DATA.CONST_PARAMETERS_PER_PAGE do

        local Section = getSectionNameForParameterAtPosition(ParamPos) or ""

        if Section ~= "" then
            SectionNames[ParamPos] = Section
        elseif ParamPos > 1 then
            -- save the previous section name b/c they're only given with the first parameter of the section.
            SectionNames[ParamPos] = SectionNames[ParamPos-1]
        end

    end

    return SectionNames

end

------------------------------------------------------------------------------------------------------------------------

return ParameterHelper