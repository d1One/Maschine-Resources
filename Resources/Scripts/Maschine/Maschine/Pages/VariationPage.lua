require "Scripts/Shared/Pages/PageMaschine"
require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Maschine/Components/Pages/VariationPageBase"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
VariationPage = class( 'VariationPage', VariationPageBase )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function VariationPage:__init(Controller)

    VariationPageBase.__init(self, "VariationPage", Controller)

    self.RandomKeyParamSections1 = {"PBTY","NOTE RANGE","","VELOCITY","RANGE","CHORDS","NOTELGTH","TIMESHIFT"}
    self.RandomKeyParamSections2 = {"DISTRIBUTION","","","","","","",""}
    self.RandomPadParamSections  = {"PBTY","VELOCITY RANGE","","TIMESHIFT","NOTELGTH","DISTRIBUTION","",""}
    self.HumanParamSections      = {"VELOCITY RANGE","","TIMESHIFT","","","","",""}

    self.RandomKeyParamNames1 = {"PBTY","NOTE LO","NOTE HI","VEL LO","VEL HI","NOTE COUNT","STEPS","STEP"}
    self.RandomKeyParamNames2 = {"NOTE COUNT", "NOTES", "NOTE LGTH", "", "", "", "", ""}
    self.RandomPadParamNames  = {"PBTY","VEL LO","VEL HI","STEP","STEPS","NOTE LGTH","",""}
    self.HumanParamNames      = {"VEL LO","VEL HI","STEP","","","","",""}

end

------------------------------------------------------------------------------------------------------------------------

function VariationPage:setupScreen()

    -- create screen
    self.Screen = ScreenMaschine(self)

    -- Left screen
    self.Screen:addScreenButtonBar(self.Screen.ScreenLeft, {"VARIATION", "HUMANIZE", "RANDOM", "APPLY"}, "ScreenButton", false)
    self.Screen.ScreenButton[1]:style("VARIATION", "HeadPin")
    self.Screen.InfoBar = InfoBar(self.Controller, self.Screen.ScreenLeft)
    self.Screen:addParameterBar(self.Screen.ScreenLeft)

    -- Right screen
    self.Screen:addScreenButtonBar(self.Screen.ScreenRight, {"", "", "", ""}, "HeadButton")
    self.Screen.InfoBarRight = InfoBar(self.Controller, self.Screen.ScreenRight, "RightScreenDefault")
    self.Screen:addParameterBar(self.Screen.ScreenRight)

end

------------------------------------------------------------------------------------------------------------------------

