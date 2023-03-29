------------------------------------------------------------------------------------------------------------------------
-- BrowsePage unit base.
--
-- A unit is the column of widgets on the KKS hardware consisting of two text displays and the associated encoder.
-- There are 9 units: "Page/Preset" unit with text displays but without an encoder, and 8 subsequent units with
-- text displays and encoders.
--
-- BrowsePageUnitBase defines an interface that knows how to draw into a unit's text displays and process its encoder
-- events.
------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
BrowsePageUnitBase = class( 'BrowsePageUnitBase' )

function BrowsePageUnitBase:__init(Index, Page)

    self.Index = Index
    self.Controller = Page.Controller
    self.Page = Page

    self.DisplayPage = NHLController:getScreen()

    self.DB3Frontend = App:getDatabaseFrontend()
    self.BrowserModel = self.DB3Frontend:getBrowserModel()
    self.AttributesModel = self.BrowserModel:getAttributesModel()
    self.BankChainModel = self.BrowserModel:getBankChainModel()
    self.ProductModel = self.BrowserModel:getProductModel()
    self.ResultListModel = self.BrowserModel:getResultListModel()
    self.BrowserController = self.DB3Frontend:getBrowserController()

    self.KnobEncoderCounter = 0 -- encoder smoother

end

------------------------------------------------------------------------------------------------------------------------
-- Common
------------------------------------------------------------------------------------------------------------------------

function BrowsePageUnitBase:smoothEncoder(KnobValue, Threshold) -- encoder smoother

    local RetVal = 0

    if KnobValue * self.KnobEncoderCounter < 0 then

        -- reset the current delta if signs (knob direction) changes
        self.KnobEncoderCounter = 0

    else

        self.KnobEncoderCounter = self.KnobEncoderCounter + KnobValue

        if KnobValue >= 0 and self.KnobEncoderCounter >= Threshold then

            RetVal = math.floor(self.KnobEncoderCounter / Threshold)
            self.KnobEncoderCounter = self.KnobEncoderCounter - Threshold*RetVal

        elseif KnobValue <= 0 and self.KnobEncoderCounter <= -Threshold then

            RetVal = math.ceil(self.KnobEncoderCounter / Threshold)
            self.KnobEncoderCounter = self.KnobEncoderCounter - Threshold*RetVal

        end

    end

    return RetVal

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageUnitBase:draw()
    -- overriden by descendants
end

------------------------------------------------------------------------------------------------------------------------
-- Komplete Kontrol Only
------------------------------------------------------------------------------------------------------------------------

function BrowsePageUnitBase:getParameterValue()
    -- overriden by descendants
    return ""
end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageUnitBase:getParameterName()
    -- overriden by descendants
    return ""
end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageUnitBase:isEnabled()
    -- overriden by descendants
    return true
end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageUnitBase:isValueChangeDeferred()
    -- overriden by descendants
    return false
end

------------------------------------------------------------------------------------------------------------------------
-- Maschine Only
------------------------------------------------------------------------------------------------------------------------

function BrowsePageUnitBase:onEncoderChanged(Value)
    -- overriden by descendants
end
