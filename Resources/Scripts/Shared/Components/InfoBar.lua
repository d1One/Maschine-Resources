------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Components/InfoBarBase"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
InfoBar = class( 'InfoBar', InfoBarBase )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function InfoBar:__init(Controller, ParentBar, Mode)

    -- init base class
    InfoBarBase.__init(self, Controller, ParentBar)

    -- spacer & dotted line
    self.SpacerTop = NI.GUI.insertLabel(ParentBar, "Spacer")
    self.SpacerTop:style("", "Spacer3px")
    self.LineTop = NI.GUI.insertLabel(ParentBar, "Line")
    self.LineTop:style("", "LineX")

    -- insert a bar with 3 labels for transport infos
    self.Labels = {}

    self.Bar = ScreenHelper.createBarWithLabels(ParentBar, self.Labels, {"", "", ""}, "InfoBar", "InfoBar")
    self.Labels[1]:style("", "InfoBarLeft1")
    self.Labels[2]:style("", "InfoBarLeft2")
    self.Labels[3]:style("", "InfoBarLeft3")

    -- spacer & dotted line
    self.LineBottom = NI.GUI.insertLabel(ParentBar, "Line")
    self.LineBottom:style("", "LineX")
    self.SpacerBottom = NI.GUI.insertLabel(ParentBar, "Spacer")
    self.SpacerBottom:style("", "Spacer3px")

    self:setMode(Mode)

    self.Labels[3]:setAutoResize(true)
    self.Bar:setFlex(self.Labels[2])

end

------------------------------------------------------------------------------------------------------------------------

function InfoBar:setActive(Active)

    self.SpacerTop:setActive(Active)
    self.LineTop:setActive(Active)
    self.Bar:setActive(Active)
    self.LineBottom:setActive(Active)
    self.SpacerBottom:setActive(Active)

end

------------------------------------------------------------------------------------------------------------------------

function InfoBar:setMode(Mode)

    if Mode == nil then
       Mode = "Default"
    end

    self.Mode = Mode

    if Mode == "Default" then

        -- Default update: Obj#. Object Name  |  Tempo  |   Song Position
        self.UpdateFunctor = function(ForceUpdate)
            self:updateFocusMixingObjectName(self.Labels[1], ForceUpdate, true)

            if MaschineHelper.isRecordingSample() then
				self.Labels[2]:setText("RECORDING...")
			else
	            InfoBarBase.updateTempo(self.Labels[2], true)
	        end

            self:updatePlayPosition(self.Labels[3], true)
        end

    elseif Mode == "RightScreenDefault" then

		-- right screen empty
		self.UpdateFunctor = function(ForceUpdate)
            self.Labels[2]:setActive(false);
            self.Labels[3]:setActive(false);
        end

    elseif Mode == "RightScreenPresets" then

        -- Used for Plug-in mode on Control page (right screen only); updates the module's preset name
        self.UpdateFunctor = function(ForceUpdate)
            InfoBarBase.updateSoundInfoName(self.Labels[1], ForceUpdate)
            self.Labels[2]:setActive(false);
            self.Labels[3]:setActive(false);
        end

    elseif Mode == "BrowseScreenLeft" then

        self.UpdateFunctor = function(ForceUpdate)
			local DBModel = App:getDatabaseFrontend():getBrowserModel()
			ForceUpdate = ForceUpdate or DBModel:isFileTypeSetStateFlag()

			self:updateFocusMixingObjectName(self.Labels[1], ForceUpdate, true)
			InfoBarBase.updateFocusSlotName(self.Labels[2], ForceUpdate, true)
            self.Labels[3]:setText("")
		end

    elseif Mode == "EventsScreenRight" then

        self.UpdateFunctor = function(ForceUpdate) end -- update functor set from page

    elseif Mode == "PadScreenMode" then

        self.UpdateFunctor = function(ForceUpdate)
            self:updateFocusMixingObjectName(self.Labels[1], ForceUpdate, true)
            self:updateBaseKey(self.Labels[2], ForceUpdate)
            self:updatePlayPosition(self.Labels[3], true)
        end

    elseif  Mode == "BaseKeyOffsetTempMode" then

        self.UpdateFunctor = function(ForceUpdate)
            self:updateFocusMixingObjectName(self.Labels[1], ForceUpdate, true)
            self:updateBaseKeyOffset(self.Labels[2], ForceUpdate)
            self:updatePlayPosition(self.Labels[3], true)
        end

    elseif Mode == "FocusedSoundMode" then

        self.UpdateFunctor = function(ForceUpdate)
            InfoBarBase.updateFocusSound(self.Labels[1], ForceUpdate, true)
            InfoBarBase.updateTempo(self.Labels[2], ForceUpdate)
            self:updatePlayPosition(self.Labels[3], true)
        end

    elseif Mode == "FocusedSongMode" then

        self.UpdateFunctor = function(ForceUpdate)
            InfoBarBase.updateProjectName(self.Labels[1], ForceUpdate)
        end

    elseif Mode == "QuickEdit" then

        self.UpdateFunctor = function(ForceUpdate)
            local QEdit = self.Controller.QuickEdit
            if QEdit and QEdit:isChanged() then
				self.Labels[1]:setText(QEdit:getLevelText() .. " " .. QEdit:getModeText())
                self.Labels[2]:setText("")
				InfoBarBase.updateQEValue(self, self.Labels[3])
			end
        end

        self:update(true)

    elseif Mode == "QuickEditStep" then

        self.UpdateFunctor = function(ForceUpdate)
			self.Labels[1]:setText("STEP " .. StepHelper.getWheelModeText())
			self.Labels[2]:setText("")
			self.Labels[3]:setText(QuickEditHelper.getStepValueText())
		end

    elseif Mode == "ProjectSaved" then

        self.UpdateFunctor = function(ForceUpdate)

            self.Labels[1]:setText("PROJECT SAVED")
            self.Labels[2]:setText("")

        end

    elseif self.Mode == "Loop" then

        self.UpdateFunctor = function(ForceUpdate)

            self.Labels[1]:setText("LOOP")
            self.Labels[2]:setText(ArrangerHelper.getLoopActiveAsString())

        end

    end

end

------------------------------------------------------------------------------------------------------------------------
