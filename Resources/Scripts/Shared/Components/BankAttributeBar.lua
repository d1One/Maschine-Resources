------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
BankAttributeBar = class( 'BankAttributeBar' )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function BankAttributeBar:__init(Screen, Bar)

    -- Controller
    self.Controller = Screen.Page.Controller

    local MainBar = NI.GUI.insertBar( Bar, "BankAttributeBar")
    MainBar:style(NI.GUI.ALIGN_WIDGET_DOWN, "BankAttributeBar")

    self.BankAttributeStack = NI.GUI.insertStack(MainBar, "BankAttributeStack")
    self.BankAttributeStack:style("BankAttributeStack")
    self.BankChainBar = NI.GUI.insertBar(self.BankAttributeStack, "BankChainBar")
    self.BankChainBar:style(NI.GUI.ALIGN_WIDGET_DOWN, "BankChainBar")
    self:createBankChain(Screen)
    self.AttributesBar = NI.GUI.insertBar(self.BankAttributeStack, "AttributesBar")
    self.AttributesBar:style(NI.GUI.ALIGN_WIDGET_DOWN, "AttributesBar")
    self:createAttributes(Screen)

    self:setBankChainMode()

end

------------------------------------------------------------------------------------------------------------------------
-- bank chain creation
------------------------------------------------------------------------------------------------------------------------

function BankAttributeBar:createBankChain(Screen)

    -- insert bank button
    local BankChain = NI.GUI.insertButton(self.BankChainBar, "BankChain")
    BankChain:style("PRODUCT", "AttributeButton")

    local BankSlotBar = NI.GUI.insertBar(self.BankChainBar, "ButtonBar")
    BankSlotBar:style(NI.GUI.ALIGN_WIDGET_RIGHT, "")

    self.BankSlots = {}

    -- insert labels
    self.BankSlots[1] = NI.GUI.insertLabel(BankSlotBar, "Slot1")
    self.BankSlots[1]:style("", "InfoBar")
    local VertLine1 = NI.GUI.insertLabel(BankSlotBar, "VertLine")
    VertLine1:style("", "LineY")
    self.BankSlots[2] = NI.GUI.insertLabel(BankSlotBar, "Slot2")
    self.BankSlots[2]:style("", "InfoBar")
    local VertLine2 = NI.GUI.insertLabel(BankSlotBar, "VertLine")
    VertLine2:style("", "LineY")
    self.BankSlots[3] = NI.GUI.insertLabel(BankSlotBar, "Slot3")
    self.BankSlots[3]:style("", "InfoBar")

    -- label cropping
    NI.GUI.enableCropModeForLabel(self.BankSlots[1])
    NI.GUI.enableCropModeForLabel(self.BankSlots[2])
    NI.GUI.enableCropModeForLabel(self.BankSlots[3])

end

------------------------------------------------------------------------------------------------------------------------
-- attributes creation
------------------------------------------------------------------------------------------------------------------------

function BankAttributeBar:createAttributes(Screen)

    -- insert attributes button
    self.AttributesHeader = NI.GUI.insertButton(self.AttributesBar, "Attributes")
    self.AttributesHeader:style("ATTRIBUTES", "AttributeButton")

    local AttributeBar = NI.GUI.insertBar(self.AttributesBar, "ButtonBar")
    AttributeBar:style(NI.GUI.ALIGN_WIDGET_RIGHT, "")

    self.Attributes = {}

    -- insert labels
    self.Attributes[1] = NI.GUI.insertLabel(AttributeBar, "Type")
    self.Attributes[1]:style("", "InfoBar")
    local VertLine1 = NI.GUI.insertLabel(AttributeBar, "VertLine")
    VertLine1:style("", "LineY")
    self.Attributes[2] = NI.GUI.insertLabel(AttributeBar, "Subtype")
    self.Attributes[2]:style("", "InfoBar")
    local VertLine2 = NI.GUI.insertLabel(AttributeBar, "VertLine")
    VertLine2:style("", "LineY")
    self.Attributes[3] = NI.GUI.insertLabel(AttributeBar, "Mode")
    self.Attributes[3]:style("", "InfoBar")

    -- label cropping
    NI.GUI.enableCropModeForLabel(self.Attributes[1])
    NI.GUI.enableCropModeForLabel(self.Attributes[2])
    NI.GUI.enableCropModeForLabel(self.Attributes[3])

end

------------------------------------------------------------------------------------------------------------------------
-- Modes
------------------------------------------------------------------------------------------------------------------------

function BankAttributeBar:setBankChainMode()

    self.BankAttributeStack:setTopIndex(0)
    self.KnobFunctor = function(Knob, EncoderInc)
			BrowseHelper.offsetBankChain(Knob - 1, EncoderInc)
			self:update(true)
			self.AttributesBar:setAlign()
    	end

end

------------------------------------------------------------------------------------------------------------------------

function BankAttributeBar:setAttributesMode()

    self.BankAttributeStack:setTopIndex(1)
    self.KnobFunctor =
    	function(Knob, EncoderInc)
    		BrowseHelper.offsetAttribute(Knob - 1, EncoderInc)
			self:update(true)
			self.BankChainBar:setAlign()
		end

end

------------------------------------------------------------------------------------------------------------------------

function BankAttributeBar:toggleMode()

    local CurrentPage = self.BankAttributeStack:getTopIndex()

    if CurrentPage == 0 then
        self:setAttributesMode()
    else
        self:setBankChainMode()
    end

end

------------------------------------------------------------------------------------------------------------------------
-- Update
------------------------------------------------------------------------------------------------------------------------

function BankAttributeBar:update(ForceUpdate)

    BrowseHelper.updateBankChain(self.BankSlots, ForceUpdate)
    BrowseHelper.updateAttributes(self.Attributes, ForceUpdate)

    if self.AttributesHeader then
        BrowseHelper.updateAttributesHeader(self.AttributesHeader)
    end

end

------------------------------------------------------------------------------------------------------------------------
-- Event handling
------------------------------------------------------------------------------------------------------------------------

function BankAttributeBar:onKnob(Knob, EncoderInc)

    self.KnobFunctor(Knob, EncoderInc)

end

------------------------------------------------------------------------------------------------------------------------
