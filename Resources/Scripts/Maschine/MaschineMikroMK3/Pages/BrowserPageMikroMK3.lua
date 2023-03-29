------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/MaschineMikroMK3/Pages/PageMikroMK3"
require "Scripts/Maschine/MaschineMK3/Helper/MK3Helper"
require "Scripts/Shared/Helpers/MiscHelper"
require "Scripts/Shared/Helpers/WidgetHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
BrowserPageMikroMK3 = class( 'BrowserPageMikroMK3', PageMikroMK3 )

------------------------------------------------------------------------------------------------------------------------

function BrowserPageMikroMK3:__init(Controller)

    PageMikroMK3.__init(self, "BrowserPageMikroMK3", Controller)

end

------------------------------------------------------------------------------------------------------------------------

function BrowserPageMikroMK3:setupScreen()

    PageMikroMK3.setupScreen(self)
    self.StarIcon = NI.GUI.insertLabel(self.Screen.BottomBar, "StarIcon")
    self.StarIcon:style("", "star")

end

------------------------------------------------------------------------------------------------------------------------

function BrowserPageMikroMK3:onShow(Show)

    if Show then
        BrowseHelper.forceCacheRefresh()
    end

    PageMikroMK3.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function BrowserPageMikroMK3:updateScreen()

    if BrowseHelper.isBusy() then
        return
    end

    self.Screen
        :setTopRowIcon(string.lower(BrowseHelper.getFileTypeName()), "")
        :setTopRowText(BrowseHelper.getFileTypeName().."s")
        :updateScrollbar(BrowseHelper.getResultListSize(), BrowseHelper.getResultListFocusItem())

    if BrowseHelper.getResultListSize() > 0 then
        local ResultListModel = App:getDatabaseFrontend():getBrowserModel():getResultListModel()
        local FocusItem = BrowseHelper.getResultListFocusItem()
        self.Screen:setBottomRowText(ResultListModel:getItemName(FocusItem))
        self.StarIcon:setActive(BrowseHelper.isFocusItemFavorite())
    else
        local ShowingFavourites = BrowseHelper.isFavoritesFilterEnabled()
        self.Screen:setBottomRowText(ShowingFavourites and "No ★" or "No Results")
        self.StarIcon:setActive(false)
    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowserPageMikroMK3:onDB3ModelChanged(Model)

    Model = BrowseHelper.updateCachedData(Model)

    if Model == NI.DB3.MODEL_RESULTS then
        self:updateScreen()
    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowserPageMikroMK3:onPadEvent(PadIndex, Trigger, PadValue)

    if Trigger then
        local IsPadMode = NHLController:getPadMode() == NI.HW.PAD_MODE_SOUND

        if BrowseHelper.canPrehear() then
            BrowseHelper.prehearViaPad(PadIndex)
        elseif IsPadMode then
            MaschineHelper.setFocusSound(PadIndex)
        end
    end

    if PadModeHelper.isStepModeEnabled() and not self.Controller:isShiftPressed() then
        StepHelper.onPadEvent(PadIndex, Trigger, PadValue)
    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowserPageMikroMK3:onWheelEvent(EncoderInc)

    local Increment = BrowseHelper.getIncrementStepMikroMK3(EncoderInc, self.Controller:isShiftPressed())
    BrowseHelper.offsetResultListFocusBy(Increment, true)

end


------------------------------------------------------------------------------------------------------------------------
