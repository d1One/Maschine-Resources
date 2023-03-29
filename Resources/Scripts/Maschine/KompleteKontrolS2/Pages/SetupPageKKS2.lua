------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Pages/PageMaschine"
require "Scripts/Shared/Components/ScreenMaschineStudio"

------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
SetupPageKKS2 = class( 'SetupPageKKS2', PageMaschine )

local VELOCITIES = {"Soft 3", "Soft 2", "Soft 1", "Linear", "Hard 1", "Hard 2", "Hard 3", "Fixed"}

------------------------------------------------------------------------------------------------------------------------

function SetupPageKKS2:__init(Controller)

    PageMaschine.__init(self, "SetupPageKKS2", Controller)

    self.HWKompletePrefs = NI.HW.getPreferencesKompleteKontrolS()
    self:setupScreen()

end

------------------------------------------------------------------------------------------------------------------------

function SetupPageKKS2:setupScreen()

    self.Screen = ScreenMaschineStudio(self)
    self.Screen:styleScreenWithParameters(self.Screen.ScreenLeft, {"", "", "", ""}, "HeadButton", false, true)
    self.Screen:styleScreenWithParameters(self.Screen.ScreenRight, {"", "", "", ""}, "HeadButton", false, false)

    self.Screen.ScreenRight.ParamBar:setActive(false)

    self.PageLEDs = {NI.HW.LED_SETUP}

end

------------------------------------------------------------------------------------------------------------------------

function SetupPageKKS2:onShow(Show)

    if Show then
        self.HWKompletePrefs:read(NHLController)

    end

    PageMaschine.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function SetupPageKKS2:updateScreens(ForceUpdate)

    self.Screen.ScreenLeft.InfoBar:update(ForceUpdate)

    if ForceUpdate then
        self.HWKompletePrefs:read(NHLController)

    end

    for Index = 1, 8 do
        self.Screen.ScreenButton[Index]:setVisible(Index == 1)
        self.Screen.ScreenButton[Index].Color = nil
        self.Screen.ScreenButton[Index]:setPaletteColorIndex(0)
        self.Screen.ScreenButton[Index]:setSelected(Index == 1)
        self.Screen.ScreenButton[Index]:style(Index == 1 and "SETUP" or "", Index == 1 and "HeadPin" or "HeadButton")
    end

    PageMaschine.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function SetupPageKKS2:updateParameters(ForceUpdate)

    ParameterHandler.NumPages = 1

    local Values = {}
    local Lists = {}
    local Names = {}
    local Sections = {}

    Sections[1] = "Keys"
    Names[1] = "SCALING"
    Lists[1] = VELOCITIES
    Values[1] = VELOCITIES[self.HWKompletePrefs:getVelocityCurve() + 1]

    Sections[2] = "Display"
    Names[2] = "BRIGHTNESS"
    Values[2] = tostring(self.HWKompletePrefs:getDisplayBrightness())

    self.ParameterHandler:setParameters({})
    self.ParameterHandler:setCustomNames(Names)
    self.ParameterHandler:setCustomValues(Values)
    self.ParameterHandler:setCustomSections(Sections)

    self.Controller.CapacitiveList:assignListsToCaps(Lists, Values)

    PageMaschine.updateParameters(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function SetupPageKKS2:onScreenEncoder(Index, Value)

    local EncoderSmoothed = MaschineHelper.onScreenEncoderSmoother(Index, Value, .1) ~= 0
    local Next = Value > 0

    if Index == 1 and EncoderSmoothed then
        self:selectPrevNextVelocityCurve(Next)

    elseif Index == 2 then
        self:incDecDisplayBrightness(Next)

    end

    PageMaschine.onScreenEncoder(self, Index, Value)

end

------------------------------------------------------------------------------------------------------------------------

function SetupPageKKS2:selectPrevNextVelocityCurve(Next)

    local Current = self.HWKompletePrefs:getVelocityCurve()
    self.HWKompletePrefs:setVelocityCurve(math.bound(Current + (Next and 1 or -1), 0, 7))

    self.HWKompletePrefs:write(NHLController)
    self:updateParameters()

end

------------------------------------------------------------------------------------------------------------------------

function SetupPageKKS2:incDecDisplayBrightness(Next)

    local Current = self.HWKompletePrefs:getDisplayBrightness()
    self.HWKompletePrefs:setDisplayBrightness(math.bound(Current + (Next and 1 or -1), 0, 100))
    self.HWKompletePrefs:write(NHLController)
    self:updateParameters()

end

------------------------------------------------------------------------------------------------------------------------

