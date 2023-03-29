local FunctionChecker = require("Scripts/Shared/Components/FunctionChecker")
require "Scripts/Shared/Components/ScreenMikroASeriesBase"
require "Scripts/Shared/KH1062/Pages/KH1062Page"

return function (PageName, ScreenStack, IdeaSpaceModel, IdeaSpaceController, Callbacks, OptionalArgs)

    local Screen = ScreenMikroASeriesBase(PageName, ScreenStack, OptionalArgs)
    local Page = KH1062Page(Screen)

    FunctionChecker.checkFunctionsExist(Callbacks, {"isShiftPressedFunc", "closePatternLengthEditorFunc"})

    Screen:setTopRowIcon()
          :setBottomRowIcon()
          :showParameterInBottomRow()
          :setParameterName("Length")

    Page.updateScreen = function()

        Screen:setTopRowText(IdeaSpaceModel:getFocusPatternName())
              :setParameterValue(IdeaSpaceModel:getFocusPatternLengthString())

    end

    Page.onWheel = function(_, Delta)

        local Fine = Callbacks.isShiftPressedFunc()
        IdeaSpaceController:incrementPatternLength(Delta, Fine)

    end

    Page.SwitchEventTable:setHandler({ Switch = NI.HW.BUTTON_WHEEL, Shift = false, Pressed = true },
        function() Callbacks.closePatternLengthEditorFunc() end
    )

    return Page

end