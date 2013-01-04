﻿-- Paladin Rotation Helper by Timofeev Alexey & Co
-- Binding
BINDING_HEADER_PRH = "Paladin Rotation Helper"
BINDING_NAME_PRH_OFF = "Выкл ротацию"
BINDING_NAME_PRH_DEBUG = "Вкл/Выкл режим отладки"
BINDING_NAME_PRH_MOUNT = "Вкл/Выкл маунта"
BINDING_NAME_PRH_AOE = "Вкл/Выкл AOE в ротации"
BINDING_NAME_PRH_INTERRUPT = "Вкл/Выкл сбивание кастов"
BINDING_NAME_PRH_AUTOAGGRO = "Авто АГГРО"
BINDING_NAME_PRH_BERSMOD = "Режим берсерка"

-- addon main frame
local frame=CreateFrame("Frame",nil,UIParent)
print("Paladin Rotation Helper loaded")
-- protected lock test
RunMacroText("/cleartarget")
-- attach events
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")

local LastUpdate = 0
local UpdateInterval = 0.025
local Paused = false
local Debug = false
local AutoAGGRO = true
local BersState = false
local CanInterrupt = true
local NextTarget = nil
local NextGUID = nil

function CanUseInterrupt()
    return CanInterrupt
end

function UseInterrupt()
    CanInterrupt = not CanInterrupt
    if CanInterrupt then
        echo("Interrupt: ON",true)
    else
        echo("Interrupt: OFF",true)
    end 
end

function NextIsTarget(target)
    if not target then target = "target" end
    return (UnitGUID("target") == NextGUID)
end

function ClearNextTarget()
    NextTarget = nil
    NextGUID = nil
end

function GetNextTarget()
    return NextTarget
end

function Mount()

    if CanExitVehicle() then
        VehicleExit()
    end
    
    if not IsMounted() and InCombatLockdown() then return end
    
    if IsMounted() then
            Dismount()
    else 
        if IsEquippedItemType("Удочка") then
             UseSpell("Рыбная ловля")
            return
        end
        
        if IsAltKeyDown() then
            UseMount("Тундровый мамонт путешественника")
            return
        end

        if IsFlyableArea() and not IsShiftKeyDown() then
            UseMount("Великолепный ковер-самолет")
        else
            UseMount("Призыв скакуна")
        end

    end
    
end

function AutoAGGROToggle()
    AutoAGGRO = not AutoAGGRO
    if AutoAGGRO then
        echo("АвтоАГГРО: ON",true)
    else
        echo("АвтоАГГРО: OFF",true)
    end 
end

function GetAutoAGGRO()
    return AutoAGGRO
end 

function BersModToggle()
    BersState = not BersState
    if BersState then
        echo("Берс Мод: ON",true)
    else
        echo("Берс Мод: OFF",true)
    end 
end

function GetBersState()
    return BersState
end  

function AutoRotationOff()
    Paused = true
    echo("Авто ротация: OFF",true)
    RunMacroText("/stopattack")
end

function DebugToggle()
    Debug = not Debug
    if Debug then
        echo("Режим отладки: ON",true)
    else
        echo("Режим отладки: OFF",true)
    end 
end

function IsDebug()
    return Debug
end    

function IsAttack()
    return (IsMouseButtonDown(4) == 1)
end


function IsAOE()
   if IsShiftKeyDown() == 1 then return true end
   return (IsValidTarget("target") and IsValidTarget("focus") and not IsOneUnit("target", "focus") and InMelee())
end

function onUpdate(frame, elapsed)

    if ApplyCommands() then return end

    if (IsAttack() and Paused) then
        echo("Авто ротация: ON",true)
        Paused = false
    end
    
    LastUpdate = LastUpdate + elapsed
    if LastUpdate < UpdateInterval then return end
    LastUpdate = 0

    if Paused then 
        return 
    end
    
    if UnitIsDeadOrGhost("player") or UnitIsCharmed("player") or not UnitPlayerControlled("player") then return end
    
    Idle()   
  
end
frame:SetScript("OnUpdate", onUpdate)


local dispellBlacklist = {}
local dispell = nil
local dispelTime = GetTime()
function TryDispell(unit)
    if not UnitIsFriend("player", unit) then return false end
    if not InRange("Очищение", unit) then return false end
    if GetTime() - dispelTime < 1.5 then return false end
    local ret = false
    for i = 1, 40 do
        if not ret then
            local name, _, _, _, debuffType, duration, expirationTime   = UnitDebuff(unit, i,true) 
            if name and (expirationTime - GetTime() >= 3 or expirationTime == 0) and (debuffType == "Poison" or debuffType == "Disease" or debuffType == "Magic") and (not dispellBlacklist[name] or GetTime() - dispellBlacklist[name] > 30) then
                if DoSpell("Очищение", unit) then 
                    print("Очищение ", unit, name)
                    dispell = name
                    dispelTime = GetTime()
                    ret = true 
                end
            end
        end
    end
    return ret
end


local ForbearanceTime = 0
function InForbearance(unit)
    if unit == nil then unit = "player" end
    return ((GetTime() - ForbearanceTime < 30) or HasDebuff("Воздержанность", 0.01, unit))
end


function onEvent(self, event, ...)
    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unit, spell = select(1,...)
        if spell == "Гнев карателя" and unit == "player" then ForbearanceTime = GetTime() end
        return
    end
    if (event=="COMBAT_LOG_EVENT_UNFILTERED") then
        local timestamp, type, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellId, spellName, destFlag, err = select(1, ...)
        if not(destName ~= GetUnitName("player")) and sourceName ~= nil and not UnitCanCooperate("player",sourceName) then 
            if not Paused then 
                NextTarget = sourceName
                NextGUID = sourceGUID
            end
        end
        if sourceGUID == UnitGUID("player") and (type:match("^SPELL_CAST") and spellId and spellName)  then

            if  err then
                
                if dispell and err == "Нечего рассеивать." then
                    print(dispell, "не снимается")
                    dispellBlacklist[dispell] = GetTime()
                end
                
                if Debug then
                    print("["..spellName .. "]: ".. err)
                end
            end
            
        end
    end
end
frame:SetScript("OnEvent", onEvent)




function DoSpell(spellName, target)
    if tContains({"Гнев карателя", "Божественный щит", "Возложение рук", "Божественная защита", "Длань защиты"}, spellName) and InForbearance(target) then return false end
    return UseSpell(spellName, target)
end
