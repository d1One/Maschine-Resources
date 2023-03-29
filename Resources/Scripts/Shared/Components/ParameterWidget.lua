require "Scripts/Shared/Helpers/MaschineHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
ParameterWidget = class( 'ParameterWidget' )

------------------------------------------------------------------------------------------------------------------------

function ParameterWidget:__init(Parent, WidgetName, UnitVisible)

    self.MainBar = NI.GUI.insertBar( Parent, WidgetName)
    self.MainBar:style(NI.GUI.ALIGN_WIDGET_DOWN, "")

    self.FirstRow = NI.GUI.insertBar( self.MainBar, "pParamNameBar")
    self.FirstRow:style(NI.GUI.ALIGN_WIDGET_RIGHT, "")
    self.SecondRow = NI.GUI.insertBar( self.MainBar, "pParamValueBar")
    self.SecondRow:style(NI.GUI.ALIGN_WIDGET_RIGHT, "")

    self.Name = NI.GUI.insertLabel ( self.FirstRow, "m_pParamNameWidget")
    self.Name:style("", "ParameterName")
    self.FirstRow:setFlex(self.Name)
    NI.GUI.enableAbbreviationModeForLabel(self.Name)

    self.MacroAssigned = NI.GUI.insertBar( self.FirstRow, "m_pParamMacroAssignedWidget")
    self.MacroAssigned:style(NI.GUI.ALIGN_WIDGET_RIGHT, "ParameterMacroAssigned")
    self.MacroAssigned:setActive(false)

    self.Modulated = NI.GUI.insertBar( self.FirstRow, "m_pParamModulatedWidget")
    self.Modulated:style(NI.GUI.ALIGN_WIDGET_RIGHT, "ParameterModulated")
    self.Modulated:setActive(false)

    self.Value = NI.GUI.insertLabel ( self.SecondRow, "m_pParamValueWidget")
    self.Value:style("", "ParameterValue")
    self.Value:setAutoResize(true)
    NI.GUI.enableAbbreviationModeForLabel(self.Value)

    self.Unit = NI.GUI.insertLabel ( self.SecondRow, "m_pParamValueWidgetUnit")
    self.Unit:style("", "ParameterValueUnit")
    self.Unit:setAutoResize(true)
    self.Unit:setActive(UnitVisible)

end

------------------------------------------------------------------------------------------------------------------------

function ParameterWidget:setName(Name)

    self.Name:setText(Name)

end

------------------------------------------------------------------------------------------------------------------------

function ParameterWidget:setValue(Value)

    self.Value:setText(Value)

end

------------------------------------------------------------------------------------------------------------------------

function ParameterWidget:setUnit(Unit)

    self.Unit:setText(Unit)

end

------------------------------------------------------------------------------------------------------------------------

function ParameterWidget:isEmpty()

    return self.Name:getText() == "" and self.Value:getText() == ""

end

------------------------------------------------------------------------------------------------------------------------

function ParameterWidget:setUnitVisible(IsVisible)

    self.Unit:setActive(IsVisible)

end

------------------------------------------------------------------------------------------------------------------------

function ParameterWidget:setAttribute(Attribute, Value)

    self.MainBar:setAttribute(Attribute, Value)

end

------------------------------------------------------------------------------------------------------------------------

function ParameterWidget:setVisible(Visible)

    self.MainBar:setVisible(Visible)

end

------------------------------------------------------------------------------------------------------------------------

function ParameterWidget:setMacroAssigned(Assigned)

    self.MacroAssigned:setActive(Assigned)

end

------------------------------------------------------------------------------------------------------------------------

function ParameterWidget:setModulated(Modulated)

    self.Modulated:setActive(Modulated)

end

------------------------------------------------------------------------------------------------------------------------

