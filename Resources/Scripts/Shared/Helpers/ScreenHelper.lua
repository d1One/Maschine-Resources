require "Scripts/Shared/Components/ParameterWidget"

local ATTR_IS_FOCUSED = NI.UTILS.Symbol("isFocused")
local ATTR_SPAN = NI.UTILS.Symbol("span")

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
ScreenHelper = class( 'ScreenHelper' )

------------------------------------------------------------------------------------------------------------------------

function ScreenHelper.setWidgetText(Widgets, Texts, SetVisibility)

	-- treat SetVisibility argument as default to true
	if SetVisibility == nil then
		SetVisibility = true
	end

    if not Widgets or not Texts then
        error("ScreenHelper.setWidgetText() Widgets or Texts are nil", 2)
    end

    -- insert button
    local Size = #Widgets
    for Index = 1, Size do
        local Text      = Texts[Index]
        local Widget    = Widgets[Index]

        -- set widget text
        if Widget ~= nil then

            if Text == nil then
                Text = ""
            end

            Widget:setText(Text)
            Widget:setEnabled(Text ~= "")

            if SetVisibility then
				Widget:setVisible(Text ~= "")
			end

            if not Widget:isEnabled() and Widget:isSelected() then
				Widget:setSelected(false)
			end
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function ScreenHelper.setWidgetSpan(Widgets, From, To, WithPageNumbers)

    if From > #Widgets then
        return
    end

    local Span = 1

    for Index = To, From, -1 do

        if Index > #Widgets then
            Span = Span + 1
        elseif Widgets[Index]:getText() == "" and Index > From then
            Widgets[Index]:setActive(false)
            Span = Span + 1
        else
            Widgets[Index]:setActive(true)
            if WithPageNumbers == true and Index == To then
                Widgets[Index]:setAttribute(ATTR_SPAN, "pages")
            else
                Widgets[Index]:setAttribute(ATTR_SPAN, "span" .. Span)
            end
            Span = 1
        end

    end

end

------------------------------------------------------------------------------------------------------------------------
-- Functor: Visible, Enabled, Selected, Focused, Text
function ScreenHelper.updateButtonsWithFunctor(Buttons, ButtonStateFunctor)

    -- iterate over LEDs
    for Index, Button in ipairs (Buttons) do

        -- get text, select and enable state from functor
        local Visible, Enabled, Selected, Focused, Text  = ButtonStateFunctor(Index)

        ScreenHelper.updateButton(Button, Visible, Enabled, Selected, Focused, Text)

    end

end

------------------------------------------------------------------------------------------------------------------------

function ScreenHelper.updateButton(Button, Visible, Enabled, Selected, Focused, Text, Style)

    if Button == nil then
        return
    end

    Button:setVisible(Visible == true)
    Button:setEnabled(Enabled == true)
    Button:setSelected(Selected == true)

    if Style then
        Button:style("", Style)
    end

    if Text then
        Button:setText(Text)
    else
        Button:setText("")
    end

    Button:setAttribute(ATTR_IS_FOCUSED, Focused == true and "true" or "false")

end

------------------------------------------------------------------------------------------------------------------------

function ScreenHelper.createBarWithButtons(ParentBar, Buttons, Text, BarStyle, ButtonStyle)

    -- Button Bar
    local ButtonBar = NI.GUI.insertBar(ParentBar, "ButtonBar")
    ButtonBar:style(NI.GUI.ALIGN_WIDGET_RIGHT, BarStyle)

    -- insert button
    local Size = #Text
    for Index = 1, Size do
        Buttons[#Buttons + 1] = NI.GUI.insertButton(ButtonBar, "Button"..tostring(#Buttons + 1))
        Buttons[#Buttons]:style(Text[Index], ButtonStyle)

        Buttons[#Buttons]:setVisible(Text[Index] ~= "")
        Buttons[#Buttons]:setEnabled(Text[Index] ~= "")

        -- enable string cropping
        NI.GUI.enableCropModeForButton(Buttons[#Buttons])
    end

    return ButtonBar

end

------------------------------------------------------------------------------------------------------------------------

function ScreenHelper.createBarWith16Buttons(ParentBar, Buttons, Text, ButtonStyle)

    if ButtonStyle == nil then
		ButtonStyle = "Pad" -- default style
	end

    local ContainerBar = NI.GUI.insertBar(ParentBar, "Grid")
    ContainerBar:style(NI.GUI.ALIGN_WIDGET_UP, "Grid")
    ParentBar:setFlex(ContainerBar)

    -- insert 16 buttons
    for BarIndex = 1, 4 do

        local ButtonBar = NI.GUI.insertBar(ContainerBar, "ButtonBar")
        ButtonBar:style(NI.GUI.ALIGN_WIDGET_RIGHT, "PadRow")
        for ButtonIndex = 1, 4 do
            local Index = (BarIndex - 1) * 4 + ButtonIndex
            Buttons[#Buttons + 1] = NI.GUI.insertButton(ButtonBar, "Button"..tostring(Index))
            Buttons[#Buttons]:style(Text[Index], ButtonStyle)

            -- enable string cropping
            NI.GUI.enableCropModeForButton(Buttons[#Buttons])
        end

    end

    return ContainerBar

end

------------------------------------------------------------------------------------------------------------------------

function ScreenHelper.createBarWith4Buttons(ParentBar, Buttons, Text)

    -- Button Bar
    local ButtonBar = NI.GUI.insertBar(ParentBar, "ButtonBar")
    ButtonBar:style(NI.GUI.ALIGN_WIDGET_RIGHT, "Grid4Rows")

    -- insert 4 buttons
    for Index = 1, 4 do
        Buttons[#Buttons + 1] = NI.GUI.insertButton(ButtonBar, "Button"..tostring(Index))
        Buttons[#Buttons]:style(Text[Index], "Grid4Rows")

        Buttons[#Buttons]:setVisible(Text[Index] ~= "")

        -- enable string cropping
        NI.GUI.enableCropModeForButton(Buttons[#Buttons])
    end
end


------------------------------------------------------------------------------------------------------------------------

function ScreenHelper.createBarWithLabels(ParentBar, Labels, Text, BarStyle, LabelStyle)

    -- Label Bar.  "LabelBar" is the bar's id
    local LabelBar = NI.GUI.insertBar(ParentBar, "LabelBar")
    LabelBar:style(NI.GUI.ALIGN_WIDGET_RIGHT, BarStyle)

    local Size = #Text
    for Index = 1, Size do
        Labels[#Labels + 1] = NI.GUI.insertLabel(LabelBar, "Label"..tostring(Index))
        Labels[#Labels]:style(Text[Index], LabelStyle)

        -- enable string cropping
        NI.GUI.enableCropModeForLabel(Labels[#Labels])

    end

    return LabelBar

end

------------------------------------------------------------------------------------------------------------------------

function ScreenHelper.createResultListItem(ParentBar, BarStyle, LabelStyle)

    local ResultListItemWidget = NI.GUI.insertResultListItemWidget(ParentBar, "ResultListItemWidget")
    ResultListItemWidget:style(NI.GUI.ALIGN_WIDGET_RIGHT, BarStyle)
    local TextLabel = ResultListItemWidget:getTextLabel()
    TextLabel:style("", LabelStyle)
    NI.GUI.enableCropModeForLabel(TextLabel)

    return ResultListItemWidget

end

------------------------------------------------------------------------------------------------------------------------

function ScreenHelper.createBarWith4ParameterWidgets(ParentBar, ParameterWidgets, UseUnitWidgets)

    local ParamWidgetBar = NI.GUI.insertBar(ParentBar, "ParamWidgetBar")
    ParamWidgetBar:style(NI.GUI.ALIGN_WIDGET_RIGHT, "")

    -- insert 4 parameter widgets
    for Index = 1, 4 do
        local ParamWidget = ParameterWidget(ParamWidgetBar, "ParamWidget"..tostring(#ParameterWidgets + 1), UseUnitWidgets == true)
        ParameterWidgets[#ParameterWidgets + 1] = ParamWidget

    end

    return ParamWidgetBar

end

------------------------------------------------------------------------------------------------------------------------

function ScreenHelper.createBarWith4Labels(ParentBar, Labels, Text)

    local LabelBar  = NI.GUI.insertBar(ParentBar, "LabelBar")
    LabelBar:style(NI.GUI.ALIGN_WIDGET_RIGHT, "Grid4Rows")

    -- insert 4 buttons
    for Index = 1, 4 do
        Labels[#Labels + 1] = NI.GUI.insertLabel(LabelBar, "Label"..tostring(Index))
        Labels[#Labels]:style(Text[Index], "LabelGrid")
    end

end

------------------------------------------------------------------------------------------------------------------------

function ScreenHelper.createBarWith2Labels(ParentBar, Labels, Text)

    -- Label Bar
    local LabelBar = NI.GUI.insertBar(ParentBar, "LabelBar")
    LabelBar:style(NI.GUI.ALIGN_WIDGET_RIGHT, "Grid4Rows")

    -- insert 2 buttons
    for Index = 1, 2 do
        Labels[#Labels + 1] = NI.GUI.insertLabel(LabelBar, "Label"..tostring(Index))
        Labels[#Labels]:style(Text[Index], "DoubleGrid")
    end

end

------------------------------------------------------------------------------------------------------------------------

function ScreenHelper.createBarWith4ScreenButtons(ParentBar, Buttons)

    -- Button Bar
    local ButtonBar = NI.GUI.insertBar(ParentBar, "ButtonBar")
    ButtonBar:style(NI.GUI.ALIGN_WIDGET_RIGHT, "HeadRow")

    for Index = 1, 4 do
        Buttons[Index] = NI.GUI.insertButton(ButtonBar, "Button"..tostring(Index))
        Buttons[Index]:style("", "HeadButton")
        NI.GUI.enableCropModeForButton(Buttons[Index])
    end

    return ButtonBar

end

------------------------------------------------------------------------------------------------------------------------
