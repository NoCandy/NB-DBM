﻿local Vashj = DBM:NewBossMod("Vashj", DBM_VASHJ_NAME, DBM_VASHJ_DESCRIPTION, DBM_COILFANG, DBM_SERPENT_TAB, 6);

Vashj.Version			= "1.2";
Vashj.Author			= "NB-Bodil"; -- Original by Tandanu
Vashj.MinRevision		= 760;

local shieldsDown = 0;
local phase = 1;

local usedIcons = {
	[1]	= false,
	[2] = false,
	[3] = false,
	[4] = false,
	[5] = false,
	[6] = false,
	[7] = false,
	[8] = false
}

--Vashj:RegisterCombat("YELL", {DBM_VASHJ_YELL_PULL1, DBM_VASHJ_YELL_PULL2, DBM_VASHJ_YELL_PULL3, DBM_VASHJ_YELL_PULL4}); -- stupid yells
Vashj:RegisterCombat("COMBAT");

Vashj:RegisterEvents(
	"CHAT_MSG_MONSTER_YELL",
	"SPELL_CAST_SUCCESS",
	"SPELL_AURA_APPLIED",
	"SPELL_AURA_REMOVED",
	"CHAT_MSG_LOOT"
);

Vashj:AddOption("RangeCheck", true, DBM_VASHJ_OPTION_RANGECHECK);
Vashj:AddOption("WarnCharge", true, DBM_VASHJ_OPTION_CHARGE);
Vashj:AddOption("ChargeWhisper", false, DBM_VASHJ_OPTION_CHARGEWHISP);
Vashj:AddOption("IconCharge", true, DBM_VASHJ_OPTION_CHARGEICON);
Vashj:AddOption("WarnSpawns", true, DBM_VASHJ_OPTION_SPAWNS);
Vashj:AddOption("WarnLoot", true, DBM_VASHJ_OPTION_COREWARN);
Vashj:AddOption("IconLoot", true, DBM_VASHJ_OPTION_COREICON);
Vashj:AddOption("SpecWarnLoot", true, DBM_VASHJ_OPTION_CORESPECWARN);

Vashj:AddBarOption("Static Charge: (.*)")
Vashj:AddBarOption("Strider")
Vashj:AddBarOption("Tainted Elemental")
Vashj:AddBarOption("Naga")


function Vashj:OnCombatStart()
	usedIcons = {
		[1]	= false,
		[2] = false,
		[3] = false,
		[4] = false,
		[5] = false,
		[6] = false,
		[7] = false,
		[8] = false
	};
	shieldsDown = 0;
	phase = 1;
	if self.Options.RangeCheck then
		DBM_Gui_DistanceFrame_Show();
	end
end

function Vashj:OnCombatEnd()
	usedIcons = {
		[1]	= false,
		[2] = false,
		[3] = false,
		[4] = false,
		[5] = false,
		[6] = false,
		[7] = false,
		[8] = false
	};
	shieldsDown = 0;
	phase = 1;
	if self.Options.RangeCheck then
		DBM_Gui_DistanceFrame_Hide();
	end
end

function Vashj:OnEvent(event, arg1)
	if event == "SPELL_AURA_APPLIED" then
		if arg1.spellId == 38132 then
			self:SendSync("Loot"..tostring(arg1.destName))
		end
	elseif event == "SPELL_CAST_SUCCESS" then
		if arg1.spellId == 38280 then
			self:SendSync("Charge"..tostring(arg1.destName))
		end
	elseif event == "ClearIcon" and arg1 then
		usedIcons[arg1] = false;
	
	elseif event == "CHAT_MSG_MONSTER_YELL" and arg1 then
		if string.find(arg1, DBM_VASHJ_YELL_PHASE2) then
			phase = 2;
			self:Announce(DBM_VASHJ_WARN_PHASE2, 1);
			
			self:StartStatusBarTimer(62, "Strider", "Interface\\Icons\\INV_Misc_Fish_13");
			self:StartStatusBarTimer(53, "Tainted Elemental", "Interface\\Icons\\Spell_Nature_ElementalShields");
			self:StartStatusBarTimer(47.5, "Naga", "Interface\\Icons\\INV_Misc_MonsterHead_02");
			
			self:ScheduleSelf(47.5, "Spawn", "Naga");
			self:ScheduleSelf(51, "Spawn", "Elemental");
			self:ScheduleSelf(62, "Spawn", "Strider");
			self:ScheduleSelf(42.5, "SpawnSoonWarn", "Naga");
			self:ScheduleSelf(46, "SpawnSoonWarn", "Elemental");
			self:ScheduleSelf(57, "SpawnSoonWarn", "Strider");
		elseif string.find(arg1, DBM_VASHJ_YELL_PHASE3) then
			self:SendSync("Phase3");
		end
		
	elseif event == "SpawnSoonWarn" and arg1 and self.Options.WarnSpawns then		
		if arg1 == "Elemental" then
			self:Announce(DBM_VASHJ_WARN_ELE_SOON, 1);
		elseif arg1 == "Strider" then
			self:Announce(DBM_VASHJ_WARN_STRIDER_SOON, 1);
		elseif arg1 == "Naga" then
			self:Announce(DBM_VASHJ_WARN_NAGA_SOON, 1);
		end
		
	elseif event == "Spawn" and arg1 and phase == 2 then
		-- break loop after wipes
		local wipeCounter = 0;
		for i = 1, GetNumRaidMembers() do
			--if UnitName("raid"..i.."target") == DBM_VASHJ_NAME and not UnitAffectingCombat("raid"..i.."target") then
				--return;
			--end
			if UnitIsDeadOrGhost("raid"..i) then
				wipeCounter = wipeCounter + 1;
			end
		end
		if wipeCounter >= 20 then
			shieldsDown = 0;
			phase = 1;
			return;
		end
		
		if arg1 == "Elemental" then
			if self.Options.WarnSpawns then
				self:Announce(DBM_VASHJ_WARN_ELE_NOW, 3);
			end
			self:StartStatusBarTimer(50, "Tainted Elemental", "Interface\\Icons\\Spell_Nature_ElementalShields");
			self:ScheduleSelf(50, "Spawn", "Elemental");
			self:ScheduleSelf(45, "SpawnSoonWarn", "Elemental");
		elseif arg1 == "Strider" then
			if self.Options.WarnSpawns then
				self:Announce(DBM_VASHJ_WARN_STRIDER_NOW, 2);
			end
			self:ScheduleSelf(60, "Spawn", "Strider");
			self:ScheduleSelf(55, "SpawnSoonWarn", "Strider");
			self:StartStatusBarTimer(60, "Strider", "Interface\\Icons\\INV_Misc_Fish_13");
		elseif arg1 == "Naga" then
			if self.Options.WarnSpawns then
				self:Announce(DBM_VASHJ_WARN_NAGA_NOW, 2);
			end
			self:ScheduleSelf(45, "Spawn", "Naga");
			self:ScheduleSelf(40, "SpawnSoonWarn", "Naga");
			self:StartStatusBarTimer(45, "Naga", "Interface\\Icons\\INV_Misc_MonsterHead_02");
		end

	elseif event == "SPELL_AURA_REMOVED" then
		if arg1.spellId == 38112 then
			self:SendSync("ShieldDown");
		end
		
	elseif event == "CHAT_MSG_LOOT" and arg1 then
		local _, _, player, itemID = string.find(arg1, DBM_VASHJ_LOOT);
		if player and itemID and tonumber(itemID) == 31088 then
			if player == DBM_YOU then
				player = UnitName("player");
			end
			self:SendSync("Loot"..player);
		end
	end
end

function Vashj:OnSync(msg)
	if string.sub(msg, 0, 6) == "Charge" then
		local target = string.sub(msg, 7);		
		
		self:StartStatusBarTimer(20.5, "Static Charge: "..target, "Interface\\Icons\\Spell_Nature_LightningOverload");
		if target == UnitName("player") then
			self:AddSpecialWarning(DBM_VASHJ_SPECWARN_CHARGE);
		end
		if self.Options.WarnCharge then
			self:Announce(string.format(DBM_VASHJ_WARN_CHARGE, target), 1);
		end
		if self.Options.ChargeWhisper then
			self:SendHiddenWhisper(DBM_VASHJ_SPECWARN_CHARGE, target)
		end
		
		local iconID = 0;
		for i = 8, 1, -1 do
			if not usedIcons[i] then
				iconID = i;
				usedIcons[i] = target;
				break;
			end
		end
		if self.Options.IconCharge and iconID ~= 0 and self.Options.Announce and DBM.Rank >= 1 then
			self:SetIcon(target, 20, iconID);
			self:ScheduleSelf(20, "ClearIcon", iconID);
		end
	
	elseif msg == "ShieldDown" then
		shieldsDown = shieldsDown + 1;
		if shieldsDown < 4 then
			self:Announce(string.format(DBM_VASHJ_WARN_SHIELD_FADED, shieldsDown), 3);
		elseif shieldsDown == 4 then
			self:SendSync("Phase3");
		end
	elseif msg == "Phase3" then
		phase = 3;
		self:UnScheduleSelf("Spawn", "Elemental");
		self:UnScheduleSelf("Spawn", "Strider");
		self:UnScheduleSelf("Spawn", "Naga");
		self:UnScheduleSelf("SpawnSoonWarn", "Elemental");
		self:UnScheduleSelf("SpawnSoonWarn", "Strider");
		self:UnScheduleSelf("SpawnSoonWarn", "Naga");
		self:EndStatusBarTimer("Elemental");
		self:EndStatusBarTimer("Strider");
		self:EndStatusBarTimer("Naga");
		self:Announce(DBM_VASHJ_WARN_PHASE3, 3);		

	elseif string.sub(msg, 0, 4) == "Loot" then
		local target = string.sub(msg, 5);
		if self.Options.WarnLoot then
			self:Announce(string.format(DBM_VASHJ_WARN_CORE_LOOT, target), 1);
		end
		if self.Options.IconLoot and self.Options.Announce and DBM.Rank >= 1 then
			self:SetIcon(target, 30);
		end
		if target == UnitName("player") and self.Options.SpecWarnLoot then
			self:AddSpecialWarning(DBM_VASHJ_SPECWARN_CORE);
		end
	end
end
