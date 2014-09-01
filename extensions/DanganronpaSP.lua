module("extensions.DanganronpaSP",package.seeall)
extension=sgs.Package("DanganronpaSP");

sgs.LoadTranslationTable{
	["DanganronpaSP"]="弹丸论破SP",
}

--Souda Kazuichi (SP)
SoudaKazuichiSP=sgs.General(extension,"SoudaKazuichiSP","dgrp","4",true)

--JiGong
LuaJiGongAcquire = sgs.CreateTriggerSkill{
	name = "#LuaJiGongAcquire",
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local move = data:toMoveOneTime()
		local souda = room:findPlayerBySkillName(self:objectName())
		if (not souda) or (not souda:isAlive()) then
			return false 
		end
		if (souda:getPhase() ~= sgs.Player_NotActive) then 
			return false
		end
		if move.from ~= nil then 
			if (move.from:objectName() == souda:objectName()) then
				return false
			end
		end
		if (move.to_place == sgs.Player_DiscardPile) then --到弃牌堆
			local card_ids = sgs.IntList()
        	for _, card_id in sgs.qlist(move.card_ids) do
            	if (sgs.Sanguosha:getCard(card_id):getTypeId() == sgs.Card_TypeEquip) then
					card_ids:append(card_id)
				end
			end
			if card_ids:isEmpty() then
				return false
			elseif souda:askForSkillInvoke("LuaJiGong",sgs.QVariant("obtain")) then
				for _, id in sgs.qlist(card_ids) do
					if move.card_ids:contains(id) then
						move.from_places:removeAt(move.card_ids:indexOf(id))
						move.card_ids:removeOne(id)
						data:setValue(move)
					end
					room:moveCardTo(sgs.Sanguosha:getCard(id), souda, sgs.Player_PlaceHand, move.reason, true)
					if not souda:isAlive() then 
						break 
					end 
				end
			end
		end
		return false
	end,
}

JiGongCard = sgs.CreateSkillCard{
	name = "JiGongCard",
	will_throw = false,
	target_fixed = true,
	on_use = function(self, room, source, targets)
		--技能发动特效
		room:notifySkillInvoked(source,"LuaJiGong")
		room:broadcastSkillInvoke("LuaJiGong")
		--发送信息
		local msg = sgs.LogMessage()
		msg.type = "$JiGongRecast"
		msg.from = source
		msg.card_str = tostring(self:getEffectiveId())
		room:sendLog(msg)
	
		local reason = sgs.CardMoveReason()
		reason.m_reason = sgs.CardMoveReason_S_REASON_RECAST
		reason.m_skillName = "LuaJiGong"
		reason.m_playerId = source:objectName()
		room:moveCardTo(self,nil,sgs.Player_DiscardPile,reason,true)
		source:drawCards(1)
	end,
}

LuaJiGong = sgs.CreateViewAsSkill{
	name = "LuaJiGong",
	n = 1,
	view_filter=function(self,selected,to_select)
		return to_select:getTypeId() == sgs.Card_TypeEquip
	end,
	view_as=function(self,cards)
		if #cards == 0 then
			return nil
		end
		local card=JiGongCard:clone()
		for _,c in ipairs(cards) do
			card:addSubcard(c)
		end
		return card
	end,
}

SoudaKazuichiSP:addSkill(LuaJiGongAcquire)
SoudaKazuichiSP:addSkill(LuaJiGong)
extension:insertRelatedSkills("LuaJiGong","#LuaJiGongAcquire")

sgs.LoadTranslationTable{	
	["SoudaKazuichiSP"]="SP左右田和一",
	["&SoudaKazuichiSP"]="左右田",
	["#SoudaKazuichiSP"]="超高校级的机械师",
	["designer:SoudaKazuichiSP"]="Smwlover",
	["illustrator:SoudaKazuichiSP"]="Pixiv Illust_id = 41140162",
	
	["LuaJiGong"]="技工",
	[":LuaJiGong"]="你可以重铸你的装备牌。你的回合外，当有牌进入弃牌堆时，若此牌不是你的牌，你可以获得其中的装备牌。",
	["LuaJiGong:obtain"]="你可以获得其中的装备牌",
	
	["jigong"]="技工",
	["$JiGongRecast"]="%from 重铸了一张卡牌 %card",
}

--Sonia Nevermind (SP)
SoniaNevermindSP=sgs.General(extension,"SoniaNevermindSP","dgrp","3",false)

--WangNvNew
LuaWangNvNew = sgs.CreateTriggerSkill{
	name = "LuaWangNvNew",
	events = {sgs.EventPhaseChanging, sgs.DrawNCards},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_Judge then
				if player:getJudgingArea():length() > 0 then
					--技能发动特效
					room:notifySkillInvoked(player,self:objectName())
					room:broadcastSkillInvoke(self:objectName())
					--发送信息
					local log = sgs.LogMessage()
					log.type = "#TriggerSkill"
					log.from = player
					log.arg = self:objectName()
					room:sendLog(log)
				end
				player:skip(sgs.Player_Judge) --跳过判定阶段
			end
		elseif event == sgs.DrawNCards then
			if player:getJudgingArea():length() > 0 then
				--技能发动特效
				room:notifySkillInvoked(player,self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				--发送信息
				local log = sgs.LogMessage()
				log.type = "#TriggerSkill"
				log.from = player
				log.arg = self:objectName()
				room:sendLog(log)
			end
			local num = player:getJudgingArea():length()
			local count = data:toInt() + num
			data:setValue(count)
		end
		return false
	end,
}

--LuaTianRanNew
LuaTianRanNew = sgs.CreateTriggerSkill{
	name = "LuaTianRanNew" ,
	events = {sgs.Damaged, sgs.FinishJudge} ,
	frequency = sgs.Skill_Frequent ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damaged then
			--按点卖血
			local damage = data:toDamage()
			local num = damage.damage
			for i = 1,num,1 do
				if player:askForSkillInvoke(self:objectName()) then
					local judge = sgs.JudgeStruct()
					judge.pattern = ".|diamond"
					judge.good = true
					judge.reason = self:objectName()
					judge.who = player
					judge.play_animation = true
					room:judge(judge)
				end
			end
		elseif event == sgs.FinishJudge then
			local judge = data:toJudge()
			if judge.reason == self:objectName() then
				local choice
				local card = judge.card
				if judge:isGood() then
					--场上是否有人可以成为【乐不思蜀】的目标？
					local trick = sgs.Sanguosha:cloneCard("indulgence", card:getSuit(), card:getNumber())
					trick:setSkillName(self:objectName())
					trick:addSubcard(card)
					local targets = sgs.SPlayerList()
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						if not p:containsTrick("indulgence") and not player:isProhibited(p, trick) then
							targets:append(p)
						end
					end
					--选择合适的目标
					if not targets:isEmpty() then
						target = room:askForPlayerChosen(player, targets, self:objectName(), "LuaTianRanTarget", true, true)
					end
					if target then
						local use = sgs.CardUseStruct()
						use.from = player
						use.to:append(target)
						use.card = trick
						room:useCard(use, true)
					else
						player:obtainCard(card)
					end
				else
					player:obtainCard(card)
				end
			end
		end
		return false
	end,
}

SoniaNevermindSP:addSkill(LuaTianRanNew)
SoniaNevermindSP:addSkill(LuaWangNvNew)

sgs.LoadTranslationTable{	
	["SoniaNevermindSP"]="SP索尼娅",
	["&SoniaNevermindSP"]="索尼娅",
	["#SoniaNevermindSP"]="超高校级的王女",
	["designer:SoniaNevermindSP"]="Smwlover",
	["illustrator:SoniaNevermindSP"]="Pixiv Illust_id = 38530341",
	
	["LuaWangNvNew"]="王女",
	[":LuaWangNvNew"]="<font color=\"blue\"><b>锁定技，</b></font>你永远跳过你的判定阶段。摸牌阶段，你额外摸X张牌（X为你判定区牌的数量）。",
	["LuaTianRanNew"]="天然",
	[":LuaTianRanNew"]="你每受到1点伤害，可以进行一次判定。若判定结果为方片，你可以将该牌当作【乐不思蜀】置于任意一名角色的判定区。无论判定结果如何，你都可以获得该判定牌。",
	["LuaTianRanTarget"]="请选择一名角色作为“天然”的目标或点“取消”获得该判定牌",
}