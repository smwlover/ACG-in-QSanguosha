module("extensions.Danganronpa",package.seeall)
extension=sgs.Package("Danganronpa");

sgs.LoadTranslationTable{
	["dgrp"]="弹",
	["Danganronpa"]="弹丸论破",
}

--技能暗将
SkillAnJiang=sgs.General(extension,"SkillAnJiang","dgrp","5",true,true,true)

--失去“未来”时清除“未来”标记，全局技能
MiraiClearMark = sgs.CreateTriggerSkill{
	name = "#MiraiClearMark",
	events = {sgs.EventAcquireSkill, sgs.EventLoseSkill},
	global = true,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local name = data:toString()
		if name == "LuaMirai" then
			if event == sgs.EventAcquireSkill then
				if player:getMark("@mirai") == 0 then
					player:gainMark("@mirai")
				end
			elseif event == sgs.EventLoseSkill then
				if player:getMark("@mirai") > 0 then
					player:loseAllMarks("@mirai")
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end,
}
local skill=sgs.Sanguosha:getSkill("#MiraiClearMark")
if not skill then
	local skillList=sgs.SkillList()
	skillList:append(MiraiClearMark)
	sgs.Sanguosha:addSkills(skillList)
end --全局触发技

--Chapter 1

--Togami Byakuya Fake
TogamiByakuyaFake=sgs.General(extension,"TogamiByakuyaFake","dgrp","4",true)

--ShiShen
LuaShiShen = sgs.CreateTriggerSkill{
	name = "LuaShiShen" ,
	events = {sgs.PreCardUsed} ,
	frequency = sgs.Skill_Compulsory ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card and use.card:isKindOf("AmazingGrace") then
			local togami = room:findPlayerBySkillName(self:objectName())
			if (not togami) or (not togami:isAlive()) then
				return false
			end
			if use.to:contains(togami) then
				--修改use.to中存储的角色的顺序
				while use.to:at(0):objectName() ~= togami:objectName() do
					local p=use.to:at(0)
					use.to:removeAt(0)
					use.to:append(p)
				end
				
				--技能发动特效
				room:notifySkillInvoked(togami,self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				--发送信息
				local log = sgs.LogMessage()
				log.type = "#TriggerSkill"
				log.from = togami
				log.arg = self:objectName()
				room:sendLog(log)
				
				data:setValue(use) --设置新的结算顺序
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
}

--YinHu
LuaYinHu=sgs.CreateTriggerSkill{
	name = "LuaYinHu" ,
	events = {sgs.DamageInflicted} ,
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local victim = damage.to
		local source = damage.from
		local card = damage.card
		local room = victim:getRoom()
		if (not source) or (not source:isAlive()) then
			return false
		end
		if (not card) or (not card:isKindOf("Slash")) then
			return false
		end
		if victim:isKongcheng() then
			return false
		end --受伤害的角色没有手牌，无法触发该技能
		local togami = room:findPlayerBySkillName(self:objectName())
		if (not togami) or (not togami:isAlive()) then
			return false
		end
		--检查是否在十神的攻击范围内
		if not togami:inMyAttackRange(victim) then
			return false
		end
		
		local victimData = sgs.QVariant()
		victimData:setValue(victim)
		--询问是否发动技能
		if room:askForSkillInvoke(togami,self:objectName(),victimData) then
			--指示线
			room:doAnimate(1, togami:objectName(), victim:objectName())
		
			local card = nil
			if victim:getHandcardNum() > 1 then
				card = room:askForCard(victim, ".!", "@giveCard:"..source:objectName(), sgs.QVariant(), sgs.Card_MethodNone)
				if not card then
					card = victim:getHandcards():at(math.random(0, victim:getHandcardNum() - 1))
				end
			else
				card = victim:getHandcards():first()
			end
			room:obtainCard(source,card,false)
			
			--发送信息
			local msg = sgs.LogMessage()
			msg.type = "#YinHuPrevent"
			msg.from = source
			msg.to:append(victim)
			msg.arg = damage.card:objectName()
			room:sendLog(msg)
			return true --防止伤害
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
}

--ZhaQi
LuaZhaQi = sgs.CreateTriggerSkill{
	name = "LuaZhaQi" ,
	events = {sgs.GameStart} ,
	frequency = sgs.Skill_Wake ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local trigger = false
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if p:getGeneralName()=="TogamiByakuya" or p:getGeneral2Name()=="TogamiByakuya" then
				trigger=true
				break
			end
		end
		if trigger then
			--技能发动特效
			room:notifySkillInvoked(player,self:objectName())
			room:broadcastSkillInvoke(self:objectName())
			--发送信息
			local log = sgs.LogMessage()
			log.type = "#ZhaQiWaking"
			log.from = player
			log.arg = self:objectName()
			log.arg2 = "TogamiByakuya"
			room:sendLog(log)
			--全屏特效
			room:doLightbox("ZhaQi$", 2500)
			
			if room:changeMaxHpForAwakenSkill(player) then
				room:acquireSkill(player, "nosguhuo") --获得旧版蛊惑
			end
		end
		return false
	end,
}

TogamiByakuyaFake:addSkill(LuaShiShen)
TogamiByakuyaFake:addSkill(LuaYinHu)
TogamiByakuyaFake:addSkill(LuaZhaQi)

sgs.LoadTranslationTable{	
	["TogamiByakuyaFake"]="十神白夜-伪",
	["&TogamiByakuyaFake"]="十神",
	["#TogamiByakuyaFake"]="超高校级的欺诈师",
	["designer:TogamiByakuyaFake"]="Smwlover",
	["illustrator:TogamiByakuyaFake"]="Ruby",
	
	["LuaShiShen"]="食神",
	[":LuaShiShen"]="<font color=\"blue\"><b>锁定技，</b></font>一名角色使用【五谷丰登】指定目标后，若你是目标之一，则该【五谷丰登】从你开始结算。",
	["LuaYinHu"]="荫护",
	[":LuaYinHu"]="你攻击范围内的一名角色受到【杀】造成的伤害时，你可以令其交给此【杀】的使用者一张手牌，然后防止此伤害。",
	["LuaZhaQi"]="诈欺",
	[":LuaZhaQi"]="<font color=\"purple\"><b>觉醒技，</b></font>游戏开始时，若场上有两名名为<font color=\"purple\">十神白夜</font>的角色，你减少1点体力上限，然后获得技能“蛊惑”。",
	
	["@giveCard"]="请交给 %src 一张手牌",
	["#YinHuPrevent"]="%from 对 %to 使用【%arg】造成的伤害被防止",
	["#ZhaQiWaking"]="场上有两名名为 %arg2 的角色， %from 的觉醒技 %arg 被触发",
	["ZhaQi$"]="image=image/animate/zhaqi.png",
}

--Hanamura Teruteru
HanamuraTeruteru=sgs.General(extension,"HanamuraTeruteru","dgrp","3",true)

--NianRe
NianReCard = sgs.CreateSkillCard{
	name = "NianReCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		if sgs.Self:getHp() <= 2 then
			return #targets == 0 and (not to_select:isKongcheng()) and to_select:objectName() ~= sgs.Self:objectName()
		else
			return #targets == 0 and (not to_select:isMale()) and (not to_select:isKongcheng()) and to_select:objectName() ~= sgs.Self:objectName()
		end
	end,
	feasible = function(self, targets)
		return #targets == 1
	end,
	on_use = function(self, room, source, targets)
		--技能触发效果
		room:notifySkillInvoked(source, "LuaNianRe")
		room:broadcastSkillInvoke("LuaNianRe")
		
		local success = source:pindian(targets[1], "LuaNianRe", self)
		if success then
			local player = targets[1]
			if source:isAlive() and player:isAlive() and (not player:isAllNude()) then
				--发送信息
				local msg = sgs.LogMessage()
				msg.type = "#NianReObtain"
				msg.from = source
				msg.to:append(player)
				room:sendLog(msg)
				
				local card_id = room:askForCardChosen(source, player, "hej", "LuaNianRe")
				room:obtainCard(source, sgs.Sanguosha:getCard(card_id), room:getCardPlace(card_id) ~= sgs.Player_PlaceHand)
			end
		else --视为使用杀
			if targets[1]:canSlash(source, nil, false) then
				--发送信息
				local msg = sgs.LogMessage()
				msg.type = "#NianReSlash"
				msg.from = targets[1]
				msg.to:append(source)
				room:sendLog(msg)
					
				local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				slash:setSkillName("LuaNianRe")
				local card_use = sgs.CardUseStruct()
				card_use.card = slash
				card_use.from = targets[1]
				card_use.to:append(source)
				room:useCard(card_use, false)
			end
		end
	end,
}

LuaNianRe = sgs.CreateViewAsSkill{
	name = "LuaNianRe",
	n = 1,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = NianReCard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return (not player:hasUsed("#NianReCard")) and (not player:isKongcheng())
	end,
}

--PinWei
LuaPinWei = sgs.CreateTriggerSkill{
	name = "LuaPinWei" ,
	frequency = sgs.Skill_Frequent,
	events = {sgs.CardUsed, sgs.CardResponded, sgs.Pindian},
	on_trigger = function(self, event, player, data)
		if event==sgs.CardUsed then
			local room = player:getRoom()
			local hanamura = room:findPlayerBySkillName(self:objectName())
			if (not hanamura) or (not hanamura:isAlive()) or (hanamura:objectName() ~= player:objectName()) then 
				return false 
			end --不是自己使用的情况
			local use = data:toCardUse()
			if not use.card:isKindOf("SkillCard") then
				if use.card:getSuit() == sgs.Card_Heart then
					if player:askForSkillInvoke(self:objectName()) then
						player:drawCards(1)
					end
				end
			end
		elseif event==sgs.CardResponded then
			local room = player:getRoom()
			local hanamura = room:findPlayerBySkillName(self:objectName())
			if (not hanamura) or (not hanamura:isAlive()) or (hanamura:objectName() ~= player:objectName()) then 
				return false 
			end
			local response = data:toCardResponse()
			if not response.m_card:isKindOf("SkillCard") then
				if response.m_card:getSuit() == sgs.Card_Heart then
					if player:askForSkillInvoke(self:objectName()) then
						player:drawCards(1)
					end
				end
			end
		elseif event==sgs.Pindian then
			local pindian = data:toPindian()
			local hanamura = nil
			local card = nil
			if (pindian.from and pindian.from:isAlive() and pindian.from:hasSkill(self:objectName())) then
				hanamura = pindian.from
				card = pindian.from_card
			elseif (pindian.to and pindian.to:isAlive() and pindian.to:hasSkill(self:objectName())) then
				hanamura = pindian.to
				card = pindian.to_card
			end
			if hanamura and hanamura:isAlive() then
				if card and card:getSuit() == sgs.Card_Heart then
					if hanamura:askForSkillInvoke(self:objectName()) then
						hanamura:drawCards(1)
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end,
}

HanamuraTeruteru:addSkill(LuaPinWei)
HanamuraTeruteru:addSkill(LuaNianRe)

sgs.LoadTranslationTable{	
	["HanamuraTeruteru"]="花村辉辉",
	["&HanamuraTeruteru"]="花村",
	["#HanamuraTeruteru"]="超高校级的料理人",
	["designer:HanamuraTeruteru"]="Smwlover",
	["illustrator:HanamuraTeruteru"]="Ruby",
	
	["LuaPinWei"]="大厨",
	[":LuaPinWei"]="你使用或打出一张红桃牌时，或将一张红桃牌作为拼点牌亮出时，可以摸一张牌。",
	["LuaNianRe"]="拈惹",
	[":LuaNianRe"]="<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以与一名女性角色拼点。若你赢，你获得该角色区域中的一张牌；若你没赢，视为该角色对你使用了一张【杀】。若你的体力值不大于2，去掉描述中的“女性”。",
	["nianre"]="拈惹",
	
	["#NianReObtain"]="%from 拼点赢，需要从 %to 的区域中获得一张牌。",
	["#NianReSlash"]="%to 拼点没赢，视为 %from 对 %to 使用一张【杀】。",
}

--Chapter 2

--Koizumi Mahiru
KoizumiMahiru=sgs.General(extension,"KoizumiMahiru","dgrp","3",false)

--PaiYou
PaiYouCard = sgs.CreateSkillCard{
	name = "LuaPaiYou",
	filter = function(self, targets, to_select, player)
		return #targets == 0 and to_select:isWounded()
	end,
	feasible = function(self, targets)
		return #targets == 1
	end,
	on_use = function(self, room, source, targets)
		--技能发动特效
		room:notifySkillInvoked(source,"LuaPaiYou")
		room:broadcastSkillInvoke("LuaPaiYou")
	
		local recover = sgs.RecoverStruct()
		recover.who = source --是小泉真昼令其回复体力的
		room:recover(targets[1],recover) --回复1点体力
	end,
}

LuaPaiYouVS = sgs.CreateViewAsSkill{
	name = "LuaPaiYou",
	response_pattern = "@@LuaPaiYou",
	n = 1,
	view_filter = function(self, selected, to_select)
		return to_select:isRed()
	end,
	view_as = function(self, cards)
		if #cards == 0 then
			return 
		end
		local paiyouCard = PaiYouCard:clone()
		paiyouCard:addSubcard(cards[1])
		return paiyouCard
	end,
}

LuaPaiYou = sgs.CreateTriggerSkill {
	name = "LuaPaiYou",
	events = {sgs.EventPhaseStart},
	view_as_skill = LuaPaiYouVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Finish and (not player:isNude()) then
			local trigger = false
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:isWounded() then
					trigger = true
					break
				end
			end
			if trigger then
				room:askForUseCard(player, "@@LuaPaiYou", "@LuaPaiYou")
			end
		end
		return false
	end,
}

--DingGe
LuaDingGe=sgs.CreateTriggerSkill{
	name = "LuaDingGe",
	events = {sgs.HpRecover},
	on_trigger = function(self, event, player, data)
		local room=player:getRoom()
		local koizumi = room:findPlayerBySkillName(self:objectName())
		if (not koizumi) or (not koizumi:isAlive()) then
			return false
		end
		local recoverData = sgs.QVariant()
		recoverData:setValue(player)
		if room:askForSkillInvoke(koizumi,self:objectName(),recoverData) then
			--指示线
			room:doAnimate(1, koizumi:objectName(), player:objectName())
			
			if player:getEquips():length() == 0 then
				player:drawCards(2)
			else
				player:drawCards(1)
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
}

KoizumiMahiru:addSkill(LuaPaiYou)
KoizumiMahiru:addSkill(LuaDingGe)

sgs.LoadTranslationTable{	
	["KoizumiMahiru"]="小泉真昼",
	["&KoizumiMahiru"]="小泉",
	["#KoizumiMahiru"]="超高校级的写真家",
	["designer:KoizumiMahiru"]="Smwlover",
	["illustrator:KoizumiMahiru"]="Ruby",
	
	["LuaPaiYou"]="排忧",
	[":LuaPaiYou"]="结束阶段开始时，你可以弃置一张红色牌，令一名角色回复1点体力。",
	["LuaDingGe"]="定格",
	[":LuaDingGe"]="一名角色回复体力时，你可以令其摸一张牌。若该角色装备区没有装备牌，改为令其摸两张牌。",
	
	["luapaiyou"]="排忧",
	["@LuaPaiYou"]="你可以发动“排忧”",
	["~LuaPaiYou"]="选择一张红色牌→选择一名角色→点“确定”",
}

--Pekoyama Peko
PekoyamaPeko=sgs.General(extension,"PekoyamaPeko","dgrp","3",false)

--ZiDian
LuaZiDian = sgs.CreateTriggerSkill{
	name = "LuaZiDian",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageCaused},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.chain or damage.transfer or not damage.by_user then 
			return false 
		end --必须是目标角色
		local card = damage.card
		if card and card:isKindOf("Slash") then
			if damage.from and damage.to:getHp() > damage.from:getHp() then
				damage.damage = damage.damage + 1
				data:setValue(damage)
				
				--技能发动特效
				room:notifySkillInvoked(damage.from,self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				--指示线
				room:doAnimate(1, player:objectName(), damage.to:objectName())
				--发送信息
				local msg = sgs.LogMessage()
				msg.type = "#ZiDianDamage"
				msg.from = damage.from
				msg.arg = damage.damage - 1
				msg.arg2 = damage.damage
				room:sendLog(msg)
			end
		end
		return false
	end,
}

--GuoJue
LuaGuoJue = sgs.CreateTriggerSkill{
	name = "LuaGuoJue" ,
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.PreHpRecover},
	on_trigger = function(self, event, player, data)
		if player:askForSkillInvoke("LuaGuoJue",sgs.QVariant("prevent")) then
			local targets = sgs.SPlayerList()
			local room = player:getRoom()
			local list = room:getAlivePlayers()
			for _,target in sgs.qlist(list) do
				if player:canSlash(target, nil, false) then
					targets:append(target)
				end
			end
			if targets:isEmpty() then
				return false
			end
			local target = room:askForPlayerChosen(player, targets, self:objectName(),"@GuoJueInvoke",false,false)
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			slash:setSkillName(self:objectName())
			local card_use = sgs.CardUseStruct()
			card_use.card = slash
			card_use.from = player
			card_use.to:append(target)
			room:useCard(card_use, false)
			return true
		end
		return false
	end,
}

--TouShen
TouShenCard = sgs.CreateSkillCard{
	name = "TouShenCard",
	target_fixed = false,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	feasible = function(self, targets)
		return #targets == 1
	end,
	on_use = function(self, room, source, targets)
		--技能发动特效
		room:notifySkillInvoked(source,"LuaTouShen")
		room:broadcastSkillInvoke("LuaTouShen")
		--全屏特效
		room:doLightbox("TouShen$", 2500)
	
		source:loseMark("@toushen")
		targets[1]:gainMark("@toushen_target")
		room:obtainCard(targets[1],source:wholeHandCards(),false)
	end,
}

LuaTouShenVS = sgs.CreateViewAsSkill{
	name = "LuaTouShen",
	n = 0,
	view_as = function(self, cards)
		local card=TouShenCard:clone()
		return card
	end,
	enabled_at_play = function(self, player)
		return (player:getMark("@toushen") >= 1) and (not player:isKongcheng())
	end
}

LuaTouShen = sgs.CreateTriggerSkill{
	name = "LuaTouShen" ,
	frequency = sgs.Skill_Limited,
	limit_mark = "@toushen",
	events = {},
	view_as_skill = LuaTouShenVS ,
	on_trigger = function()
		return false
	end
}

LuaTouShenProhibit = sgs.CreateProhibitSkill{
	name = "#LuaTouShenProhibit",
	is_prohibited = function(self, from, to, card)
		return ((from:hasSkill(self:objectName()) and to:getMark("@toushen_target")>0) or (to:hasSkill(self:objectName()) and from:getMark("@toushen_target")>0)) and card:isKindOf("Slash")
	end,
}

LuaTouShenUse = sgs.CreateTriggerSkill{
	name = "#LuaTouShenUse",
	events = {sgs.CardUsed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card and use.card:isKindOf("Slash") then			
			local pekoyama = room:findPlayerBySkillName(self:objectName())
			if pekoyama and pekoyama:isAlive() then
				use.from = pekoyama
				data:setValue(use)
				
				--技能发动特效
				room:notifySkillInvoked(pekoyama,"LuaTouShen")
				room:broadcastSkillInvoke("LuaTouShen")
				--指示线
				for _, p in sgs.qlist(use.to) do
					room:doAnimate(1, use.from:objectName(), p:objectName())
				end
				--发送信息
				local msg = sgs.LogMessage()
				msg.type="#TouShenUse"
				msg.from = pekoyama
				msg.arg = use.card:objectName()
				room:sendLog(msg)
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:isAlive() and target:getMark("@toushen_target")>0
	end,
}

LuaTouShenUsed = sgs.CreateTriggerSkill{
	name = "#LuaTouShenUsed",
	events = {sgs.TargetConfirming},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card and use.card:isKindOf("Slash") and use.to:contains(player) then
			local pekoyama = room:findPlayerBySkillName(self:objectName())
			if pekoyama and pekoyama:isAlive() then
				if use.from:objectName() ~= pekoyama:objectName() and use.from:canSlash(pekoyama, use.card, false) then				
					use.to:removeOne(player)
					use.to:append(pekoyama)
					room:sortByActionOrder(use.to)
					data:setValue(use)
					
					--技能发动特效
					room:notifySkillInvoked(pekoyama,"LuaTouShen")
					room:broadcastSkillInvoke("LuaTouShen")
					--指示线
					room:doAnimate(1, use.from:objectName(), pekoyama:objectName())
					--发送信息
					local msg = sgs.LogMessage()
					msg.type = "#TouShenUsed"
					msg.to = use.to
					msg.arg = use.card:objectName()
					room:sendLog(msg)
					
					room:getThread():trigger(sgs.TargetConfirming, room, pekoyama, data)
					return false
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:isAlive() and target:getMark("@toushen_target")>0
	end,
}

LuaTouShenDie = sgs.CreateTriggerSkill{
	name = "#LuaTouShenDie" ,
	events = {sgs.Death} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local death = data:toDeath()
		if death.who:getMark("@toushen_target") > 0 then
			local pekoyama = room:findPlayerBySkillName(self:objectName())
			if (not pekoyama) or (not pekoyama:isAlive()) then
				return false
			end
			
			--技能发动特效
			room:notifySkillInvoked(pekoyama,"LuaTouShen")
			room:broadcastSkillInvoke("LuaTouShen")
			--发送信息
			local msg = sgs.LogMessage()
			msg.type = "#TouShenDie"
			msg.to:append(pekoyama)
			room:sendLog(msg)
			
			room:killPlayer(pekoyama)
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and (not target:hasSkill(self:objectName()))
	end,
}

PekoyamaPeko:addSkill(LuaZiDian)
PekoyamaPeko:addSkill(LuaGuoJue)
PekoyamaPeko:addSkill(LuaTouShen)
PekoyamaPeko:addSkill(LuaTouShenProhibit)
PekoyamaPeko:addSkill(LuaTouShenUse)
PekoyamaPeko:addSkill(LuaTouShenUsed)
PekoyamaPeko:addSkill(LuaTouShenDie)
extension:insertRelatedSkills("LuaTouShen","#LuaTouShenProhibit")
extension:insertRelatedSkills("LuaTouShen","#LuaTouShenUse")
extension:insertRelatedSkills("LuaTouShen","#LuaTouShenUsed")
extension:insertRelatedSkills("LuaTouShen","#LuaTouShenDie")

sgs.LoadTranslationTable{	
	["PekoyamaPeko"]="边古山佩子",
	["&PekoyamaPeko"]="边古山",
	["#PekoyamaPeko"]="超高校级的剑道家",
	["designer:PekoyamaPeko"]="Smwlover",
	["illustrator:PekoyamaPeko"]="Ruby",
	
	["LuaGuoJue"]="果决",
	[":LuaGuoJue"]="你即将回复体力时，可以防止之。若如此做，视为你对一名其他角色使用了一张【杀】（不计入出牌阶段使用次数限制）。",
	["LuaGuoJue:prevent"]="你可以防止回复体力，并且视为对一名角色使用一张【杀】",
	["LuaZiDian"]="紫电",
	[":LuaZiDian"]="<font color=\"blue\"><b>锁定技，</b></font>你使用【杀】对体力值大于你的目标角色造成的伤害+1。",
	["LuaTouShen"]="投身",
	[":LuaTouShen"]="<font color=\"red\"><b>限定技，</b></font>出牌阶段，你可以将所有手牌交给一名其他角色，若如此做，直到游戏结束或你死亡：<br />该角色使用【杀】指定目标时，视为此【杀】由你使用；<br />该角色成为【杀】的目标时，将此【杀】的目标转移给你；<br />你不能对该角色使用【杀】；该角色不能对你使用【杀】；<br />该角色死亡后，你立即死亡。",
	
	["toushen"]="投身",
	["@toushen"]="投身",
	["@toushen_target"]="投身目标",
	["@GuoJueInvoke"]="请选择一名角色视为对其使用【杀】",
	
	["#ZiDianDamage"]="%from 的武将技能“紫电”被触发，伤害从 %arg 点增加至 %arg2 点。",
	["#TouShenUse"]="因为“投身”的影响，此【%arg】视为由 %from 使用。",
	["#TouShenUsed"]="因为“投身”的影响，此【%arg】的目标改为 %to。",
	["#TouShenDie"]="因为“投身”的影响， %to 死亡。",
	["TouShen$"]="image=image/animate/toushen.png",
}

--Chapter 3 

--Saionji Hiyoko
SaionjiHiyoko=sgs.General(extension,"SaionjiHiyoko","dgrp","3",false)

--DuShe
LuaDuShe = sgs.CreateTriggerSkill{
	name = "LuaDuShe" ,
	events = {sgs.Damaged} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local source = damage.from
		local victim = damage.to
		local can_get = false
		local disabled_ids = sgs.IntList()
		--可以移动哪些装备
		if source and source:hasEquip() then
			for i = 0, 3, 1 do
				if source:getEquip(i) then
					if victim:getEquip(i) then
						disabled_ids:append(source:getEquip(i):getEffectiveId())
					else
						can_get = true
					end
				end
			end	
		end
		--选择选项
		local choice = nil
		if can_get then
			choice = room:askForChoice(victim, self:objectName(),"nothing+DuSheDraw+DuSheMove",data)
		else
			choice = room:askForChoice(victim, self:objectName(),"nothing+DuSheDraw",data)
		end
		if choice == "DuSheMove" then
			--指示线
			room:doAnimate(1, victim:objectName(), source:objectName())
			--技能发动特效
			room:notifySkillInvoked(victim,"LuaDuShe")
			room:broadcastSkillInvoke("LuaDuShe")
			--发送消息
			local msg = sgs.LogMessage()
			msg.type = "#SkillInvoke"
			msg.from = victim
			msg.arg = self:objectName()
			room:sendLog(msg)
			
			local card_id = room:askForCardChosen(victim, source, "e", self:objectName(), false, sgs.Card_MethodNone, disabled_ids)
			if victim:property("DuSheMoveID"):toString() ~= "" then
				room:setPlayerProperty(victim, "DuSheMoveID", sgs.QVariant(""))
			end
			room:moveCardTo(sgs.Sanguosha:getCard(card_id), victim, sgs.Player_PlaceEquip)
		elseif choice == "DuSheDraw" then
			--技能发动特效
			room:notifySkillInvoked(victim,"LuaDuShe")
			room:broadcastSkillInvoke("LuaDuShe")
			--发送消息
			local msg = sgs.LogMessage()
			msg.type = "#SkillInvoke"
			msg.from = victim
			msg.arg = self:objectName()
			room:sendLog(msg)
			
			victim:drawCards(1)
		end
		return false
	end,
}

--ShanWu	
ShanWuCard = sgs.CreateSkillCard{
	name="ShanWuCard",
	target_fixed=false,
	filter = function(self, targets, to_select, player)
		local length = self:getSubcards():length()
		return #targets < length and to_select:isWounded()
	end,
	feasible = function(self, targets)
		local length = self:getSubcards():length()
		return #targets == length
	end,
	on_use = function(self, room, source, targets)
		--技能发动特效
		room:notifySkillInvoked(source,"LuaShanWu")
		room:broadcastSkillInvoke("LuaShanWu")
		
		for i=1, #targets, 1 do
			local recover = sgs.RecoverStruct()
			recover.who = source
			room:recover(targets[i],recover)
		end
		if #targets >= 3 then
			source:turnOver()
		end
	end,
}

LuaShanWu = sgs.CreateViewAsSkill{
	name = "LuaShanWu",
	n=999,
	view_filter = function(self, selected, to_select)
		return to_select:isKindOf("EquipCard")
	end,
	view_as=function(self, cards)
		if #cards == 0 then
			return nil
		end
		local card=ShanWuCard:clone()
		card:setSkillName(self:objectName())
		for _, c in ipairs(cards) do
			card:addSubcard(c)
		end
		return card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#ShanWuCard")
	end,
}

SaionjiHiyoko:addSkill(LuaShanWu)
SaionjiHiyoko:addSkill(LuaDuShe)

sgs.LoadTranslationTable{	
	["SaionjiHiyoko"]="西园寺日寄子",
	["&SaionjiHiyoko"]="西园寺",
	["#SaionjiHiyoko"]="超高校级的日本舞蹈家",
	["designer:SaionjiHiyoko"]="Smwlover",
	["illustrator:SaionjiHiyoko"]="Ruby",
	
	["LuaShanWu"]="扇舞",
	[":LuaShanWu"]="<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以弃置任意数量的装备牌，然后令等量的角色依次回复1点体力。若你以此法令三名或以上的角色回复体力，你须将武将牌翻面。",
	["LuaDuShe"]="毒舌",
	[":LuaDuShe"]="每当你受到伤害后，你可以选择一项：将伤害来源装备区中的一张装备牌移动到你装备区中的相应位置，或者摸一张牌。",
	
	["nothing"]="不发动",
	["DuSheDraw"]="摸一张牌",
	["DuSheMove"]="移动装备牌",
	["shanwu"]="扇舞",
	["#SkillInvoke"]="%from 发动了技能 %arg",
}

--Mioda Ibuki
MiodaIbuki=sgs.General(extension,"MiodaIbuki","dgrp","3",false)

--YanYi
function getColorStr(card)
	if card:isRed() then
		return "red"
	elseif card:isBlack() then
		return "black"
	end
	return "unknown"
end

YanYiCard = sgs.CreateSkillCard{
	name = "LuaYanYi",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		--技能发动特效
		room:notifySkillInvoked(source,"LuaYanYi")
		room:broadcastSkillInvoke("LuaYanYi")
		
		--展示技能卡
		room:showCard(source, self:getEffectiveId())
		--设置标记
		local card = sgs.Sanguosha:getCard(self:getSubcards():first())
		room:setPlayerProperty(source, "LuaYanYiPattern", sgs.QVariant(card:objectName()))
		room:setPlayerProperty(source, "LuaYanYiColor", sgs.QVariant(getColorStr(card)))
	end,
}

YanYiFixed = sgs.CreateSkillCard{
	name = "YanYiFixed",
	target_fixed = true,
	will_throw = false,
	on_validate = function(self, use)
		local subcard = sgs.Sanguosha:getCard(self:getSubcards():first())
		local suit = subcard:getSuit()
		local point = subcard:getNumber()
		local id = subcard:getId()
		local pattern = self:getUserString()
		local vscard = sgs.Sanguosha:cloneCard(pattern, suit, point)
		vscard:addSubcard(id)
		vscard:setSkillName("LuaYanYi")
		return vscard
	end,
}

YanYiUnfixed = sgs.CreateSkillCard{
	name = "YanYiUnfixed",
	target_fixed = false,
	will_throw = false,
	filter = function(self, selected, to_select)
		local pattern = self:getUserString()
		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_NoSuit, 0)
		local targetlist = sgs.PlayerList()
		for _,p in pairs(selected) do
			targetlist:append(p)
		end
		return card:targetFilter(targetlist, to_select, sgs.Self)
	end,
	feasible = function(self, targets)
		return #targets ~= 0 --这里必须要限定一下目标数量不能为0，因为铁索连环只能使用不能重铸
	end,
	on_validate = function(self, use)
		local subcard = sgs.Sanguosha:getCard(self:getSubcards():first())
		local suit = subcard:getSuit()
		local point = subcard:getNumber()
		local id = subcard:getId()
		local pattern = self:getUserString()
		local vscard = sgs.Sanguosha:cloneCard(pattern, suit, point)
		vscard:addSubcard(id)
		vscard:setSkillName("LuaYanYi")
		return vscard
	end,
}

LuaYanYiVS = sgs.CreateViewAsSkill{
	name = "LuaYanYi",
	response_pattern = "@@LuaYanYi",
	n = 1,
	view_filter = function(self, selected, to_select)
		local player = sgs.Self
		local color = player:property("LuaYanYiColor"):toString()
		if color == "" then
			return to_select:isNDTrick() and to_select:objectName() ~= "nullification"
		else
			return getColorStr(to_select) == color and not to_select:isEquipped()
		end
	end,
	view_as = function(self, cards)
		if #cards == 0 then
			return 
		end
		local player = sgs.Self
		local pattern = player:property("LuaYanYiPattern"):toString()
		if pattern == "" then
			local yanyiCard = YanYiCard:clone()
			yanyiCard:addSubcard(cards[1])
			return yanyiCard
		else
			if sgs.Sanguosha:cloneCard(pattern, sgs.Card_NoSuit, 0):targetFixed() then
				local yanyifixed = YanYiFixed:clone()
				yanyifixed:addSubcard(cards[1])
				yanyifixed:setUserString(pattern)
				yanyifixed:setSkillName("LuaYanYi")
				return yanyifixed
			else
				local yanyiunfixed = YanYiUnfixed:clone()
				yanyiunfixed:addSubcard(cards[1])
				yanyiunfixed:setUserString(pattern)
				yanyiunfixed:setSkillName("LuaYanYi")
				return yanyiunfixed
			end
		end
	end,
	enabled_at_play = function(self, player)
		local pattern = player:property("LuaYanYiPattern"):toString()
		if pattern == "" then
			return false
		end
		local vscard = sgs.Sanguosha:cloneCard(pattern, sgs.Card_NoSuit, 0)
		if player:isCardLimited(vscard,sgs.Card_MethodUse) or not vscard:isAvailable(player) then
			return false
		end
		return (not player:hasFlag("yanyiUsed")) and (not player:isNude())
	end,
}

LuaYanYi = sgs.CreateTriggerSkill{
	name = "LuaYanYi",
	events = {sgs.EventPhaseStart, sgs.EventPhaseChanging, sgs.PreCardUsed},
	view_as_skill = LuaYanYiVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.from == sgs.Player_Play then
				room:setPlayerProperty(player, "LuaYanYiPattern", sgs.QVariant(""))
				room:setPlayerProperty(player, "LuaYanYiColor", sgs.QVariant(""))
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() ~= sgs.Player_Play then
				return false
			end
			if player:isKongcheng() then
				return false
			end
			room:askForUseCard(player, "@@LuaYanYi", "@LuaYanYi")
		elseif event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if player:getPhase() ~= sgs.Player_Play then
				return false
			end
			if use.card:getSkillName() == self:objectName() then
				room:setPlayerFlag(player, "yanyiUsed")
			end
		end
	end,
}

--SanMan
LuaSanMan=sgs.CreateTriggerSkill{
	name="LuaSanMan",
	frequency=sgs.Skill_Frequent,
	events={sgs.BeforeCardsMove, sgs.CardsMoveOneTime},
	on_trigger=function(self, event, player, data)
		local room = player:getRoom()
		if (player:getPhase() ~= sgs.Player_NotActive) then
			return false
		end
		local move = data:toMoveOneTime()
		if (not move.from) or (move.from:objectName() ~= player:objectName()) then
			return false
		end
		if event == sgs.BeforeCardsMove then
			local reason = move.reason.m_reason
			if bit32.band(reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) ~= sgs.CardMoveReason_S_REASON_DISCARD then
				return false
			end
			local i = 0
			for _,id in sgs.qlist(move.card_ids) do
				card = sgs.Sanguosha:getCard(id)
				if move.from_places:at(i) == sgs.Player_PlaceHand or move.from_places:at(i) == sgs.Player_PlaceEquip then
					if card and card:isRed() and room:getCardOwner(id):getSeat() == player:getSeat() then
						player:addMark(self:objectName())
						break
					end
				end
				i = i + 1
			end
		else
			if player:getMark(self:objectName()) > 0 then
				if player:askForSkillInvoke(self:objectName(),sgs.QVariant("draw")) then
					player:drawCards(2)
				end
				player:setMark(self:objectName(),0)
			end
		end
		return false
	end,
}

--QingYin
function getPatternStr(tableId)
	local a,b,c,d = true, true, true, true --分别为：黑桃、红桃、梅花、方片
	for _,id in sgs.qlist(tableId) do
		local card = sgs.Sanguosha:getCard(id)
		if card:getSuitString() == "spade" then
			a = false
		elseif card:getSuitString() == "heart" then
			b = false
		elseif card:getSuitString() == "club" then
			c = false
		elseif card:getSuitString() == "diamond" then
			d = false
		end
	end
	local patterns = {}
	if a then
		table.insert(patterns, "spade")
	end
	if b then
		table.insert(patterns, "heart")
	end
	if c then
		table.insert(patterns, "club")
	end
	if d then
		table.insert(patterns, "diamond")
	end
	patternStr = table.concat(patterns, ",")
	if patternStr == "" then
		patternStr = "impossibleSuit"
	end
	return patternStr
end

QingYinCard = sgs.CreateSkillCard{
	name = "LuaQingYin",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		--技能发动特效
		room:notifySkillInvoked(source,"LuaQingYin")
		room:broadcastSkillInvoke("LuaQingYin")
		--指示线
		for _, p in sgs.qlist(room:getOtherPlayers(source)) do
			room:doAnimate(1, source:objectName(), p:objectName())
		end
		--全屏特效
		room:doLightbox("QingYin$", 2500)
		
		source:loseMark("@qingyin")
		--展示所有手牌
		local ids = self:getSubcards()
		local patternStr = getPatternStr(ids)
		room:fillAG(ids, nil, ids)
		
		local playerData = sgs.QVariant()
		playerData:setValue(source)
		room:setTag("qingyinInvoking", playerData)
		for _, p in sgs.qlist(room:getOtherPlayers(source)) do
			if (not p) or (not p:isAlive()) then
				continue
			end
			local card = room:askForCard(p,".|"..patternStr.."|.|hand","@qingyinShow",sgs.QVariant(patternStr),sgs.Card_MethodNone,nil,false,"LuaQingYin",false)
			if card then
				room:showCard(p,card:getId())
			else
				source:drawCards(1)
			end
		end
		room:removeTag("qingyinInvoking")
		room:clearAG(nil)
	end,
}

LuaQingYinVS = sgs.CreateViewAsSkill{
	name = "LuaQingYin",
	response_pattern = "@@LuaQingYin",
	n = 4,
	view_filter = function(self, selected, to_select)
		if #selected == 0 then
			return true
		elseif #selected == 1 then
			return to_select:getSuit() ~= selected[1]:getSuit()
		elseif #selected == 2 then
			return to_select:getSuit() ~= selected[1]:getSuit() and to_select:getSuit() ~= selected[2]:getSuit()
		elseif #selected == 3 then
			return to_select:getSuit() ~= selected[1]:getSuit() and to_select:getSuit() ~= selected[2]:getSuit() and to_select:getSuit() ~= selected[3]:getSuit()
		end
	end,
	view_as = function(self, cards)
		if #cards == 0 then
			return nil
		end
		local card=QingYinCard:clone()
		for _,c in ipairs(cards) do
			card:addSubcard(c)
		end
		card:setSkillName("LuaQingYin")
		return card
	end,
}

LuaQingYin = sgs.CreateTriggerSkill{
	name = "LuaQingYin",
	frequency = sgs.Skill_Limited,
	events = {sgs.EventPhaseStart},
	view_as_skill = LuaQingYinVS,
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Draw then
			if player:getMark("@qingyin") == 0 then
				return false
			end
			if player:isKongcheng() then
				return false
			end
			local room = player:getRoom()
			if room:askForUseCard(player, "@@LuaQingYin", "@LuaQingYin") then
				return true
			end
		end
		return false
	end,
}

LuaQingYinStart = sgs.CreateTriggerSkill{
	name = "#LuaQingYinStart",
	events = {sgs.GameStart},
	on_trigger = function(self, event, player, data)
		player:gainMark("@qingyin")
	end
}

MiodaIbuki:addSkill(LuaYanYi)
MiodaIbuki:addSkill(LuaSanMan)
MiodaIbuki:addSkill(LuaQingYin)
MiodaIbuki:addSkill(LuaQingYinStart)
extension:insertRelatedSkills("LuaQingYin","#LuaQingYinStart")

sgs.LoadTranslationTable{	
	["MiodaIbuki"]="澪田唯吹",
	["&MiodaIbuki"]="澪田",
	["#MiodaIbuki"]="超高校级的轻音部",
	["designer:MiodaIbuki"]="Smwlover",
	["illustrator:MiodaIbuki"]="Ruby",
	
	["LuaYanYi"]="颜艺",
	[":LuaYanYi"]="出牌阶段开始时，你可以展示一张非延时锦囊牌。若如此做，本阶段限一次，你可以将一张与该牌同颜色的牌当该牌使用。",
	["LuaSanMan"]="散漫",
	[":LuaSanMan"]="每当你于回合外因弃置而失去红色牌时，你可以摸两张牌。",
	["LuaQingYin"]="轻音",
	[":LuaQingYin"]="<font color=\"red\"><b>限定技，</b></font>摸牌阶段，你可以放弃摸牌并展示任意数量的花色各不相同的手牌，然后所有其他角色需依次选择一项：展示一张与你所展示的牌花色均不同的手牌，或者令你摸一张牌。",

	["luayanyi"]="颜艺",
	["luaqingyin"]="轻音",
	["@qingyin"]="轻音",
	["@LuaYanYi"]="你可以发动“颜艺”展示一张非延时锦囊牌（除【无懈可击】）",
	["~LuaYanYi"]="选择一张非延时锦囊牌→点“确定”",
	["LuaSanMan:draw"]="你可以摸两张牌",
	["@LuaQingYin"]="你可以发动“轻音”",
	["~LuaQingYin"]="选中任意数量花色不同的手牌→点“确定”",
	["@qingyinShow"]="请弃置一张手牌，否则 澪田唯吹 摸一张牌",
	["QingYin$"]="image=image/animate/qingyin.png",
}

--Tsumiki Mikan
TsumikiMikan=sgs.General(extension,"TsumikiMikan","dgrp","3",false)

--RuoQi
LuaRuoQiStart=sgs.CreateTriggerSkill{
	name = "LuaRuoQi",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self,event,player,data)
		if player:getPhase() ~= sgs.Player_RoundStart then
			return false 
		end
		--player是即将回合开始的角色，tsumiki是控制罪木的角色
		local room = player:getRoom()
		local tsumiki = room:findPlayerBySkillName(self:objectName())
		if (not tsumiki) or (not tsumiki:isAlive()) or (tsumiki:objectName() == player:objectName()) then 
			return false 
		end
		if not player:inMyAttackRange(tsumiki) then
			return false
		end --不在攻击范围内
		--开始询问发动【弱气】
		if tsumiki:canDiscard(tsumiki, "he") then
			if room:askForCard(tsumiki, ".Equip", "@ruoqi", sgs.QVariant(), self:objectName()) then
				room:setPlayerFlag(tsumiki, "ruoqi_used")
			end
		end
		return false
	end,
	can_trigger = function(self, target) --不能设置成只有自己才可以被触发，那样的话就变成只有自己的回合开始才发动了
		return target
	end,
}

LuaRuoQiDamage=sgs.CreateTriggerSkill{
	name = "#LuaRuoQiDamage",
	events = {sgs.Damaged},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if player:hasFlag("ruoqi_used") then
			room:setPlayerFlag(player, "-ruoqi_used")
			
			--发送信息
			local msg = sgs.LogMessage()
			msg.type = "#RuoQiDamaged"
			msg.from = player
			msg.arg = "LuaRuoQi"
			room:sendLog(msg)
		end
		return false
	end,
}

LuaRuoQiEnd=sgs.CreateTriggerSkill{
	name = "#LuaRuoQiEnd",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self,event,player,data)
		if player:getPhase() ~= sgs.Player_NotActive then
			return false 
		end
		--player是即将回合结束的角色，tsumiki是控制罪木的角色
		local room = player:getRoom()
		local tsumiki = room:findPlayerBySkillName(self:objectName())
		if (not tsumiki) or (not tsumiki:isAlive()) or (tsumiki:objectName() == player:objectName()) then 
			return false 
		end --自己的回合结束阶段不发动
		if tsumiki:hasFlag("ruoqi_used") then
			room:drawCards(tsumiki, 2, "LuaRuoQi")
			room:setPlayerFlag(tsumiki, "-ruoqi_used")
			
			--技能触发效果
			room:notifySkillInvoked(tsumiki, "LuaRuoQi")
			room:broadcastSkillInvoke("LuaRuoQi")
			--发送信息
			local msg = sgs.LogMessage()
			msg.type = "#RuoQiEnd"
			msg.from = tsumiki
			msg.arg = "LuaRuoQi"
			msg.arg2 = 2
			room:sendLog(msg)
		end
		return false
	end,
	can_trigger = function(self, target) --不能设置成只有自己才可以被触发，那样的话就变成只有自己的回合结束才发动了
		return target
	end,
}

--YuShang
LuaYuShang=sgs.CreateTriggerSkill{
	name = "LuaYuShang",
	events = {sgs.AskForPeaches},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local who = room:getCurrentDyingPlayer()
		if not who:faceUp() then 
			return false 
		end
		local dying = sgs.QVariant()
		dying:setValue(who)
		while (true) do --只要满足条件可以一直发动
			if who:getHp() > 0 then
				break
			end
			if not who:faceUp() then
				break
			end
			if who:isDead() then
				break
			end
			if room:askForSkillInvoke(player,self:objectName(),dying) then
				--指示线
				room:doAnimate(1, player:objectName(), who:objectName()) --1是QSanProtocol中代表指示线动画的数值

				local recover = sgs.RecoverStruct()
				recover.who = player --是罪木蜜柑令其回复体力的
				room:recover(who,recover) --回复1点体力
				who:turnOver() --翻面
			else
				break
			end
		end
		return false
	end,
}

--Huiyi
LuaHuiYi=sgs.CreateTriggerSkill{
	name="LuaHuiYi",
	frequency=sgs.Skill_Wake,
	events={sgs.TurnedOver},
	on_trigger=function(self,event,player,data)
		local room = player:getRoom()
		--技能触发效果
		room:notifySkillInvoked(player, self:objectName())
		room:broadcastSkillInvoke(self:objectName())
		--发送信息
		local log = sgs.LogMessage()
		log.type = "#HuiYiWaking"
		log.from = player
		log.arg = self:objectName()
		room:sendLog(log)
		--全屏特效
		room:doLightbox("HuiYi$", 2500)
		
		player:gainMark("@waked")
		room:setPlayerMark(player, "HuiyiWaked", 1)
		if not player:faceUp() then
			player:turnOver()
		end
		--失去技能
		room:detachSkillFromPlayer(player,"LuaRuoQi") --不能失去LuaRuoQiDamage和LuaRuoQiEnd，因为已经触发的效果不能被打断。
		--获得技能
		room:acquireSkill(player,"LuaJiLi",true)
	end,
	can_trigger=function(self,target)
		if target then
			if target:hasSkill(self:objectName()) then
				if target:isAlive() then
					local mark = target:getMark("HuiyiWaked")
					return mark == 0
				end
			end
		end
	end,
}

--JiLi
JiLiCard=sgs.CreateSkillCard{
	name="JiLiCard",
	target_fixed=false,
	will_throw=true,
	filter=function(self,targets,to_select)
		if #targets > 0 then
			return false
		end
		return to_select:isAlive() and not to_select:faceUp()
	end,
	on_effect=function(self,effect)
		local source=effect.from
		local dest=effect.to
		local room=source:getRoom()
		
		--技能触发效果
		room:notifySkillInvoked(source, "LuaJiLi")
		room:broadcastSkillInvoke("LuaJiLi")
		
		if not room:askForCard(dest,"jink","@jili",sgs.QVariant(),sgs.Card_MethodResponse,nil,false,"LuaJiLi",false) then
			room:killPlayer(dest)
		end
	end,
}

LuaJiLi=sgs.CreateViewAsSkill{
	name="LuaJiLi",
	n=0,
	view_as=function(self,cards)
		local card=JiLiCard:clone()
		return card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#JiLiCard")
	end
}

SkillAnJiang:addSkill(LuaJiLi)
TsumikiMikan:addSkill(LuaYuShang)
TsumikiMikan:addSkill(LuaRuoQiStart)
TsumikiMikan:addSkill(LuaRuoQiDamage)
TsumikiMikan:addSkill(LuaRuoQiEnd)
TsumikiMikan:addSkill(LuaHuiYi)
extension:insertRelatedSkills("LuaRuoQi","#LuaRuoQiDamage")
extension:insertRelatedSkills("LuaRuoQi","#LuaRuoQiEnd")

sgs.LoadTranslationTable{
	["TsumikiMikan"]="罪木蜜柑",
	["&TsumikiMikan"]="罪木",
	["#TsumikiMikan"]="超高校级的保健委员",
	["designer:TsumikiMikan"]="Smwlover",
	["illustrator:TsumikiMikan"]="Ruby",
	
	["LuaYuShang"]="愈伤",
	[":LuaYuShang"]="一名武将牌正面朝上的角色处于濒死状态时，你可以令该角色回复一点体力，然后该角色将武将牌翻面。",
	["LuaRuoQi"]="弱气",
	[":LuaRuoQi"]="一名你在其攻击范围内的其他角色的回合开始时，你可以弃置一张装备牌。若如此做，该角色的回合结束时，若你于本回合内没有受到伤害，你摸两张牌。",
	["LuaHuiYi"]="回忆",
	[":LuaHuiYi"]="<font color=\"purple\"><b>觉醒技，</b></font>你的武将牌被翻面时，你需将武将牌调整至正面朝上，然后失去技能“弱气”并获得技能“祭礼”（<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以令一名武将牌背面朝上的角色打出一张【闪】，若该角色不如此做，其立即死亡）。",
	["LuaJiLi"]="祭礼",
	[":LuaJiLi"]="<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以令一名武将牌背面朝上的角色打出一张【闪】，若该角色不如此做，其立即死亡。",
	
	["HuiYi$"]="image=image/animate/huiyi.png",
	["#HuiYiWaking"]="%from 的觉醒技 %arg 被触发",
	["jili"]="祭礼",
	["@jili"]="你需要打出一张【闪】来响应“祭礼”。",
	["@ruoqi"]="你可以发动技能“弱气”弃置一张装备牌。",
	
	["#RuoQiDamaged"]="%from 受到了伤害， %arg 发动失败。",
	["#RuoQiEnd"]="%from 本回合没有受到伤害， %arg 效果被触发，摸 %arg2 张牌。",
}

--Chapter 4

--Meka Nidai
MekaNidai=sgs.General(extension,"MekaNidai","dgrp","5",true,true,true)

--Nidai Nekomaru
NidaiNekomaru=sgs.General(extension,"NidaiNekomaru","dgrp","4",true)

--ChuiLian
Table2IntList = function(theTable)
	local result = sgs.IntList()
	for i = 1, #theTable, 1 do
		result:append(theTable[i])
	end
	return result
end

LuaChuiLian = sgs.CreateTriggerSkill {
	name = "LuaChuiLian",
	events = {sgs.TargetConfirmed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card:isKindOf("Slash") and use.from:objectName()==player:objectName() then
			local nidai = room:findPlayerBySkillName(self:objectName())
			if (not nidai) or (not nidai:isAlive()) then
				return false
			end
			if nidai:isKongcheng() then
				return false
			end
			if room:askForCard(nidai, ".Basic", "@chuilian", sgs.QVariant(), self:objectName()) then
				--指示线
				room:doAnimate(1, nidai:objectName(), player:objectName())
				--发送信息
				local log = sgs.LogMessage()
				log.type = "#ChuiLianInvoked"
				log.from = player
				log.arg = self:objectName()
				log.arg2 = use.card:objectName()
				room:sendLog(log)
				
				--令此杀不可闪避
				local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
				local index = 1
				for _, p in sgs.qlist(use.to) do
					jink_table[index] = 0
					index = index + 1
				end
				local jink_data = sgs.QVariant()
				jink_data:setValue(Table2IntList(jink_table))
				player:setTag("Jink_" .. use.card:toString(), jink_data)
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
}

--ChongSheng
LuaChongSheng = sgs.CreateTriggerSkill{
	name = "LuaChongSheng" ,
	events = {sgs.EventPhaseStart} ,
	frequency = sgs.Skill_Wake ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		--技能发动特效
		room:notifySkillInvoked(player,self:objectName())
		room:broadcastSkillInvoke(self:objectName())
		--发送信息
		local log = sgs.LogMessage()
		log.type = "#ChongShengWaking"
		log.from = player
		log.arg = self:objectName()
		log.arg2 = 1
		room:sendLog(log)
		--全屏特效
		room:doLightbox("ChongSheng$", 2500)
		
		--变身为机械弐大
		local isSecondaryHero = player:getGeneralName() ~= "NidaiNekomaru"
		room:changeHero(player, "MekaNidai", false, false, isSecondaryHero, false)
		--回复至满体力
		local recover = sgs.RecoverStruct()
		recover.who = player
		recover.recover = player:getMaxHp() - player:getHp()
		room:recover(player, recover)
		return false
	end,
	can_trigger = function(self, target)
		return target and target:isAlive() and target:hasSkill(self:objectName()) and (target:getPhase() == sgs.Player_Start) and (target:getHp() == 1) and (target:getMark("ChongshengWaked") == 0)
	end,
}

--JiXie
LuaJiXie = sgs.CreateTriggerSkill{
	name = "LuaJiXie",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageInflicted},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local card = damage.card
		if card and card:isKindOf("Slash") then
			if (not damage.from) or (not damage.from:isAlive()) then
				return false
			end
			local damageBefore = damage.damage
			if damage.from:distanceTo(damage.to) <= 1 then
				damage.damage = damage.damage + 1	
			else
				damage.damage = damage.damage - 1
			end
			data:setValue(damage)
	
			--技能发动特效
			room:notifySkillInvoked(player,self:objectName())
			room:broadcastSkillInvoke(self:objectName())
			--发送信息
			local msg = sgs.LogMessage()
			msg.type = "#TriggerSkill"
			msg.from = player
			msg.arg = self:objectName()
			room:sendLog(msg)
			local msg = sgs.LogMessage()
			msg.type = "#JiXieInvoked"
			msg.to:append(damage.to)
			msg.arg = damageBefore
			msg.arg2 = damage.damage
			room:sendLog(msg)
			
			if damage.damage < 1 then 
				room:setEmotion(damage.to, "skill_nullify") --伤害防止特效
				return true 
			end --伤害为0直接防止
		end
		return false
	end,
}

SkillAnJiang:addSkill(LuaJiXie)
MekaNidai:addSkill(LuaChuiLian)
MekaNidai:addSkill(LuaJiXie)
NidaiNekomaru:addSkill(LuaChuiLian)
NidaiNekomaru:addSkill(LuaChongSheng)

sgs.LoadTranslationTable{	
	["NidaiNekomaru"]="弐大猫丸",
	["&NidaiNekomaru"]="弐大",
	["MekaNidai"]="机械弐大",
	["&MekaNidai"]="弐大",
	["#NidaiNekomaru"]="超高校级的经理人",
	["designer:NidaiNekomaru"]="Smwlover",
	["illustrator:NidaiNekomaru"]="Ruby",
	
	["LuaChuiLian"]="锤炼",
	[":LuaChuiLian"]="一名角色使用【杀】指定目标后，你可以弃置一张基本牌，令此【杀】不可被闪避。",
	["LuaChongSheng"]="重生",
	[":LuaChongSheng"]="<font color=\"purple\"><b>觉醒技，</b></font>准备阶段开始时，若你的体力值为1，你增加1点体力上限并将体力回复至体力上限，然后获得技能“机械”（<font color=\"blue\"><b>锁定技，</b></font>你受到【杀】造成的伤害时，若伤害来源与你的距离为1以内，此伤害+1；否则此伤害-1）。",
	["LuaJiXie"]="机械",
	[":LuaJiXie"]="<font color=\"blue\"><b>锁定技，</b></font>你受到【杀】造成的伤害时，若伤害来源与你的距离为1以内，此伤害+1；否则此伤害-1。",
	
	["@chuilian"]="你可以弃置一张基本牌，令此【杀】不可被闪避。",
	["#ChuiLianInvoked"]="%from 使用的【%arg2】因 %arg 的原因不可被闪避。",
	["ChongSheng$"]="image=image/animate/chongsheng.png",
	["#ChongShengWaking"]="%from 的体力值为 %arg2 ，觉醒技 %arg 被触发",
	["#JiXieInvoked"]="%to 受到的伤害由 %arg 点变化至 %arg2 点。",
}

--Tanaka Gandamu
TanakaGandamu=sgs.General(extension,"TanakaGandamu","dgrp","4",true)

--YuShou
function hasSuit(suit, player)
	for _, p in sgs.qlist(player:getSiblings()) do
		if p and p:isAlive() and (not p:getPile("mouse"):isEmpty()) then
			local id = p:getPile("mouse"):first()
			local card = sgs.Sanguosha:getCard(id)
			if suit == card:getSuit() then
				return true
			end
		end
	end
	return false
end

YuShouCard = sgs.CreateSkillCard{
	name = "YuShouCard",
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return #targets == 0 and to_select:getPile("mouse"):isEmpty() and (to_select:objectName() ~= player:objectName())
	end,
	feasible = function(self, targets)
		return #targets == 1
	end,
	on_use = function(self, room, source, targets)
		--技能发动特效
		room:notifySkillInvoked(source,"LuaYuShou")
		room:broadcastSkillInvoke("LuaYuShou")
		
		--置于武将牌上
		local id = self:getEffectiveId()
		targets[1]:addToPile("mouse", id, true)
	end,
}
	
LuaYuShou = sgs.CreateViewAsSkill{
	name = "LuaYuShou",
	n=1,
	view_filter = function(self, selected, to_select)
		local player = sgs.Self
		return (not to_select:isEquipped()) and (not hasSuit(to_select:getSuit(),player))
	end,
	view_as=function(self, cards)
		if #cards == 0 then
			return nil
		end
		local card=YuShouCard:clone()
		card:setSkillName(self:objectName())
		card:addSubcard(cards[1])
		return card
	end,
	enabled_at_play = function(self, player)
		return not player:isKongcheng()
	end,
}

LuaYuShouDistance = sgs.CreateDistanceSkill{
	name="#LuaYuShouDistance",
	correct_func=function(self,from,to)
		if from:hasSkill("LuaYuShou") and (not to:getPile("mouse"):isEmpty()) then
			return -1000; --距离始终视为1
		end
	end,
}

LuaMouse = sgs.CreateTriggerSkill{ --全局触发技
	name = "#LuaMouse",
	events = {sgs.EventPhaseStart},
	global = true,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() ~= sgs.Player_Start then
			return false
		end
		if player:getPile("mouse"):isEmpty() then
			return false
		end
		--发送信息
		local log = sgs.LogMessage()
		log.type = "#MouseTrigger"
		log.to:append(player)
		log.arg = "mouse"
		room:sendLog(log)
		
		if player:isKongcheng() then
			return false
		end
		local card = room:askForCard(player,"slash","@yushou",sgs.QVariant(),sgs.Card_MethodResponse,nil,false,"LuaYuShou",false)
		if card then
			local id = player:getPile("mouse"):first()
			local mouse = sgs.Sanguosha:getCard(id)
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, player:objectName(), "LuaYuShou", "")
			room:throwCard(mouse, reason, nil)
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end,
}

--MoZhen
MoZhenCard = sgs.CreateSkillCard{
	name = "LuaMoZhen",
	filter = function(self, targets, to_select)
		local victimString = sgs.Self:property("slashVictim"):toString()
		local victim = nil
		local players = sgs.Self:getSiblings()
		for _,player in sgs.qlist(players) do
			if player:objectName() == victimString then
				victim = player
				break
			end
		end
		if (not victim) then
			return false
		end
		return #targets == 0 and victim:isAdjacentTo(to_select) and victim:objectName() ~= to_select:objectName()
	end,
	feasible = function(self, targets)
		return #targets == 1
	end,
	on_use = function(self, room, source, targets)
		--技能发动特效
		room:notifySkillInvoked(source,"LuaMoZhen")
		room:broadcastSkillInvoke("LuaMoZhen")
		
		room:damage(sgs.DamageStruct("LuaMoZhen",source,targets[1]))
	end,
}

LuaMoZhenVS = sgs.CreateViewAsSkill{
	name = "LuaMoZhen",
	response_pattern = "@@LuaMoZhen",
	n = 1,
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards)
		if #cards == 0 then
			return nil
		end
		local mozhenCard = MoZhenCard:clone()
		mozhenCard:addSubcard(cards[1])
		return mozhenCard
	end
}

LuaMoZhen = sgs.CreateTriggerSkill{
	name = "LuaMoZhen",
	events = {sgs.Damage},
	view_as_skill = LuaMoZhenVS,
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local room = player:getRoom()
		if damage.card and damage.card:isKindOf("Slash") and (not damage.chain) and (not damage.transfer) then
			local from = damage.from
			local to = damage.to
			if not to:isAlive() then
				return false
			end
			if from:distanceTo(to) ~= 1 then
				return false
			end
			if from:isNude() then
				return false
			end
			room:setPlayerProperty(from, "slashVictim", sgs.QVariant(to:objectName()))
			room:askForUseCard(from, "@@LuaMoZhen", "@LuaMoZhen")
			room:setPlayerProperty(from, "slashVictim", sgs.QVariant(""))
		end
		return false
	end,
}

--LinRan
LinRanCard = sgs.CreateSkillCard{
	name = "LinRanCard",
	target_fixed = false,
	filter = function(self, targets, to_select)
		if #targets==0 then
			return to_select:getHp()<4
		elseif #targets==1 then
			return targets[1]:getHp() + to_select:getHp()<4
		elseif #targets==2 then
			return targets[1]:getHp() + targets[2]:getHp() + to_select:getHp()<4
		elseif #targets==3 then
			return targets[1]:getHp() + targets[2]:getHp() + targets[3]:getHp() + to_select:getHp()<4
		else
			return false
		end
	end,
	on_use = function(self, room, source, targets)
		--技能触发效果
		room:notifySkillInvoked(source, "LuaLinRan")
		room:broadcastSkillInvoke("LuaLinRan")
		--全屏特效
		room:doLightbox("LinRan$", 2500)
		
		for i=1, #targets, 1 do
			targets[i]:drawCards(3)
		end
		-- 田中立即死亡
		source:loseMark("@linran")
		room:killPlayer(source)
	end,
}

LuaLinRanVS = sgs.CreateViewAsSkill{
	name = "LuaLinRan",
	n = 0,
	view_as = function(self, cards)
		local card=LinRanCard:clone()
		return card
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@linran") >= 1
	end
}

LuaLinRan = sgs.CreateTriggerSkill{
	name = "LuaLinRan" ,
	frequency = sgs.Skill_Limited,
	limit_mark = "@linran",
	events = {},
	view_as_skill = LuaLinRanVS ,
	on_trigger = function()
		return false
	end
}

TanakaGandamu:addSkill(LuaYuShou)
TanakaGandamu:addSkill(LuaYuShouDistance)
TanakaGandamu:addSkill(LuaMoZhen)
TanakaGandamu:addSkill(LuaLinRan)
extension:insertRelatedSkills("LuaYuShou","#LuaYuShouDistance")
local skill=sgs.Sanguosha:getSkill("#LuaMouse")
if not skill then
	local skillList=sgs.SkillList()
	skillList:append(LuaMouse)
	sgs.Sanguosha:addSkills(skillList)
end --全局触发技

sgs.LoadTranslationTable{	
	["TanakaGandamu"]="田中眼蛇梦",
	["&TanakaGandamu"]="田中",
	["#TanakaGandamu"]="超高校级的饲育委员",
	["designer:TanakaGandamu"]="Smwlover",
	["illustrator:TanakaGandamu"]="Ruby",
	
	["LuaYuShou"]="御兽",
	[":LuaYuShou"]="出牌阶段，你可以将一张与场上所有“鼠”的花色均不同的手牌置于一名其他角色的武将牌上，称为“鼠”。若一名角色的武将牌上有“鼠”，你与该角色的距离始终视为1，且该角色于其准备阶段开始时，可以打出一张【杀】并将“鼠”置入弃牌堆。",
	["LuaMoZhen"]="魔阵",
	[":LuaMoZhen"]="你使用【杀】对一名距离为1的目标角色造成伤害后，可以弃置一张牌，然后对一名与该角色相邻的角色造成1点伤害。",
	["LuaLinRan"]="凛然",
	[":LuaLinRan"]="<font color=\"red\"><b>限定技，</b></font>出牌阶段，你可以令任意数量的体力值之和小于4的角色依次摸三张牌，然后你立即死亡。",

	["@yushou"]="你可以打出一张【杀】并将“鼠”置入弃牌堆",
	["mouse"]="鼠",
	["yushou"]="御兽",
	["luamozhen"]="魔阵",
	["linran"]="凛然",
	["@linran"]="凛然",
	["LinRan$"]="image=image/animate/linran.png",
	["#MouseTrigger"]="%to 的“%arg”效果被触发",
	["@LuaMoZhen"]="你可以弃置一张牌发动“魔阵”",
	["~LuaMoZhen"]="选中一张牌→选中一名与该角色相邻的角色→点“确定”",
}

--Chapter 5

--Komaeda Nagito
KomaedaNagito=sgs.General(extension,"KomaedaNagito","dgrp","3",true)

--XingYun
LuaXingYun = sgs.CreateTriggerSkill{
	name = "LuaXingYun",
	events = {sgs.StartJudge},
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:askForSkillInvoke(self:objectName(), sgs.QVariant("watch")) then
			local x = player:getMaxHp() - player:getHp() + 1
			local ids = room:getNCards(x, false)
			room:fillAG(ids, player)
			
			player:setTag("xingyunJudge", data)
			local id = room:askForAG(player,ids,false,self:objectName())
			player:setTag("xingyunJudge", sgs.QVariant(""))
			
			room:clearAG(player)
			if id == -1 then
				return false
			end
			--弃置剩余的牌
			local card_to_throw = {}
			for i=0, x-1, 1 do
				if ids:at(i) ~= id then
					table.insert(card_to_throw, ids:at(i))
				end
			end
			local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			for _, id in ipairs(card_to_throw) do
				dummy:addSubcard(id)
			end
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, player:objectName(), self:objectName(), nil)
			room:throwCard(dummy, reason, nil)
			--将选中的牌作为判定牌
			local judge = data:toJudge()
			judge.card = sgs.Sanguosha:getCard(id)
			room:moveCardTo(judge.card,nil,judge.who,sgs.Player_PlaceJudge,sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_JUDGE,judge.who:objectName(),self:objectName(),"",judge.reason),true)
			judge:updateResult()
			room:setTag("SkipGameRule",sgs.QVariant(true))
		end
		return false
	end,
}

--RuShen
LuaRuShen = sgs.CreateTriggerSkill{
	name = "LuaRuShen",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Finish then
			local room = player:getRoom()
			if room:askForSkillInvoke(player, self:objectName()) then
				--进行判定
				local judge = sgs.JudgeStruct()
				judge.pattern = ".|heart"
				judge.good = true
				judge.reason = self:objectName()
				judge.who = player
				room:judge(judge)
				--执行后续效果
				if judge:isGood() then
					player:drawCards(3)
				else
					if player:isKongcheng() then
						return false
					end
					room:askForDiscard(player, self:objectName(), 1, 1, false) --最后一个false代表必须弃置，不可以选择不弃
				end
			end
		end
		return false
	end,
}

--ZhiNian
ZhiNianCard = sgs.CreateSkillCard{
	name = "LuaZhiNian",
	will_throw = false,
	filter = function(self, targets, to_select, player)
		local slash = sgs.Card_Parse(sgs.Self:property("slashUse"):toString())
		if not slash then
			return false
		end
		return (to_select:getHandcardNum() < player:getHandcardNum()) and player:canSlash(to_select,slash,false) and (not to_select:hasFlag("alreadytar"))
	end,
	feasible = function(self, targets)
		return #targets == 1
	end,
	on_use = function(self, room, source, targets)
		room:setPlayerFlag(targets[1],"slashtar")
		--将这张手牌交给所选择的角色
		room:obtainCard(targets[1],self,false)
		
		local slash = sgs.Card_Parse(source:property("slashUse"):toString())
		--技能发动特效
		room:notifySkillInvoked(source,"LuaZhiNian")
		room:broadcastSkillInvoke("LuaZhiNian")
		--发送信息
		local log = sgs.LogMessage()
		log.type = "#SlashUsed"
		log.to:append(targets[1])
		log.arg=slash:objectName()
		room:sendLog(log)
	end,
}

LuaZhiNianVS = sgs.CreateViewAsSkill{
	name = "LuaZhiNian",
	response_pattern = "@@LuaZhiNian",
	n = 1,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 0 then
			return
		end
		local card = ZhiNianCard:clone()
		card:addSubcard(cards[1])
		return card
	end
}

LuaZhiNian = sgs.CreateTriggerSkill{
	name = "LuaZhiNian" ,
	events = {sgs.TargetConfirming} ,
	view_as_skill = LuaZhiNianVS,
	on_trigger = function(self, event, pp, data)
		local room = pp:getRoom()
		local use = data:toCardUse()
		if (not use.card) or (not use.card:isKindOf("Slash")) then
			return false
		end
		local komaeda = room:findPlayerBySkillName(self:objectName())
		if (not komaeda) or (not komaeda:isAlive()) then
			return false
		end
		local from = use.from
		local player = komaeda
		if from:objectName() == player:objectName() then
			if player:isKongcheng() then
				return false
			end
			room:setPlayerProperty(player, "slashUse", sgs.QVariant(use.card:toString()))
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if use.to:contains(p) then
					room:setPlayerFlag(p,"alreadytar")
				end
			end --记录已经成为杀的目标的角色
			room:askForUseCard(player, "@@LuaZhiNian", "@LuaZhiNian")
			room:setPlayerProperty(player, "slashUse", sgs.QVariant(""))
			local tar = nil
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:hasFlag("slashtar") then
					room:setPlayerFlag(p,"-slashtar")
					tar = p
				end
				if p:hasFlag("alreadytar") then
					room:setPlayerFlag(p,"-alreadytar")
				end
			end
			if tar then
				use.to:append(tar)
				room:sortByActionOrder(use.to)
				data:setValue(use)
			end
		elseif not use.to:contains(player) then
			if from:canSlash(player, use.card, false) then
				if from:getHandcardNum() > player:getHandcardNum() then
					local fromData = sgs.QVariant()
					fromData:setValue(from)
					if room:askForSkillInvoke(player,self:objectName(),fromData) then
						local card = nil
						if from:getHandcardNum() > 1 then
							card = room:askForCard(from, ".!", "@giveCard:"..player:objectName(), sgs.QVariant(), sgs.Card_MethodNone)
							if not card then
								card = from:getHandcards():at(math.random(0, from:getHandcardNum() - 1))
							end
						else
							card = from:getHandcards():first()
						end
						room:obtainCard(player,card,false)
						
						--指示线
						room:doAnimate(1, from:objectName(), player:objectName())
						--发送信息
						local log = sgs.LogMessage()
						log.type = "#SlashUsed"
						log.to:append(player)
						log.arg=use.card:objectName()
						room:sendLog(log)
						
						--也成为此【杀】目标
						use.to:append(player)
						room:sortByActionOrder(use.to)
						data:setValue(use)
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
} --注意：【执念】是直接成为【杀】的目标，不会触发指定目标时的技能，比如【流离】等，也不会再次触发【执念】。

KomaedaNagito:addSkill(LuaXingYun)
KomaedaNagito:addSkill(LuaRuShen)
KomaedaNagito:addSkill(LuaZhiNian)

sgs.LoadTranslationTable{	
	["KomaedaNagito"]="狛枝凪斗",
	["&KomaedaNagito"]="狛枝",
	["#KomaedaNagito"]="超高校级的幸运",
	["designer:KomaedaNagito"]="Smwlover",
	["illustrator:KomaedaNagito"]="Ruby",
	
	["LuaXingYun"]="幸运",
	[":LuaXingYun"]="你进行判定时，可以观看牌堆顶的X张牌（X为你已损失的体力值+1），将其中一张作为判定牌，将其余的牌置入弃牌堆。",
	["LuaRuShen"]="入神",
	[":LuaRuShen"]="结束阶段开始时，你可以进行一次判定，若判定结果为红桃，你摸三张牌；否则你需弃置一张牌。",
	["LuaZhiNian"]="执念",
	[":LuaZhiNian"]="一名其他角色使用【杀】指定目标时，若其手牌数大于你且你不是此【杀】的目标，你可以令其交给你一张手牌，然后你成为此【杀】的额外目标；<br />你使用【杀】指定目标时，可以交给一名手牌数小于你且不是此【杀】目标的其他角色一张手牌，然后该角色成为此【杀】额外的目标。",
	
	["LuaXingYun:watch"]="你可以发动“幸运”观看牌堆顶的牌",
	["luazhinian"]="执念",
	["@LuaZhiNian"]="你可以交给一名其他角色一张手牌，令其成为该【杀】的额外目标",
	["~LuaZhiNian"]="选择一张手牌→选择一名角色→点“确定”",
	["#SlashUsed"]="%to 成为此【%arg】的额外目标",
}

--Nanami Chiaki
NanamiChiaki=sgs.General(extension,"NanamiChiaki","dgrp","3",false)

--WeiLai
LuaMirai=sgs.CreateMaxCardsSkill{
	name="LuaMirai",
	extra_func=function(self, target)
		local extra = 0
		local players = target:getSiblings()
		for _,player in sgs.qlist(players) do
			if player:isAlive() and player:hasSkill(self:objectName()) then
				extra = extra + 1
			end
		end
		if target:hasSkill(self:objectName()) then
			return extra
		end
	end,
}

LuaMiraiTrigger=sgs.CreateTriggerSkill{
	name="#LuaMiraiTrigger",
	events={sgs.EventPhaseStart, sgs.GameStart},
	on_trigger=function(self,event,player,data)
		if event == sgs.GameStart then
			if player:getMark("@mirai") == 0 then
				player:gainMark("@mirai")
			end
		else
			local phase=player:getPhase()
			local room=player:getRoom()
			if phase == sgs.Player_Discard then
				local extra = 0
				local players = room:getAlivePlayers()
				for _,player in sgs.qlist(players) do
					if player:isAlive() and player:hasSkill(self:objectName()) then
						extra = extra + 1
					end
				end
				if extra == 1 then
					return false
				end
			
				--技能发动特效
				room:notifySkillInvoked(player,"LuaMirai")
				room:broadcastSkillInvoke("LuaMirai")
				--发送信息
				local log = sgs.LogMessage()
				log.type = "#Mirai"
				log.from = player
				log.arg = "LuaMirai"
				log.arg2 = extra-1
				room:sendLog(log)
			end
		end
		return false
	end,
}

--TiXu
LuaTiXu = sgs.CreateTriggerSkill{
	name = "LuaTiXu",
	events = {sgs.Damaged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local card = damage.card
		if not card then
			return false
		end
		local number = card:getNumber() --在源码中这个函数已经考虑了各种情况，包括经过转化的卡牌的子卡点数为所有子卡点数之和。
		if not (number >= 1 and number <= 13) then
			return false
		end
		local nanami = room:findPlayerBySkillName(self:objectName())
		if (not nanami) or (not nanami:isAlive()) then
			return false
		end
		if nanami:isNude() then
			return false
		end
		--DamageData
		local damageData = sgs.QVariant()
		damageData:setValue(damage)
		if room:askForCard(nanami, ".|.|"..(number).."~", "@TiXuDiscard:"..damage.to:objectName().."::"..tostring(number) , damageData, self:objectName()) then
			--指示线
			room:doAnimate(1, nanami:objectName(), damage.to:objectName())
			
			damage.to:drawCards(2)
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
}

--ChengShi
LuaChengShi = sgs.CreateTriggerSkill{
	name = "LuaChengShi",
	events = {sgs.Death},
	priority = -2,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local death = data:toDeath()
		if death.who:objectName() ~= player:objectName() then
			return false
		end
		if player:askForSkillInvoke(self:objectName(), sgs.QVariant("invoke:::"..tostring(8))) then
			local playerData = sgs.QVariant()
			playerData:setValue(player)
			room:setTag("ChengShiPlayer", playerData)
			room:setTag("ChengShiCounter", sgs.QVariant(8))
		
			--动画效果
			if player:getGeneralName() == "NanamiChiaki" or player:getGeneral2Name() == "NanamiChiaki" then
				room:doLightbox("ChengShi$", 2500)
			elseif player:getGeneralName() == "zuoci" or player:getGeneral2Name() == "zuoci" then
				room:doLightbox("ChengShiZuoCi$", 2500)
				player:setTag("Huashens", sgs.QVariant()) --如果是左慈，清空化身牌堆
			end
		end
		return false
		end,
	can_trigger = function(self, target)
		return target and target:hasSkill(self:objectName())
	end,
}

ChengshiCount = sgs.CreateTriggerSkill{
	name = "#ChengshiCount",
	events = {sgs.EventPhaseStart},
	global = true,
	on_trigger = function(self, event, player, data)
		if not player:isAlive() then
			return false
		end
		if player:getPhase() ~= sgs.Player_NotActive then
			return false 
		end
		local room = player:getRoom()
		local chengshiPlayer = room:getTag("ChengShiPlayer"):toPlayer()
		local chengshiCount = room:getTag("ChengShiCounter"):toString()
		if not chengshiPlayer then
			return false
		end
		if chengshiPlayer:isAlive() then
			return false
		end
		if chengshiCount == "" then
			return false
		end
		local counter = tonumber(chengshiCount)
		if counter > 1 then
			room:setTag("ChengShiCounter", sgs.QVariant(counter - 1))
			
			--提示信息
			local msg = sgs.LogMessage()
			msg.type = "#ChengShiCounter"
			msg.from = chengshiPlayer
			msg.arg = counter - 1
			room:sendLog(msg)
		elseif counter == 1 then
			room:removeTag("ChengShiPlayer")
			room:removeTag("ChengShiCounter")
		
			--技能发动特效
			room:notifySkillInvoked(chengshiPlayer,"LuaChengShi")
			room:broadcastSkillInvoke("LuaChengShi")
			--动画效果
			if chengshiPlayer:getGeneralName() == "NanamiChiaki" or chengshiPlayer:getGeneral2Name() == "NanamiChiaki" then
				room:doLightbox("ChengShi$", 2500)
			elseif chengshiPlayer:getGeneralName() == "zuoci" or chengshiPlayer:getGeneral2Name() == "zuoci" then
				room:doLightbox("ChengShiZuoCi$", 2500)
			end
			--提示信息
			local msg = sgs.LogMessage()
			msg.type = "#ChengShiBack"
			msg.from = chengshiPlayer
			room:sendLog(msg)
		
			local maxhp = chengshiPlayer:getMaxHp()
			room:revivePlayer(chengshiPlayer)
			room:setPlayerProperty(chengshiPlayer, "hp", sgs.QVariant(maxhp))
			chengshiPlayer:drawCards(maxhp)
			--重新载入武将牌
			if chengshiPlayer:getGeneralName() == "zuoci" then
				room:changeHero(chengshiPlayer, "zuoci", false, true, false, false)
			elseif chengshiPlayer:getGeneral2Name() == "zuoci" then
				room:changeHero(chengshiPlayer, "zuoci", false, true, true, false)
			elseif chengshiPlayer:getGeneralName() == "NanamiChiaki" then
				room:changeHero(chengshiPlayer, "NanamiChiaki", false, true, false, false)
			elseif chengshiPlayer:getGeneral2Name() == "NanamiChiaki" then
				room:changeHero(chengshiPlayer, "NanamiChiaki", false, true, true, false)
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end,
}	

local skill=sgs.Sanguosha:getSkill("#ChengshiCount")
if not skill then
	local skillList=sgs.SkillList()
	skillList:append(ChengshiCount)
	sgs.Sanguosha:addSkills(skillList)
end --全局触发技
NanamiChiaki:addSkill(LuaMirai)
NanamiChiaki:addSkill(LuaMiraiTrigger)
NanamiChiaki:addSkill(LuaTiXu)
NanamiChiaki:addSkill(LuaChengShi)
extension:insertRelatedSkills("LuaMirai","#LuaMiraiTrigger")

sgs.LoadTranslationTable{	
	["NanamiChiaki"]="七海千秋",
	["&NanamiChiaki"]="七海",
	["#NanamiChiaki"]="超高校级的游戏玩家",
	["designer:NanamiChiaki"]="Smwlover",
	["illustrator:NanamiChiaki"]="Ruby",

	["LuaMirai"]="未来",
	[":LuaMirai"]="<font color=\"blue\"><b>锁定技，</b></font>你的手牌上限+X（X为拥有技能“未来”的其他存活角色数量）。",
	["LuaTiXu"]="体恤",
	[":LuaTiXu"]="一名角色受到伤害后，你可以弃置一张牌（该牌的点数需不小于造成伤害的牌），令该角色摸两张牌。",
	["LuaChengShi"]="程式",
	[":LuaChengShi"]="<font color=\"brown\"><b>重整技，</b></font>你死亡时，可以获得8枚“时间”标记；一名角色的回合结束时，弃掉1枚“时间”标记；最后1枚“时间”标记被弃掉时，你使用“七海千秋”的武将牌重新加入游戏（身份不变）。<br /><br />◆重新加入游戏时，你的体力值与手牌数均等于体力上限。",
	
	["#Mirai"]="%from 的武将技能 %arg 被触发，手牌上限增加 %arg2",
	["@mirai"]="未来",
	["@TiXuDiscard"]="你可以弃置一张点数不小于 %arg 的手牌令 %src 摸两张牌",
	["LuaChengShi:invoke"]="你可以发动“程式”， %arg 个回合后重新加入游戏",
	["#ChengShiCounter"]="距离 %from 重新加入游戏还有 %arg 个回合",
	["#ChengShiBack"]="%from 重新加入游戏",
	["ChengShi$"]="image=image/animate/chengshi.png",
	["ChengShiZuoCi$"]="image=image/animate/chengshizuoci.png",
}

--Chapter 6 Survivors

--Kamukura Izuru
KamukuraIzuru=sgs.General(extension,"KamukuraIzuru","dgrp","3",true,true,true)

--XinSi
function getAvailableSkills(player)
	local result = {}
	local skillList = player:getSkillList(false, true) --include_equip, visible_only
	for _,skill in sgs.qlist(skillList) do
		if skill then
			local name = skill:objectName()
			if name ~= "huangtianv" and name ~= "zhiba_pindian" and name ~= "xiansi_slash" then
				table.insert(result, name)
			end
		end
	end
	return table.concat(result,"+")
end

LuaXinSi = sgs.CreateTriggerSkill{
	name = "LuaXinSi",
	events = {sgs.Dying},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying = data:toDying()
		local victim = dying.who
		local damage = dying.damage
		if (not damage) or (not damage.from) then
			return false
		end
		if damage.from:objectName() ~= player:objectName() then
			return false
		end
		if player:objectName() == victim:objectName() then
			return false
		end
		--查看濒死角色的技能
		local skills = getAvailableSkills(victim)
		if skills == "" then
			return false
		end
		local choice = room:askForChoice(player, self:objectName(),"nothing+"..skills)
		if choice ~= "nothing" then
			--技能触发效果
			room:notifySkillInvoked(player,self:objectName())
			room:broadcastSkillInvoke(self:objectName())
			--指示线
			room:doAnimate(1, player:objectName(), victim:objectName())
			--发送信息
			local log = sgs.LogMessage()
			log.type = "#XinSiInvoke"
			log.from = player
			log.to:append(victim)
			log.arg = self:objectName()
			room:sendLog(log)
		
			room:detachSkillFromPlayer(victim, choice);
			--记录失去的技能
			local skillStr = player:property("xinsiLose"):toString()
			local skillLost = {}
			if skillStr ~= "" then
				skillLost = skillStr:split("+")
			end
			if not table.contains(skillLost, choice) then
				table.insert(skillLost, choice)
			end
			skillStr = table.concat(skillLost, "+")
			room:setPlayerProperty(player, "xinsiLose", sgs.QVariant(skillStr))
		end
		return false
	end,
}

--ZiRu
function getAvailableSkillToAcquire(player)
	local result = {}
	local skillStr = player:property("xinsiLose"):toString()
	if skillStr == "" then
		return ""
	end
	local skillLost = skillStr:split("+")
	--去掉其中的主公技、限定技、觉醒技与重整技，以及神座已经有的技能
	for i = 1,#skillLost,1 do
		local name = skillLost[i]
		local skill = sgs.Sanguosha:getSkill(name)
		if skill:getFrequency() == sgs.Skill_Wake or
		   skill:getFrequency() == sgs.Skill_Limited or
		   skill:isLordSkill() or
		   name == "LuaChengShi" or
		   name == "LuaTongHua" or
		   name == "huanshen" or
		   name == "weidi" or
		   name == "xinsheng" or 
		   name == "xiaode" or
		   player:hasSkill(name) then
			continue
		end
		table.insert(result, name)
	end
	return table.concat(result,"+")
end

ZiRuCard = sgs.CreateSkillCard{
	name = "LuaZiRu",
	filter = function(self, targets, to_select, player)
		return #targets == 0 and to_select:getHandcardNum() > player:getHandcardNum()
	end,
	feasible = function(self, targets)
		local player = sgs.Self
		local skillStr = getAvailableSkillToAcquire(player)
		if skillStr == "" then
			return #targets == 1
		else
			return #targets <= 1
		end
	end,
	on_use = function(self, room, source, targets)
		--技能发动特效
		room:notifySkillInvoked(source,"LuaZiRu")
		room:broadcastSkillInvoke("LuaZiRu")
	
		if #targets == 1 then
			room:damage(sgs.DamageStruct("LuaZiRu",source,targets[1]))
		else
			local skillStr = getAvailableSkillToAcquire(source)
			local choice = room:askForChoice(source,"LuaZiRu",skillStr)
			room:acquireSkill(source, choice)
			room:setPlayerProperty(source, "ziruAcquire", sgs.QVariant(choice))
		end
	end,
}

LuaZiRuVS = sgs.CreateViewAsSkill{
	name = "LuaZiRu",
	response_pattern = "@@LuaZiRu",
	n = 0,
	view_as = function(self, cards)
		local ziruCard = ZiRuCard:clone()
		return ziruCard
	end,
}

LuaZiRu = sgs.CreateTriggerSkill{
	name = "LuaZiRu",
    events = {sgs.EventPhaseStart},
	view_as_skill = LuaZiRuVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
        if player:getPhase() == sgs.Player_NotActive then
			--失去因“自如”而获得的技能
			local skill = player:property("ziruAcquire"):toString()
			if skill ~= "" then
				room:detachSkillFromPlayer(player,skill)
				room:setPlayerProperty(player, "ziruAcquire", sgs.QVariant(""))
			end
			--令神座选择一项
			room:askForUseCard(player, "@@LuaZiRu", "@LuaZiRu")
		end
		return false
	end,
}

--ChenLun
function getAvailableSkillNum(player)
	local result = {}
	local skillList = player:getSkillList(false, true) --include_equip, visible_only
	for _,skill in sgs.qlist(skillList) do
		if skill then
			local name = skill:objectName()
			if name ~= "huangtianv" and name ~= "zhiba_pindian" and name ~= "xiansi_slash" then
				table.insert(result, name)
			end
		end
	end
	return #result
end

ChenLunCard = sgs.CreateSkillCard{
	name = "ChenLunCard",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		--技能触发效果
		room:notifySkillInvoked(source, "LuaChenLun")
		room:broadcastSkillInvoke("LuaChenLun")
		--全屏特效
		room:doLightbox("ChenLun$", 2500)
		--指示线
		for _, p in sgs.qlist(room:getOtherPlayers(source)) do
			room:doAnimate(1, source:objectName(), p:objectName())
		end
	
		source:loseMark("@chenlun")
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if not p:isAlive() then
				continue
			end
			local num = getAvailableSkillNum(p)
			if num > 0 then
				room:askForDiscard(p, "LuaChenLun", num, num, false, true)
			end
		end
	end,
}

LuaChenLunVS = sgs.CreateViewAsSkill{
	name = "LuaChenLun",
	n = 0,
	view_as = function(self, cards)
		local card=ChenLunCard:clone()
		return card
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@chenlun") >= 1
	end
}

LuaChenLun = sgs.CreateTriggerSkill{
	name = "LuaChenLun" ,
	frequency = sgs.Skill_Limited,
	limit_mark = "@chenlun",
	events = {},
	view_as_skill = LuaChenLunVS ,
	on_trigger = function()
		return false
	end,
}

KamukuraIzuru:addSkill(LuaXinSi)
KamukuraIzuru:addSkill(LuaZiRu)
KamukuraIzuru:addSkill(LuaChenLun)

sgs.LoadTranslationTable{	
	["KamukuraIzuru"]="神座出流",
	["&KamukuraIzuru"]="神座",
	
	["LuaXinSi"]="心死",
	[":LuaXinSi"]="其他角色因为你造成的伤害而进入濒死状态时，你可以声明该角色的一个技能，并令该角色永久失去此技能。",
	["LuaZiRu"]="自如",
	[":LuaZiRu"]="回合结束后，你可以选择一项：声明一个因为“心死”而失去的技能（限定技、觉醒技、主公技与重整技除外），若如此做，你视为拥有此技能直到你的下回合结束；或者对一名手牌数大于你的角色造成1点伤害。",
	["LuaChenLun"]="沉沦",
	[":LuaChenLun"]="<font color=\"red\"><b>限定技，</b></font>出牌阶段，你可以令所有角色各弃置X张牌（X为该角色的技能数量，不足则全弃）。",
	
	["#XinSiInvoke"]="%from 对 %to 发动了技能“%arg”",
	["@LuaZiRu"]="你可以发动技能“自如”",
	["~LuaZiRu"]="选择一名角色（若不选则要声明一个因“心死”失去的技能）→点“确定”",
	["luaziru"]="自如",
	["@chenlun"]="沉沦",
	["ChenLun$"]="image=image/animate/chenlun.png",
	["chenlun"]="沉沦",
}

--Ultimate Hinata
UltimateHinata=sgs.General(extension,"UltimateHinata","dgrp","3",true,true,true)

--KaiChuang
KaiChuangCard = sgs.CreateSkillCard{
	name = "KaiChuangCard",
	filter = function(self, targets, to_select)
		local count = 0
		local player = sgs.Self
		for _, p in sgs.qlist(player:getSiblings()) do
			if p and p:isAlive() and p:hasSkill("LuaMirai") then
				count = count + 1
			end
		end
		if player:hasSkill("LuaMirai") then
			count = count + 1
		end
		if count ~= self:getSubcards():length() then
			return false
		else
			return #targets == 0 and not to_select:hasSkill("LuaMirai")
		end
	end,
	on_effect = function(self, effect)
		local from = effect.from
		local to = effect.to
		local room = from:getRoom()
		--技能触发效果
		room:notifySkillInvoked(from, "LuaKaiChuang")
		room:broadcastSkillInvoke("LuaKaiChuang")
	
		room:acquireSkill(to,"LuaMirai",true)
		to:gainMark("@mirai")
	end,
}

LuaKaiChuang = sgs.CreateViewAsSkill{
	name = "LuaKaiChuang",
	n = 999,
	view_filter = function()
		return true
	end,
	view_as = function(self, cards)
		local create = KaiChuangCard:clone()
		if #cards ~= 0 then
			for _, c in ipairs(cards) do
				create:addSubcard(c)
			end
		end
		return create
	end,
	enabled_at_play = function(self, player)
		return player:canDiscard(player, "he")
	end,
}

--QiXin
LuaQiXin = sgs.CreateTriggerSkill{
	name = "LuaQiXin",
	events = {sgs.Damaged},
	can_trigger = function(self, target)
		return target and target:isAlive() and target:hasSkill("LuaMirai")
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local hinata = room:findPlayerBySkillName(self:objectName())
		if (not hinata) or (not hinata:isAlive()) then
			return false
		end
		local victimData = sgs.QVariant()
		victimData:setValue(player)
		--询问是否发动技能
		if room:askForSkillInvoke(hinata,self:objectName(),victimData) then
			--指示线
			room:doAnimate(1, hinata:objectName(), player:objectName())
			
			local num = player:getMaxCards() - player:getHandcardNum()
			if num > 0 then
				player:drawCards(num)
			end
		end
		return false
	end,
}

UltimateHinata:addSkill(LuaKaiChuang)
UltimateHinata:addSkill(LuaQiXin)
UltimateHinata:addSkill("LuaMirai")
UltimateHinata:addSkill("#LuaMiraiTrigger")

sgs.LoadTranslationTable{	
	["UltimateHinata"]="觉醒创",
	["&UltimateHinata"]="日向",

	["LuaKaiChuang"]="开创",
	[":LuaKaiChuang"]="出牌阶段，你可以弃置X张牌（X为场上拥有技能“未来”的角色数量），令一名没有技能“未来”的角色失去技能“未来”。",
	["LuaQiXin"]="齐心",
	[":LuaQiXin"]="一名拥有技能“未来”的角色受到伤害后，你可以令该角色将手牌补充至手牌上限的张数。",
	
	["kaichuang"]="开创",
}

--Hinata Hajime
HinataHajime=sgs.General(extension,"HinataHajime$","dgrp","4",true) --主公武将

--Ronpa
RonpaCard = sgs.CreateSkillCard {
	name = "LuaRonpa",
	will_throw = false,
	target_fixed = true,
	handling_method = sgs.Card_MethodNone,
	on_use = function(self, room, source)
		--技能发动特效
		room:notifySkillInvoked(source,"LuaRonpa")
		room:broadcastSkillInvoke("LuaRonpa")
	
		source:addToPile("kotodama",self) --言弹
	end
}

LuaRonpaVS = sgs.CreateViewAsSkill {
	name = "LuaRonpa",
	n = 999,
	response_pattern = "@@LuaRonpa",
	view_filter = function(self, cards, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 0 then
			return nil
		end
		local card = RonpaCard:clone()
		for _, c in ipairs(cards) do
			card:addSubcard(c)
		end
		return card
	end,
}

LuaRonpa = sgs.CreateTriggerSkill {
	name = "LuaRonpa",
	view_as_skill = LuaRonpaVS,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Finish and not player:isKongcheng() then
			room:askForUseCard(player, "@@LuaRonpa", "@LuaRonpa")
		end
		return false
	end,
}

LuaRonpaClear = sgs.CreateTriggerSkill {
	name = "#LuaRonpaClear",
	events = {sgs.EventPhaseStart, sgs.EventLoseSkill},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if not player:hasSkill(self:objectName()) then
				return false
			end
			if player:getPhase() == sgs.Player_Start and not player:getPile("kotodama"):isEmpty() then
				--技能发动特效
				room:notifySkillInvoked(player,"LuaRonpa")
				room:broadcastSkillInvoke("LuaRonpa")
				--发送消息
				local log = sgs.LogMessage()
				log.type = "#TriggerSkill"
				log.from = player
				log.arg = "LuaRonpa"
				room:sendLog(log)
				local log = sgs.LogMessage()
				log.type = "#RonpaClear"
				log.from = player
				log.arg = "kotodama"
				room:sendLog(log)
			
				--创建一张虚拟的【杀】
				local slash = sgs.Sanguosha:cloneCard("slash")
				for _, id in sgs.qlist(player:getPile("kotodama")) do
					slash:addSubcard(id)
				end
				player:obtainCard(slash)
			end
		elseif event == sgs.EventLoseSkill then
			local name = data:toString()
			if name == "LuaRonpa" and not player:getPile("kotodama"):isEmpty() then
				local slash = sgs.Sanguosha:cloneCard("slash")
				for _, id in sgs.qlist(player:getPile("kotodama")) do
					slash:addSubcard(id)
				end
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, player:objectName(), "LuaRonpa", "")
				room:throwCard(slash, reason, nil)
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
	priority = 10,
}

LuaRonpaUse = sgs.CreateTriggerSkill {
	name = "#LuaRonpaUse" ,
	events = {sgs.TargetConfirmed, sgs.CardEffected} ,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if not use.card:isNDTrick() then
				return false
			end
			if use.to:length() > 1 then
				return false
			end
			if not use.to:contains(player) then
				return false
			end
			local hinata = room:findPlayerBySkillName(self:objectName())
			if (not hinata) or (not hinata:isAlive()) then
				return false
			end
			if hinata:getPile("kotodama"):isEmpty() then
				return false
			end
			local victimData = sgs.QVariant()
			victimData:setValue(player)
			if room:askForSkillInvoke(hinata,"LuaRonpa",victimData) then
				--指示线
				room:doAnimate(1, hinata:objectName(), player:objectName())
				--选择一张言弹
				local ids = hinata:getPile("kotodama")
				local count = ids:length()
				local id
				if count==1 then
					id = ids:first()
				else
					room:fillAG(ids,hinata)
					id = room:askForAG(hinata,ids,false,"LuaRonpa")
					room:clearAG(hinata)
					if id == -1 then
						return false
					end
				end
				local card = sgs.Sanguosha:getCard(id)
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, hinata:objectName(), "LuaRonpa", "")
				room:throwCard(card, reason, nil)
				player:setTag("LuaRonpa", sgs.QVariant(use.card:toString()))
				
				--发送消息
				local log = sgs.LogMessage()
				log.type = "#RonpaNullified"
				log.from = player
				log.arg = use.card:objectName()
				room:sendLog(log)
			end
		else
			if not player:isAlive() then
				return false
			end
			local effect = data:toCardEffect()
			if player:getTag("LuaRonpa") == nil or (player:getTag("LuaRonpa"):toString() ~= effect.card:toString()) then 
				return false 
			end
			player:setTag("LuaRonpa", sgs.QVariant(""))
			return true --无效
		end
		return false
	end,
}

--JueZe
function hasGeneral(generalTable, room)
	for _, p in sgs.qlist(room:getAlivePlayers()) do
		local name1 = p:getGeneralName()
		local name2 = p:getGeneral2Name()
		if table.contains(generalTable, name1) or table.contains(generalTable, name2) then
			return true
		end
	end
	return false
end

LuaJueZe = sgs.CreateTriggerSkill{
	name = "LuaJueZe" ,
	events = {sgs.GameStart, sgs.EventPhaseStart} ,
	frequency = sgs.Skill_Limited ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local generalTable = {"NanamiChiaki", "EnoshimaJunko", "NaegiMakoto"}
		local trigger = hasGeneral(generalTable, room)
		if trigger then
			if event == sgs.GameStart then
				room:setPlayerMark(player, "RoundCounter", 2)
			elseif event == sgs.EventPhaseStart then
				if player:getPhase() ~= sgs.Player_Start then
					return false
				end
				if player:getMark("RoundCounter") > 0 then
					local choice = room:askForChoice(player, self:objectName(),"nothing+changeToKamukura+changeToUltimate")
					if choice == "nothing" then
						room:setPlayerMark(player, "RoundCounter", player:getMark("RoundCounter") - 1)
					else
						local general
						if choice == "changeToKamukura" then
							general = "KamukuraIzuru"
						else
							general = "UltimateHinata"
						end
		
						--技能发动特效
						room:notifySkillInvoked(player,self:objectName())
						room:broadcastSkillInvoke(self:objectName())
						--发送信息
						local log = sgs.LogMessage()
						log.type = "#JueZeInvoke"
						log.from = player
						log.arg = self:objectName()
						room:sendLog(log)
						--全屏特效
						room:doLightbox("JueZe$", 2500)
						
						--变身成为神座出流或觉醒创
						local isSecondaryHero = player:getGeneralName() ~= "HinataHajime"
						room:changeHero(player, general, false, true, isSecondaryHero, true) --full_state, invoke_start, secondary_hero, send_log
					end
				end
			end
		end
		return false
	end,
	priority = -2,
}
			
HinataHajime:addSkill(LuaRonpa)
HinataHajime:addSkill(LuaRonpaClear)
HinataHajime:addSkill(LuaRonpaUse)
HinataHajime:addSkill(LuaJueZe)
extension:insertRelatedSkills("LuaRonpa","#LuaRonpaClear")
extension:insertRelatedSkills("LuaRonpa","#LuaRonpaUse")

sgs.LoadTranslationTable{	
	["HinataHajime"]="日向创",
	["&HinataHajime"]="日向",
	["#HinataHajime"]="超高校级的???",
	["designer:HinataHajime"]="Smwlover",
	["illustrator:HinataHajime"]="Ruby",

	["LuaJueZe"]="抉择",
	[":LuaJueZe"]="<font color=\"red\"><b>限定技，</b></font>准备阶段开始时，若“七海千秋”、“苗木诚”或“江之岛盾子”在场，你可以将你的武将牌替换为“DGRP-022 日向创”或“DGRP-023 神座出流”。你只能在你的第一个或第二个回合发动此技能。",
	["LuaRonpa"]="论破",
	[":LuaRonpa"]="结束阶段开始时，你可以将任意数量的手牌置于武将牌上，称为“言弹”。一名角色成为非延时锦囊牌的唯一目标后，你可以将一张“言弹”置入弃牌堆，令此牌对该角色无效。<font color=\"blue\"><b>锁定技，</b></font>准备阶段开始时，你获得所有的“言弹”。",

	["changeToKamukura"]="将武将牌替换为神座出流",
	["changeToUltimate"]="将武将牌替换为觉醒创",
	["JueZe$"]="image=image/animate/jueze.png",
	["#JueZeInvoke"]="%from 发动了技能 %arg",
	["#RonpaNullified"]="【%arg】对 %from 无效",
	["luaronpa"]="论破",
	["kotodama"]="言弹",
	["#RonpaClear"]="%from 获得了所有的 %arg",
	["@LuaRonpa"]="你可以将任意数量的手牌置于武将牌上",
	["~LuaRonpa"]="选中任意数量的手牌→点“确定”",
}

--Kuzuryuu Fuyuhiko
KuzuryuuFuyuhiko=sgs.General(extension,"KuzuryuuFuyuhiko","dgrp","3",true)

--HeiDao
function findPlayerByObjectName(player, name)
	local res = nil
	for _, p in sgs.qlist(player:getSiblings()) do
		if p:objectName() == name and p:isAlive() then
			res = p
		end
	end
	return res
end

HeiDaoCard = sgs.CreateSkillCard{ --用来发动技能的技能卡
	name = "HeiDaoCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		--技能发动特效
		room:notifySkillInvoked(source,"LuaHeiDao")
		room:broadcastSkillInvoke("LuaHeiDao")
		
		local choice =  room:askForChoice(targets[1],"LuaHeiDao","receiveDamage+unlimitedSlash")
		if choice == "receiveDamage" then
			room:damage(sgs.DamageStruct("LuaHeiDao",source,targets[1]))
		else
			room:setPlayerProperty(source, "HeiDaoTarget", sgs.QVariant(targets[1]:objectName()))
			room:setPlayerFlag(source, "HeiDaoUnlimited")
			source:drawCards(1)

			--发送消息
			local log = sgs.LogMessage()
			log.type = "#HeiDaoSuccess"
			log.from = source
			log.to:append(targets[1])
			room:sendLog(log)
		end
	end,
}

HeiDaoSlashCard = sgs.CreateSkillCard{ --用来对该角色无限出【杀】的技能卡
	name = "HeiDaoSlashCard",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		local targetName = source:property("HeiDaoTarget"):toString()
		local target = findPlayerByObjectName(source, targetName)
		if target then
			local target_serverPlayer = nil
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:objectName() == target:objectName() then
					target_serverPlayer = p
				end
			end --player类型到serverPlayer类型的转型
			if not target_serverPlayer then
				return false
			end
			room:askForUseSlashTo(source, target_serverPlayer, "@HeiDaoSlash:"..target:objectName().."::", false, false, false) --distance_limit, disable_extra, add_history
		end
	end,
}
	
LuaHeiDao = sgs.CreateViewAsSkill{ --需要根据两种情况返回不同的技能卡
	name = "LuaHeiDao",
	n = 1,
	view_filter = function(self, selected, to_select)
		if #selected == 0 then
			if not sgs.Self:hasUsed("#HeiDaoCard") then
				return to_select:isBlack()
			end
		end
	end,
	view_as = function(self, cards)
		if not sgs.Self:hasUsed("#HeiDaoCard") then
			if #cards == 1 then
				local card = HeiDaoCard:clone()
				card:addSubcard(cards[1])
				return card
			end
		else
			if sgs.Self:hasFlag("HeiDaoUnlimited") then
				if #cards == 0 then
					return HeiDaoSlashCard:clone()
				end
			end
		end
		return nil
	end,	
	enabled_at_play = function(self, player)
		if not player:hasUsed("#HeiDaoCard") then
			return not player:isNude()
		else
			if player:isNude() then
				return false
			end
			if player:hasFlag("HeiDaoUnlimited") then
				local targetName = player:property("HeiDaoTarget"):toString()
				local target = findPlayerByObjectName(player, targetName)
				if target then
					return player:canSlash(target, nil, false)
				end
			end
		end
		return false
	end,
}

LuaHeiDaoDistance = sgs.CreateDistanceSkill{
	name="#LuaHeiDaoDistance",
	correct_func=function(self,from,to)
		if from:hasSkill("LuaHeiDao") and from:hasFlag("HeiDaoUnlimited") then
			local targetName = from:property("HeiDaoTarget"):toString()
			if to:objectName() == targetName then
				return -1000;
			end
		end
	end,
}
	
LuaHeiDaoClear = sgs.CreateTriggerSkill{
	name = "#LuaHeiDaoClear",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Finish then
			room:setPlayerProperty(player,"HeiDaoTarget",sgs.QVariant(""))
		end --不用考虑flag的清除，flag在回合结束会自动清除
	end,
}	

--QingChou
QingChouCard = sgs.CreateSkillCard{
	name = "LuaQingChou",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		--技能发动特效
		room:notifySkillInvoked(source,"LuaQingChou")
		room:broadcastSkillInvoke("LuaQingChou")
	end,
}	

LuaQingChouVS = sgs.CreateViewAsSkill{
	name = "LuaQingChou",
	n = 1,
	response_pattern = "@@LuaQingChou",
	view_filter = function(self, selected, to_select)
		return #selected == 0 and to_select:isRed()
	end,
	view_as = function(self, cards)
		if #cards == 0 then
			return nil
		end
		local card = QingChouCard:clone()
		card:addSubcard(cards[1])
		return card
	end,
}

LuaQingChou = sgs.CreateTriggerSkill{
	name = "LuaQingChou",
	events = {sgs.DamageDone, sgs.CardFinished},
	view_as_skill = LuaQingChouVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DamageDone then
			local damage = data:toDamage()
			local card = damage.card
			local from = damage.from
			local kuzuryuu = room:findPlayerBySkillName(self:objectName())
			if (not kuzuryuu) or (not kuzuryuu:isAlive()) or (not kuzuryuu:hasSkill(self:objectName())) then
				return false
			end
			if (not from) or (from:objectName() == kuzuryuu:objectName()) then
				return false
			end
			if (not card) or (not card:isKindOf("Slash")) then
				return false
			end
			from:setTag("invokeQingChou", sgs.QVariant(card:toString()))
		else
			local kuzuryuu = room:findPlayerBySkillName(self:objectName())
			if (not kuzuryuu) or (not kuzuryuu:isAlive()) or (not kuzuryuu:hasSkill(self:objectName())) then
				return false
			end
			local use = data:toCardUse()
			local card = use.card
			local from = use.from
			if (not from) or (not from:isAlive()) then
				return false
			end
			local slashStr = from:getTag("invokeQingChou"):toString()
			if slashStr ~= card:toString() then
				return false
			end
			from:setTag("invokeQingChou",sgs.QVariant(""))
			--视为使用【杀】
			if kuzuryuu:canSlash(from, nil, false) then
				if not kuzuryuu:isNude() then
					if room:askForUseCard(kuzuryuu, "@@LuaQingChou", "@LuaQingChou:"..from:objectName().."::") then
						local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
						slash:setSkillName(self:objectName())
						local card_use = sgs.CardUseStruct()
						card_use.card = slash
						card_use.from = kuzuryuu
						card_use.to:append(from)
						room:useCard(card_use, false)
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end,
}

KuzuryuuFuyuhiko:addSkill(LuaHeiDao)
KuzuryuuFuyuhiko:addSkill(LuaHeiDaoDistance)
KuzuryuuFuyuhiko:addSkill(LuaHeiDaoClear)
KuzuryuuFuyuhiko:addSkill(LuaQingChou)
extension:insertRelatedSkills("LuaHeiDao","#LuaHeiDaoDistance")
extension:insertRelatedSkills("LuaHeiDao","#LuaHeiDaoClear")
	
sgs.LoadTranslationTable{	
	["KuzuryuuFuyuhiko"]="九头龙冬彦",
	["&KuzuryuuFuyuhiko"]="九头龙",
	["#KuzuryuuFuyuhiko"]="超高校级的黑道",
	["designer:KuzuryuuFuyuhiko"]="Smwlover",
	["illustrator:KuzuryuuFuyuhiko"]="Ruby",
	
	["LuaHeiDao"]="黑道",
	[":LuaHeiDao"]="<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以弃置一张黑色牌，令一名其他角色选择一项：令你摸一张牌，然后本阶段内无视与该角色的距离，且对其使用【杀】无次数限制；或受到你造成的1点伤害。",
	["LuaQingChou"]="情仇",
	[":LuaQingChou"]="一名其他角色使用的【杀】结算完毕后，若此【杀】造成了伤害，你可以弃置一张红色牌，视为你对其使用了一张【杀】。",
	
	["heidao"]="黑道",
	["heidaoslash"]="黑道",
	["luaqingchou"]="情仇",
	["unlimitedSlash"]="摸一张牌、无视距离、无限次数",
	["receiveDamage"]="受到1点伤害",
	["#HeiDaoSuccess"]="%from 本回合无视与 %to 的距离，且可以对 %to 使用任意数量的【杀】",
	["@HeiDaoSlash"]="请对 %src 使用一张【杀】",
	["@LuaQingChou"]="你可以弃置一张红色牌，视为对 %src 使用一张【杀】",
	["~LuaQingChou"]="选中一张红色牌→点“确定”",
}

--Sonia Nevermind
SoniaNevermind=sgs.General(extension,"SoniaNevermind","dgrp","3",false)

--TianRan
LuaTianRan = sgs.CreateTriggerSkill{
	name = "LuaTianRan" ,
	events = {sgs.Damaged, sgs.EventPhaseChanging} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damaged then
			if player:isAlive() and player:hasSkill(self:objectName()) then
				local damage = data:toDamage()
				local card = damage.card
				if card and card:isKindOf("Slash") then
					local from = damage.from
					if (not from) or (not from:isAlive()) then
						return false
					end
					if player:hasFlag("tianranUsed") then
						return false
					end
					--询问是否发动“天然”
					local userData = sgs.QVariant()
					userData:setValue(from)
					if room:askForSkillInvoke(player,self:objectName(),userData) then
						--指示线
						room:doAnimate(1, player:objectName(), from:objectName())
						
						local recover = sgs.RecoverStruct()
						room:recover(player, recover)
						from:drawCards(2)
						room:setPlayerFlag(player, "tianranUsed")
					end
				end
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
            if change.to == sgs.Player_NotActive then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if p:hasFlag("tianranUsed") then
                        room:setPlayerFlag(p, "-tianranUsed")
                    end
                end
            end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end,
}

--WangNv
LuaWangNv = sgs.CreateTriggerSkill{
	name = "LuaWangNv",
	events = {sgs.DrawNCards},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		--检查与索尼娅距离为1的角色数
		local num = 0
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if p:distanceTo(player) <= 1 then
				num = num + 1
			end
		end
		if num == 2 then
			return false
		end
		if player:askForSkillInvoke(self:objectName(),sgs.QVariant("draw:::"..tostring(num))) then
			local count = num
			data:setValue(count)
		end
		return false
	end,
}

SoniaNevermind:addSkill(LuaTianRan)
SoniaNevermind:addSkill(LuaWangNv)

sgs.LoadTranslationTable{	
	["SoniaNevermind"]="索尼娅内瓦曼德",
	["&SoniaNevermind"]="索尼娅",
	["#SoniaNevermind"]="超高校级的王女",
	["designer:SoniaNevermind"]="Smwlover",
	["illustrator:SoniaNevermind"]="Ruby",
	
	["LuaWangNv"]="王女",
	[":LuaWangNv"]="摸牌阶段，你可以将摸牌的数量调整为X（X为与你距离为1以内的角色数量）。",
	["LuaTianRan"]="天然",
	[":LuaTianRan"]="你受到一名角色使用【杀】造成的伤害后，可以令该角色摸两张牌，然后你回复1点体力。每名角色的回合限一次。",
	["LuaWangNv:draw"]="你可以将你的摸牌数量改为 %arg",
}

--Souda Kazuichi
SoudaKazuichi=sgs.General(extension,"SoudaKazuichi","dgrp","4",true)

--JiGongNew
function isCardAvailable(room, card)
	local equip = card:getRealCard():toEquipCard()
	local equip_index = equip:location()
	for _, p in sgs.qlist(room:getAlivePlayers()) do
		if p:getEquip(equip_index) == nil then
			return true
		end
	end
	return false
end

JiGongNewCard = sgs.CreateSkillCard{
	name = "JiGongNewCard",
	will_throw = true,
	target_fixed = true,
	on_use = function(self, room, source, tars)
		--技能发动特效
		room:notifySkillInvoked(source,"LuaJiGongNew")
		room:broadcastSkillInvoke("LuaJiGongNew")
	
		--检视所有装备牌
		local discard = room:getDiscardPile()
		local enabled, disabled = sgs.IntList(), sgs.IntList()
		local equips = sgs.IntList()
		for _,id in sgs.qlist(discard) do
			local card = sgs.Sanguosha:getCard(id)
			if card:isKindOf("EquipCard") then
				equips:append(id)
				if isCardAvailable(room, card) then
					enabled:append(id)
				else
					disabled:append(id)
				end
			end
		end
		--选择一张装备牌
		local id = -1
		if equips:length() ~= 0 then
			room:fillAG(equips, source, disabled)
			id = room:askForAG(source, enabled, true, "LuaJiGongNew")
			room:clearAG(source)
		end
		--如果没有选择牌
		if id == -1 then
			source:drawCards(2)
		else
			local card = sgs.Sanguosha:getCard(id)
			local equip = card:getRealCard():toEquipCard()
			local equip_index = equip:location()
			--选择一名角色
			local targets = sgs.SPlayerList()
			local list = room:getAlivePlayers()
			for _,target in sgs.qlist(list) do
				if target:getEquip(equip_index) == nil then
					targets:append(target)
				end
			end
			if targets:isEmpty() then
				return false
			end
			local target = room:askForPlayerChosen(source, targets, "LuaJiGongNew", "@JiGongChoose", false, false)
			if target then
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, source:objectName(), target:objectName(), nil)
				room:moveCardTo(card, nil, target, sgs.Player_PlaceEquip, reason)
				
				--指示线
				room:doAnimate(1, source:objectName(), target:objectName())
				--发送信息
				local msg = sgs.LogMessage()
				msg.type = "$JiGongPut"
				msg.from = source
				msg.to:append(target)
				msg.card_str = tostring(card:getEffectiveId())
				room:sendLog(msg)
			end
		end
	end,
}

LuaJiGongNew = sgs.CreateViewAsSkill{
	name = "LuaJiGongNew",
	n = 1,
	view_filter = function(self, selected, to_select)
		return #selected == 0 and to_select:isKindOf("EquipCard")
	end,
	view_as = function(self, cards)
		if #cards == 0 then
			return nil
		end
		local card = JiGongNewCard:clone()
		card:setSkillName(self:objectName())
		card:addSubcard(cards[1])
		return card
	end,
	enabled_at_play = function(self, player)
		return (not player:hasUsed("#JiGongNewCard")) and (not player:isNude())
	end,
}

SoudaKazuichi:addSkill(LuaJiGongNew)

sgs.LoadTranslationTable{	
	["SoudaKazuichi"]="左右田和一",
	["&SoudaKazuichi"]="左右田",
	["#SoudaKazuichi"]="超高校级的机械师",
	["designer:SoudaKazuichi"]="Smwlover",
	["illustrator:SoudaKazuichi"]="Ruby",
	
	["LuaJiGongNew"]="技工",
	[":LuaJiGongNew"]="<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以弃置一张装备牌，然后检视弃牌堆中的所有装备牌，最后选择一项：将其中一张装备牌置于一名角色的装备区；或者摸两张牌。",
	
	["jigongnew"]="技工",
	["@JiGongChoose"]="请选择一名角色，将该装备牌置于该角色的装备区中",
	["$JiGongPut"]="%from 将 %card 从弃牌堆中置于 %to 的装备区中",
}

--Owari Akane
OwariAkane=sgs.General(extension,"OwariAkane","dgrp","4",false)

--KuangYe
LuaKuangYe=sgs.CreateTriggerSkill{
	name="LuaKuangYe",
	frequency=sgs.Skill_NotFrequent,
	events={sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Draw then --摸牌阶段
			if player:isWounded() then --受伤
				local room = player:getRoom()
				if player:askForSkillInvoke(self:objectName(), sgs.QVariant("giveUpDraw")) then
					local x = player:getLostHp()
					local ids = room:getNCards(x, false) --牌堆顶翻开牌
					local move = sgs.CardsMoveStruct()
					move.card_ids = ids
					move.to = player
					move.to_place = sgs.Player_PlaceTable
					move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, player:objectName(), self:objectName(), nil)
					room:moveCardsAtomic(move, true)
					local card_to_throw = {} --要弃置的牌
					local card_to_gotback = {} --要拿回的牌
					for i=0, x-1, 1 do
						local id = ids:at(i)
						local card = sgs.Sanguosha:getCard(id)
						if card:isKindOf("BasicCard") then
							table.insert(card_to_gotback, id)
						else
							table.insert(card_to_throw, id)
						end
					end
					if #card_to_gotback > 0 then
						local dummy2 = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
						for _, id in ipairs(card_to_gotback) do
							dummy2:addSubcard(id)
						end
						room:obtainCard(player, dummy2)
					end --获得所有的基本牌，这里构造了一张虚拟的杀，这张杀的子卡是要获得的牌
					if #card_to_throw > 0 then
						local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
						for _, id in ipairs(card_to_throw) do
							dummy:addSubcard(id)
						end
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, player:objectName(), self:objectName(), nil)
						room:throwCard(dummy, reason, nil)
					end
					local count=#card_to_throw
					--视为使用杀
					for i=1, count, 1 do
						local targets = sgs.SPlayerList()
						local list = room:getAlivePlayers()
						for _,target in sgs.qlist(list) do
							if player:canSlash(target, nil, false) then
								targets:append(target)
							end
						end
						if targets:isEmpty() then
							return false
						end
						local target = room:askForPlayerChosen(player, targets, self:objectName(), "@KuangYeInvoke",false,true)
						--考虑AI最后没有选到合适角色的情况
						if not target then
							local randomNum = math.random(0, targets:length() - 1)
							target = targets:at(randomNum)
						end
						local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
						slash:setSkillName(self:objectName())
						local card_use = sgs.CardUseStruct()
						card_use.card = slash
						card_use.from = player
						card_use.to:append(target)
						room:useCard(card_use, false)
					end
					return true
				end
			end
		end
		return false
	end,
}

OwariAkane:addSkill(LuaKuangYe)

sgs.LoadTranslationTable{	
	["OwariAkane"]="终里赤音",
	["&OwariAkane"]="终里",
	["#OwariAkane"]="超高校级的体操部",
	["designer:OwariAkane"]="Smwlover",
	["illustrator:OwariAkane"]="Ruby",
	
	["LuaKuangYe"]="狂野",
	[":LuaKuangYe"]="摸牌阶段开始时，若你已受伤，你可以放弃摸牌并展示牌堆顶的X张牌（X为你已损失的体力值），弃置其中的非基本牌，然后获得其余的牌。每有一张非基本牌以此法被弃置，视为你对一名其他角色使用了一张【杀】。",
	["@KuangYeInvoke"]="请选择一名角色视为对其使用【杀】",
	["LuaKuangYe:giveUpDraw"]="你可以放弃摸牌，然后从牌堆顶展示牌"
}

--Danganronpa I Characters

--Naegi Makoto
NaegiMakoto=sgs.General(extension,"NaegiMakoto$","dgrp","3",true)

--XinYang
LuaXinYang = sgs.CreateTriggerSkill{
	name = "LuaXinYang" ,
	frequency = sgs.Skill_Frequent ,
	events = {sgs.CardUsed, sgs.CardResponded, sgs.FinishJudge, sgs.EventLoseSkill} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			local card = use.card
			local num = card:getNumber()
			if num == 1 or num == 10 or num == 3 or num == 7 then
				if not card:isKindOf("SkillCard") then
					if player:askForSkillInvoke(self:objectName(),sgs.QVariant("invoke")) then
						local judge = sgs.JudgeStruct()
						judge.pattern = ".|spade"
						judge.good = false
						judge.reason = self:objectName()
						judge.who = player
						judge.play_animation = true
						room:judge(judge)
					end
				end
			end
		elseif event == sgs.CardResponded then
			local response = data:toCardResponse()
			local card = response.m_card
			local num = card:getNumber()
			if num == 1 or num == 10 or num == 3 or num == 7 then
				if not card:isKindOf("SkillCard") then
					if player:askForSkillInvoke(self:objectName(),sgs.QVariant("invoke")) then
						local judge = sgs.JudgeStruct()
						judge.pattern = ".|spade"
						judge.good = false
						judge.reason = self:objectName()
						judge.who = player
						judge.play_animation = true
						room:judge(judge)
					end
				end
			end
		elseif event == sgs.FinishJudge then
			local judge = data:toJudge()
			if judge.reason == self:objectName() then
				if judge:isGood() then
					local id = judge.card:getEffectiveId()
					player:addToPile("kibou", id)
					return true
				end
			end
		else
			if data:toString() == self:objectName() then
				player:removePileByName("kibou")
			end
		end
		return false
	end,
}

LuaXinYangExchange = sgs.CreateTriggerSkill{
	name = "#LuaXinYangExchange" ,
	frequency = sgs.Skill_Frequent ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Finish then
			if not player:getPile("kibou"):isEmpty() then
				local ids = player:getPile("kibou")
				local count = ids:length()
				local id
				if count == 1 then
					id = ids:first()
				else
					room:fillAG(ids,player)
					id = room:askForAG(player,ids,true,"LuaXinYang")
					room:clearAG(player)
				end
				if id ~= -1 then
					--技能发动特效
					room:notifySkillInvoked(player,"LuaXinYang")
					room:broadcastSkillInvoke("LuaXinYang")
				
					local card = sgs.Sanguosha:getCard(id)
					room:obtainCard(player, card, true)
					--发送信息
					local log = sgs.LogMessage()
					log.type = "$XinYangExchange"
					log.from = player
					log.card_str = tostring(card:getEffectiveId())
					log.arg = "LuaXinYang"
					room:sendLog(log)
				
					--选择一张牌加入“希望”牌堆
					card = room:askForCard(player, ".!", "@exchangeCard", sgs.QVariant(), sgs.Card_MethodNone)
					if not card then
						if not player:isKongcheng() then
							card = player:getHandcards():at(math.random(0, player:getHandcardNum() - 1))
						else
							return false
						end
					end
					player:addToPile("kibou", card:getId(), true)
				end
			end
			return false
		end
	end,
}

--ZhengJiu
LuaZhengJiu = sgs.CreateTriggerSkill{
	name = "LuaZhengJiu",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self,event,player,data)
		if player:getPhase() ~= sgs.Player_RoundStart then
			return false 
		end
		local room = player:getRoom()
		local naegi = room:findPlayerBySkillName(self:objectName())
		if (not naegi) or (not naegi:isAlive()) or (naegi:objectName() == player:objectName()) then
			return false
		end
		if not naegi:isWounded() then
			return false
		end
		if naegi:getPile("kibou"):isEmpty() then
			return false
		end
		--开始询问是否发动【拯救】
		local currentData = sgs.QVariant()
		currentData:setValue(player)
		if room:askForSkillInvoke(naegi,self:objectName(),currentData) then
			--技能发动特效
			room:notifySkillInvoked(naegi,"LuaZhengJiu")
			room:broadcastSkillInvoke("LuaZhengJiu")
			--指示线
			room:doAnimate(1, naegi:objectName(), player:objectName())
		
			local hopes = naegi:getPile("kibou")
			local count = hopes:length()
			local id
			if count == 1 then
				id = hopes:first()
			else
				room:fillAG(hopes,naegi)
				id = room:askForAG(naegi,hopes,false,self:objectName())
				room:clearAG(naegi)
				if id == -1 then
					return false
				end
			end
			--将“希望”交给该角色
			local card = sgs.Sanguosha:getCard(id)
			room:obtainCard(player, card, true)
			--给该角色一个flag，flag回合结束会自动清除
			room:setPlayerFlag(player, "DamageDisabled")
		end
		return false
	end,
	can_trigger = function(self, target) --不能设置成只有自己才可以被触发，那样的话就变成只有自己的回合开始才发动了
		return target
	end,
}

LuaZhengJiuDisable = sgs.CreateTriggerSkill{ --全局触发技
	name = "#LuaZhengJiuDisable",
	events = {sgs.DamageCaused},
	global = true,
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local room = player:getRoom()
		if damage.from and damage.from:isAlive() and damage.from:hasFlag("DamageDisabled") then
			--发送信息
			local log = sgs.LogMessage()
			log.type = "#ZhengJiuDisable"
			log.from = player
			log.arg = "LuaZhengJiu"
			room:sendLog(log)
		
			room:setEmotion(damage.to, "skill_nullify") --伤害防止特效
			return true
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end,
}

NaegiMakoto:addSkill(LuaXinYang)
NaegiMakoto:addSkill(LuaXinYangExchange)
NaegiMakoto:addSkill(LuaZhengJiu)
NaegiMakoto:addSkill("LuaMirai")
NaegiMakoto:addSkill("#LuaMiraiTrigger")
extension:insertRelatedSkills("LuaXinYang","#LuaXinYangExchange")
local skill=sgs.Sanguosha:getSkill("#LuaZhengJiuDisable")
if not skill then
	local skillList=sgs.SkillList()
	skillList:append(LuaZhengJiuDisable)
	sgs.Sanguosha:addSkills(skillList)
end --全局触发技

sgs.LoadTranslationTable{	
	["NaegiMakoto"]="苗木诚",
	["&NaegiMakoto"]="苗木",
	["#NaegiMakoto"]="超高校级的幸运/希望",
	["designer:NaegiMakoto"]="Smwlover",
	["illustrator:NaegiMakoto"]="Ruby",
	
	["LuaXinYang"]="信仰",
	[":LuaXinYang"]="你使用或打出一张点数为A、10、3或7的牌时，可以进行一次判定，将非黑桃的判定牌置于你的武将牌上，称为“希望”。结束阶段开始时，你可以将一张手牌与一张“希望”交换。",
	["LuaZhengJiu"]="拯救",
	[":LuaZhengJiu"]="一名其他角色的回合开始时，若你已受伤，你可以将一张“希望”交给该角色，若如此做，该角色本回合内无法造成伤害。",
	
	["@exchangeCard"]="请选择一张手牌加入“希望”牌堆",
	["LuaXinYang:invoke"]="你可以发动“信仰”进行判定",
	["$XinYangExchange"]="%from 发动技能“%arg”将 %card 加入手牌",
	["kibou"]="希望",
	["#ZhengJiuDisable"]="%from 造成的伤害因为“%arg”的原因被防止",
}

--Kirigiri Kyouko
KirigiriKyouko=sgs.General(extension,"KirigiriKyouko","dgrp","3",false)

--MingCha
LuaMingCha = sgs.CreateTriggerSkill{
	name = "LuaMingCha" ,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() ~= sgs.Player_Start then
			return false
		end
		local kirigiri = room:findPlayerBySkillName(self:objectName())
		if (not kirigiri) or (not kirigiri:isAlive()) then
			return false
		end
		if not(kirigiri:getHp() < player:getHp()) then
			return false
		end --必须是体力值大于雾切的角色
		if kirigiri:askForSkillInvoke(self:objectName(),sgs.QVariant("draw")) then
			--指示线
			room:doAnimate(1, kirigiri:objectName(), player:objectName())
		
			kirigiri:drawCards(1)
			card = room:askForCard(kirigiri, "..!", "@mingchaPlace", sgs.QVariant(), sgs.Card_MethodNone)
			if not card then
				return false
			end
			reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, kirigiri:objectName(), self:objectName(), "")
			room:moveCardTo(card, nil, sgs.Player_DrawPile, reason, false)
		end
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
}

--JianRen
LuaJianRen = sgs.CreateTriggerSkill{
	name = "LuaJianRen" ,
	events = {sgs.Damaged} ,
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if not damage.from or damage.from:isKongcheng() then
			return
		end
		local target = damage.from
		local targetData = sgs.QVariant()
		targetData:setValue(target)
		if room:askForSkillInvoke(player,self:objectName(),targetData) then
			--指示线
			room:doAnimate(1, player:objectName(), target:objectName())
		
			local ids = target:handCards()
			local enabled, disabled = sgs.IntList(), sgs.IntList()
			for _,id in sgs.qlist(ids) do
				if sgs.Sanguosha:getCard(id):isRed() then
					enabled:append(id)
				else
					disabled:append(id)
				end
			end
			--观看所有手牌
			room:fillAG(ids, player, disabled)
			room:setPlayerProperty(player, "jianrenTarget", targetData)
			local id = room:askForAG(player, enabled, true, self:objectName())
			room:setPlayerProperty(player, "jianrenTarget", sgs.QVariant(""))
			room:clearAG(player)
			
			--发送信息
			local log = sgs.LogMessage()
			log.type = "#JianRenView"
			log.from = player
			log.to:append(target)
			room:sendLog(log)
			
			if id ~= -1 then
				local targets = room:getOtherPlayers(damage.from)
				local receiver = room:askForPlayerChosen(player, targets, self:objectName(),"@JianRenInvoke",false,false)
				if player:property("jianrenChoose"):toString() ~= "" then
					room:setPlayerProperty(player, "jianrenChoose", sgs.QVariant(""))
				end
				if receiver then
					player:setFlags("Global_GongxinOperator")
					room:obtainCard(receiver, sgs.Sanguosha:getCard(id), false)
					player:setFlags("-Global_GongxinOperator")
				end
			end
		end
		return false
	end,
}

KirigiriKyouko:addSkill(LuaMingCha)
KirigiriKyouko:addSkill(LuaJianRen)
KirigiriKyouko:addSkill("LuaMirai")
KirigiriKyouko:addSkill("#LuaMiraiTrigger")
extension:insertRelatedSkills("LuaMirai","#LuaMiraiTrigger")

sgs.LoadTranslationTable{	
	["KirigiriKyouko"]="雾切响子",
	["&KirigiriKyouko"]="雾切",
	["#KirigiriKyouko"]="超高校级的侦探",
	["designer:KirigiriKyouko"]="Smwlover",
	["illustrator:KirigiriKyouko"]="Ruby",
	
	["LuaMingCha"]="明察",
	[":LuaMingCha"]="一名体力值大于你的角色的准备阶段开始时，你可以摸一张牌，然后将一张牌置于牌堆顶。",
	["LuaJianRen"]="坚韧",
	[":LuaJianRen"]="每当你受到伤害后，你可以观看伤害来源的所有手牌，然后你可以将其中的一张红色牌交给除伤害来源外的一名角色。",
	
	["LuaMingCha:draw"]="你可以发动“明察”摸一张牌",
	["@mingchaPlace"]="请将一张牌置于牌堆顶",
	["@JianRenInvoke"]="请选择一名角色获得此牌",
	["#JianRenView"]="%from 观看了 %to 的所有手牌",
}

--Togami Byakuya
TogamiByakuya=sgs.General(extension,"TogamiByakuya","dgrp","3",true)

--CaiFa
CaiFaCard = sgs.CreateSkillCard{
	name = "CaiFaCard",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		--技能发动特效
		room:notifySkillInvoked(source,"LuaCaiFa")
		room:broadcastSkillInvoke("LuaCaiFa")
	
		local judge = sgs.JudgeStruct()
		judge.good = true
		judge.who = source
		judge.reason = "LuaCaiFa"
		judge.play_animation = false
		room:judge(judge)
	end,
}

CaiFaFixed = sgs.CreateSkillCard{
	name = "CaiFaFixed",
	target_fixed = true,
	will_throw = false,
	on_validate = function(self, use)
		use.m_isOwnerUse = false
		local pattern = self:getUserString()
		local card = sgs.Sanguosha:getCard(tonumber(pattern))
		return card
	end,
}
	
CaiFaUnfixed = sgs.CreateSkillCard{
	name = "CaiFaUnfixed",
	target_fixed = false,
	will_throw = false,
	filter = function(self, selected, to_select)
		local pattern = self:getUserString()
		local card = sgs.Sanguosha:getCard(tonumber(pattern))
		local targetlist = sgs.PlayerList()
		for _,p in pairs(selected) do
			targetlist:append(p)
		end
		return card:targetFilter(targetlist, to_select, sgs.Self)
	end,
	feasible = function(self, targets)
		return #targets ~= 0 --这里必须要限定一下目标数量不能为0，因为铁索连环只能使用不能重铸
	end,
	on_validate = function(self, use)
		use.m_isOwnerUse = false
		local pattern = self:getUserString()
		local card = sgs.Sanguosha:getCard(tonumber(pattern))
		return card
	end,
}

LuaCaiFaVS = sgs.CreateZeroCardViewAsSkill{
	name = "LuaCaiFa",
	response_pattern = "@@LuaCaiFa",
	view_as = function()
		local player = sgs.Self
		local pattern = player:property("caifa_id"):toString()
		if pattern == "" then
			return CaiFaCard:clone()
		else
			local card = sgs.Sanguosha:getCard(tonumber(pattern))
			if not card:targetFixed() then
				local caifaunfixed = CaiFaUnfixed:clone()
				caifaunfixed:setUserString(pattern)
				return caifaunfixed
			end
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasFlag("caifa_failed")
	end,
}

LuaCaiFa = sgs.CreateTriggerSkill{
	name = "LuaCaiFa",
	events = {sgs.FinishJudge},
	view_as_skill = LuaCaiFaVS,
	on_trigger = function(self, event, player, data)
		local judge = data:toJudge()
		if judge.reason ~= "LuaCaiFa" then
			return false
		end
		local card = judge.card
		local room = player:getRoom()	
		--判断该卡牌能否使用
		local canUse = false
		if card:isAvailable(player) and (not player:isCardLimited(card,sgs.Card_MethodUse)) then
			canUse = true
		end
		if not canUse then
			room:setPlayerFlag(player, "caifa_failed")
			
			--发送信息
			local log = sgs.LogMessage()
			log.type = "#CaiFaFail"
			log.from = player
			log.arg = card:objectName()
			log.arg2 = self:objectName()
			room:sendLog(log)
			--播放判定动画
			judge.good = false
			judge:updateResult()
			room:sendJudgeResult(judge)
			return false
		else
			--播放判定动画
			judge.good = true
			judge:updateResult()
			room:sendJudgeResult(judge)
		end
		--是否使用该卡牌
		room:setPlayerProperty(player, "caifa_id", sgs.QVariant(card:toString()))
		--以下根据target_fixed的值分两种情况考虑
		if card:targetFixed() then
			if player:askForSkillInvoke(self:objectName(),sgs.QVariant("use:::"..card:objectName())) then
				local caifafixed = CaiFaFixed:clone()
				caifafixed:setUserString(card:toString())
				local card_use = sgs.CardUseStruct()
				card_use.card = caifafixed
				card_use.from = player
				room:useCard(card_use, false) --add_history
			else
				room:setPlayerFlag(player, "caifa_failed")
			end
		else
			local carduse = nil
			carduse = room:askForUseCard(player, "@@LuaCaiFa", "@LuaCaiFa:::"..card:objectName())
			if not carduse then
				room:setPlayerFlag(player, "caifa_failed")
			end
		end
		room:setPlayerProperty(player, "caifa_id", sgs.QVariant(""))
		return false
	end,
}

--ChiMing
function targetsTable2QList(thetable)
	local theqlist = sgs.PlayerList()
	for _, p in ipairs(thetable) do
		theqlist:append(p)
	end
	return theqlist
end

LuaExtraCollateralCard = sgs.CreateSkillCard{
	name = "LuaChiMing" ,
	filter = function(self, targets, to_select)
		--获取这张借刀杀人的牌
		local coll = sgs.Card_Parse(sgs.Self:property("extra_collateral"):toString())
		if (not coll) then 
			return false 
		end
		--获取这张借刀杀人的目标
		local tos = sgs.Self:property("extra_collateral_current_targets"):toString():split("+")
		--获取这张借刀杀人的使用者
		local userString = sgs.Self:property("extra_collateral_user"):toString()
		local user = nil
		local players = sgs.Self:getSiblings()
		for _,player in sgs.qlist(players) do
			if player:objectName() == userString then
				user = player
				break
			end
		end
		if (not user) then
			return false
		end
		if (#targets == 0) then
			return (not table.contains(tos, to_select:objectName())) 
			   and (not user:isProhibited(to_select, coll)) 
			   and coll:targetFilter(targetsTable2QList(targets), to_select, user)
		else
			return coll:targetFilter(targetsTable2QList(targets), to_select, user)
		end
	end,
	feasible = function(self, targets)
		return #targets==2
	end,
	about_to_use = function(self, room, cardUse)
		local killer = cardUse.to:first()
		local victim = cardUse.to:last()
		killer:setFlags("ExtraCollateralTarget")
		local _data = sgs.QVariant()
		_data:setValue(victim)
		killer:setTag("collateralVictim", _data)
		
		--获取这张借刀杀人的使用者，以便显示指示线
		local userString = cardUse.from:property("extra_collateral_user"):toString()
		local user = nil
		local players = cardUse.from:getSiblings()
		for _,player in sgs.qlist(players) do
			if player:objectName() == userString then
				user = player
				break
			end
		end
		
		--指示线
		room:doAnimate(1, user:objectName(), killer:objectName())
		room:doAnimate(1, killer:objectName(), victim:objectName())
		--发送信息
		local log = sgs.LogMessage()
		log.type = "#ChiMingAddLog"
		log.from = cardUse.from
		log.arg = "LuaChiMing"
		log.arg2 = "collateral"
		log.to:append(killer)
		room:sendLog(log)
		
		local log2 = sgs.LogMessage()
		log2.type = "#CollInfo"
		log2.from = killer
		log2.to:append(victim)
		room:sendLog(log2)
	end,
}

LuaExtraCollateralCardVS = sgs.CreateZeroCardViewAsSkill{
	name = "LuaChiMing",
	response_pattern = "@@LuaChiMing",
	view_as = function()
		return LuaExtraCollateralCard:clone()
	end,
}
	
LuaChiMing = sgs.CreateTriggerSkill{
	name = "LuaChiMing" ,
	events = {sgs.CardUsed} ,
	view_as_skill = LuaExtraCollateralCardVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		local togami = room:findPlayerBySkillName(self:objectName())
		if (not togami) or (not togami:isAlive()) then
			return false
		end
		if player:objectName() == togami:objectName() then
			return false
		end
		if togami:isNude() then
			return false
		end
		if use.card:isNDTrick() then
			if sgs.Sanguosha:getCurrentCardUseReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then 
				return false 
			end
			if use.card:isKindOf("AOE") or use.card:isKindOf("GlobalEffect") then
				return false
			end
			--检测合法目标
			local available_targets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if (use.to:contains(p) or room:isProhibited(player, p, use.card)) then 
					continue 
				end
				if (use.card:targetFilter(sgs.PlayerList(), p, player)) then
					available_targets:append(p)
				end
			end
			if available_targets:isEmpty() then
				return false
			end
			--选择目标
			local user = sgs.QVariant()
			user:setValue(player)
			if room:askForCard(togami, ".."..string.upper(string.sub(use.card:getSuitString(), 1, 1)), "@ChiMingAdd:::".. use.card:objectName() , sgs.QVariant(), self:objectName()) then
				local extra = nil
				if not use.card:isKindOf("Collateral") then
					extra = room:askForPlayerChosen(togami, available_targets,self:objectName(),"@ChiMingChoose")
				
					--指示线
					room:doAnimate(1, use.from:objectName(), extra:objectName())
					--发送信息
					local log = sgs.LogMessage()
					log.type = "#ChiMingAddLog"
					log.from = togami
					log.arg = self:objectName()
					log.arg2 = use.card:objectName()
					log.to:append(extra)
					room:sendLog(log)
				else
					--借刀杀人情况
					local tos = {}
					for _, t in sgs.qlist(use.to) do
						table.insert(tos, t:objectName())
					end
					room:setPlayerProperty(togami, "extra_collateral", sgs.QVariant(use.card:toString()))
					room:setPlayerProperty(togami, "extra_collateral_user", sgs.QVariant(use.from:objectName()))
					room:setPlayerProperty(togami, "extra_collateral_current_targets", sgs.QVariant(table.concat(tos, "+")))
					room:askForUseCard(togami, "@@LuaChiMing", "@ChiMingChoose")
					room:setPlayerProperty(togami, "extra_collateral", sgs.QVariant(""))
					room:setPlayerProperty(togami, "extra_collateral_user", sgs.QVariant(""))
					room:setPlayerProperty(togami, "extra_collateral_current_targets", sgs.QVariant("+"))
					--选择完目标的情况
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						if p:hasFlag("ExtraCollateralTarget") then
							p:setFlags("-ExtraCollateralTarget")
							extra = p
							break
						end
					end	
				end	
				use.to:append(extra)
				room:sortByActionOrder(use.to)
				data:setValue(use)
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
}

TogamiByakuya:addSkill(LuaCaiFa)
TogamiByakuya:addSkill(LuaChiMing)
TogamiByakuya:addSkill("LuaMirai")
TogamiByakuya:addSkill("#LuaMiraiTrigger")

sgs.LoadTranslationTable{	
	["TogamiByakuya"]="十神白夜",
	["&TogamiByakuya"]="十神",
	["#TogamiByakuya"]="超高校级的贵公子",
	["designer:TogamiByakuya"]="Smwlover",
	["illustrator:TogamiByakuya"]="Ruby",

	["LuaCaiFa"]="财阀",
	[":LuaCaiFa"]="出牌阶段，你可以进行一次判定，你可以（合理地）使用（或重铸）此判定牌，若你没有如此做，本回合你无法再次发动“财阀”。",
	["LuaChiMing"]="叱命",
	[":LuaChiMing"]="一名其他角色使用的非延时锦囊牌指定目标时，你可以弃置一张与该牌同花色的牌，然后为该牌额外指定一名合理的角色为目标（有距离限制）。",
	
	["caifa"]="财阀",
	["@LuaCaiFa"]="你可以使用此【%arg】",
	["LuaCaiFa:use"]="你可以使用此【%arg】",
	["~LuaCaiFa"]="若需要选择目标，则选择合理的目标→点“确定”",
	["#CaiFaFail"]="%from 无法合理使用此【%arg】，本回合不能再发动“%arg2”",
	["@ChiMingAdd"]="你可以弃置一张牌为此【%arg】额外指定一名角色为目标",
	["@ChiMingChoose"]="请选择额外目标",
	["#ChiMingAddLog"]="%from 发动技能 %arg 额外指定 %to 为【%arg2】的目标",
	["#CollInfo"]="%from 被指定对 %to 使用【杀】",
	["~LuaChiMing"]="选择【借刀杀人】的额外目标→选择令其使用【杀】的目标→点“确定”",
}

--Enoshima Junko Copy
EnoshimaCopy=sgs.General(extension,"EnoshimaCopy","dgrp","3",false, true, true)

--Enoshima Junko
EnoshimaJunko=sgs.General(extension,"EnoshimaJunko","dgrp","4",false)

--QinRan
QinRanCard=sgs.CreateSkillCard{
	name="QinRanCard",
	target_fixed=false,
	will_throw=true,
	filter=function(self,targets,to_select)
		if #targets > 0 then
			return false
		end
		local player = sgs.Self
		return player:inMyAttackRange(to_select)
	end,
	feasible = function(self, targets)
		return #targets == 1
	end,
	on_effect=function(self,effect)
		local source=effect.from
		local dest=effect.to
		local room=source:getRoom()
		--技能触发效果
		room:notifySkillInvoked(source, "LuaQinRan")
		room:broadcastSkillInvoke("LuaQinRan")
		
		dest:drawCards(1)
		room:loseHp(dest,1)
		if dest and dest:isAlive() then	
			--发送信息
			local msg = sgs.LogMessage()
			msg.type = "#QinRanSlash"
			msg.from = dest
			room:sendLog(msg)
			
			room:askForUseCard(dest, "slash", "@qinranSlash", -1, sgs.Card_MethodUse, false)
		end
	end,
}

LuaQinRan=sgs.CreateViewAsSkill{
	name="LuaQinRan",
	n=0,
	view_as=function(self,cards)
		local card=QinRanCard:clone()
		return card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#QinRanCard")
	end
}

--ShiZhong
LuaShiZhong = sgs.CreateTriggerSkill{
	name = "LuaShiZhong",
	events = {sgs.Damage},
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local room = player:getRoom()
		if damage.card and damage.card:isKindOf("Slash") and (not damage.chain) and (not damage.transfer) then
			--检测场上拥有技能“势众”的其他角色数量
			local num = 0
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do 
				if p:hasSkill(self:objectName()) then
					num = num + 1
				end
			end
			if num == 0 then
				return false
			end
			if player:askForSkillInvoke(self:objectName(),sgs.QVariant("draw:::"..tostring(num))) then
				--每个拥有技能“势众”的角色摸num张牌
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:isAlive() and p:hasSkill(self:objectName()) then
						p:drawCards(num)
					end
				end
			end
		end
		return false
	end,
}

--TongHua
LuaTongHua = sgs.CreateTriggerSkill{
	name = "LuaTongHua" ,
	events = {sgs.BuryVictim},  --BuryVictim时机在一名角色的死亡结算中触发一次，player是该角色
	priority = -2 ,
	view_as_skill = TongHuaVS ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local death = data:toDeath()
		local enoshima = room:findPlayerBySkillName(self:objectName())
		if (not enoshima) or (not enoshima:isAlive()) or (enoshima:getMaxHp() <= 1) then
			return false
		end --体力上限为1不能发动此技能
		if death.damage and death.damage.from and death.damage.from:isAlive() then
			return false
		end
		if death.who:getGeneralName() == "EnoshimaCopy" or death.who:getGeneral2Name() == "EnoshimaCopy" then
			return false
		end
		--不能和七海的“程式”冲突
		if death.who:getGeneralName() == "NanamiChiaki" or death.who:getGeneral2Name() == "NanamiChiaki" then
			local str = room:getTag("ChengShiCounter"):toString()
			if str ~= "" then
				return false
			end
		end
		--询问是否发动“同化”
		local victimData = sgs.QVariant()
		victimData:setValue(death.who)
		if room:askForSkillInvoke(enoshima,self:objectName(),victimData) then
			--减少体力上限
			room:loseMaxHp(enoshima)
			--指示线
			local who = death.who
			room:doAnimate(1, enoshima:objectName(), who:objectName())
			--动画效果
			if enoshima:getGeneralName() == "EnoshimaJunko" or enoshima:getGeneral2Name() == "EnoshimaJunko" then
				room:doLightbox("TongHua$", 2500)
			elseif enoshima:getGeneralName() == "zuoci" or enoshima:getGeneral2Name() == "zuoci" then
				room:doLightbox("TongHuaZuoCi$", 2500)
			end
			--发送信息
			local msg = sgs.LogMessage()
			msg.type = "#TongHuaChange"
			msg.from = who
			room:sendLog(msg)
			
			--重新加入游戏
			room:changeHero(who, "EnoshimaCopy", false, false, false, true) --如果是双将则令其主将变为江之岛
			local maxhp = who:getMaxHp()
			room:revivePlayer(who)
			room:setPlayerProperty(who, "hp", sgs.QVariant(maxhp))
			room:setPlayerProperty(who, "kingdom", sgs.QVariant("dgrp"))
			local role = enoshima:getRole()
			if role == "lord" then
				who:setRole("loyalist")
				room:setPlayerProperty(who, "role", sgs.QVariant("loyalist"))
			elseif role == "loyalist" then
				who:setRole("loyalist")
				room:setPlayerProperty(who, "role", sgs.QVariant("loyalist"))
			elseif role == "rebel" then
				who:setRole("rebel")
				room:setPlayerProperty(who, "role", sgs.QVariant("rebel"))
			elseif role == "renegade" then
				who:setRole("renegade")
				room:setPlayerProperty(who, "role", sgs.QVariant("renegade"))
			end --改变阵营
			who:drawCards(maxhp)
			
			room:resetAI(who)
			room:updateStateItem()
			room:setTag("SkipGameRule",sgs.QVariant(true))  --跳过死亡结算
			
			--保存一个表，存储被江之岛更改过身份的所有角色的集合
			local copies = room:getTag("copies"):toString()
			local copyTable
			if copies == "" then
				copyTable = {}
				table.insert(copyTable, enoshima:objectName())
				table.insert(copyTable, who:objectName())
			else
				copyTable = copies:split("+")
				table.insert(copyTable, who:objectName())
			end
			room:setTag("copies", sgs.QVariant(table.concat(copyTable, "+")))
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end,
}

LuaTongHuaWin = sgs.CreateTriggerSkill{
	name = "#LuaTongHuaWin" ,
	events = {sgs.BeforeGameOverJudge} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local copyTable = room:getTag("copies"):toString():split("+")
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if table.contains(copyTable, p:objectName()) then
				if p:getRole() ~= "renegade" then
					return false
				end
			else
				return false
			end
		end
		room:gameOver(room:getTag("copies"):toString())
		return false
	end,
	can_trigger = function(self, target)
		return target
	end,
}

EnoshimaJunko:addSkill(LuaShiZhong)
EnoshimaJunko:addSkill(LuaQinRan)
EnoshimaJunko:addSkill(LuaTongHua)
EnoshimaJunko:addSkill(LuaTongHuaWin)
extension:insertRelatedSkills("LuaTongHua","#LuaTongHuaWin")
EnoshimaCopy:addSkill(LuaShiZhong)
EnoshimaCopy:addSkill(LuaQinRan)

sgs.LoadTranslationTable{	
	["EnoshimaJunko"]="江之岛盾子",
	["&EnoshimaJunko"]="江之岛",
	["#EnoshimaJunko"]="超高校级的绝望",
	["designer:EnoshimaJunko"]="Smwlover",
	["illustrator:EnoshimaJunko"]="Ruby",
	
	["EnoshimaCopy"]="江之岛复制品",
	["&EnoshimaCopy"]="江之岛",
	
	["LuaShiZhong"]="势众",
	[":LuaShiZhong"]="你使用【杀】对目标角色造成伤害后，可以令所有拥有技能“势众”的角色依次摸X张牌（X为拥有技能“势众”的其他角色数量）。",
	["LuaShiZhong:draw"]="你可以令所有拥有技能“势众”的角色依次摸 %arg 张牌",
	["LuaQinRan"]="侵染",
	[":LuaQinRan"]="<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以令你攻击范围内的一名角色摸一张牌并失去1点体力，然后该角色可以使用一张【杀】。",
	["LuaTongHua"]="同化",
	[":LuaTongHua"]="<font color=\"brown\"><b>重整技，</b></font>一名不是“江之岛盾子”的角色死亡后，若场上不存在凶手，你可以减少1点体力上限，令该角色使用一张“DGRP-021 江之岛盾子”的武将牌重新加入游戏，并将阵营调整为与你相同。<br /><br />◆重新加入游戏时，其体力值与手牌数均等于体力上限。<br />◆若你的体力上限为1，你无法发动此技能。<br />◆若七海千秋先发动了“程式”，你无法发动此技能。",

	["qinran"]="侵染",
	["luatonghua"]="同化",
	["#QinRanSlash"]="%from 可以使用一张【杀】",
	["@qinranSlash"]="你可以使用一张【杀】",
	["#TongHuaChange"]="%from 的阵营变为与江之岛盾子相同",
	["TongHua$"]="image=image/animate/tonghua.png",
	["TongHuaZuoCi$"]="image=image/animate/tonghuazuoci.png",
}