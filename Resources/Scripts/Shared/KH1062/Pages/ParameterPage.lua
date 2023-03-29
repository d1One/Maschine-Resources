require "Scripts/Shared/Components/ScreenMikroASeriesBase"
local AccessibilityHelper = require("Scripts/Shared/KH1062/AccessibilityHelper")
require "Scripts/Shared/KH1062/Pages/KH1062Page"


return function (PageName, ScreenStack, SwitchHandler, getFocusParameterData, OptionalArgs)

    local Screen = ScreenMikroASeriesBase(PageName, ScreenStack, OptionalArgs)
    local Page = KH1062Page(Screen, SwitchHandler)

    local function getDisplayNameOrNoParameter(DisplayName)

        return DisplayName and DisplayName or "No Parameter"

    end

    Page.updateScreen = function (self)

        local ParameterData = getFocusParameterData()
        if not ParameterData then
            return
        end

        Screen:setTopRowIcon()
              :setTopRowText(ParameterData.SectionName or "")
              :setBottomRowIcon()
              :setParameterName(getDisplayNameOrNoParameter(ParameterData.DisplayName))
              :setParameterValue(ParameterData.DisplayValue or "")
              :showParameterInBottomRow()


    end

    Page.sayPage = function (self)

        local ParameterData = getFocusParameterData()
        if not ParameterData then
            return
        end
        local DisplayName = getDisplayNameOrNoParameter(ParameterData.DisplayName)
        local Environment = OptionalArgs
        if Environment then
            Environment.AccessibilityController.say(
                AccessibilityHelper.getChangedParameterTextFromPage(
                    Environment.AccessibilityModel.ParameterPageCache,
                    ParameterData.SectionName,
                    DisplayName)
            )
            Environment.AccessibilityController.setParameterPageCache({
                SectionName = ParameterData.SectionName,
                DisplayName = DisplayName
            })
        end

    end

    return Page

end