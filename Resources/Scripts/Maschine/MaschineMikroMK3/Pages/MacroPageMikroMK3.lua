------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/MaschineMikroMK3/Pages/PageMikroMK3"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
MacroPageMikroMK3 = class( 'MacroPageMikroMK3', PageMikroMK3 )

------------------------------------------------------------------------------------------------------------------------

function MacroPageMikroMK3:__init(Controller)

    PageMikroMK3.__init(self, "MacroPageMikroMK3", Controller)

end

------------------------------------------------------------------------------------------------------------------------

function MacroPageMikroMK3:setupScreen()

    PageMikroMK3.setupScreen(self)

    self.Screen:showParameterInBottomRow()

end

------------------------------------------------------------------------------------------------------------------------

function MacroPageMikroMK3:updateScreen()

    local Name, Value = self:getParameterText()
    local Title = self:getSectionName()

    if Title == "" then
        -- use the page name if there's no section name
        Title = NI.DATA.ParameterCache.getFocusedMixingLayerPageName(App)
    end

    self.Screen
        :setTopRowText(Title)
        :setParameterName(Name)
        :setParameterValue(Value)

end

------------------------------------------------------------------------------------------------------------------------

function MacroPageMikroMK3:getParameterText()

    local Name, Value = "", ""
    local ActualParameter = NI.DATA.ParameterCache.getFocusedParameter(App, true)

    if ActualParameter then

        -- parameter name
        Name = NI.GUI.ParameterWidgetHelper.getParameterName(ActualParameter)

        -- parameter value
        Value = NI.GUI.ParameterWidgetHelper.getValueString(ActualParameter, MaschineHelper.isAutoWriting())

	end

    if Name == "" then
        Name = NI.DATA.ParameterPageAccess.isMacroPageActive(App) and "No Macro" or "No Parameter"
    end

    return Name, Value

end

------------------------------------------------------------------------------------------------------------------------

function MacroPageMikroMK3:getSectionName()

    local ParamCache = App:getStateCache():getParameterCache()
    local ParamPosition = ParamCache:getFocusParameterPosition()
    if ParamPosition == NPOS then
        return ""
    end

    local SectionName = ""
    for Idx = ParamPosition, 0, -1 do
        local Parameter = ParamCache:getGenericParameter(Idx, false)
        SectionName = Parameter and Parameter:getSectionName() or ""
        if SectionName ~= "" then
            return SectionName
        end
    end

    return ""

end

------------------------------------------------------------------------------------------------------------------------

function MacroPageMikroMK3:onWheelEvent(Value)
    -- do nothing as macro parameters are handled as realtime encoder events
end

------------------------------------------------------------------------------------------------------------------------
