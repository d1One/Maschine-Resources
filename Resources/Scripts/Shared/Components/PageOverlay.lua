require "Scripts/Shared/Helpers/ScreenHelper"
require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Shared/Helpers/LedHelper"
require "Scripts/Shared/Components/ParameterWidget"

local ATTR_EMPTY = NI.UTILS.Symbol("empty")

local class = require 'Scripts/Shared/Helpers/classy'
PageOverlay = class( 'PageOverlay' )

------------------------------------------------------------------------------------------------------------------------
-- Parameter/ScreenButtonDataFunc: A static function that fetches the data for a certain parameter or button based on a
--                                 given index from 1 to 8
-- OnScreenButton/EncoderFunc: A static function that enacts a certain action on a given button/encoder index from 1 to 8
--
-- You can provide functions for the screen buttons or the encoders or both.
-- Moreover, you don't have to provide cases for each button or encoder if they are not used, as the overlay hides unused
-- buttons and encoders from the screen.
--
-- The data table for the encoders can contain:
-- GroupName (string), Name (string), Value (string or numeric), CapListValues (a list of strings),
-- CapListColors (a list of colors), CapListIndex (numeric)
--
-- The data table for the buttons can contain:
-- Enabled (bool), Visible (bool), Text (string), Selected (bool)
--
-- The data can be stored in any order as long as the table key matches, and each field is optional.
------------------------------------------------------------------------------------------------------------------------

function PageOverlay:__init(Controller, Funcs)

    self.Controller = Controller

    self.ParameterGroupNameLeft = {}
    self.ParameterGroupNameRight = {}
    self.ParameterWidgetsLeft = {}
    self.ParameterWidgetsRight = {}

    self.ScreenButtonsLeft = {}
    self.ScreenButtonsRight = {}

    self.Funcs = Funcs

    self:setupScreen()

    self.CapacitiveList = CapacitiveOverlayList(self)
    self.CapacitiveList:reset()

end

------------------------------------------------------------------------------------------------------------------------

function PageOverlay:setupScreen()

    local OverlayRoot = NHLController:getHardwareDisplay():getOverlayRoot()
    self.ParametersOverlay = NI.GUI.insertBar(OverlayRoot, "ParametersOverlay")
    self.ParametersOverlay:style(NI.GUI.ALIGN_WIDGET_RIGHT, "ParametersOverlay")
    self.ParametersOverlay:setVisible(false)

    -- Screen left and right
    self.DisplayBarLeft = NI.GUI.insertBar(self.ParametersOverlay, "ParametersOverlayScreenLeft")
    self.DisplayBarLeft:style(NI.GUI.ALIGN_WIDGET_DOWN, "HalfOverlay")
    self.DisplayBarRight = NI.GUI.insertBar(self.ParametersOverlay, "ParametersOverlayScreenRight")
    self.DisplayBarRight:style(NI.GUI.ALIGN_WIDGET_DOWN, "HalfOverlay")

    -- ScreenButtons
    self.ButtonBarLeft = ScreenHelper.createBarWith4ScreenButtons(self.DisplayBarLeft, self.ScreenButtonsLeft)
    self.ButtonBarRight = ScreenHelper.createBarWith4ScreenButtons(self.DisplayBarRight, self.ScreenButtonsRight)
    self.ButtonBarLeft:setVisible(false)
    self.ButtonBarRight:setVisible(false)

    -- ParamBar
    self.ParamBarLeft = NI.GUI.insertBar(self.DisplayBarLeft, "ParamBar")
    self.ParamBarLeft:style(NI.GUI.ALIGN_WIDGET_DOWN, "ParamBar")
    self.ParamBarRight = NI.GUI.insertBar(self.DisplayBarRight, "ParamBar")
    self.ParamBarRight:style(NI.GUI.ALIGN_WIDGET_DOWN, "ParamBar")
    self.ParamBarLeft:setNoAlign(true)
    self.ParamBarRight:setNoAlign(true)

    ScreenHelper.createBarWithLabels(self.ParamBarLeft , self.ParameterGroupNameLeft, {"Select", "", "", ""}, "GroupNames", "ParameterGroupName")
    ScreenHelper.createBarWithLabels(self.ParamBarRight , self.ParameterGroupNameRight, {"", "", "", ""}, "GroupNames", "ParameterGroupName")

    self.ParamBarLeft:setVisible(false)
    self.ParamBarRight:setVisible(false)

    -- parameter widgets
    ScreenHelper.createBarWith4ParameterWidgets(self.ParamBarLeft, self.ParameterWidgetsLeft, true)
    ScreenHelper.createBarWith4ParameterWidgets(self.ParamBarRight, self.ParameterWidgetsRight, true)

    for Index, ScreenButton in pairs (self.ScreenButtonsLeft) do
        ScreenButton:setVisible(false)
    end
    for Index, ScreenButton in pairs (self.ScreenButtonsRight) do
        ScreenButton:setVisible(false)
    end

    if self.Funcs.OnSetupFunc then
        self.Funcs.OnSetupFunc(self)
    end

end

------------------------------------------------------------------------------------------------------------------------

function PageOverlay:setVisible(Visible)

    self.CapacitiveList:reset()

    if Visible then
        self:updateParameters()
        NHLController:setEncoderMode(NI.HW.ENC_MODE_NONE)
        NHLController:setScreenButtonMode(NI.HW.SCREENBUTTON_MODE_NONE)
    end

    self.ParametersOverlay:setVisible(Visible)
    self.ParamBarLeft:setVisible(Visible)
    self.ParamBarRight:setVisible(Visible)
    self.ButtonBarLeft:setVisible(Visible)
    self.ButtonBarRight:setVisible(Visible)

    if self.Funcs.OnShowFunc then
        self.Funcs.OnShowFunc(Visible)
    end

end

------------------------------------------------------------------------------------------------------------------------

function PageOverlay:updateParameters()

    for i=1, 8 do

        local Data = self.Funcs.ParameterDataFunc and self.Funcs.ParameterDataFunc(i) or {}

        local GroupName = i < 5 and self.ParameterGroupNameLeft[i] or self.ParameterGroupNameRight[i - 4]
        GroupName:setText(Data.GroupName and Data.GroupName or "")

        local ParameterWidget = i < 5 and self.ParameterWidgetsLeft[i] or self.ParameterWidgetsRight[i - 4]
        ParameterWidget:setName(Data.Name and Data.Name or "")
        ParameterWidget:setValue(Data.Value and Data.Value or "")
        ParameterWidget:setAttribute(ATTR_EMPTY, ParameterWidget:isEmpty() and "true" or "false")

        if Data.CapListValues then
            self.CapacitiveList:assignListToCap(i, Data.CapListValues, Data.CapListColors)
            self.CapacitiveList:setListFocusItem(i, Data.CapListIndex)

        else
            self.CapacitiveList:assignListToCap(i, {})
        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function PageOverlay:updateScreenButtons()

    local ScreenButtons = {}
    for i = 1, 8 do

        local Data = self.Funcs.ScreenButtonDataFunc and self.Funcs.ScreenButtonDataFunc(i) or {}
        local ScreenButton = i < 5 and self.ScreenButtonsLeft[i] or self.ScreenButtonsRight[i - 4]
        ScreenButton:setEnabled(Data.Enabled and Data.Enabled or false)
        ScreenButton:setVisible(Data.Visible and Data.Visible or false)
        ScreenButton:style(Data.Text and Data.Text or "", Data.Style and Data.Style or "HeadButton")
        ScreenButton:setSelected(Data.Selected and Data.Selected or false)

        ScreenButton:setPaletteColorIndex(Data.Color == nil and 0 or (Data.Color + 1))
        ScreenButton.Color = Data.Color
        ScreenButtons[i] = ScreenButton
    end

    LEDHelper.updateScreenButtonLEDs(self.Controller, ScreenButtons)

end

------------------------------------------------------------------------------------------------------------------------

function PageOverlay:isVisible()

    return self.ParamBarLeft:isVisible()

end

------------------------------------------------------------------------------------------------------------------------

function PageOverlay:update()

    if self.Funcs.OnUpdateFunc then
        self.Funcs.OnUpdateFunc(self)
    end

    self:updateParameters()
    self:updateScreenButtons()

end

------------------------------------------------------------------------------------------------------------------------

function PageOverlay:onScreenButton(Index, Pressed)

    if self.Funcs.OnScreenButtonFunc then
        self.Funcs.OnScreenButtonFunc(Index, Pressed)
    end

end

------------------------------------------------------------------------------------------------------------------------

function PageOverlay:onScreenEncoder(Index, EncoderInc)

    if self.Funcs.OnScreenEncoderFunc then
        self.Funcs.OnScreenEncoderFunc(Index, EncoderInc)
    end

end

------------------------------------------------------------------------------------------------------------------------

function PageOverlay:getScreenEncoderInfo(Index)

    if self.Funcs.GetScreenEncoderInfoFunc then
        return self.Funcs.GetScreenEncoderInfoFunc(Index)
    end

    return nil

end

------------------------------------------------------------------------------------------------------------------------

function PageOverlay:getScreenButtonInfo(Index)

    if self.Funcs.GetScreenButtonInfoFunc then
        return self.Funcs.GetScreenButtonInfoFunc(Index)
    end

    return nil

end

------------------------------------------------------------------------------------------------------------------------

function PageOverlay:getCurrentPageSpeechAssistanceMessage(Right)

    if self.Funcs.GetCurrentPageSpeechAssistanceMessageFunc then
        return self.Funcs.GetCurrentPageSpeechAssistanceMessageFunc(Right)
    end

end

------------------------------------------------------------------------------------------------------------------------

function PageOverlay:onLeftRightButton(Right, Pressed)

    if self.Funcs.OnLeftRightButtonFunc then
        self.Funcs.OnLeftRightButtonFunc(Right, Pressed)
    end

end

------------------------------------------------------------------------------------------------------------------------

function PageOverlay:updateLEDs()

    if self.Funcs.UpdateLEDsFunc then
        self.Funcs.UpdateLEDsFunc()
    end
end

------------------------------------------------------------------------------------------------------------------------

function PageOverlay:onTimer()

    self.CapacitiveList:onTimer()

end

------------------------------------------------------------------------------------------------------------------------

function PageOverlay:onCapTouched(Cap, Touched)

    if self.Funcs.onCapTouched then
        self.Funcs.onCapTouched(Cap, Touched)
    end

end

------------------------------------------------------------------------------------------------------------------------

function PageOverlay:onClear(Pressed)

    if self.Funcs.OnClearFunc then
        self.Funcs.OnClearFunc(Pressed)
    end

end

------------------------------------------------------------------------------------------------------------------------

function PageOverlay:onWheel(Value)

    if self.Funcs.OnWheelFunc then
        self.Funcs.OnWheelFunc(Value)
    end

end

------------------------------------------------------------------------------------------------------------------------

function PageOverlay:onWheelButton(Pressed)

    if self.Funcs.OnWheelButtonFunc then
        self.Funcs.OnWheelButtonFunc(Pressed)
    end

end

------------------------------------------------------------------------------------------------------------------------

function PageOverlay:onWheelDirection(Pressed, Button)

    if self.Funcs.OnWheelDirectionFunc then
        self.Funcs.OnWheelDirectionFunc(Pressed, Button)
    end

end

------------------------------------------------------------------------------------------------------------------------

function PageOverlay:getWheelDirectionInfo(Direction)

    if self.Funcs.OnGetWheelDirectionInfoFunc then
        return self.Funcs:OnGetWheelDirectionInfoFunc(Direction)
    end

end
