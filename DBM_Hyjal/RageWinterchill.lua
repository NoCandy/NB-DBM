local Rage = DBM:NewBossMod("Rage", DBM_RAGE_NAME, DBM_RAGE_DESCRIPTION, DBM_MOUNT_HYJAL, DBM_HYJAL_TAB, 1);

Rage.Version	= "1.1";
Rage.Author		= "NB-Bodil"; -- Original by Tandanu

Rage:RegisterCombat("YELL", DBM_RAGE_YELL_PULL, nil, nil, nil, 60);

Rage:AddOption("WarnIce", true, DBM_RAGE_OPTION_ICEBOLT);
Rage:AddOption("IceIcon", true, DBM_RAGE_OPTION_ICON);
Rage:AddOption("WarnDnD", true, DBM_RAGE_OPTION_DND);
Rage:AddOption("WarnDnDSoon", true, DBM_RAGE_OPTION_DND_SOON);

Rage:AddBarOption("Death & Decay")
Rage:AddBarOption("Next Death & Decay")

Rage:RegisterEvents(
	"SPELL_AURA_APPLIED",
	"UNIT_SPELLCAST_CHANNEL_START",
	"SPELL_CAST_START",
	"SPELL_DAMAGE"
);

function Rage:OnCombatStart(delay)
	self:StartStatusBarTimer(45 - delay, "Next Death & Decay", "Interface\\Icons\\Spell_Shadow_DeathAndDecay");
	self:ScheduleSelf(40 - delay, "WarnDnDSoon");
end

function Rage:OnEvent(event, arg1)
	if event == "SPELL_DAMAGE" then
		if arg1.spellId == 31249 then
			self:SendSync("Icebolt"..tostring(arg1.destName))
		end	
	elseif event == "SPELL_AURA_APPLIED" then
		if arg1.spellId == 31258 and arg1.destName == UnitName("player") then
			self:AddSpecialWarning(DBM_RAGE_SPECWARN_DND_YOU);
		end
	elseif event == "UNIT_SPELLCAST_CHANNEL_START" and type(arg1) == "string" and UnitName(arg1) == DBM_RAGE_NAME then
		if UnitChannelInfo(arg1) == DBM_RAGE_SPELL_DEATH_DECAY then
			self:SendSync("DnD");
		end
	elseif event == "SPELL_CAST_START" then
		if arg1.spellId == 31258 then
			self:SendSync("CastDnD");
		end
	elseif event == "DnDEnd" then
		if self.Options.WarnDnD then
			self:Announce(DBM_RAGE_WARN_DND_END, 1);
		end
		self:StartStatusBarTimer(55, "Next Death & Decay", "Interface\\Icons\\Spell_Shadow_DeathAndDecay");
		self:ScheduleSelf(50, "WarnDnDSoon");
	elseif event == "WarnDnDSoon" then
		if self.Options.WarnDnDSoon then
			self:Announce(DBM_RAGE_WARN_DND_SOON, 1);
		end
	end
end

function Rage:OnSync(msg)
	if msg:sub(0, 7) == "Icebolt" and self.InCombat then
		msg = msg:sub(8);
		if self.Options.WarnIce then
			self:Announce(DBM_RAGE_WARN_ICEBOLT:format(msg), 2);
		end
		if self.Options.IceIcon then
			self:SetIcon(msg, 4);
		end
	elseif msg == "DnD" then
		self:StartStatusBarTimer(15, "Death & Decay", "Interface\\Icons\\Spell_Shadow_DeathAndDecay");
		self:ScheduleSelf(15, "DnDEnd");
		self:SendSync("CastDnD");
	elseif msg == "CastDnD" then
		if self.Options.WarnDnD then
			self:Announce(DBM_RAGE_WARN_DND, 3);
		end
	end
end