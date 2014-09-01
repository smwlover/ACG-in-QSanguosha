--DGRP-03 小泉真昼
--排忧: 结束阶段开始时，你可以弃置一张红色牌，令一名角色回复1点体力。
--定格: 一名角色回复体力时，你可以令其摸一张牌。若该角色装备区没有装备牌，改为令其摸两张牌。

--PaiYou
function SmartAI:getWoundedFriend_for_Koizumi()
	self:sort(self.friends, "hp")
	local list1 = {}  -- need help
	local list2 = {}  -- do not need help
	local addToList = function(p, index)
		if p:isWounded() then
			table.insert(index == 1 and list1 or list2, p)
		end
	end

	local getCmpHp = function(p)
		local hp = p:getHp()
		if p:isLord() and self:isWeak(p) then hp = hp - 10 end
		if p:objectName() == self.player:objectName() and self:isWeak(p) and p:hasSkill("qingnang") then hp = hp - 5 end
		if p:hasSkill("buqu") and p:getPile("buqu"):length() > 0 then hp = hp + math.max(0, 5 - p:getPile("buqu"):length()) end
		if p:hasSkill("nosbuqu") and p:getPile("nosbuqu"):length() > 0 then hp = hp + math.max(0, 5 - p:getPile("nosbuqu"):length()) end
		if p:hasSkills("nosrende|rende|kuanggu|kofkuanggu|zaiqi") and p:getHp() >= 2 then hp = hp + 5 end
		
		--考虑小泉的【定格】的影响，如果有【定格】，则在选择目标时也要考虑目标是否没有装备
		if self.player:hasSkill("LuaDingGe") then
			if p:getEquips():isEmpty() then
				hp = hp - 1
			end
		end
		return hp
	end

	local cmp = function (a, b)
		if getCmpHp(a) == getCmpHp(b) then
			return sgs.getDefenseSlash(a, self) < sgs.getDefenseSlash(b, self)
		else
			return getCmpHp(a) < getCmpHp(b)
		end
	end

	for _, friend in ipairs(self.friends) do
		if friend:isLord() then
			if friend:getMark("hunzi") == 0 and friend:hasSkill("hunzi")
				and self:getEnemyNumBySeat(self.player, friend) <= (friend:getHp() >= 2 and 1 or 0) then
				addToList(friend, 2)
			elseif friend:getHp() >= getBestHp(friend) then
				addToList(friend, 2)
			elseif not sgs.isLordHealthy() then
				addToList(friend, 1)
			end
		else
			addToList(friend, friend:getHp() >= getBestHp(friend) and 2 or 1)
		end
	end
	table.sort(list1, cmp)
	table.sort(list2, cmp)
	return list1, list2
end

sgs.ai_skill_use["@@LuaPaiYou"] = function(self, prompt)
	--小泉真昼的所有牌
	local total = self.player:getHandcardNum() + self.player:getEquips():length()
	--寻找需要帮助的队友
	local arr1, arr2 = self:getWoundedFriend_for_Koizumi()
	local target = nil
	if #arr1 > 0 and (self:isWeak(arr1[1]) or total >= 2) and arr1[1]:getHp() < getBestHp(arr1[1]) then 
		target = arr1[1] 
	end
	if target then
		--寻找需要弃置的牌
		local cards = self.player:getCards("he")
		local cardTable = sgs.QList2Table(cards)
		
		--对卡牌的价值进行排序
		local aux_func = function(card)
			local place = self.room:getCardPlace(card:getEffectiveId())
			if place == sgs.Player_PlaceEquip then
				if card:isKindOf("SilverLion") and self.player:isWounded() then return -2
				elseif card:isKindOf("Weapon") and self.player:getHandcardNum() < 3 and not self:needKongcheng() then return 0
				elseif card:isKindOf("OffensiveHorse") and self.player:getHandcardNum() < 3 and not self:needKongcheng() then return 0
				elseif card:isKindOf("OffensiveHorse") then return 1
				elseif card:isKindOf("Weapon") then return 2
				elseif card:isKindOf("DefensiveHorse") then return 3
				elseif self.player:hasSkills("bazhen|yizhong") and card:isKindOf("Armor") then return 0
				elseif card:isKindOf("Armor") then return 4
				end
			elseif self.player:hasSkills(sgs.lose_equip_skill) then return 5
			else return 0
			end
		end
		local compare_func = function(a, b)
			if aux_func(a) ~= aux_func(b) then return aux_func(a) < aux_func(b) end
			return self:getKeepValue(a) < self:getKeepValue(b)
		end
		table.sort(cardTable, compare_func)
		
		--选择最需要扔掉的卡牌（考虑了如果有失去装备的技能，优先扔掉装备）
		for _, card in ipairs(cardTable) do
			if card:isRed() and (not card:isKindOf("Peach")) then
				return "#LuaPaiYou:" .. card:getId() .. ":->" .. target:objectName()
			end
		end
	end
	return "."
end

sgs.ai_card_intention.LuaPaiYou = -80
sgs.dynamic_value.benefit.LuaPaiYou = true

--DingGe
sgs.ai_skill_invoke.LuaDingGe = function(self, data)
	local target = data:toPlayer()
	if self:isFriend(target) then
		if not self:needKongcheng(target, true) then
			sgs.updateIntention(self.player, target, -80) --更新仇恨值
			return true
		end
	end
	return false
end

sgs.ai_chaofeng.KoizumiMahiru = 5

--DGRP-05 西园寺日寄子
--扇舞: 出牌阶段限一次，你可以弃置任意数量的装备牌，然后令等量的角色依次回复1点体力。若你以此法令三名或以上的角色回复体力，你须将武将牌翻面。
--毒舌: 每当你受到伤害后，你可以选择一项：将伤害来源装备区中的一张装备牌移动到你装备区中的相应位置，或者摸一张牌。

--DuShe
function canObtain(source, victim, number)
	return source:getEquip(number) and (not victim:getEquip(number))
end

sgs.ai_skill_choice["LuaDuShe"] = function(self,choices,data)
	local choiceTable = choices:split("+")
	if not table.contains(choiceTable, "DuSheMove") then
		return (self:needKongcheng() and "nothing") or "DuSheDraw"
	else
		local damage = data:toDamage()
		local source = damage.from
		local victim = damage.to
		local room = self.room
		if self:isFriend(source) then
			if canObtain(source, victim, 1) and self:needToThrowArmor(source) and (not self.player:hasSkill("bazhen|yizhong")) then --白银狮子
				room:setPlayerProperty(victim, "DuSheMoveID", sgs.QVariant(source:getEquip(1):getEffectiveId()))
				return "DuSheMove"
			end
			if source:hasSkills(sgs.lose_equip_skill) then --孙尚香、凌统
				if canObtain(source, victim, 0) then
					room:setPlayerProperty(victim, "DuSheMoveID", sgs.QVariant(source:getEquip(0):getEffectiveId()))
					return "DuSheMove"
				elseif canObtain(source, victim, 3) then
					room:setPlayerProperty(victim, "DuSheMoveID", sgs.QVariant(source:getEquip(3):getEffectiveId()))
					return "DuSheMove"
				elseif not self:isWeak(source) then
					if canObtain(source, victim, 2) then
						room:setPlayerProperty(victim, "DuSheMoveID", sgs.QVariant(source:getEquip(2):getEffectiveId()))
						return "DuSheMove"
					elseif canObtain(source, victim, 1) and (not self.player:hasSkill("bazhen|yizhong")) then
						room:setPlayerProperty(victim, "DuSheMoveID", sgs.QVariant(source:getEquip(1):getEffectiveId()))
						return "DuSheMove"
					end
				end
			end
			return (self:needKongcheng() and "nothing") or "DuSheDraw"
		else
			if not source:hasSkills(sgs.lose_equip_skill) then
				if canObtain(source, victim, 1) and (not self:needToThrowArmor(source)) and (not self.player:hasSkill("bazhen|yizhong")) then
					room:setPlayerProperty(victim, "DuSheMoveID", sgs.QVariant(source:getEquip(1):getEffectiveId()))
					return "DuSheMove"
				elseif canObtain(source, victim, 2) then
					room:setPlayerProperty(victim, "DuSheMoveID", sgs.QVariant(source:getEquip(2):getEffectiveId()))
					return "DuSheMove"
				elseif canObtain(source, victim, 3) then
					room:setPlayerProperty(victim, "DuSheMoveID", sgs.QVariant(source:getEquip(3):getEffectiveId()))
					return "DuSheMove"
				elseif canObtain(source, victim, 0) then
					room:setPlayerProperty(victim, "DuSheMoveID", sgs.QVariant(source:getEquip(0):getEffectiveId()))
					return "DuSheMove"
				end
			end
			return (self:needKongcheng() and "nothing") or "DuSheDraw"
		end
	end
end

sgs.ai_skill_cardchosen["LuaDuShe"] = function(self,who,flags)
	local idStr = self.player:property("DuSheMoveID"):toString()
	local id = tonumber(idStr)
	local card = sgs.Sanguosha:getCard(id)
	return card
end

sgs.ai_chaofeng.SaionjiHiyoko = -1

--DGRP-06 澪田唯吹
--颜艺: 出牌阶段开始时，你可以展示一张非延时锦囊牌。若如此做，本阶段限一次，你可以将一张与该牌同颜色的牌当该牌使用。
--散漫: 每当你于回合外因弃置而失去红色牌时，你可以摸两张牌。
--轻音: 限定技，摸牌阶段，你可以放弃摸牌并展示任意数量的花色各不相同的手牌，然后所有其他角色需依次选择一项：展示一张与你所展示的牌花色均不同的手牌，或者令你摸一张牌。

--QingYin
sgs.ai_skill_cardask["@qingyinShow"] = function(self, data, pattern, target, target2)
	local patternStr = data:toString()
	local room = self.room
	local mioda = room:getTag("qingyinInvoking"):toPlayer()
	if (not mioda) or (not patternStr) or (pattenStr == "") then
		return "."
	else
		if self:isFriend(mioda) then
			return "."
		else
			local patternTable = patternStr:split(",")
			local cards = self.player:getCards("h")
			for _,card in sgs.qlist(cards) do
				if table.contains(patternTable, card:getSuitString()) then
					sgs.updateIntention(self.player, mioda, 30) --更新仇恨值
					return card:toString()
				end
			end
		end
	end
	return "."
end

sgs.ai_chaofeng.MiodaIbuki = 1

--DGRP-10 狛枝凪斗
--幸运: 你进行判定时，可以观看牌堆顶的X张牌（X为你已损失的体力值+1），将其中一张作为判定牌，将其余的牌置入弃牌堆。
--入神: 结束阶段开始时，你可以进行一次判定，若判定结果为红桃，你摸三张牌；否则你需弃置一张牌。
--执念: 一名其他角色使用【杀】指定目标时，若其手牌数大于你且你不是此【杀】的目标，你可以令其交给你一张手牌，然后你成为此【杀】的额外目标；你使用【杀】指定目标时，可以交给一名手牌数小于你且不是此【杀】目标的其他角色一张手牌，然后该角色成为此【杀】额外的目标。

--RuShen
sgs.ai_skill_invoke.LuaRuShen = function(self, data)
	if self:isWeak() and self:hasWizard(self.enemies, true) and (not self:isKongcheng()) then
		return false
	end
	return true
end

--XingYun
sgs.ai_skill_askforag.LuaXingYun = function(self, card_ids)
	local judge = self.player:getTag("xingyunJudge"):toJudge()
	for _, id in ipairs(card_ids) do
		local card = sgs.Sanguosha:getCard(id)
		local card_x = sgs.Sanguosha:getEngineCard(card:getEffectiveId())
		--红颜的影响
		if self.player:hasSkill("hongyan") and card_x:getSuit() == sgs.Card_Spade then
			card_x = sgs.Sanguosha:cloneCard(card_x:objectName(), sgs.Card_Heart, card:getNumber())
		end
		--判断该牌是否符合判定的条件
		if judge:isGood(card_x) then
			return id
		end
	end
	return card_ids[1]
end

sgs.ai_chaofeng.KomaedaNagito = 1

--DGRP-11 七海千秋
--未来: 锁定技，你的手牌上限+X（X为拥有技能“未来”的其他存活角色数量）。
--体恤: 一名角色受到伤害后，你可以弃置一张牌（该牌的点数需不小于造成伤害的牌），令该角色摸两张牌。
--程式: 重整技，你死亡时，可以获得8枚“时间”标记；一名角色的回合结束时，弃掉1枚“时间”标记；最后1枚“时间”标记被弃掉时，你使用“七海千秋”的武将牌重新加入游戏（身份不变）。

--TiXu
sgs.ai_skill_cardask["@TiXuDiscard"] = function(self, data)
	local damage = data:toDamage()
	local target = damage.to
	local damageCard = damage.card
	if not self:isFriend(target) then
		return "."
	end
	if self:needKongcheng(target, true) then
		return "."
	end
	
	--检查七海手牌数是否充足
	local invoke = false
	local total = self.player:getHandcardNum() + self.player:getEquips():length()
	if total > 1 then
		invoke = true
	elseif total == 1 and self:isWeak(target) then
		invoke = true
	end
	if invoke then
		local cards = self.player:getCards("he")
		local cardTable = sgs.QList2Table(cards)
		
		--对卡牌的价值进行排序
		local aux_func = function(card)
			local place = self.room:getCardPlace(card:getEffectiveId())
			if place == sgs.Player_PlaceEquip then
				if card:isKindOf("SilverLion") and self.player:isWounded() then return -2
				elseif card:isKindOf("Weapon") and self.player:getHandcardNum() < 3 and not self:needKongcheng() then return 0
				elseif card:isKindOf("OffensiveHorse") and self.player:getHandcardNum() < 3 and not self:needKongcheng() then return 0
				elseif card:isKindOf("OffensiveHorse") then return 1
				elseif card:isKindOf("Weapon") then return 2
				elseif card:isKindOf("DefensiveHorse") then return 3
				elseif self.player:hasSkills("bazhen|yizhong") and card:isKindOf("Armor") then return 0
				elseif card:isKindOf("Armor") then return 4
				end
			elseif self.player:hasSkills(sgs.lose_equip_skill) then return 5
			else return 0
			end
		end
		local compare_func = function(a, b)
			if aux_func(a) ~= aux_func(b) then return aux_func(a) < aux_func(b) end
			return (self:getKeepValue(a) + a:getNumber() * 0.2) < (self:getKeepValue(b) + b:getNumber() * 0.2)
		end --点数较大的牌比较值得保留
		table.sort(cardTable, compare_func)
		
		--选择最需要扔掉的卡牌（考虑了如果有失去装备的技能，优先扔掉装备）
		for _, card in ipairs(cardTable) do
			if card:getNumber() >= damageCard:getNumber() then
				if not card:isKindOf("Peach") then
					sgs.updateIntention(self.player, target, -80) --更新仇恨值
					return "$" .. card:getEffectiveId()
				end
			end
		end
	end
	return "."
end

function sgs.ai_cardneed.LuaTiXu(to, card, self)
	if self:getUseValue(card) < 6 then
		local total = to:getHandcardNum() + to:getEquips():length()
		return total <= 2 and card:getNumber() > 9
	end
end --在七海缺牌时，其他角色可以给七海一些点数大的牌

--ChengShi
sgs.ai_skill_invoke.LuaChengShi = true
sgs.ai_chaofeng.NanamiChiaki = 2

--DGRP-14 索尼娅内瓦曼德
--天然: 你受到一名角色使用【杀】造成的伤害后，可以令该角色摸2张牌，然后你回复1点体力。
--王女: 摸牌阶段，你可以将摸牌的数量调整为X（X为与你距离为1以内的角色数量）。

--WangNv
sgs.ai_skill_invoke.LuaWangNv = function(self, data)
	local room = self.room
	local player = self.player
	--检查与索尼娅距离为1的角色数
	local num = 0
	for _, p in sgs.qlist(room:getAlivePlayers()) do
		if p:distanceTo(player) <= 1 then
			num = num + 1
		end
	end
	return num > 2
end

sgs.ai_chaofeng.SoniaNevermind = 1

--DGRP-16 终里赤音
--狂野: 摸牌阶段开始时，若你已受伤，你可以放弃摸牌并展示牌堆顶的X张牌（X为你已损失的体力值），弃置其中的非基本牌，然后获得其余的牌。每有一张非基本牌以此法被弃置，视为你对一名其他角色使用了一张【杀】。

--KuangYe
sgs.ai_skill_invoke.LuaKuangYe = function(self, data)
	local lostHp = self.player:getLostHp()
	if lostHp >= 3 then
		return true
	elseif lostHp <= 1 then
		return false
	else
		--如果自己缺手牌则不发动
		if self.player:getHandcardNum() == 0 then
			return false
		end
		--如果跳过了出牌阶段且手牌溢出则发动
		if self.player:isSkipped(sgs.Player_Play) and self.player:getHandcardNum() >= 2 then 
			return true 
		end
		--找到防御比较弱的敌人
		self:sort(self.enemies, "defenseSlash")
		for _, enemy in ipairs(self.enemies) do
			local def = sgs.getDefenseSlash(enemy, self)
			local slash = sgs.Sanguosha:cloneCard("slash")
			local eff = self:slashIsEffective(slash, enemy) and sgs.isGoodTarget(enemy, self.enemies, self)

			if self.player:canSlash(enemy, slash, false) and (not self:slashProhibit(nil, enemy)) and (def < 6) and eff then
				return true
			end
		end
	end
	return false
end

sgs.ai_skill_playerchosen.LuaKuangYe = function(self, targets)
	self:updatePlayers()
	local best_target, target = nil, nil
	local defense = 6
	for _, enemy in ipairs(self.enemies) do
		local def = sgs.getDefense(enemy)
		local slash = sgs.Sanguosha:cloneCard("slash")
		local eff = self:slashIsEffective(slash, enemy) and sgs.isGoodTarget(enemy, self.enemies, self)

		if not self.player:canSlash(enemy, slash, false) then
		elseif self:slashProhibit(nil, enemy) then
		elseif eff then
			if enemy:getHp() == 1 and getCardsNum("Jink", enemy, self.player) == 0 then
				best_target = enemy
				break
			end
			if def < defense then
				best_target = enemy
				defense = def
			end
			target = enemy
		end
	end
	--确定发动的目标
	if best_target then
		return best_target
	end
	if target then
		return target
	end
	--找不到合适的发动目标
	if #self.enemies > 0 then
		local randomNum = math.random(1, #self.enemies)
		return self.enemies[randomNum]
	end
	return nil
end

sgs.ai_playerchosen_intention.LuaKuangYe = 80
sgs.ai_chaofeng.OwariAkane = 1

--DGRP-18 雾切响子
--明察: 一名体力值大于你的角色的准备阶段开始时，你可以摸一张牌，然后将一张牌置于牌堆顶。
--坚韧: 每当你受到伤害后，你可以观看伤害来源的所有手牌，然后你可以将其中的一张红色牌交给除伤害来源外的一名角色。
--未来: 锁定技，你的手牌上限+X（X为拥有技能“未来”的其他存活角色数量）。

--JianRen
sgs.ai_skill_askforag.LuaJianRen = function(self, card_ids)
	if #card_ids == 0 then
		return -1
	else
		local target = self.player:property("jianrenTarget"):toPlayer()
		local room = self.room
		local player = self.player
		if not self:isFriend(target) then
			local ids = card_ids
			local cards = {}
			for _, id in ipairs(ids) do
				table.insert(cards, sgs.Sanguosha:getCard(id))
			end
			for _, card in ipairs(cards) do
				if card:isKindOf("Peach") then
					room:setPlayerProperty(player, "jianrenChoose", sgs.QVariant(card:getEffectiveId()))
					return card:getEffectiveId() 
				end
			end
			for _, card in ipairs(cards) do
				if card:isKindOf("Indulgence") and not (self:isWeak() and self:getCardsNum("Jink") == 0) then
					room:setPlayerProperty(player, "jianrenChoose", sgs.QVariant(card:getEffectiveId()))
					return card:getEffectiveId() 
				end
				if card:isKindOf("AOE") and not (self:isWeak() and self:getCardsNum("Jink") == 0) then
					room:setPlayerProperty(player, "jianrenChoose", sgs.QVariant(card:getEffectiveId()))
					return card:getEffectiveId()
				end
			end
			self:sortByUseValue(cards)
			room:setPlayerProperty(player, "jianrenChoose", sgs.QVariant(cards[1]:getEffectiveId()))
			return cards[1]:getEffectiveId()
		end
	end
	return -1
end

sgs.ai_skill_playerchosen.LuaJianRen = function(self, targets)
	local idStr = self.player:property("jianrenChoose"):toString()
	local id = tostring(idStr)
	local card = sgs.Sanguosha:getCard(id)
	local cards = { card }
	--寻找合适的队友
	local c, friend = self:getCardNeedPlayer(cards, self.friends)
	if friend then 
		return friend
	end
	self:sort(self.friends)
	for _, friend in ipairs(self.friends) do
		if self:isValuableCard(card, friend) and not hasManjuanEffect(friend) and not self:needKongcheng(friend, true) then return friend end
	end
	for _, friend in ipairs(self.friends) do
		if self:isWeak(friend) and not hasManjuanEffect(friend) and not self:needKongcheng(friend, true) then return friend end
	end
	local trash = card:isKindOf("Disaster") or card:isKindOf("GodSalvation") or card:isKindOf("AmazingGrace")
	if trash then --废牌可以破敌人的空城
		for _, enemy in ipairs(self.enemies) do
			if enemy:getPhase() > sgs.Player_Play and self:needKongcheng(enemy, true) and not hasManjuanEffect(enemy) then return enemy end
		end
	end
	for _, friend in ipairs(self.friends) do
		if not hasManjuanEffect(friend) and not self:needKongcheng(friend, true) then return friend end
	end
end

sgs.ai_playerchosen_intention.LuaJianRen = function(self, from, to)
	if not self:needKongcheng(to, true) and not hasManjuanEffect(to) then 
		sgs.updateIntention(from, to, -50) 
	end
end
sgs.ai_chaofeng.KirigiriKyouko = -1