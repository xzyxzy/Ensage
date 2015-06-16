--<<PL by qqzzxxcc>>
require("libs.Utils")
require("libs.TargetFind")
require("libs.ScriptConfig")
require("libs.Animations")

config = ScriptConfig.new()
config:SetParameter("ComboKey", "E", config.TYPE_HOTKEY) 
config:SetParameter("AttackKey", "R", config.TYPE_HOTKEY) 
config:SetParameter("RunKey", "D", config.TYPE_HOTKEY) 
config:Load()

local ComboKey		= config.ComboKey
local AttackKey		= config.AttackKey
local RunKey		= config.RunKey
local active		= false 
local registered	= false 
local drange 	= 750
local attack	= 0
local move		= 0
local target    = nil             
local effect	= nil
local walking	= true
local sleepaggro = 0
local x,y		= 1350, 50
local monitor = client.screenSize.x/1600
local font = drawMgr:CreateFont("font","Verdana",12,300)
local statusText = drawMgr:CreateText(x*monitor,y*monitor,0x00F5F5FF,"PL || Press " .. string.char(ComboKey) .. " ||",font) statusText.visible = false

function onLoad()
	if PlayingGame() then
		local me = entityList:GetMyHero()
		if not me or me.classId ~= CDOTA_Unit_Hero_PhantomLancer then 
			script:Disable()
		else
			registered = true
			statusText.visible = true
			script:RegisterEvent(EVENT_FRAME,Main)
			script:RegisterEvent(EVENT_KEY,Key)
			script:UnregisterEvent(onLoad)
			effect = Effect(me,"range_display")
			effect:SetVector(1,Vector(drange,0,0))
		end
	end
end

function Key(msg,code)
	if client.chat or client.console or client.loading then return end
	if code == ComboKey then
		active = (msg == KEY_DOWN)
	end
	if code == AttackKey then
		attackmode = (msg == KEY_DOWN)
	end
	if code == RunKey then
		runmode = (msg == KEY_DOWN)
	end
end

function isAttacking(ent)
	if ent.activity == LuaEntityNPC.ACTIVITY_ATTACK or ent.activity == LuaEntityNPC.ACTIVITY_ATTACK1 or ent.activity == LuaEntityNPC.ACTIVITY_ATTACK2 then
		return true
	end
	return false
end

function Main(tick)
	if client.chat or client.console or client.loading then return end
	local me = entityList:GetMyHero()
	if not me then return end
	local Blink = me:GetAbility(2)
	local rushsleep = nil
	local arrows = nil
	local redarrows = nil
	local illus_check = nil
	local treads = me:FindItem("item_power_treads")
	local illuaspd = 0
	local illuapoint = 0
	local apoint = ((0.5*100)/(1+me.attackSpeed))*1000
	local enemies = entityList:GetEntities({type=LuaEntity.TYPE_HERO,team = me:GetEnemyTeam(),alive=true,visible=true})
	local diffusal1 = me:FindItem("item_diffusal_blade") 
	local diffusal2 = me:FindItem("item_diffusal_blade_2")
	local diffus = me:FindItem("item_diffusal_blade") or me:FindItem("item_diffusal_blade_2")
	local Bash = me:FindItem("item_abyssal_blade")
	local satanic = me:FindItem("item_satanic")
	local illusions = entityList:GetEntities({classId = me.classId, controllable = true, team = me.team, illusion = true, alive = true})
	local golem = entityList:FindEntities({classId = CDOTA_BaseNPC_Warlock_Golem, team = me:GetEnemyTeam(),alive=true,visible=true})
	local v = targetFind:GetClosestToMouse(100)
	local cake = client.mousePosition - me.position
	local rush = me:DoesHaveModifier("modifier_phantom_lancer_phantom_edge_boost")
	local iceblasted = me:DoesHaveModifier("modifier_ice_blast")
	if diffus then
		for y,u in ipairs(golem) do
			if u and u.visible and u.alive and u.health > 0 then
				if GetDistance2D(me,u) <= 600 and SleepCheck("golem") then
					me:SafeCastItem(diffus.name,u)
					Sleep(50, "golem")
				end
			end
		end
	end
	if not walking and not active and not attackmode and not runmode then
		walking = true
	end
	if not SleepCheck then 
		return 
	end
	if treads and treads.bootsState ~= 0 then
		if SleepCheck("resetpt") and not iceblasted and not active and not attackmode and not runmode then 
			me:SetPowerTreadsState(PT_STR)
			if not iceblasted and not active and not attackmode and not runmode then 
				Sleep(3000,"resetpt")
			end
		end
	end
	if me:GetAbility(3).level <= 2 then
		Range = 750
	end
	if me:GetAbility(3).level == 3 then
		Range = 800
	end
	if me:GetAbility(3).level == 4 then
		Range = 900
	end
	if Range > drange then 
		drange = Range
		effect = Effect(me,"range_display")
		effect:SetVector(1,Vector(drange,0,0))
	end
	if me:GetAbility(2).cd < ((30-(me:GetAbility(2).level)*5)-1+(client.latency/3/1000)) and me:GetAbility(2).cd > ((30-(me:GetAbility(2).level)*5)-1.05+(client.latency/3/1000)) and SleepCheck() and not attackmode and not active and not runmode then
        local alpha = math.atan2(cake.x,cake.y)
        local dAlpha = 2*math.pi/(#illusions + 1)
        me:Move(client.mousePosition)
        for n,m in ipairs(illusions) do
			m:Move(m.position + Vector(math.cos(alpha + dAlpha*n),math.sin(alpha + dAlpha*n),0)*50)
			for d=500,3000,500 do
				m:Move(m.position + Vector(math.cos(alpha + dAlpha*n),math.sin(alpha + dAlpha*n),0)*d, true)
			end
		end
		Sleep(15+1*#illusions)
	end
	if attackmode then
		if #illusions > 0 then			
			for i,v in ipairs(illusions) do				
				for k,z in ipairs(entityList:GetProjectiles({target=me})) do
					if z.source then
						if z.source.classId == CDOTA_BaseNPC_Creep_Lane or z.source.classId == CDOTA_BaseNPC_Tower then
							if v.team == me.team and v.visible and v.alive and tick > sleepaggro and v.health > (v.health/100)*5 and GetDistance2D(z.source,me) <= z.source.attackRange + 25 then								
								if GetDistance2D(v,me) < me.attackRange + 200 then								
									me:Attack(v)
									sleepaggro = tick + 200
								end
							end
						end
					end
				end
			end
		end
		if SleepCheck("redarrows") and not isAttacking(me) then
			if SleepCheck("change") and treads and treads.bootsState ~= 0 and not iceblasted then
				me:SetPowerTreadsState(PT_STR)
				Sleep(200, "change")
			end
			me:AttackMove(client.mousePosition)
			Sleep(apoint+200, "redarrows")
		end
		if not (me.activity == LuaEntityNPC.ACTIVITY_IDLE or me.activity == LuaEntityNPC.ACTIVITY_IDLE1 or me.activity == LuaEntityNPC.ACTIVITY_MOVE) then
			if SleepCheck("change") and treads and treads.bootsState ~= 2 and not iceblasted and not Animations.CanMove(me) then
				me:SetPowerTreadsState(PT_AGI)
				Sleep(200, "change")
			end
		end
		if SleepCheck("illus_check") then
			for l,k in ipairs(illusions) do
				if not isAttacking(k) then
					illuapoint = ((0.5*100)/(1+k.attackSpeed))*1000
					k:AttackMove(client.mousePosition)
				end
			end
			Sleep(illuapoint+200,"illus_check")
		end
	end
	if runmode then
		if walking and not rush and SleepCheck("rushsleep") and SleepCheck("arrows") then
			if SleepCheck("change") and treads and treads.bootsState ~= 0 and not iceblasted then
				me:SetPowerTreadsState(PT_STR)
				Sleep(180, "change")
			end
			me:Move(client.mousePosition)
			Sleep(20, "arrows")
		end
		if v and v.visible and v.alive and v.health > 0 then
			local illusioncounter = 0
			if SleepCheck("illus_check") then
				for l,k in ipairs(illusions) do
					illusioncounter = l
					if k.recentDamage == 0 then
						k:Attack(v)
					end
				end
				Sleep(100*illusioncounter,"illus_check")
			end
		end
	end
	if active then
		if not rush and GetDistance2D(me,v) > me.attackRange*2 then
			local walking = true
		end
		if walking and not rush and SleepCheck("rushsleep") and SleepCheck("arrows") then
			if SleepCheck("change") and treads and treads.bootsState ~= 0 and not iceblasted then
				me:SetPowerTreadsState(PT_STR)
				Sleep(180, "change")
			end
			me:Move(client.mousePosition)
			Sleep(100, "arrows")
		end
		if v and v.visible and v.alive and v.health > 0 then
			local disabled = v:IsHexed() or v:IsStunned() 
			local illusioncounter = 0
			if v.health > 0 and v.alive then
				if SleepCheck("illus_check") then
					for l,k in ipairs(illusions) do
						illusioncounter = l
						if k.recentDamage == 0 then
							illuaspd = k.attackSpeed
							k:Attack(v)
						end
					end
					Sleep(100*illusioncounter,"illus_check")
				end
			end
			if GetDistance2D(me,v) < Range and SleepCheck("rushsleep") and not rush then
				if me:GetAbility(1) and not (me:GetAbility(1).cd > 0) and me:GetAbility(1).manacost < (me.mana/me.maxMana)*(me.maxMana+117) and (treads and treads.bootsState ~= 1) and not v:IsMagicImmune() and not rush and SleepCheck("casting") and (GetDistance2D(me,v) < 300 or me:GetAbility(3).cd ~= 0 or me:GetAbility(3).level == 0) and me:GetAbility(1).level > 0 and me:CanCast() and GetDistance2D(me,v) <= 750 and not isAttacking(me) then
					if SleepCheck("change") and treads and treads.bootsState ~= 1 and not iceblasted then
						me:SetPowerTreadsState(PT_INT)
						Sleep(me:GetAbility(1):FindCastPoint()*1000+me:GetTurnTime(v)*1000, "change")
					end
					me:SafeCastAbility(me:GetAbility(1),v)
                    Sleep(me:GetAbility(1):FindCastPoint()*1000+me:GetTurnTime(v)*1000, "casting")
				end
				if me:GetAbility(1):CanBeCasted() and not v:IsMagicImmune() and not rush and SleepCheck("casting") and (GetDistance2D(me,v) < 300 or me:GetAbility(3).cd ~= 0 or me:GetAbility(3).level == 0) and me:GetAbility(1).level > 0 and me:CanCast() and GetDistance2D(me,v) <= 750 then
					if SleepCheck("change") and treads and treads.bootsState ~= 1 and not iceblasted and not rush then
						me:SetPowerTreadsState(PT_INT)
						Sleep(180, "change")
					end
					me:SafeCastAbility(me:GetAbility(1),v)
                    Sleep(me:GetAbility(1):FindCastPoint()*1000+me:GetTurnTime(v)*1000, "casting")
				end
				if (diffusal1 or diffusal2) and not rush and me.movespeed*0.87 < v.movespeed and not v:IsMagicImmune() and GetDistance2D(me,v) > 240 and not v:IsLinkensProtected() and (((me:GetAbility(1).cd > 3) and (me:GetAbility(1).cd < 6)) or (me.mana < me:GetAbility(1).manacost)) and not disabled then
					if diffusal1 and diffusal1:CanBeCasted() then me:SafeCastItem(diffusal1.name,v) end
					if diffusal2 and diffusal2:CanBeCasted() then me:SafeCastItem(diffusal2.name,v) end
				end
				if Bash and Bash:CanBeCasted() and not disabled and not linkens and not rush then
					me:CastAbility(Bash, v)
				end
				if satanic and satanic:CanBeCasted() and me.health < me.maxHealth*0.3 and GetDistance2D(me,v) <= 128 and not rush then 
					me:CastAbility(satanic)
				end
				if not Animations.CanMove(me) and not rush then
					if tick > attack and GetDistance2D(me, v) <= me.attackRange*2 and SleepCheck("rushsleep") then
						if SleepCheck("change") and treads and treads.bootsState ~= 2 and not iceblasted then
							me:SetPowerTreadsState(PT_AGI)
							Sleep(apoint+200, "change")
						end
						walking = false
						me:Attack(v)
						attack = tick + Animations.maxCount/1.5
					end
				elseif tick > move and not rush and SleepCheck("rushsleep") then
					walking = true
					me:Move(client.mousePosition)
					move = tick + Animations.maxCount/1.5
				end
				if me:GetAbility(3).cd == 0 and  me:GetAbility(3).level > 0 and SleepCheck("rushsleep") and GetDistance2D(me, v) > 300 then
					if SleepCheck("change") and treads and treads.bootsState ~= 0 and not iceblasted then
						me:SetPowerTreadsState(PT_STR)
						Sleep(180, "change")
					end
					me:Attack(v)	
					Sleep(300,"rushsleep")
				end
			end
		end
	end
end

function onClose()
	collectgarbage("collect")
	if registered then
	    statusText.visible = false
        script:UnregisterEvent(Main)
    	script:UnregisterEvent(Key)
    	script:RegisterEvent(EVENT_FRAME,onLoad)
	    registered = false
	end
end

script:RegisterEvent(EVENT_CLOSE,onClose) 
script:RegisterEvent(EVENT_FRAME,onLoad)
