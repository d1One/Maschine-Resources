------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Pages/PageMaschine"
require "Scripts/Maschine/Maschine/Pages/ModulePage"
require "Scripts/Shared/Components/SlotStackStudio"
require "Scripts/Shared/Components/ScreenMaschineStudio"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
ModulePageStudio = class( 'ModulePageStudio', ModulePage )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function ModulePageStudio:__init(Controller)

    PageMaschine.__init(self, "ModulePageStudio", Controller)

    -- create screen
    self:setupScreen()

    -- define page leds
    self.PageLEDs = { NI.HW.LED_BROWSE }

end

------------------------------------------------------------------------------------------------------------------------
-- setup screen
------------------------------------------------------------------------------------------------------------------------

function ModulePageStudio:setupScreen()

    -- setup screen
    self.Screen = ScreenMaschineStudio(self)

    -- screen buttons
    self.Screen:styleScreenWithParameters(self.Screen.ScreenLeft,
        {"MASTER", "GROUP", "SOUND", ""},
        {"HeadTabLeft", "HeadTabCenter", "HeadTabRight", "HeadButton"}, false, true)
    self.Screen:styleScreenWithParameters(self.Screen.ScreenRight,
        {"PREVIOUS", "NEXT", "CANCEL", "LOAD"}, "HeadButton", false, false)

    self.Screen.ScreenButton[5]:setStyle("PreviousButton")
    self.Screen.ScreenButton[6]:setStyle("NextButton")

    self.SlotStack = self.Controller.SharedObjects.SlotStack

    -- parameter bar

    ScreenHelper.setWidgetText(self.Screen.ParameterGroupName, {"Attributes", "", "", ""})

    self.Screen.ParameterWidgets[1]:setName("TYPE")
    self.Screen.ParameterWidgets[2]:setName("FORMAT")
    self.Screen.ParameterWidgets[3]:setName("VENDOR")

    -- setup functions of modules vector
    local Size  = function() return ModuleHelper.getResultListSize() end
    local Setup = function(Label) ModulePageStudio.setupResultListItem(self, Label) end
    local Load  = function(Label, Index) ModuleHelper.loadResultListItem(Label, Index) end

    -- insert vector
    self.ResultList = NI.GUI.insertLabelVector(self.Screen.ScreenRight.DisplayBar, "ResultList")
    self.ResultList:style(false, '')
    self.Screen.ScreenRight.DisplayBar:setFlex(self.ResultList)

    self.ResultList:getScrollbar():setAutohide(false)
    self.ResultList:getScrollbar():setShowIncDecButtons(false)

    -- connect vector to functions
    NI.GUI.connectVector(self.ResultList, Size, Setup, Load)


end

------------------------------------------------------------------------------------------------------------------------

function ModulePageStudio:showPluginLoaderControllers(ForceUpdate)
    if BrowseHelper.isInstrumentSlot() then
        self.Controller.CapacitiveList:assignListToCap(1, {"Instrument", "Effect"})
    else
        self.Controller.CapacitiveList:assignListToCap(1, {})
    end

    self.Controller.CapacitiveList:assignListToCap(2, ModuleHelper.getPluginFormatsForCurrentType())

    local VendorList = ModuleHelper.VendorNames[ModuleHelper.getCurrentType()][ModuleHelper.getSelectedFormat()]
    local TypeList = {}

    -- If NI products are installed, we change the name NI to Native Instruments for the studio
    -- We need do the following as tables are passed by reference in Lua and we don`t want to alter the original
    if VendorList[1] == "NI" then

        for Index = 1, #VendorList do
            TypeList[Index] = ModuleHelper.getVendorDisplayName(VendorList[Index])
        end

        TypeList[1] = "Native Instruments"
    else
        TypeList = VendorList
    end

    self.Controller.CapacitiveList:assignListToCap(3, TypeList)

    if ModuleHelper.getCurrentVendorIndex() == -1 then
        local vendors = ModuleHelper.VendorNames[ModuleHelper.getCurrentType()][ModuleHelper.getSelectedFormat()]
        ModuleHelper.CurrentVendor = vendors[1]
    end

    self.Controller.CapacitiveList:setListFocusItem(1,
            ModuleHelper.getCurrentType() == ModuleHelper.TYPE_INSTRUMENT and 0 or 1)

    self.Controller.CapacitiveList:setListFocusItem(2, ModuleHelper.getCurrentFormatIndex())

    self.Controller.CapacitiveList:setListFocusItem(3, ModuleHelper.getCurrentVendorIndex() - 1)
end

function ModulePageStudio:updateParameters(ForceUpdate)

    ModulePage.updateParameters(self, ForceUpdate)

    ModulePageStudio.showPluginLoaderControllers(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function ModulePageStudio:onShow(Show)

    if Show then
        self.SlotStack:insertInto(self.Screen.ScreenLeft.DisplayBar)
        self.Screen.ScreenLeft.DisplayBar:setFlex(self.SlotStack.Stack)

        ModulePageStudio.showPluginLoaderControllers(self, false)
    end

    PageMaschine.onShow(self, Show)

    if NI.HW.FEATURE.JOGWHEEL then
        if Show == true then
            self.OldJogWheelMode = NHLController:getJogWheelMode()
            NHLController:setJogWheelMode(NI.HW.JOGWHEEL_MODE_CUSTOM)

        elseif self.OldJogWheelMode then
            NHLController:setJogWheelMode(self.OldJogWheelMode)
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function ModulePageStudio:updateScreens(ForceUpdate)

    -- Update InfoBar
    self.Screen.ScreenLeft.InfoBar:update(ForceUpdate)

    self.SlotStack:update(ForceUpdate)

    -- Call base
    ModulePage.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function ModulePageStudio:updateScreenButtons(ForceUpdate)

    -- call base
    ModulePage.updateScreenButtons(self, ForceUpdate)

    local HeadTab    = "HeadTabCenter"
    self.Screen.ScreenButton[2]:style("GROUP", HeadTab)     -- note: setStyle() doesn't work!

end

------------------------------------------------------------------------------------------------------------------------

function ModulePageStudio:updateJogwheel()

    if NI.HW.FEATURE.JOGWHEEL then

        LEDHelper.setLEDState(NI.HW.LED_JOGWHEEL_BROWSE, LEDHelper.LS_BRIGHT)
        JogwheelLEDHelper.updateAllOn(MaschineStudioController.JOGWHEEL_RING_LEDS)

    end

    local LED_Left = NI.HW.FEATURE.JOGWHEEL and NI.HW.LED_TRANSPORT_PREV or NI.HW.LED_WHEEL_BUTTON_LEFT
    local LED_Right = NI.HW.FEATURE.JOGWHEEL and NI.HW.LED_TRANSPORT_NEXT or NI.HW.LED_WHEEL_BUTTON_RIGHT
    local BUTTON_Left = NI.HW.FEATURE.JOGWHEEL and NI.HW.BUTTON_TRANSPORT_PREV or NI.HW.BUTTON_WHEEL_LEFT
    local BUTTON_Right = NI.HW.FEATURE.JOGWHEEL and NI.HW.BUTTON_TRANSPORT_NEXT or NI.HW.BUTTON_WHEEL_RIGHT

    local ListSize = ModuleHelper.getResultListSize()
    local CanPrev = ModuleHelper.getCurrentModuleIndex() > 0
    local CanNext = ListSize > 0 and ModuleHelper.getCurrentModuleIndex() < ListSize - 1

    LEDHelper.updateButtonLED(self.Controller, LED_Left, BUTTON_Left, CanPrev)
    LEDHelper.updateButtonLED(self.Controller, LED_Right, BUTTON_Right, CanNext)

    return true

end

------------------------------------------------------------------------------------------------------------------------

function ModulePageStudio:updateWheelButtonLEDs()

    if NI.HW.FEATURE.JOYCODER then

        local CanLeft = ControlHelper.hasPrevNextSlotOrPageGroup(false, false)
        local CanRight = ControlHelper.hasPrevNextSlotOrPageGroup(true, false)
        local Color = LEDColors.WHITE

        LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_WHEEL_BUTTON_UP, NI.HW.BUTTON_WHEEL_UP, false, Color)
        LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_WHEEL_BUTTON_DOWN, NI.HW.BUTTON_WHEEL_DOWN, false, Color)
        LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_WHEEL_BUTTON_LEFT, NI.HW.BUTTON_WHEEL_LEFT, CanLeft, Color)
        LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_WHEEL_BUTTON_RIGHT, NI.HW.BUTTON_WHEEL_RIGHT, CanRight, Color)

    end

end

------------------------------------------------------------------------------------------------------------------------
-- Resultlist vector callbacks
------------------------------------------------------------------------------------------------------------------------

function ModulePageStudio:setupResultListItem(Label)

    Label:style("", "ListItem")
    NI.GUI.enableCropModeForLabel(Label)

end

------------------------------------------------------------------------------------------------------------------------
-- Event handling
------------------------------------------------------------------------------------------------------------------------

function ModulePageStudio:onWheel(Inc)

    if NI.HW.FEATURE.JOYCODER or NHLController:getJogWheelMode() == NI.HW.JOGWHEEL_MODE_CUSTOM then

        self:onScreenEncoder(5, Inc)
        NHLController:triggerAccessibilitySpeech(NI.HW.ZONE_ERPS, 8)

        return true

    end

	return false

end

------------------------------------------------------------------------------------------------------------------------

function ModulePageStudio:onWheelButton(Pressed)

    if Pressed and (NI.HW.FEATURE.JOYCODER or NHLController:getJogWheelMode() == NI.HW.JOGWHEEL_MODE_CUSTOM) then
        ModuleHelper.loadModule()
        ModuleHelper.closeModulePage(self.Controller)
    end

    return true

end

------------------------------------------------------------------------------------------------------------------------

function ModulePageStudio:onWheelDirection(Pressed, Button)

    if Pressed then
        if Button == NI.HW.BUTTON_WHEEL_LEFT or Button == NI.HW.BUTTON_WHEEL_RIGHT then
            ControlHelper.onPrevNextSlot(Button == NI.HW.BUTTON_WHEEL_RIGHT, false)
        end
    else
        local ModuleName = MaschineHelper.getFocusChannelSlotName()
        NHLController:addAccessibilityControlData(NI.HW.ZONE_SCREENINFO, 0, 0, 0, 0, ModuleName)
        NHLController:triggerAccessibilitySpeech(NI.HW.ZONE_SCREENINFO, 0)
    end

    self:updateWheelButtonLEDs()

end

------------------------------------------------------------------------------------------------------------------------

function ModulePageStudio:onPrevNextButton(Pressed, Next)

    ModulePage.onPrevNextButton(self, Pressed, Next)

    return true

end

------------------------------------------------------------------------------------------------------------------------

function ModulePageStudio:onScreenButton(ButtonIdx, Pressed)

    if Pressed and ButtonIdx == 8 and BrowseHelper.getInsertMode() ~= NI.DATA.INSERT_MODE_OFF then

        -- call base class here already,
        -- to properly set LED states before page change
        PageMaschine.onScreenButton(self, ButtonIdx, true)

        ModuleHelper.loadModuleInsertMode()
        ModuleHelper.closeModulePage(self.Controller)

		self:updateScreens()

    else

        ModulePage.onScreenButton(self, ButtonIdx, Pressed)

    end

end

------------------------------------------------------------------------------------------------------------------------

function ModulePageStudio:focusedItemInfo()
    local Info = {}
    Info.SpeechSectionName = ""
    Info.SpeechName = MaschineHelper.getFocusChannelSlotName()
    Info.SpeechValue = ""
    Info.SpeakNameInNormalMode = false
    Info.SpeakValueInNormalMode = true
    Info.SpeakNameInTrainingMode = true
    Info.SpeakValueInTrainingMode = true

    return Info
end

------------------------------------------------------------------------------------------------------------------------

function ModulePageStudio:getAccessiblePageInfo()

    return "Plug-in Browser"

end

------------------------------------------------------------------------------------------------------------------------
