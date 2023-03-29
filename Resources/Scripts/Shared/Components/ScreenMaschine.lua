------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Components/ScreenBase"
require "Scripts/Shared/Components/InfoBar"
require "Scripts/Shared/Helpers/ScreenHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
ScreenMaschine = class( 'ScreenMaschine', ScreenBase )

------------------------------------------------------------------------------------------------------------------------

function ScreenMaschine:__init(Page)

    -- init base class
    ScreenBase.__init(self, Page)

    self.ScreenButtonsWereEnabled = {true, true, true, true, true, true, true, true}

end

------------------------------------------------------------------------------------------------------------------------

function ScreenMaschine:setupScreen()

    -- create root bar
    self.RootBar = NI.GUI.createBar()
    self.RootBar:style(NI.GUI.ALIGN_WIDGET_RIGHT, "Page")

    -- insert page into page stack
    local ScreenStack = NHLController:getHardwareDisplay():getPageStack()
    NI.GUI.insertPage(ScreenStack, self.RootBar, self.Page.Name)

    -- create bars for left and right page
    self.ScreenLeft = NI.GUI.insertBar(self.RootBar, self.Page.Name .. "ScreenLeft")
    self.ScreenLeft:style(NI.GUI.ALIGN_WIDGET_DOWN, "HalfPage")
    self.ScreenRight = NI.GUI.insertBar(self.RootBar, self.Page.Name .. "ScreenRight")
    self.ScreenRight:style(NI.GUI.ALIGN_WIDGET_DOWN, "HalfPage")

    self.ScreenButton = {}
    self.ParameterGroupName = {}
    self.ParameterWidgets = {}
    self.Arrows = {}

    if self.Page.ParameterHandler then
		self.Page.ParameterHandler:setup(self.ParameterGroupName, self.ParameterWidgets)
	end

end

------------------------------------------------------------------------------------------------------------------------

function ScreenMaschine:styleScreenWithParameters(ParentBar, ScreenButtonTexts, ScreenButtonStyle, IsPinnable)

	-- Screen Buttons bar
	self:addScreenButtonBar(ParentBar, ScreenButtonTexts, ScreenButtonStyle, IsPinnable)

    -- Transport / Info bar
    self.InfoBar = InfoBar(self.Page.Controller, ParentBar)

	-- Parameter bar
	self:addParameterBar(ParentBar)

end

------------------------------------------------------------------------------------------------------------------------

function ScreenMaschine:setArrowText(ArrowIndex, Text, AccessibleText)

	if self.Arrows[ArrowIndex] == nil then
		return
	end

	-- Activate Arrow
	if Text and Text ~= "" then
		self.Arrows[ArrowIndex].Label:setText(Text)
        self.Arrows[ArrowIndex].AccessibleText = AccessibleText

		self.Arrows[ArrowIndex].Label:setVisible(true)
		self.Arrows[ArrowIndex].Label:setActive(true)
        self.Arrows[ArrowIndex].Bar:style(NI.GUI.ALIGN_WIDGET_RIGHT, "ArrowOn")
		self.Arrows[ArrowIndex].Left:style("<<", "ArrowLeft")
		self.Arrows[ArrowIndex].Right:style(">>", "ArrowRight")
	-- Deactivate Arrow
	else
        self:unsetArrowText(ArrowIndex)
	end

end

------------------------------------------------------------------------------------------------------------------------

function ScreenMaschine:unsetArrowText(ArrowIndex, ReplacementTextLeft, ReplacementTextRight)

	if self.Arrows[ArrowIndex] == nil then
		return
	end

    self.Arrows[ArrowIndex].Label:setVisible(false)
    self.Arrows[ArrowIndex].Label:setActive(false)
    self.Arrows[ArrowIndex].Bar:style(NI.GUI.ALIGN_WIDGET_RIGHT, "ArrowOff")
    self.Arrows[ArrowIndex].Left:style(ReplacementTextLeft or "", "HeadButton") --todo: customize?
    self.Arrows[ArrowIndex].Right:style(ReplacementTextRight or "", "HeadButton")

end

------------------------------------------------------------------------------------------------------------------------
-- NOTES
-- If one of the Texts is '<<' an arrow object is automatically inserted
-- ButtonStyle can be an Array of strings
function ScreenMaschine:addScreenButtonBar(ParentBar, Text, ButtonStyle, IsPinnable)

    local StylesAsList = ButtonStyle[1] or false

    -- Button Bar
    local ButtonBar = NI.GUI.insertBar(ParentBar, "ButtonBar")
    ButtonBar:style(NI.GUI.ALIGN_WIDGET_RIGHT, "HeadRow")

    local Index = 1
    local Size = #Text

    while Index <= Size do

        if Text[Index] == "<<" then

        	-- Content of 'Arrow' table:
        	-- *Bar : Container Bar
        	-- *Left : Left Arrow Button
        	-- *Right : Right Arrow Button
        	-- *Label : Arrow Label

        	local Arrow = {}

            Arrow.Bar = NI.GUI.insertBar(ButtonBar, "ArrowButtonBar")
            Arrow.Bar:style(NI.GUI.ALIGN_WIDGET_RIGHT, "ArrowOn")

			-- insert Left Arrow
            Arrow.Left = NI.GUI.insertButton(Arrow.Bar, "Button"..tostring(#self.ScreenButton + 1))
            Arrow.Left:style(Text[Index], "ArrowLeft")
			self.ScreenButton[#self.ScreenButton + 1] = Arrow.Left

			-- insert Right Arrow
            Arrow.Right = NI.GUI.insertButton(Arrow.Bar, "Button"..tostring(#self.ScreenButton + 1))
            Arrow.Right:style(Text[Index+1], "ArrowRight")
			self.ScreenButton[#self.ScreenButton + 1] = Arrow.Right

            -- insert arrow label
            Arrow.Label = NI.GUI.insertLabel(Arrow.Bar, "ArrowLabel")
            Arrow.Label:style("", "ArrowLabel")
            Arrow.Label:setNoAlign(true)
            NI.GUI.enableCropModeForLabel(Arrow.Label)

            self.Arrows[#self.Arrows+1] = Arrow
            Index = Index + 2

        else

	        -- insert regular button
            local Button = NI.GUI.insertButton(ButtonBar, "Button"..tostring(#self.ScreenButton + 1))
            Button:style(Text[Index], StylesAsList and ButtonStyle[Index] or ButtonStyle)

            Button:setVisible(Text[Index] ~= "")
            Button:setEnabled(Text[Index] ~= "")
            NI.GUI.enableCropModeForButton(Button)

            self.ScreenButton[#self.ScreenButton + 1] = Button
            Index = Index + 1
        end
    end

    return ButtonBar

end

------------------------------------------------------------------------------------------------------------------------

function ScreenMaschine:addParameterBar(ParentBar)

    ParentBar.ParamBar = NI.GUI.insertBar(ParentBar, "ParamBar")
    ParentBar.ParamBar:style(NI.GUI.ALIGN_WIDGET_DOWN, "Parameters")

    -- Parameter page name
    ScreenHelper.createBarWithLabels(ParentBar.ParamBar, self.ParameterGroupName, {"", "", "", ""},
        "GroupNames", "ParameterGroupName")

    -- line
    local Line = NI.GUI.insertLabel(ParentBar.ParamBar, "Line")
    Line:style("", "BlackLine")

	-- parameter widgets
	ScreenHelper.createBarWith4ParameterWidgets(ParentBar.ParamBar, self.ParameterWidgets)

end

------------------------------------------------------------------------------------------------------------------------

function ScreenMaschine:update(ForceUpdate)

	-- info bar
	if self.InfoBar then
		self.InfoBar:update(ForceUpdate)
	end

end

------------------------------------------------------------------------------------------------------------------------

-- ButtonIdx: Index Of ScreenButton
-- Button: NI.HW.<Name>
-- Enable: if the Button should be enabled if not Pressed
function ScreenMaschine:updateScreenButton(ButtonIdx, Button, Enable)

    if self.Controller.SwitchPressed[Button] == true then
        local SelectedOrEnabled = Enable or self.ScreenButtonsWereEnabled[ButtonIdx] == true
        self.ScreenButton[ButtonIdx]:setSelected(SelectedOrEnabled)
        self.ScreenButton[ButtonIdx]:setEnabled(SelectedOrEnabled)
        self.ScreenButtonsWereEnabled[ButtonIdx] = Enable
    else
        self.ScreenButton[ButtonIdx]:setSelected(false)
        self.ScreenButton[ButtonIdx]:setEnabled(Enable)
        self.ScreenButtonsWereEnabled[ButtonIdx] = Enable
    end

end

------------------------------------------------------------------------------------------------------------------------

function ScreenMaschine:getArrowIndexByButtonIndex(ButtonIdx)

    for ArrowIndex, Arrow in ipairs(self.Arrows) do
        if Arrow.Label:isVisible() and
            (Arrow.Left == self.ScreenButton[ButtonIdx] or Arrow.Right == self.ScreenButton[ButtonIdx]) then
            return ArrowIndex
        end
    end

    return nil

end

------------------------------------------------------------------------------------------------------------------------

function ScreenMaschine:getAccessibleArrowDirectionTextByButtonIndex(ButtonIdx)

    if ButtonIdx > #self.ScreenButton then
        return ""
    end

    local ArrowIndex = self:getArrowIndexByButtonIndex(ButtonIdx)
    if not ArrowIndex then return nil end

    return self.Arrows[ArrowIndex].Left == self.ScreenButton[ButtonIdx] and "Previous" or "Next"

end

------------------------------------------------------------------------------------------------------------------------

function ScreenMaschine:getAccessibleTextByButtonIndex(ButtonIdx)

    if ButtonIdx > #self.ScreenButton then
        return ""
    end

    local ArrowIndex = self:getArrowIndexByButtonIndex(ButtonIdx)
    if not ArrowIndex then
        return self.ScreenButton[ButtonIdx]:isVisible() and self.ScreenButton[ButtonIdx]:getText() or ""
    end

    return self.Arrows[ArrowIndex].AccessibleText or self.Arrows[ArrowIndex].Label:getText()

end

------------------------------------------------------------------------------------------------------------------------

function ScreenMaschine:getAccessibleParamDescriptionByIndex(ParamIdx)

    if ParamIdx > #self.ParameterWidgets then
        return "", "", "", ""
    end

    local Name = self.ParameterWidgets[ParamIdx].Name:isVisible() and self.ParameterWidgets[ParamIdx].Name:getText() or ""
    local Value = self.ParameterWidgets[ParamIdx].Value:isVisible() and self.ParameterWidgets[ParamIdx].Value:getText() or ""
    local Unit = self.ParameterWidgets[ParamIdx].Unit:isVisible() and self.ParameterWidgets[ParamIdx].Unit:getText() or ""

    local Section = (ParamIdx <= #self.ParameterGroupName and self.ParameterGroupName[ParamIdx]:isVisible())
        and self.ParameterGroupName[ParamIdx]:getText()
        or ""

    return Section, Name, Value, Unit

end

------------------------------------------------------------------------------------------------------------------------
