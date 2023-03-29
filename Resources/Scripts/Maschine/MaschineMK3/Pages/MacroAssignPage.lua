------------------------------------------------------------------------------------------------------------------------
require "Scripts/Shared/Pages/PageMaschine"
require "Scripts/Shared/Helpers/MaschineHelper"
------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
MacroAssignPage = class( 'MacroAssignPage', PageMaschine )

------------------------------------------------------------------------------------------------------------------------

local MacroAssignTarget = NI.DATA.LEVEL_TAB_SOUND

------------------------------------------------------------------------------------------------------------------------

function MacroAssignPage:__init(Controller)

    PageMaschine.__init(self, "MacroAssignPage", Controller)

    self.PageLEDs = { NI.HW.LED_MACRO }
    self.IsPinned = true -- always pinned

    self:setupScreen()

end

------------------------------------------------------------------------------------------------------------------------

function MacroAssignPage:setupScreen()

    self.Screen = ScreenMaschineStudio(self)

    local ScreenButtonsLeft = {"SET MACRO", "MASTER", "GROUP", "SOUND"}
    self.Screen:styleScreenWithParameters(self.Screen.ScreenLeft, ScreenButtonsLeft, "HeadButton", false)
    self.Screen:styleScreenWithParameters(self.Screen.ScreenRight, {"", "", "", ""}, "HeadButton", false, false)
    self.Screen.ScreenButton[1]:style("SET MACRO", "HeadPin")
    self.Screen.ScreenButton[1]:setSelected(true)

    self.Screen.ScreenRight.DisplayBar:style(NI.GUI.ALIGN_WIDGET_DOWN, "StudioDisplay")

    local EmptyInfo = NI.GUI.insertLabel(self.Screen.ScreenRight.DisplayBar, "EmptyInfo")
    EmptyInfo:style("", "EmptyInfo")

    local ParamBar = NI.GUI.insertBar(self.Screen.ScreenRight, "ParamBar")
    ParamBar:style(NI.GUI.ALIGN_WIDGET_DOWN, "ParamBar")
    self.Screen:addParameterBar(ParamBar)


end

------------------------------------------------------------------------------------------------------------------------

function MacroAssignPage:onShow(Show)

    if Show then
        MacroAssignTarget = MaschineHelper.getLevelTab()
    end

    PageMaschine.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

local function UpdateMacroAssignTarget()

    local LevelTab = MaschineHelper.getLevelTab()

    -- Make sure that the MacroAssignTarget is never higher then the LevelTab,
    -- so that i.e. a Group parameter is not assigned to Sound level
    if LevelTab and MacroAssignTarget > LevelTab then
        MacroAssignTarget = LevelTab
    end

end

------------------------------------------------------------------------------------------------------------------------

function MacroAssignPage:updateScreens(ForceUpdate)

    UpdateMacroAssignTarget()

    PageMaschine.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

local function UpdateMacroAssignedState(ParameterHandler)

    local Params = ParameterHandler.Parameters
    local Widgets = ParameterHandler.ParameterWidgets

    for Index = 1, 8 do
        local IsMacroAssigned = Params[Index] and MacroAssignTarget and
            NI.DATA.ParameterPageAccess.anyMacrosForParameter(App, Params[Index], MacroAssignTarget) or false
        Widgets[Index]:setMacroAssigned(IsMacroAssigned)
    end

end

------------------------------------------------------------------------------------------------------------------------

function MacroAssignPage:updateParameters(ForceUpdate)

    local Params = {}

    if not NI.DATA.ParameterPageAccess.isMacroPageActive(App) then
        for Index = 1, 8 do
            Params[Index] = NI.DATA.ParameterCache.getParameterByPosition(App, Index - 1)
        end
    end

    self.ParameterHandler:setParameters(Params, true)
    self.Controller.CapacitiveList:assignParametersToCaps(Params)

    UpdateMacroAssignedState(self.ParameterHandler)

    -- call base class
    PageMaschine.updateParameters(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function MacroAssignPage:updateScreenButtons(ForceUpdate)

    local LevelTab = MaschineHelper.getLevelTab()
    local IsGroup = NI.DATA.StateHelper.getFocusGroup(App) ~= nil

    self.Screen.ScreenButton[2]:setSelected(MacroAssignTarget == NI.DATA.LEVEL_TAB_SONG)

    self.Screen.ScreenButton[3]:setSelected(MacroAssignTarget == NI.DATA.LEVEL_TAB_GROUP)
    self.Screen.ScreenButton[3]:setEnabled(LevelTab >= NI.DATA.LEVEL_TAB_GROUP)
    self.Screen.ScreenButton[3]:setText("GROUP")

    self.Screen.ScreenButton[4]:setSelected(MacroAssignTarget == NI.DATA.LEVEL_TAB_SOUND)
    self.Screen.ScreenButton[4]:setEnabled(IsGroup and LevelTab >= NI.DATA.LEVEL_TAB_SOUND)
    self.Screen.ScreenButton[4]:setVisible(IsGroup)

    PageMaschine.updateScreenButtons(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function MacroAssignPage:onScreenButton(Button, Pressed)

    if Button == 1 then
        return -- do not unpin page
    end

    if Pressed then

        if Button == 2 then
            MacroAssignTarget = NI.DATA.LEVEL_TAB_SONG
        elseif Button == 3 then
            MacroAssignTarget = NI.DATA.LEVEL_TAB_GROUP
        elseif Button == 4 then
            MacroAssignTarget = NI.DATA.LEVEL_TAB_SOUND
        end

    end

    PageMaschine.onScreenButton(self, Button, Pressed)
end

------------------------------------------------------------------------------------------------------------------------

function MacroAssignPage:onCapTouched(Cap, Touched)

    if not Touched then
        return
    end

    local Param = self.ParameterHandler.Parameters[Cap]
    if Param and MacroAssignTarget then
        NI.DATA.ParameterPageAccess.setOrRemoveMacroForParameter(App, Param, MacroAssignTarget)
    end

end

------------------------------------------------------------------------------------------------------------------------

function MacroAssignPage:getAccessiblePageInfo()

    return "Macro Assign"

end

------------------------------------------------------------------------------------------------------------------------
