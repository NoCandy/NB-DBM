local TerestianIllhoof = DBM:NewBossMod("TerestianIllhoof", DBM_TI_NAME, DBM_TI_DESCRIPTION, DBM_KARAZHAN, DBM_KARAZHAN_TAB, 9);

TerestianIllhoof.Version			= "1.1";
TerestianIllhoof.Author			= "NB-Bodil"; -- Original by Tandanu

TerestianIllhoof:RegisterEvents(
	"SPELL_AURA_APPLIED",
	"CHAT_MSG_MONSTER_EMOTE",
	"SPELL_CAST_SUCCESS",
	"SPELL_SUMMON",
	"UNIT_DIED"
);

TerestianIllhoof:RegisterCombat("YELL", DBM_TI_YELL_PULL);

TerestianIllhoof:AddOption("ImpSoon", true, DBM_TI_OPTION_1);
TerestianIllhoof:AddOption("SacrificeSoon", false, DBM_TI_OPTION_2);

TerestianIllhoof:AddBarOption("Kil'rek Respawn")
TerestianIllhoof:AddBarOption("Sacrifice")

function TerestianIllhoof:OnEvent(event, arg1)
	if event == "SacrificeWarning" and self.Options.SacrificeSoon then
		self:Announce(DBM_TI_SACRIFICE_SOON, 2);
	
	elseif event == "UNIT_DIED" then
		if arg1.destName == DBM_TI_IMP_DIES then
			self:StartStatusBarTimer(45, "Kil'rek Respawn", "Interface\\Icons\\Spell_shadow_summonimp");
			self:Announce(DBM_TI_WEAKENED_WARN, 1);
			self:ScheduleSelf(40, "ImpRespawn", "soon");
		end
	
	--elseif event == "CHAT_MSG_MONSTER_EMOTE" then
		--if arg1 == DBM_TI_EMOTE_IMP then
			--self:StartStatusBarTimer(45, "Weakened", "Interface\\Icons\\Spell_Shadow_BloodBoil");
			--self:Announce(DBM_TI_WEAKENED_WARN, 1);
			--self:ScheduleSelf(40, "ImpRespawn", "soon");
		--end
	elseif event == "ImpRespawn" and self.Options.ImpSoon then
		if arg1 == "soon" then
			self:Announce(DBM_TI_IMP_SOON, 1);
		end
	elseif event == "SPELL_SUMMON" then
		if arg1.spellId == 30066 and self.Options.ImpSoon then
			self:Announce(DBM_TI_IMP_RESPAWNED, 2);
		end
	elseif event == "SPELL_AURA_APPLIED" then
		if arg1.spellId == 30115 then
			local target = arg1.destName
			if target then
				self:Announce(string.format(DBM_TI_SACRIFICE_WARN, target), 3);
				self:StartStatusBarTimer(30, "Sacrifice", "Interface\\Icons\\Spell_Shadow_AntiMagicShell");
				self:UnScheduleSelf("SacrificeWarning", "soon");
				self:ScheduleSelf(25, "SacrificeWarning", "soon");
			end
		end
	end
end
