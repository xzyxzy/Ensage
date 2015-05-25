--<<QoP by qqzzxxcc>>
require("libs.Utils")
require("libs.TargetFind")
require("libs.ScriptConfig")

config = ScriptConfig.new()
config:SetParameter("ComboKey", "D", config.TYPE_HOTKEY) 
config:Load()

local ComboKey     = config.ComboKey
local active	   = false 
local registered   = false 
local drange 	= 1650
local target    = nil             
local effect	= nil
local x,y = 1350, 50
local monitor = client.screenSize.x/1600
local font = drawMgr:CreateFont("font","Verdana",12,300)
local statusText = drawMgr:CreateText(x*monitor,y*monitor,0x00F5F5FF,"QoP || Press " .. string.char(ComboKey) .. " ||",font) statusText.visible = false

function onLoad()
	if PlayingGame() then
		local me = entityList:GetMyHero()
		if not me or me.classId ~= CDOTA_Unit_Hero_QueenOfPain then 
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
local Blink = me:GetAbility(2)
local Range = 350
local blink_range = 1300
local auto_attack = nil
local enemies = entityList:GetEntities({type=LuaEntity.TYPE_HERO,team = me:GetEnemyTeam(),alive=true,visible=true})
local sheep = me:FindItem("item_sheepstick")
local orchid = me:FindItem("item_orchid")
local veil = me:FindItem("item_veil_of_discord")
if active then
if SleepCheck("blink") and SleepCheck("auto_attack") then
    me:Move(client.mousePosition)
	Sleep(250)
end
Sleep(50)
local v = targetFind:GetClosestToMouse(100)
    if v and v.visible and v.alive and v.health > 0 then
        if SleepCheck("blink") and GetDistance2D(me,v) <= blink_range+Range and GetDistance2D(me,v) > (Range+320) and Blink and Blink:CanBeCasted() then
			bpos = (v.position - me.position) * (GetDistance2D(me,v) - Range) / GetDistance2D(me,v) + me.position
            if pcall(function () me:SafeCastAbility(Blink,bpos) end) then end
			Sleep(me:GetTurnTime(v)+client.latency,"blink")
		elseif GetDistance2D(me,v) < (Range+100) and SleepCheck("auto_attack") then
			if sheep and sheep:CanBeCasted() and not v:IsMagicImmune() and not v:IsLinkensProtected() then 
				me:SafeCastItem(sheep.name,v)
			end
			if orchid and orchid:CanBeCasted() and not v:IsMagicImmune()then 
				if not v:IsLinkensProtected() then
					me:SafeCastItem(orchid.name,v)
				elseif v:IsLinkensProtected() then
					me:CastAbility(me:GetAbility(1),v)
				end
			end
			if veil and veil:CanBeCasted() and not v:IsMagicImmune() then 
				me:SafeCastItem(veil.name,v.position)
			end
			if me:GetAbility(1):CanBeCasted() and not v:IsMagicImmune() then
				me:CastAbility(me:GetAbility(1),v)
            end
			if me:GetAbility(3):CanBeCasted() and not v:IsMagicImmune() and not (orchid ~= nil and orchid:CanBeCasted()) and not (veil ~= nil and veil:CanBeCasted()) then
				me:CastAbility(me:GetAbility(3))
            end
			if me:GetAbility(4):CanBeCasted() and (not (orchid ~= nil and orchid:CanBeCasted()) or v:IsMagicImmune()) and not (veil ~= nil and veil:CanBeCasted()) then
				me:CastAbility(me:GetAbility(4),v.position)
			end
			Sleep(700,"auto_attack")
            if not SleepCheck("auto_attack") and ((me:GetAbility(4).cd > 0 and me:GetAbility(1).cd > 0 and me:GetAbility(3).cd > 0) or v:IsMagicImmune()) then
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
