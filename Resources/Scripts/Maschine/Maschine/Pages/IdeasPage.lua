------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Components/Pages/ScenePageBase"

local ATTR_HAS_ARROW = NI.UTILS.Symbol("HasArrow")

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
IdeasPage = class( 'IdeasPage', ScenePageBase )

------------------------------------------------------------------------------------------------------------------------

function IdeasPage:__init(ParentPage, Controller)

    ScenePageBase.__init(self, ParentPage, Controller, "IdeasPage")

end

------------------------------------------------------------------------------------------------------------------------

function IdeasPage:setupScreen()

    self.Screen = ScreenWithGrid(self)
    ScreenHelper.setWidgetText(self.Screen.ScreenButton,
                               {"SCENE", "UNIQUE", "APPEND", "DUPL", "CREATE", "DELETE", "<", ">"})

    -- Parameter Bar
    self.Screen:addParameterBar(self.Screen.ScreenLeft)

    -- set custom style to grid buttons
    for i, Button in ipairs(self.Screen.ButtonPad) do
        Button:style("", "SelectPad")
    end

    self.Screen.ScreenButton[1]:style("SCENE", "HeadPin")
    self.Screen.ScreenButton[7]:style("<", "ScreenButton")
    self.Screen.ScreenButton[8]:style(">", "ScreenButton")
    self.Screen.ScreenButton[8]:setAttribute(ATTR_HAS_ARROW, "true")

end

------------------------------------------------------------------------------------------------------------------------

function IdeasPage:updateScreens(ForceUpdate)

    ScreenHelper.updateButtonsWithFunctor(self.Screen.ButtonPad,
        function (Index) return ArrangerHelper.SceneStateFunctor(Index, not self.AppendMode, self.AppendMode) end)

    -- Hide parameters in append mode
    self.ParameterHandler.SectionWidgets[1]:setVisible(not self.AppendMode)
    self.Screen.ParameterWidgets[1]:setVisible(not self.AppendMode)

    -- call base
    ScenePageBase.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function IdeasPage:updateParameters(ForceUpdate)

    self.ParameterHandler.NumParamsPerPage = 4
    self.ParameterHandler:setCustomSection(1, "Perform")
    self.ParameterHandler:setCustomName(1, "RETRIGGER")

    if not self.AppendMode then
        self.ParameterHandler:setCustomValue(1, ArrangerHelper.getSectionRetrigValueString())
    end

    ScenePageBase.updateParameters(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function IdeasPage:onScreenEncoder(Index, Value)

    if Index == 1 then
        local Song = NI.DATA.StateHelper.getFocusSong(App)
        if Song and not self.AppendMode then
            NI.DATA.ParameterAccess.addParameterEncoderDelta(App, Song:getPerformRetrigParameter(), Value, false, false)
        end
    end

end

------------------------------------------------------------------------------------------------------------------------
