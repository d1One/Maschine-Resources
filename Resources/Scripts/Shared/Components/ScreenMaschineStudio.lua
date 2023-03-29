------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Components/ScreenMaschine"
require "Scripts/Shared/Components/InfoBarStudio"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
ScreenMaschineStudio = class( 'ScreenMaschineStudio', ScreenMaschine )

------------------------------------------------------------------------------------------------------------------------

function ScreenMaschineStudio:__init(Page)

    -- init base class
    ScreenMaschine.__init(self, Page)

end

------------------------------------------------------------------------------------------------------------------------

function ScreenMaschineStudio:styleScreen(ParentBar, ScreenButtonTexts, ScreenButtonStyle, IsPinnable, HasInfoBar)

    -- Header
    self:addScreenButtonBar(ParentBar, ScreenButtonTexts, ScreenButtonStyle, IsPinnable)

    -- Info Bar (Name, Tempo, Grid, Position).  Create if nil (by default)
	if HasInfoBar or HasInfoBar == nil then
        local Bar = NI.GUI.insertBar(ParentBar, "InfoBar")
        Bar:style(NI.GUI.ALIGN_WIDGET_RIGHT, "HeadButton")
        ParentBar.InfoBar = InfoBarStudio(self.Controller, Bar)
	end

    -- Main Display
    ParentBar.DisplayBar = NI.GUI.insertBar(ParentBar, "StudioDisplayBar")
    ParentBar.DisplayBar:style(NI.GUI.ALIGN_WIDGET_RIGHT, "StudioDisplay")
    ParentBar:setFlex(ParentBar.DisplayBar)

end

------------------------------------------------------------------------------------------------------------------------

function ScreenMaschineStudio:styleScreenWithParameters(ParentBar, ScreenButtonTexts, ScreenButtonStyle, IsPinnable, HasInfoBar)

	self:styleScreen(ParentBar, ScreenButtonTexts, ScreenButtonStyle, IsPinnable, HasInfoBar)

    -- Param Bar
    ParentBar.ParamBar = NI.GUI.insertBar(ParentBar, "ParamBar")
    ParentBar.ParamBar:style(NI.GUI.ALIGN_WIDGET_DOWN, "ParamBar")
    self:addParameterBar(ParentBar.ParamBar)

end

------------------------------------------------------------------------------------------------------------------------

function ScreenMaschineStudio:addParameterBar(ParentBar)

    -- Parameter page name
    ScreenHelper.createBarWithLabels(ParentBar, self.ParameterGroupName, {"", "", "", ""}, "GroupNames", "ParameterGroupName")

    -- parameter widgets
    ScreenHelper.createBarWith4ParameterWidgets(ParentBar, self.ParameterWidgets, true)

end

