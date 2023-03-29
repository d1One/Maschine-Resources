require "Scripts/Maschine/KH1062/KH1062Model"

require "Scripts/Maschine/KH1062/DataController"
require "Scripts/Maschine/KH1062/DataModel"

local AccessibilityController = require("Scripts/Shared/KH1062/AccessibilityController")
require "Scripts/Shared/KH1062/AccessibilityModel"
require "Scripts/Shared/KH1062/AppModel"
require "Scripts/Shared/KH1062/BrowserController"
require "Scripts/Shared/KH1062/BrowserModel"
require "Scripts/Shared/KH1062/HardwareSectionController"
require "Scripts/Shared/KH1062/LedController"
require "Scripts/Shared/KH1062/QuickBrowseController"
require "Scripts/Shared/KH1062/SamplePrehearController"

------------------------------------------------------------------------------------------------------------------------

local DataModel = DataModel()

ControllerScriptInterface = KH1062Model({

    AppModel = AppModel(),
    BrowserModel = BrowserModel(),
    BrowserController = BrowserController(),
    SamplePrehearController = SamplePrehearController(),
    LedController = LedController(),
    HardwareSectionController = HardwareSectionController(),
    ScreenStack = NHLController:getHardwareDisplay():getPageStack(),
    DataController = DataController(DataModel),
    QuickBrowseController = QuickBrowseController(),
    DataModel = DataModel,
    SetupApplicationState = function()
        NI.GUI.enableAbbreviationModeUseDictionary()
    end,
    AccessibilityController = AccessibilityController,
    AccessibilityModel = AccessibilityModel()

})
