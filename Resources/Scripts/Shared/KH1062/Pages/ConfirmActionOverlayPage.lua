require "Scripts/Shared/KH1062/Pages/KH1062Page"

require "Scripts/Shared/Components/ScreenMikroASeriesBase"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
ConfirmActionOverlayPage = class( 'ConfirmActionOverlayPage', KH1062Page )

------------------------------------------------------------------------------------------------------------------------

function ConfirmActionOverlayPage:__init(PageName,
                                         ScreenStack,
                                         SwitchHandler,
                                         CancelActionFunc)

    KH1062Page.__init(self, ScreenMikroASeriesBase(PageName, ScreenStack), SwitchHandler)
    self.CancelActionFunc = CancelActionFunc

end

------------------------------------------------------------------------------------------------------------------------

function ConfirmActionOverlayPage:setupScreen()

    KH1062Page.setupScreen(self)
    self.Screen:setupScreen()

end

------------------------------------------------------------------------------------------------------------------------

function ConfirmActionOverlayPage:onShow(Show)

    KH1062Page.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function ConfirmActionOverlayPage:updateScreen()

    KH1062Page.updateScreen()
    self.Screen:setTopRowTextAttribute("bold")
    self.Screen:setTopRowText(self.ActionText)
    self.Screen:setBottomRowIcon("pressencoder", "")
    self.Screen:setBottomRowTextAttribute("")
    self.Screen:setBottomRowText(self.ConfirmText)

end

------------------------------------------------------------------------------------------------------------------------

function ConfirmActionOverlayPage:onConfirmAction()

    if self.ConfirmActionFunc then
        self:ConfirmActionFunc()
    end

end

------------------------------------------------------------------------------------------------------------------------

function ConfirmActionOverlayPage:onCancelAction()

    if self.CancelActionFunc then
        self:CancelActionFunc()
    end

end

------------------------------------------------------------------------------------------------------------------------

function ConfirmActionOverlayPage:configureAction(ActionText, ConfirmText, ButtonIdCancel, ConfirmActionFunc)

    self.ActionText = ActionText
    self.ConfirmText = ConfirmText
    self.ConfirmActionFunc = ConfirmActionFunc
    self.SwitchEventTable = SwitchEventTable()
    self.SwitchEventTable:setHandler({ Switch = NI.HW.BUTTON_WHEEL, Pressed = true },
                                        function() self:onConfirmAction() end)
    self.SwitchEventTable:setHandler({ Switch = ButtonIdCancel, Pressed = true },
                                        function() self:onCancelAction() end)

end

------------------------------------------------------------------------------------------------------------------------

function ConfirmActionOverlayPage:onStateFlagsChanged()

    -- App state has changed - close this overlay
    self:onCancelAction()

end