------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Components/ScreenBase"
require "Scripts/Maschine/MaschineMikro/InfoBarMikro"

local ATTR_ALIGN = NI.UTILS.Symbol("align")

------------------------------------------------------------------------------------------------------------------------
-- Screen for MaschineMikro
------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
ScreenMikro = class( 'ScreenMikro', ScreenBase )

------------------------------------------------------------------------------------------------------------------------
-- static defines
------------------------------------------------------------------------------------------------------------------------

ScreenMikro.PARAMETER_MODE_NONE     = 0 -- shows no parameters
ScreenMikro.PARAMETER_MODE_SINGLE   = 1 -- shows one big parameter
ScreenMikro.PARAMETER_MODE_MULTI    = 2 -- shows access to multiple parameters in a list (default)
ScreenMikro.SIMPLE_BAR              = 3 -- shows the whole screen (for busy)

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function ScreenMikro:__init(Page, ScreenMode)

    -- default screen mode is multi-value mode
    self.ScreenMode = ScreenMode and ScreenMode or self.PARAMETER_MODE_MULTI

	self.GroupBank = nil

    -- init base class
    ScreenBase.__init(self, Page)

end

------------------------------------------------------------------------------------------------------------------------
-- Setup Screen
------------------------------------------------------------------------------------------------------------------------

function ScreenMikro:setupScreen()

    -- create root bar
    self.RootBar = NI.GUI.createBar()
    self.RootBar:style(NI.GUI.ALIGN_WIDGET_DOWN, "Page")

    -- insert page into page stack
    local ScreenStack = NHLController:getHardwareDisplay():getPageStack()
    NI.GUI.insertPage(ScreenStack, self.RootBar, self.Page.Name)

    -- Tab buttons (top)
    self.ScreenButton = {}

    if self.ScreenMode ~= ScreenMikro.SIMPLE_BAR then

        self.ScreenButtonBar = ScreenHelper.createBarWithButtons(
            self.RootBar, self.ScreenButton, {"", "", ""}, "HeadTabRow", "HeadTab")

        -- Secondary screen stack for the middle of the screen
        -- Note: if the style of this is set to something in the stylesheet without a specific size or min. size,
        -- it will get the default height of 18.
        self.MikroScreenStack = NI.GUI.insertStack(self.RootBar, "MikroMidScreenStack")
        self.MikroScreenStack:style("TransportStack")

        -- InfoGroupBar: middle part of screen including title and transport bars
        self.InfoGroupBar = NI.GUI.insertBar(self.MikroScreenStack, "InfoGroupBar")
        self.InfoGroupBar:style(NI.GUI.ALIGN_WIDGET_DOWN, "")

        -- Title
        self.Title = {}
        self.Title[1] = NI.GUI.insertLabel(self.InfoGroupBar, "Title")
        self.Title[1]:style("", "Title")
        NI.GUI.enableCropModeForLabel(self.Title[1])

        -- Transport bar (middle), either Infobar or Sampling page stack
        if self.Page.Name == "SamplingPage" then
            self.SamplingPageStack = NI.GUI.insertStack(self.InfoGroupBar, "SamplingPageStack")
            self.SamplingPageStack:style("SamplingPageStack")
        else
            self.InfoBar = InfoBarMikro(self.Page.Controller, self.InfoGroupBar)
        end


        -- Black line
        local BlackLine = NI.GUI.insertLabel(self.InfoGroupBar, "Line")
        BlackLine:style("", "BlackLine")
        local BlackLineSpacer = NI.GUI.insertLabel(self.InfoGroupBar, "Spacer")
        BlackLineSpacer:style("", "Spacer3px")


        -- Parameter bar and labels (bottom)
        self.ParameterBar = {}
        self.ParameterLabel = {}

        if self.ScreenMode == self.PARAMETER_MODE_SINGLE then

            local ParamModeSingleSpacer = NI.GUI.insertLabel(self.InfoGroupBar, "Spacer")
            ParamModeSingleSpacer:style("", "Spacer3px")

            self.ParameterBar[1] = ScreenHelper.createBarWithLabels(self.InfoGroupBar, self.ParameterLabel,
				{""}, "ParameterBar", "ParameterValueSingle")

        elseif self.ScreenMode == self.PARAMETER_MODE_MULTI then

            -- self.ParameterLabel[2] = The selected parameter name
            -- self.ParameterLabel[4] = The selected parameter value
            self.ParameterBar[1] = ScreenHelper.createBarWithLabels(self.InfoGroupBar, self.ParameterLabel,
				{"", "", ""}, "ParameterBar", "")
            self.ParameterBar[2] = ScreenHelper.createBarWithLabels(self.InfoGroupBar, self.ParameterLabel,
				{""}, "ParameterValueBar", "ParameterValue")

            self.ParameterLabel[1]:style("<", "ParameterArrow")
            self.ParameterLabel[2]:style("", "ParameterName")
            self.ParameterLabel[3]:style(">", "ParameterArrow")
            self.ParameterLabel[1]:setAttribute(ATTR_ALIGN, "left")
            self.ParameterLabel[3]:setAttribute(ATTR_ALIGN, "right")

        end

        -- set default screen stack top
        self.MikroScreenStack:setTop(self.InfoGroupBar)

    end

end

------------------------------------------------------------------------------------------------------------------------

function ScreenMikro:addNavModeScreen()

    -- nav screen widgits
    self.NavGroupBar = NI.GUI.insertBar(self.MikroScreenStack, "NavGroupBar")
    self.NavGroupBar:style(NI.GUI.ALIGN_WIDGET_DOWN, "")

    -- navigation button bar
    self.NavButtons = {}
    self.NavButtonBar = ScreenHelper.createBarWithButtons(self.NavGroupBar, self.NavButtons,
        {"<", "A", "B", "C", "D", ">"}, "NavButtonRow", "HeadButtonNav")
    self.NavButtons[1]:style("<", "SmallButtonNav")
    self.NavButtons[6]:style(">", "SmallButtonNav")

    -- nav title
    self.NavTitle = {}
    self.NavTitle[1] = NI.GUI.insertLabel(self.NavGroupBar, "NavTitle")
    self.NavTitle[1]:style("", "Title")

    -- nav param select button bar
    self.NavParamSelectLabels = {}
    self.NavParamSelectBar = ScreenHelper.createBarWithLabels(self.NavGroupBar, self.NavParamSelectLabels,
        {"<", "SELECT", ">"}, "NavSelectRow", "")

    self.NavParamSelectLabels[1]:style("<", "ParameterArrow")
    self.NavParamSelectLabels[2]:style("x", "ParameterName")
    self.NavParamSelectLabels[3]:style(">", "ParameterArrow")

    self.NavParamSelectLabels[1]:setAttribute(ATTR_ALIGN,"left")
    self.NavParamSelectLabels[3]:setAttribute(ATTR_ALIGN,"right")
    self.NavParamSelectBar:setFlex(self.NavParamSelectLabels[2])

end

------------------------------------------------------------------------------------------------------------------------

function ScreenMikro:styleScreenButtons(Text, BarStyle, ButtonStyle)

    if self.ScreenMode ~= ScreenMikro.SIMPLE_BAR then

        self.ScreenButtonBar:style(NI.GUI.ALIGN_WIDGET_RIGHT, BarStyle)

        for Index, Button in ipairs(self.ScreenButton) do

            local ButtonText = Text[Index]
            Button:style(ButtonText, ButtonStyle)

            Button:setSelected(false)
            Button:setEnabled(ButtonText ~= "")
            Button:setVisible(true)
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function ScreenMikro:setNavMode(NavMode)

    if self.InfoGroupBar then
        if self.NavGroupBar then
            self.NavGroupBar:setVisible(NavMode)
            self.InfoGroupBar:setVisible(not NavMode)
            self.MikroScreenStack:setTop(NavMode and self.NavGroupBar or self.InfoGroupBar)
        else
            self.InfoGroupBar:setVisible(true)
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function ScreenMikro:getNavMode()

    if self.NavGroupBar and self.NavGroupBar:isVisible() then return 1 else return 0 end

end

------------------------------------------------------------------------------------------------------------------------

function ScreenMikro:update(ForceUpdate)

	if self.InfoBar then
		self.InfoBar:update(ForceUpdate)
	end

end

------------------------------------------------------------------------------------------------------------------------
