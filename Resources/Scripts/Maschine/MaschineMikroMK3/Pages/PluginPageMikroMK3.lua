------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/MaschineMikroMK3/Pages/PageMikroMK3"
require "Scripts/Shared/Helpers/ModuleHelper"
require "Scripts/Maschine/Helper/ModuleHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
PluginPageMikroMK3 = class( 'PluginPageMikroMK3', PageMikroMK3 )

------------------------------------------------------------------------------------------------------------------------

function PluginPageMikroMK3:__init(Controller)

    PageMikroMK3.__init(self, "PluginPageMikroMK3", Controller)

    self:resetSectionNames()

    -- Variables to show invalid state of Mikro's single-focused parameter, which can happen with a number of use-cases.
    -- Our usage of MASCHINE::DATA::ParameterCache needs a refactor to solve this properly.
    self.ResetFocusParameterIndex = false
    self.ResetFocusParameterPage = false

end

------------------------------------------------------------------------------------------------------------------------

function PluginPageMikroMK3:onShow(Show)

    if not Show then
        self:resetSectionNames()
    end

    PageMikroMK3.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function PluginPageMikroMK3:resetSectionNames()

    self.SectionNames = {}

end

------------------------------------------------------------------------------------------------------------------------

local function isParameterEditMode()

    local ModeParameter = NHLController:getContext():mikroMk3():getPluginPageIsEditingParametersParameter()
    return ModeParameter and ModeParameter:getValue()

end

------------------------------------------------------------------------------------------------------------------------

function PluginPageMikroMK3:onControllerTimer()

    if isParameterEditMode() and App:getStateCache():getParameterCache():getNumPagesOfFocusedModule() == 0 then

        -- Page mode should switch to Plugin-Browse mode (e.g. if the focused slot becomes empty)
        NI.DATA.ParameterAccess.toggleBoolParameterNoUndo(App,
            NHLController:getContext():mikroMk3():getPluginPageIsEditingParametersParameter())

    elseif self.ResetFocusParameterPage or self.ResetFocusParameterIndex then

        -- Reset focused parameter when old focus becomes invalid
        self:resetFocusParameter()

    end

end

------------------------------------------------------------------------------------------------------------------------

function PluginPageMikroMK3:resetFocusParameter()

    local ParamCache = App:getStateCache():getParameterCache()
    local PageParam = ParamCache:getModulePageParameter()

    local PageIdx = self.ResetFocusParameterPage and 0 or (PageParam and ParamCache:getModulePageParameter():getValue())
    local ParamIdx = self.ResetFocusParameterIndex and 0 or ParamCache:getFocusedModuleParameterPosition()

    self.ResetFocusParameterPage = false
    self.ResetFocusParameterIndex = false

    NI.DATA.ParameterPageAccess.setPageAndFocusParameterIndex(App, PageIdx, ParamIdx)

end

------------------------------------------------------------------------------------------------------------------------

function PluginPageMikroMK3:checkFocusParameterValidity()

    local ParamCache = App:getStateCache():getParameterCache()
    if ParamCache:getModulePageParameter() then

        local ParamPosition = ParamCache:getFocusedModuleParameterPosition()
        local Parameter = NI.DATA.ParameterCache.getFocusedModuleParameter(App)
        local FocusPage = ParamCache:getModulePageParameter():getValue()
        local NumPages = App:getStateCache():getParameterCache():getNumPagesOfFocusedModule()

        self.ResetFocusParameterIndex = not Parameter
        self.ResetFocusParameterPage = FocusPage ~= NPOS and FocusPage >= NumPages

    end

end

------------------------------------------------------------------------------------------------------------------------

function PluginPageMikroMK3:updateScreen()

    if isParameterEditMode() then
        self:updateScreenFocusParameter()
    else
        self:updateScreenFocusModule()
    end

end

------------------------------------------------------------------------------------------------------------------------

function PluginPageMikroMK3:updateScreenFocusParameter()

    self:checkFocusParameterValidity()
    self:updateSectionNames()

    local Name, Value, SectionName = self:getParameterText()

    self.Screen
        :setTopRowIcon("")
        :setBottomRowIcon("")
        :setTopRowText(SectionName)
        :showParameterInBottomRow()
        :setParameterName(Name)
        :setParameterValue(Value)

end

------------------------------------------------------------------------------------------------------------------------

function PluginPageMikroMK3:updateScreenFocusModule()

    self.Screen:setTopRowToFocusedObject()
    self.Screen:showTextInBottomRow()

    -- empty
    local Slot = NI.DATA.StateHelper.getFocusSlot(App)
    if not Slot then
        self.Screen:setBottomRowText("Empty")
        self.Screen:setBottomRowIcon("")
        return
    end

    local FocusedSlotName = MaschineHelper.getFocusSlotName()
    self.Screen:setBottomRowText(FocusedSlotName)

    -- missing plugin
    if ModuleHelper.isSlotMissing(Slot) then
        self.Screen:setBottomRowIcon("missing")
        return
    end

    -- touched
    if self.Controller:isButtonPressed(NI.HW.BUTTON_WHEEL_TOUCH) then
        self.Screen:setBottomRowIcon("button_touched")
        return
    end

    -- instrument / effect
    local Suffix = Slot:getActiveParameter():getValue() and "" or "_bypassed"
    local SlotIcon = ModuleHelper.isSlotFX(Slot) and "effect"..Suffix or "instrument"..Suffix
    self.Screen:setBottomRowIcon(SlotIcon)

end

------------------------------------------------------------------------------------------------------------------------

function PluginPageMikroMK3:getParameterText()

    local Name, Value = "", ""
    local ParamCache = App:getStateCache():getParameterCache()
    local ParamPosition = ParamCache:getFocusedModuleParameterPosition()
    local Parameter = NI.DATA.ParameterCache.getFocusedModuleParameter(App)
    local ActualParameter = NI.DATA.ParameterCache.getActualParameter(Parameter)

    if Parameter and ActualParameter then

        -- parameter name
        Name = NI.GUI.ParameterWidgetHelper.getParameterName(ActualParameter)

        -- parameter value
        Value = NI.GUI.ParameterWidgetHelper.getValueString(ActualParameter, MaschineHelper.isAutoWriting())

	end

    return Name, Value, self.SectionNames[ParamPosition]

end

------------------------------------------------------------------------------------------------------------------------

function PluginPageMikroMK3:updateSectionNames()

    local ParamCache = App:getStateCache():getParameterCache()
    local SectionNames = {}
    for Idx = 0, NI.DATA.CONST_PARAMETERS_PER_PAGE-1 do

        local Parameter = ParamCache:getParameterOfFocusedModulePage(Idx)
        local Section = Parameter and Parameter:getSectionName() or ""
        if Idx == 0 and Section == "" then
            -- If there are section names, there's always one for the first parameter,
            -- if there are none (e.g. with 3rd party plugins) show "Page x/y" instead.
            local FocusPage = tostring(NI.DATA.ParameterCache.getFocusedModulePage(App)+1)
            local NumPages = tostring(App:getStateCache():getParameterCache():getNumPagesOfFocusedModule())
            SectionNames[Idx] = "Page "..FocusPage.."/"..NumPages

        elseif Section ~= "" then

            SectionNames[Idx] = Section

        elseif Idx > 0 then
            -- Use previous section name b/c they're only given with the first parameter of the section
            SectionNames[Idx] = SectionNames[Idx-1]
        end

    end

    self.SectionNames = SectionNames

end

------------------------------------------------------------------------------------------------------------------------

function PluginPageMikroMK3:onSwitchEvent(SwitchId, Pressed)

    if SwitchId == NI.HW.BUTTON_WHEEL_TOUCH then
        self:updateScreen()
    end

end

------------------------------------------------------------------------------------------------------------------------

function PluginPageMikroMK3:onWheelEvent(Value)
    -- do nothing as plugin parameters are handled as realtime encoder events
end

------------------------------------------------------------------------------------------------------------------------
