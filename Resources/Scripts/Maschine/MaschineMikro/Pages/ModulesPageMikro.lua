------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/MaschineMikro/PageMikro"
require "Scripts/Maschine/MaschineMikro/BrowseScreenMikro"
require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Maschine/Helper/ModuleHelper"

local ATTR_LIST_VISIBLE = NI.UTILS.Symbol("ListVisible")

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
ModulesPageMikro = class( 'ModulesPageMikro', PageMikro )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function ModulesPageMikro:__init(Controller)

    -- init base class
    PageMikro.__init(self, "ModulesPage", Controller)

    -- setup screen
    self:setupScreen()

    -- define page leds
    self.PageLEDs = { NI.HW.LED_BROWSE }

    -- track filter/list mode
    self.ListVisible = false

end

------------------------------------------------------------------------------------------------------------------------
-- setup screen
------------------------------------------------------------------------------------------------------------------------

function ModulesPageMikro:setupScreen()

    -- setup screen
    self.Screen = BrowseScreenMikro(self)

    -- Screen Buttons
    self.Screen:styleScreenButtons({"FILTER", "LIST", ""}, "HeadTabRow", "HeadTab")

    -- info bar
    self.Screen.InfoBar:setMode("FocusedSlot")

    -- setup parameter handler
    self.ParameterHandler:setLabels(self.Screen.ParameterLabel[2], self.Screen.ParameterLabel[4])

    -- screen has NavMode by default
    self.Screen:setNavMode(false)

end

------------------------------------------------------------------------------------------------------------------------
-- update
------------------------------------------------------------------------------------------------------------------------

function ModulesPageMikro:updateScreens(ForceUpdate)

    -- screen buttons
    self:updateScreenButtons()

    local StateCache = App:getStateCache()

    if StateCache:isMixingLayerChanged() or StateCache:isFocusSlotChanged() or ForceUpdate then

        if ModuleHelper.getCurrentVendorIndex() == -1 then
            local vendors = ModuleHelper.VendorNames[ModuleHelper.getCurrentType()][ModuleHelper.getSelectedFormat()]
            ModuleHelper.CurrentVendor = vendors[1]
        end

        ModuleHelper.refreshResultList(self.ResultList)

    end

    -- title
    self.Screen.InfoBar:updateFocusMixingObjectName(self.Screen.Title[1], ForceUpdate, true)

    -- screen buttons
    self.Screen.ScreenButton[1]:setSelected(not self.ListVisible)
    self.Screen.ScreenButton[2]:setSelected(self.ListVisible)

    -- parameter handler
    self.ParameterHandler.UpdateFunctor = self.ListVisible and
        function(Force, NameLabel, ValueLabel) self:updateResultList(Force, NameLabel, ValueLabel) end or
                function(Force, NameLabel, ValueLabel) self:updateFilterTypes(Force, NameLabel, ValueLabel) end

    -- call base class
    PageMikro.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function ModulesPageMikro:updateParameters(ForceUpdate)

    if self.Screen:getNavMode() == 1 then
        return
    end

    PageMikro.updateParameters(self, ForceUpdate)

    self.Screen.ParameterBar[1]:setActive(not self.ListVisible)   -- setActive because of styling issues
    self.Screen.ParameterBar[2]:setAttribute(ATTR_LIST_VISIBLE, self.ListVisible and "true" or "false")

    self.Screen.ParameterLabel[1]:setVisible(not self.ListVisible and self.ParameterHandler.ParameterIndex > 1)
    self.Screen.ParameterLabel[3]:setVisible(not self.ListVisible
                                            and self.ParameterHandler.ParameterIndex < #self.ParameterHandler.Parameters)
    self.Screen.ParameterLabel[4]:setAttribute(ATTR_LIST_VISIBLE, self.ListVisible and "true" or "false")

end

------------------------------------------------------------------------------------------------------------------------

function ModulesPageMikro:updateScreenButtons()

    if self.Screen:getNavMode() > 0 then
        self.Screen.ScreenButton[3]:setSelected(true)
        self.Screen.ScreenButton[3]:setText("PLUG-IN")
        return
    end

    self.Screen:styleScreenButtons({"FILTER", "LIST", ""}, "HeadTabRow", "HeadTab")

    self.Screen.ScreenButton[1]:setSelected(not self.ListVisible)
    self.Screen.ScreenButton[2]:setSelected(self.ListVisible)

end

------------------------------------------------------------------------------------------------------------------------

function ModulesPageMikro:updateFilterTypes(ForceUpdate, NameLabel, ValueLabel)

    local IsInstrumentSlot = BrowseHelper.isInstrumentSlot()

    self.ParameterHandler:setParameters(IsInstrumentSlot and {"TYPE", "FORMAT", "VENDOR"} or {"FORMAT", "VENDOR"}, false)
    if not IsInstrumentSlot and self.ParameterHandler.ParameterIndex > 2 then
        self.ParameterHandler.ParameterIndex = 2
    end

    local Name = self.ParameterHandler.ParameterIndex..(BrowseHelper.isInstrumentSlot() and "/3: " or "/2: ")
                ..self.ParameterHandler.Parameters[self.ParameterHandler.ParameterIndex]
    local Value = ""

    if BrowseHelper.isInstrumentSlot() then
        if self.ParameterHandler.ParameterIndex == 1 then
            Value = ModuleHelper.getCurrentType() == ModuleHelper.TYPE_INSTRUMENT and "INSTRUMENT" or "EFFECT"
        elseif self.ParameterHandler.ParameterIndex == 2 then
            Value = ModuleHelper.getSelectedFormat()
        else
            Value = ModuleHelper.getVendorDisplayName(ModuleHelper.getCurrentVendor())
        end
    else
        if self.ParameterHandler.ParameterIndex == 1 then
            Value = ModuleHelper.getSelectedFormat()
        else
            Value = ModuleHelper.getVendorDisplayName(ModuleHelper.getCurrentVendor())
        end
    end

    NameLabel:setActive(true)
    NameLabel:setText(Name)
    ValueLabel:setText(Value)

end

------------------------------------------------------------------------------------------------------------------------

function ModulesPageMikro:updateResultList(ForceUpdate, NameLabel, ValueLabel)

    self.ParameterHandler:setParameters({}, false)

    NameLabel:setActive(false)
    ModuleHelper.loadResultListItem(ValueLabel, ModuleHelper.getCurrentModuleIndex())

end

------------------------------------------------------------------------------------------------------------------------

function ModulesPageMikro:updatePadLEDs()

    if self.Controller:getNavPressed() then

        local MixingLayer    = NI.DATA.StateHelper.getFocusMixingLayer(App)
        local ColorParameter = MixingLayer and MixingLayer:getColorParameter() or nil

        LEDHelper.updateLEDsWithFunctor(self.Controller.PAD_LEDS, 0,
            function(Index) return BrowseHelper.getLEDStatesSlotSelectedByIndex(Index,
                self.Controller:getShiftPressed()) end,
            function() return ColorParameter and ColorParameter:getValue() or 16 end)

    else

        Page.updatePadLEDs(self)

    end

end

------------------------------------------------------------------------------------------------------------------------

function ModulesPageMikro:updateLeftRightLEDs(ForceUpdate)

    if self.Screen:getNavMode() == 1 then
        LEDHelper.setLEDState(NI.HW.LED_LEFT, LEDHelper.LS_OFF)
        LEDHelper.setLEDState(NI.HW.LED_RIGHT, LEDHelper.LS_OFF)
        return
    end

    if self.ListVisible then

        local HasNext = ModuleHelper.getCurrentModuleIndex() < ModuleHelper.getResultListSize() - 1
        local HasPrev = ModuleHelper.getCurrentModuleIndex() > 0

        LEDStateRight = HasNext and LEDHelper.LS_DIM or LEDHelper.LS_OFF
            LEDStateLeft  = HasPrev and LEDHelper.LS_DIM or LEDHelper.LS_OFF

        -- update left/right page leds
        if not self.Controller.SwitchPressed[NI.HW.BUTTON_RIGHT] then
            LEDHelper.setLEDState(NI.HW.LED_RIGHT, LEDStateRight)
        end

        if not self.Controller.SwitchPressed[NI.HW.BUTTON_LEFT] then
            LEDHelper.setLEDState(NI.HW.LED_LEFT, LEDStateLeft)
        end

    else

        -- call base class
        PageMikro.updateLeftRightLEDs(self, ForceUpdate)

    end

end

------------------------------------------------------------------------------------------------------------------------
-- event processing
------------------------------------------------------------------------------------------------------------------------

function ModulesPageMikro:onShow(Show)

    -- LED states
    if Show then
        LEDHelper.setLEDState(NI.HW.LED_NAV, LEDHelper.LS_DIM)
    else
        self.Screen:setNavMode(false)
    end

    -- call base class
    Page.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function ModulesPageMikro:onWheelButton(Pressed)

    if self.Screen:getNavMode() == 1 then
        return
    end

    if Pressed and self.ListVisible then
        ModuleHelper.loadModule()
        ModuleHelper.closeModulePage(self.Controller)
    end

end

------------------------------------------------------------------------------------------------------------------------

function ModulesPageMikro:incrementType(Inc)

    local NewType = math.bound(
        ModuleHelper.getCurrentType() + Inc, ModuleHelper.TYPE_INSTRUMENT, ModuleHelper.TYPE_EFFECT)

    if NewType ~= ModuleHelper.getCurrentType() then
        ModuleHelper.setCurrentType(NewType)
        self:updateScreens(true)
    end

end

------------------------------------------------------------------------------------------------------------------------

function ModulesPageMikro:incrementFormat(Inc)

    local NewFormatIndex = math.bound(
        ModuleHelper.getCurrentFormatIndex() + Inc, 0, #ModuleHelper.getPluginFormatsForCurrentType() - 1)

    if NewFormatIndex ~= ModuleHelper.getCurrentFormatIndex() then
        ModuleHelper.format = ModuleHelper.getPluginFormatsForCurrentType()[NewFormatIndex + 1]
        self:updateScreens(true)
    end
   
end

------------------------------------------------------------------------------------------------------------------------

function ModulesPageMikro:incrementVendor(Inc)

    if ModuleHelper.getCurrentVendorIndex() ~= -1 then
        local VendorListSize = #ModuleHelper.VendorNames[ModuleHelper.getCurrentType()][ModuleHelper.getSelectedFormat()]
        local NewVendor = math.bound(
            ModuleHelper.getCurrentVendorIndex() + Inc, 1,
            VendorListSize)

        if NewVendor ~= ModuleHelper.getCurrentVendorIndex() then
            ModuleHelper.CurrentVendor = ModuleHelper.VendorNames[ModuleHelper.getCurrentType()][ModuleHelper.getSelectedFormat()][NewVendor]

            self:updateScreens(true)
        end
    else
        ModuleHelper.format = ModuleHelper.INTERNAL
        self:updateScreens(true)
    end

end

------------------------------------------------------------------------------------------------------------------------

function ModulesPageMikro:onWheel(Inc)

    if self.Screen:getNavMode() == 1 then

        local StateCache    = App:getStateCache()
        local FocusChain    = NI.DATA.StateHelper.getFocusChainSlots(App)

        NI.DATA.ChainAccess.shiftSlotFocus(App, FocusChain, Inc)
        return true
    end

    if self.ListVisible then

        ModuleHelper.CurrentModuleIndex[ModuleHelper.getCurrentType()][ModuleHelper.getSelectedFormat()][ModuleHelper.getCurrentVendor()] =
            math.bound(ModuleHelper.getCurrentModuleIndex() + Inc, 0, ModuleHelper.getResultListSize() - 1)
        ModuleHelper.loadResultListItem(self.Screen.ParameterLabel[4], ModuleHelper.getCurrentModuleIndex())
        self:updateLeftRightLEDs()

    else

        if BrowseHelper.isInstrumentSlot() then
            if self.ParameterHandler.ParameterIndex == 1 then
                self:incrementType(Inc)
            elseif self.ParameterHandler.ParameterIndex == 2 then
                self:incrementFormat(Inc)
            else
                self:incrementVendor(Inc)
            end
        else
            if self.ParameterHandler.ParameterIndex == 1 then
                self:incrementFormat(Inc)
            else
                self:incrementVendor(Inc)
            end
        end

    end

    return true

end

------------------------------------------------------------------------------------------------------------------------

function ModulesPageMikro:onPadEvent(PadIndex, Trigger, PadValue)

        if self.Screen:getNavMode() == 1 then

        if Trigger then

            local Slots = NI.DATA.StateHelper.getFocusChainSlots(App)

            if Slots then
                if self.Controller:getShiftPressed() then
                    local Slot = Slots:at(PadIndex - 1)
                    if Slot then
                        local ActiveParameter = Slot:getActiveParameter()
                        NI.DATA.ParameterAccess.setBoolParameter(App, ActiveParameter,
                           not ActiveParameter:getValue())
                    end
                else
                    if PadIndex <= Slots:size() then
                        NI.DATA.ChainAccess.setFocusSlot(App, Slots, Slots:at(PadIndex - 1), false)

                        local FocusSlotIndex = NI.DATA.StateHelper.getFocusSlotIndex(App)
                        if PadIndex - 1 == FocusSlotIndex then
                            ControlHelper.togglePluginWindow()
                        end
                    elseif PadIndex == Slots:size() + 1 then
                        NI.DATA.ChainAccess.setFocusSlot(App, Slots, nil, false)
                    end
                end
            end

        end

        else

                PageMikro.onPadEvent(self, PadIndex, Trigger, PadValue)

        end

end

------------------------------------------------------------------------------------------------------------------------

function ModulesPageMikro:onScreenButton(ButtonIdx, Pressed)

    if Pressed  and self.Screen:getNavMode() == 0 then

        if ButtonIdx == 1 then

            self.ListVisible = false

        elseif ButtonIdx == 2 then

            self.ListVisible = true
            ModuleHelper.refreshResultList()

        end

    end

    -- call base class for update
    PageMikro.onScreenButton(self, ButtonIdx, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function ModulesPageMikro:onPageButton(Button, PageID, Pressed)

    if Pressed and Button == NI.HW.BUTTON_BROWSE then
        if self.Controller:getShiftPressed() then
            NHLController:getPageStack():replacePage(NI.HW.PAGE_MODULE, NI.HW.PAGE_BROWSE)
        else
            NHLController:getPageStack():popPage()
        end

        return true
    end

    -- call base class
    return PageMikro.onPageButton(self, Button, PageID, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function ModulesPageMikro:onLeftRightButton(Right, Pressed)

    if Pressed and self.Screen:getNavMode() == 0 then

        local Inc = Right and 1 or -1

        if self.ListVisible then

            local HasNext = ModuleHelper.getCurrentModuleIndex() < ModuleHelper.getResultListSize() - 1
            local HasPrev = ModuleHelper.getCurrentModuleIndex() > 0

            if (Right and HasNext) or (not Right and HasPrev) then

                LEDHelper.setLEDState(Right and NI.HW.LED_RIGHT or NI.HW.LED_LEFT, LEDHelper.LS_BRIGHT)
                self:onWheel(Inc)
                ModuleHelper.loadModule()
                ModuleHelper.closeModulePage(self.Controller)

            end

        else

            self.ParameterHandler:increaseParameter(Inc)
            self:updateParameters(true)

        end

    end

end

------------------------------------------------------------------------------------------------------------------------
