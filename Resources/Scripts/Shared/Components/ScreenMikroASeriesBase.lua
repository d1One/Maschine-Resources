local StyleHelper = require("Scripts/Shared/KH1062/StyleHelper")
------------------------------------------------------------------------------------------------------------------------
-- Generic Mikro MK3 and Komplete Kontrol A-Series screen

local ATTR_ICON = NI.UTILS.Symbol("icon")
local ATTR_ONE = NI.UTILS.Symbol("one")
local ATTR_STYLE = NI.UTILS.Symbol("style")
local ATTR_WITH_ICON = NI.UTILS.Symbol("with-icon")

local class = require 'Scripts/Shared/Helpers/classy'
ScreenMikroASeriesBase = class( 'ScreenMikroASeriesBase' )

------------------------------------------------------------------------------------------------------------------------

function ScreenMikroASeriesBase:__init(PageName, ScreenStack, OptionalArgs)

    self.ScreenStack = ScreenStack
    self.PageName = PageName
    self.StyleHelper = OptionalArgs and OptionalArgs.StyleHelper or StyleHelper
    self:setupScreen()

end

------------------------------------------------------------------------------------------------------------------------

function ScreenMikroASeriesBase:onPageShow()

    self.ScreenStack:setTop(self.RootBar)

end

------------------------------------------------------------------------------------------------------------------------

function ScreenMikroASeriesBase:setupScreen()

    self.RootBar = NI.GUI.insertBar(self.ScreenStack, self.PageName)
    self.RootBar:style(NI.GUI.ALIGN_WIDGET_RIGHT, "ScreenMikroASeriesBase")

    -- Container for Top+Bottom Lines
    self.Main = NI.GUI.insertBar(self.RootBar, "Main")
    self.Main:style(NI.GUI.ALIGN_WIDGET_DOWN, "bar")
    self.RootBar:setFlex(self.Main)

    -- Top Line
    self.TopBar = NI.GUI.insertBar(self.Main, "TopBar")
    self.TopBar:style(NI.GUI.ALIGN_WIDGET_RIGHT, "IconCaptionBar")
    self.TopIcon = NI.GUI.insertLabel(self.TopBar, "TopIcon")
    self.TopIcon:style("", "Icon")
    self.TopCaption = NI.GUI.insertLabel(self.TopBar, "TopCaption")
    self.TopCaption:style("", "MikroASeries")

    self.TopBar:setFlex(self.TopCaption)
    NI.GUI.enableCropModeForLabel(self.TopCaption)

    -- Bottom Line with Icon and Text
    self.BottomBar = NI.GUI.insertBar(self.Main, "BottomBar")
    self.BottomBar:style(NI.GUI.ALIGN_WIDGET_RIGHT, "IconCaptionBar")
    self.BottomIcon = NI.GUI.insertLabel(self.BottomBar, "BottomIcon")
    self.BottomIcon:style("", "Icon")
    self.BottomCaption = NI.GUI.insertLabel(self.BottomBar, "BottomCaption")
    self.BottomCaption:style("", "MikroASeries")

    -- Bottom Line with Parameter
    self.ParameterBar = NI.GUI.insertBar(self.BottomBar, "ParameterBar")
    self.ParameterBar:style(NI.GUI.ALIGN_WIDGET_RIGHT, "ParameterBar")
    self.ParameterName = NI.GUI.insertLabel(self.ParameterBar, "ParameterName")
    self.ParameterName:style("", "MikroASeries")
    self.ParameterValue = NI.GUI.insertLabel(self.ParameterBar, "ParameterValue")
    self.ParameterValue:style("", "MikroASeries")

    self.StyleHelper.enableFlexFor(self.ParameterBar, self.ParameterName)
    self.StyleHelper.enableAutoResizeFor(self.ParameterValue)
    NI.GUI.enableAbbreviationModeForLabel(self.ParameterName)
    NI.GUI.enableCropModeForLabel(self.ParameterValue)

    self.BottomBar:setFlex(self.BottomCaption)
    NI.GUI.enableCropModeForLabel(self.BottomCaption)

    -- Scrollbar
    self.Scrollbar = NI.GUI.insertScrollbar(self.RootBar, "MikroASeries")
    self.Scrollbar:setAutohide(true)
    self.Scrollbar:setShowIncDecButtons(false)
    self.Scrollbar:style(false, 0, 0, "MikroASeries")

    -- Setup initial state
    self:setTopRowIcon()
    self:setBottomRowIcon()
    self:showTextInBottomRow()
    self:setTopRowTextAttribute("bold")

end

------------------------------------------------------------------------------------------------------------------------

-- this is needed in order to display the "1" and "11" centered
local function fixNumericTextEndingInOne(Icon, Text)

    if not tonumber(Text) then
        return
    end

    local EndsWithOne = Text:sub(#Text) == "1"
    Icon:setAttribute(ATTR_ONE, EndsWithOne and "true" or "false")

end

------------------------------------------------------------------------------------------------------------------------

local function setIcon(Icon, Attribute, Text)

    Icon:setActive(Attribute and Attribute ~= "" or false)
    if Attribute then
        Icon:setAttribute(ATTR_ICON, Attribute)
        fixNumericTextEndingInOne(Icon, Text)
    end

    Icon:setText(Text or "")

end

------------------------------------------------------------------------------------------------------------------------
-- If Attribute evaluates to false or empty string, the icon is hidden. Text is optional
------------------------------------------------------------------------------------------------------------------------

function ScreenMikroASeriesBase:setTopRowIcon(Attribute, Text)

    setIcon(self.TopIcon, Attribute, Text)
    return self

end

------------------------------------------------------------------------------------------------------------------------

function ScreenMikroASeriesBase:setTopRowText(Text)

    self.TopCaption:setText(Text or "")
    return self

end

------------------------------------------------------------------------------------------------------------------------

function ScreenMikroASeriesBase:setTopRowTextAttribute(Attribute)

    self.TopCaption:setAttribute(ATTR_STYLE, Attribute or "")
    return self

end

------------------------------------------------------------------------------------------------------------------------

function ScreenMikroASeriesBase:showTextInBottomRow()

    self.ParameterBar:setActive(false)
    self.BottomCaption:setActive(true)
    self.BottomBar:setFlex(self.BottomCaption)
    return self

end

------------------------------------------------------------------------------------------------------------------------

function ScreenMikroASeriesBase:showParameterInBottomRow()

    self.ParameterBar:setActive(true)
    self.BottomCaption:setActive(false)
    self.BottomBar:setFlex(self.ParameterBar)
    return self

end

------------------------------------------------------------------------------------------------------------------------
-- If Attribute evaluates to false or empty string, the icon is hidden. Text is optional
------------------------------------------------------------------------------------------------------------------------

function ScreenMikroASeriesBase:setBottomRowIcon(Attribute, Text)

    setIcon(self.BottomIcon, Attribute, Text)
    self.BottomBar:setAttribute(ATTR_WITH_ICON, tostring(self.BottomIcon:isActive()))
    return self

end

------------------------------------------------------------------------------------------------------------------------

function ScreenMikroASeriesBase:setBottomRowText(Text)

    self.BottomCaption:setText(Text or "")
    return self

end

------------------------------------------------------------------------------------------------------------------------

function ScreenMikroASeriesBase:setBottomRowTextAttribute(Attribute)

    self.BottomCaption:setAttribute(ATTR_STYLE, Attribute or "")
    return self

end

------------------------------------------------------------------------------------------------------------------------

function ScreenMikroASeriesBase:setParameterName(Name)

    self.ParameterName:setText(Name or "")
    return self

end

------------------------------------------------------------------------------------------------------------------------

function ScreenMikroASeriesBase:cropParameterName()

    NI.GUI.enableCropModeForLabel(self.ParameterName)
    return self

end

------------------------------------------------------------------------------------------------------------------------

function ScreenMikroASeriesBase:setParameterValue(Value)

    if Value and type(Value) ~= "string" then
        Value = tostring(Value)
    end

    self.ParameterValue:setText(Value or "")
    return self

end

------------------------------------------------------------------------------------------------------------------------

function ScreenMikroASeriesBase:updateScrollbar(Total, Value)

    self.Scrollbar:setRange(Total, 1)
    self.Scrollbar:setValue(Value, true)
    return self

end

------------------------------------------------------------------------------------------------------------------------
