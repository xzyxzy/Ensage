--<<Zeus by qqzzxxcc>>
require("libs.Utils")
require("libs.TargetFind")
require("libs.ScriptConfig")

config = ScriptConfig.new()
config:SetParameter("ComboKey", "D", config.TYPE_HOTKEY) 
config:Load()

local ComboKey     = config.ComboKey
local active	   = false 
local registered   = false 
local drange 	= 1850 
local target    = nil             
local effect	= nil
local x,y = 1350, 50
local monitor = client.screenSize.x/1600
local font = drawMgr:CreateFont("font","Verdana",12,300)
local statusText = drawMgr:CreateText(x*monitor,y*monitor,0x00F5F5FF,"Zuus || Press " .. string.char(ComboKey) .. " ||",font) statusText.visible = false

function onLoad()
	if PlayingGame() then
		local me = entityList:GetMyHero()
		if not me or me.classId ~= CDOTA_Unit_Hero_Zuus then 
			script:Disable()
		else
			registered = true
			statusText.visible = true
			script:RegisterEvent(EVENT_TICK,Main)
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
end

function Main(tick)

local me = entityList:GetMyHero()   
if not SleepCheck then return end   
local Blink = me:FindItem("item_blink")
local Range = 700
local blink_range = 1200
local auto_attack = nil
local enemies = entityList:GetEntities({type=LuaEntity.TYPE_HERO,team = me:GetEnemyTeam(),alive=true,visible=true})
local sheep = me:FindItem("item_sheepstick")
local orchid = me:FindItem("item_orchid")
local veil = me:FindItem("item_veil_of_discord")
local soulring = me:FindItem("item_soul_ring")
local arcane = me:FindItem("item_arcane_boots")
if active then
if SleepCheck("blink") and SleepCheck("auto_attack") then
    me:Move(client.mousePosition)
	Sleep(250)
end
Sleep(50)
local v = targetFind:GetClosestToMouse(100)
    if v and v.visible and v.alive and v.health > 0 then
        if SleepCheck("blink") and GetDistance2D(me,v) <= (blink_range + Range - 50) and GetDistance2D(me,v) > (Range + 220) and Blink and Blink:CanBeCasted() then
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
			if orchid and orchid:CanBeCasted() and not v:IsMagicImmune() and not v:IsLinkensProtected() then 
				me:SafeCastItem(orchid.name,v)
				Sleep(150)
			end
			if veil and veil:CanBeCasted() and not v:IsMagicImmune() then 
				me:SafeCastItem(veil.name,v.position)
				Sleep(150)
			end
			if me:GetAbility(1):CanBeCasted() and not v:IsMagicImmune() and (me:GetAbility(2).cd > 0 or v:IsLinkensProtected() or GetDistance2D(me,v) > 700) then
				me:CastAbility(me:GetAbility(1),v)
            end
			if me:GetAbility(2):CanBeCasted() and not v:IsMagicImmune() and not v:IsLinkensProtected() then
				me:SafeCastAbility(me:GetAbility(2),v)
            end
			Sleep(700,"auto_attack")
            if not SleepCheck("auto_attack") and ((me:GetAbility(2).cd > 0 and me:GetAbility(1).cd > 0) or v:IsMagicImmune()) then
                me:Attack(v)
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
    	    script:RegisterEvent(EVENT_TICK,onLoad)
	    registered = false
	end
end

script:RegisterEvent(EVENT_CLOSE,onClose) 
script:RegisterEvent(EVENT_TICK,onLoad)
