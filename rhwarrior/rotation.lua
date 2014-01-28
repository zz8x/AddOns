﻿-- Warrior Rotation Helper by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
local peaceBuff = {"Пища", "Питье"}
function Idle()

    if (IsAttack() or UnitHealth100() > 60) and HasBuff("Длань защиты") then RunMacroText("/cancelaura Длань защиты") end

    if IsAttack() then
        if HasBuff("Парашют") then RunMacroText("/cancelaura Парашют") return end
        if CanExitVehicle() then VehicleExit() return end
        if IsMounted() then Dismount() return end 
    else
        if IsMounted() or CanExitVehicle() or HasBuff(peaceBuff) or not InCombatLockdown() or IsPlayerCasting() then return end
    end

    if CanInterrupt then
        for i=1,#TARGETS do
            TryInterrupt(TARGETS[i])
        end
    end
    
    if TryHealing() then return end
    if TryProtect() then return end

    TryTarget()

    if not (IsValidTarget("target") and CanAttack("target") and (UnitAffectingCombat("target")  or IsAttack()))  then return end
    RunMacroText("/startattack")

    DoSpell("Победный раж")
    DoSpell("Удар героя")

end


------------------------------------------------------------------------------------------------------------------
function TryHealing()
    local h = CalculateHP("player")
    if InCombatLockdown() then
        if h < 30 and not IsArena() and UseHealPotion() then return true end
    end
    return false
end
------------------------------------------------------------------------------------------------------------------
function ActualDistance(target)
    if target == nil then target = "target" end
    return (CheckInteractDistance(target, 3) == 1)
end

------------------------------------------------------------------------------------------------------------------
function TryTarget(useFocus)
    -- помощь в группе
    if not IsValidTarget("target") and InGroup() then
        -- если что-то не то есть в цели
        if UnitExists("target") then RunMacroText("/cleartarget") end
        for i = 1, #TARGET do
            local t = TARGET[i]
            if t and (UnitAffectingCombat(t) or IsPvP()) and ActualDistance(t) and (not IsPvP() or UnitIsPlayer(t))  then 
                RunMacroText("/startattack [@" .. target .. "]") 
                break
            end
        end
    end
    -- пытаемся выбрать ну хоть что нибудь
    if not IsValidTarget("target") then
        -- если что-то не то есть в цели
        if UnitExists("target") then RunMacroText("/cleartarget") end

        if IsPvP() then
            RunMacroText("/targetenemyplayer [nodead]")
        else
            RunMacroText("/targetenemy [nodead]")
        end
        if not IsAttack()  -- если в авторежиме
            and (
            not IsValidTarget("target")  -- вообще не цель
            or (not IsArena() and not ActualDistance("target"))  -- далековато
            or (not IsPvP() and not UnitAffectingCombat("target")) -- моб не в бою
            or (IsPvP() and not UnitIsPlayer("target")) -- не игрок в пвп
            )  then 
            if UnitExists("target") then RunMacroText("/cleartarget") end
        end
    end

    if useFocus ~= false then 
        if not IsValidTarget("focus") then
            if UnitExists("focus") then RunMacroText("/clearfocus") end
            for i = 1, #TARGETS do
                local t = TARGETS[i]
                if UnitAffectingCombat(t) and ActualDistance(t) and not IsOneUnit("target", t) then 
                    RunMacroText("/focus " .. t) 
                    break
                end
            end
        end
        
        if not IsValidTarget("focus") or IsOneUnit("target", "focus") or (not IsArena() and not ActualDistance("focus")) then
            if UnitExists("focus") then RunMacroText("/clearfocus") end
        end
    end

    if IsArena() then
        if IsValidTarget("target") and (not UnitExists("focus") or IsOneUnit("target", "focus")) then
            if IsOneUnit("target","arena1") then RunMacroText("/focus arena2") end
            if IsOneUnit("target","arena2") then RunMacroText("/focus arena1") end
        end
    end
end

------------------------------------------------------------------------------------------------------------------

local physDebuff = {
    "Poison"
}
local magicBuff = {
    "Стылая кровь",
    "Героизм",
    "Жажда крови"

}
local magicDebuff = {
    "Призыв горгульи"
}
local checkedTargets = TARGETS
function TryProtect()

    local defPhys = false;
    local defMagic = false;

    if InCombatLockdown() and (IsValidTarget("target") or IsValidTarget("focus")) then
        for i=1,#checkedTargets do
            local t = checkedTargets[i]
            if defPhys and defMagic then break end
            if IsValidTarget(t) then
                if HasBuff("Вихрь клинков", 4, t) and InRange("Ледяные оковы", t) then
                    echo("Вихрь клинков!", true)
                    defPhys = true
                    if HasSpell("Сжаться") then RunMacroText("/cast Сжаться") end
                end
                if IsOneUnit("player", t .. "-target") then
                    if HasBuff("Гнев карателя", 4, t) and InRange("Ледяные оковы", t) then
                        echo("Гнев карателя!", true)
                        defPhys = true
                        defMagic = true;
                    end
                    if HasDebuff(magicDebuff, 4, "player") or HasBuff(magicBuff, 4, t) then
                        echo("Магия!", true)
                        defMagic = true;
                    end
                    if HasDebuff(physDebuff, 4, "player") then
                        echo("Яды!", true)
                        defPhys = true;
                    end
                end

            end
        end

        if defPhys then 
            --DoSpell("Незыблемость льда")
        end
        if defMagic then 
            --DoSpell("Антимагический панцирь")
        end
    end
    return false;
end
------------------------------------------------------------------------------------------------------------------
