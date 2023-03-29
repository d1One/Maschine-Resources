------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Components/Pages/PadModePageBase"
require "Scripts/Maschine/Maschine/Screens/ScreenWithGrid"
require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Shared/Helpers/PadModeHelper"

local ATTR_IS_PAD_MODE = NI.UTILS.Symbol("isPadMode")

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
PadModePage = class( 'PadModePage', PadModePageBase )


------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function PadModePage:__init(Controller)

    PadModePageBase.__init(self, Controller, "PadModePage")

end

------------------------------------------------------------------------------------------------------------------------
-- Setup Screen
------------------------------------------------------------------------------------------------------------------------

function PadModePage:setupScreen()

    -- create screen
    self.Screen = ScreenWithGrid(self)

    self.Screen.InfoBar:setMode("PadScreenMode")

    -- screen buttons
    ScreenHelper.setWidgetText(self.Screen.ScreenButton,
        {"PAD", "KEYBOARD", "16 VEL", "FIXED VEL", "OCT-", "OCT+", "SEMI-", "SEMI+"})

    self.Screen:addParameterBar(self.Screen.ScreenLeft)

    PadModePageBase.setupScreen(self)

end

------------------------------------------------------------------------------------------------------------------------
-- Update
------------------------------------------------------------------------------------------------------------------------

function PadModePage:updateScreens(ForceUpdate)

    -- set isPadMode attribute for small letters
    local KeyboardMode = PadModeHelper.getKeyboardMode()
    for _, Button in ipairs (self.Screen.ButtonPad) do
        Button:setAttribute(ATTR_IS_PAD_MODE, KeyboardMode and "true" or "false")
    end
    self.Screen.InfoBar.Labels[2]:setAttribute(ATTR_IS_PAD_MODE, KeyboardMode and "true" or "false")

    -- update info bar
    self.Screen.InfoBar:update(true)

    if KeyboardMode then
        self.Screen.ScreenButton[5]:setEnabled(self.SelectMode or PadModeHelper.canTransposeRootNote(-12))
        self.Screen.ScreenButton[6]:setEnabled(self.SelectMode or PadModeHelper.canTransposeRootNote(12))
        self.Screen.ScreenButton[7]:setEnabled(self.SelectMode or PadModeHelper.canTransposeRootNote(-1))
        self.Screen.ScreenButton[8]:setEnabled(self.SelectMode or PadModeHelper.canTransposeRootNote(1))
    else
        self.Screen.ScreenButton[5]:setEnabled(true)
        self.Screen.ScreenButton[6]:setEnabled(true)
        self.Screen.ScreenButton[7]:setEnabled(true)
        self.Screen.ScreenButton[8]:setEnabled(true)
    end

    -- screen update
    PadModePageBase.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function PadModePage:updateParameters(ForceUpdate)

    self.ParameterHandler.Parameters = {}

    if self.ParameterHandler.PageIndex == 2 then
        local Song = NI.DATA.StateHelper.getFocusSong(App)
        local FixedVelocityParam = Song and Song:getFixedVelocityParameter() or nil

        local ScaleEngine = NI.DATA.getScaleEngine(App)
        local ChordModeActive = ScaleEngine:getChordModeParameter():getValue() ~= 0

        self.ParameterHandler.Parameters[1] = ChordModeActive and ScaleEngine:getChordPositionParameter() or FixedVelocityParam
        self.ParameterHandler.Parameters[2] = ChordModeActive and FixedVelocityParam or nil

        local Sections = ChordModeActive and {"Chord", "Fixed Vel"} or {"Fixed Vel", ""}
        local Names = ChordModeActive and {"POSITION", "VELOCITY"} or {"VELOCITY", ""}

        self.ParameterHandler:setCustomNames(Names)
        self.ParameterHandler:setCustomSections(Sections)

    end

    -- call base
    PadModePageBase.updateParameters(self, ForceUpdate)

    -- MAS2-8249 hack
    if PadModeHelper.getKeyboardMode() then

        if PadModeHelper.isChordTypeMin7b5() and self.ParameterHandler.PageIndex == 1 then
            self.ParameterHandler:setValueAttribute(4, ATTR_IS_PAD_MODE, "true")
            self.ParameterHandler:setCustomValue(4, "MIN 7b5")
        else
            self.ParameterHandler:setCustomValue(4, "")
            self.ParameterHandler:setValueAttribute(4, ATTR_IS_PAD_MODE, "false")
        end

        -- Fire a new update to make sure the new values are displayed
        PageMaschine.updateParameters(self, ForceUpdate)

    end

end

------------------------------------------------------------------------------------------------------------------------
