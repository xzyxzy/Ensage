--<<Visage by qqzzxxcc>>
require("libs.Utils")
require("libs.TargetFind")
require("libs.ScriptConfig")
require("libs.HeroInfo")

config = ScriptConfig.new()
config:SetParameter("ComboKey", "D", config.TYPE_HOTKEY) 
config:Load()

local ComboKey     = config.ComboKey
local active	   = false 
local registered   = false 
local target    = nil             
local effect	= nil
local effectfam	= nil
local x,y = 1350, 50
local stuntimer = 0
local mpos		= nil
local movetimer = 0
local storagefam = nil
local monitor = client.screenSize.x/1600
local font = drawMgr:CreateFont("font","Verdana",12,300)
local statusText = drawMgr:CreateText(x*monitor,y*monitor,0x00F5F5FF,"Visage || Press " .. string.char(ComboKey) .. " ||",font) statusText.visible = false
tablefam = {}

function onLoad()
	if not PlayingGame() then return end
	if PlayingGame() then
		local me = entityList:GetMyHero()
		local mp = entityList:GetMyPlayer()
		if not me or me.classId ~= CDOTA_Unit_Hero_Visage then 
			script:Disable()
		else
			registered = true
			statusText.visible = true
			script:RegisterEvent(EVENT_TICK,Main)
			script:RegisterEvent(EVENT_KEY,Key)
			script:UnregisterEvent(onLoad)
		end
	end
end

function Key(msg,code)
	if client.chat or client.console or client.loading then return end
	if code == ComboKey then
		active = (msg == KEY_DOWN)
	end
end

function Main(tick)
local mp = entityList:GetMyPlayer()
local me = entityList:GetMyHero() 
if not me then return end	
if not SleepCheck then return end   
local Blink = me:FindItem("item_blink")
local Range = 600
local blink_range = 1200
local auto_attack = nil
local enemies = entityList:GetEntities({type=LuaEntity.TYPE_HERO,team = me:GetEnemyTeam(),alive=true,visible=true})
local sheep = me:FindItem("item_sheepstick")
local orchid = me:FindItem("item_orchid")
local veil = me:FindItem("item_veil_of_discord")
local solar = me:FindItem("item_solar_crest")
local medallion = me:FindItem("item_medallion_of_courage")
local soulring = me:FindItem("item_soul_ring")
local arcane = me:FindItem("item_arcane_boots")
local shiva = me:FindItem("item_shivas_guard")
local v = targetFind:GetClosestToMouse(100)
local ticktimer = GetTick()
local familiars = entityList:FindEntities({classId = CDOTA_Unit_VisageFamiliar, alive = true})
local shortest = 30000
local rangestun = 325
local name = entityList:GetMyHero().name
local apoint = ((heroInfo[name].attackPoint*100)/(1+me.attackSpeed))*1000
for b,n in ipairs(enemies) do
	if n and n.visible and n.alive == true and n.health > 0 then
		if n:IsChanneling() == true then
			enemyspell = n:GetChanneledAbility()
		else 
			selectedfam = nil
		end
		for g,h in ipairs(familiars) do
			local stone = h:FindModifier("modifier_visage_summon_familiars_stone_form_buff")
			if not tablefam[h.handle] then
				tablefam[h.handle] = {}
			end
			if not tablefam[h.handle].effectfam and h.alive == true and h.health > 0 then
				tablefam[h.handle].effectfam = Effect(h,"range_display")
				tablefam[h.handle].effectfam:SetVector(1,Vector(325,0,0))
			end
			if shortest > GetDistance2D(h,n) and h:GetAbility(1).cd == 0 and h.alive == true and h.health > 0 and not stone and (n:IsChanneling() == true and enemyspell and enemyspell ~= nil and enemyspell.channelTime ~= 0) then
				shortest = GetDistance2D(h,n)
				selectedfam = h 
			end
			if stone and h:GetAbility(1).cd > 24 then
				mp:SelectAdd(h)
			end
		end
	end
	if selectedfam ~= nil and selectedfam.alive == true and selectedfam.health > 0 and n and n.visible and n.alive == true and n.health > 0 and n:IsChanneling() == true then
		local totalrange = selectedfam.movespeed*0.5+rangestun
		local spell = selectedfam:GetAbility(1)
		local stone = selectedfam:FindModifier("modifier_visage_summon_familiars_stone_form_buff")
		if (enemyspell and enemyspell ~= nil and enemyspell.channelTime ~= 0) then
			if not stone and selectedfam.alive == true and selectedfam.health > 0 and GetDistance2D(selectedfam,n)-totalrange < (enemyspell:GetChannelTime(enemyspell.level)-enemyspell.channelTime-1.3)*selectedfam.movespeed and enemyspell.channelTime ~= 0 and selectedfam:GetAbility(1).cd < ((GetDistance2D(selectedfam,n)-totalrange)/selectedfam.movespeed) and ticktimer - movetimer > 200 and ticktimer - stuntimer > 200 then
				mp:Unselect(selectedfam)
				mpos = (n.position - selectedfam.position) * (GetDistance2D(selectedfam,n) - 320)	 / GetDistance2D(selectedfam,n) + selectedfam.position
				selectedfam:Move(mpos)
				movetimer = ticktimer
			end
			if stone and not selectedfam:GetAbility(1).cd == 0 and selectedfam.alive == true and selectedfam.health > 0 then
				mp:SelectAdd(selectedfam)
			end
			if not stone  and selectedfam.alive == true and selectedfam.health > 0 and GetDistance2D(selectedfam,n) < totalrange and not n:IsMagicImmune() and selectedfam:GetAbility(1).cd == 0 and enemyspell.channelTimeTotal-enemyspell.channelTime > 1.2 and enemyspell.channelTime ~= 0 and ticktimer - stuntimer > 150 then
				selectedfam:CastAbility(spell)
				mp:Unselect(selectedfam)
				mpos = (n.position - selectedfam.position) * (GetDistance2D(selectedfam,n) - 320) / GetDistance2D(selectedfam,n) + selectedfam.position
				if GetDistance2D(selectedfam,n) > 320 then
					selectedfam:Move(mpos)
				end
				stuntimer = ticktimer
				selectedfam = nil
			end
		end
	end
end
if active then
	if SleepCheck("blink") and SleepCheck("auto_attack") and SleepCheck("fam") then
		me:Move(client.mousePosition)
		if SleepCheck("fam") then
			for g,h in ipairs(familiars) do
				local modif = h:FindModifier("modifier_visage_summon_familiars_damage_charge")
				local spell = h:GetAbility(1)
				if not (spell.cd == 0 and GetDistance2D(h,v) < 325 and (modif and modif.stacks == 0)) then
					if not h.isAttacking and not (enemyspell and enemyspell ~= nil and enemyspell.channelTime ~= 0 and selectedfam == h) and h.alive == true and h.health > 0 and not (h.activity == LuaEntityNPC.ACTIVITY_CAST1 or h.activity == LuaEntityNPC.ACTIVITY_CAST2 or h.activity == LuaEntityNPC.ACTIVITY_CAST3 or h.activity == LuaEntityNPC.ACTIVITY_CAST4) then
					h:Move(client.mousePosition)
					Sleep((0.1)*1000,"fam")
					end
				end
			end
		end
		Sleep(150,"blink")
	end
	Sleep(50)
    if v and v.visible and v.alive == true and v.health > 0 then
        if SleepCheck("blink") and GetDistance2D(me,v) <= (blink_range + Range - 50) and GetDistance2D(me,v) > (Range + 220) and Blink and Blink:CanBeCasted() and me.alive == true and me.health > 0 then
			bpos = (v.position - me.position) * (GetDistance2D(me,v) - Range - 50) / GetDistance2D(me,v) + me.position
            if pcall(function () me:SafeCastItem(Blink.name,bpos) end) then end
			Sleep(me:GetTurnTime(v)+client.latency,"blink")
		elseif GetDistance2D(me,v) < (Range + 150) and SleepCheck("auto_attack") then
			if soulring and soulring:CanBeCasted() and (me.mana < me:GetAbility(2).manacost or me.mana < me:GetAbility(1).manacost) then
				me:SafeCastItem(soulring.name)
			end
			if arcane and arcane:CanBeCasted() and (me.mana < me:GetAbility(2).manacost or me.mana < me:GetAbility(1).manacost) then
				me:SafeCastItem(arcane.name)
			end
			if sheep and sheep:CanBeCasted() and not v:IsMagicImmune() and not v:IsLinkensProtected() then 
				me:SafeCastItem(sheep.name,v)
				Sleep(150)
			end
			if solar and solar:CanBeCasted() and not v:IsMagicImmune() then 
				me:SafeCastItem(solar.name,v)
				Sleep(150)
			end
			if medallion and medallion:CanBeCasted() and not v:IsMagicImmune() then 
				me:SafeCastItem(medallion.name,v)
				Sleep(150)
			end
			if shiva and shiva:CanBeCasted() and not v:IsMagicImmune() then 
				me:SafeCastItem(shiva.name)
				Sleep(150)
			end
			if orchid and orchid:CanBeCasted() and not v:IsMagicImmune() and not v:IsLinkensProtected() then 
				me:SafeCastItem(orchid.name,v)
				Sleep(150)
			end
			if veil and veil:CanBeCasted() and not v:IsMagicImmune() then 
				me:SafeCastItem(veil.name,v.position)
				Sleep(150)
			end
			if me:GetAbility(1):CanBeCasted() and not v:IsMagicImmune() then
				me:CastAbility(me:GetAbility(1),v)
            end
			Sleep(apoint+100,"auto_attack")
            if not SleepCheck("auto_attack") and ((me:GetAbility(1).cd > 0 or me.mana < me:GetAbility(1).manacost) or v:IsMagicImmune()) then
                me:Attack(v)
			end
		end
		if SleepCheck("fam") then
			for g,h in ipairs(familiars) do
				local modif = h:FindModifier("modifier_visage_summon_familiars_damage_charge")
				local spell = h:GetAbility(1)
				if not (spell.cd == 0 and GetDistance2D(h,v) < 325 and (modif and modif.stacks == 0)) then
				if not h.isAttacking and not (enemyspell and enemyspell ~= nil and enemyspell.channelTime ~= 0 and selectedfam == h) and (GetDistance2D(h,v) < 800 and h.alive == true and h.health > 0 and v and v.visible and v.alive == true and v.health > 0) and not (h.activity == LuaEntityNPC.ACTIVITY_CAST1 or h.activity == LuaEntityNPC.ACTIVITY_CAST2 or h.activity == LuaEntityNPC.ACTIVITY_CAST3 or h.activity == LuaEntityNPC.ACTIVITY_CAST4) then
					h:Attack(v)
					Sleep((0.6)*1000,"fam")
				end
				end
			end
		end
    end
end
end

function isAttacking(ent)
	if ent.activity == LuaEntityNPC.ACTIVITY_ATTACK or ent.activity == LuaEntityNPC.ACTIVITY_ATTACK1 or ent.activity == LuaEntityNPC.ACTIVITY_ATTACK2 then
		return true
	end
	return false
end

function onClose()
	collectgarbage("collect")
	if registered then
	    statusText.visible = false
            script:UnregisterEvent(Main)
    	    script:UnregisterEvent(Key)
    	    script:RegisterEvent(EVENT_TICK,onLoad)
		v = nil
	    registered = false
	end
end

script:RegisterEvent(EVENT_CLOSE,onClose) 
script:RegisterEvent(EVENT_TICK,onLoad)