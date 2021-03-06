﻿-- Shaman Rotation Helper by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------

SetCommand("hero", 

    function() 
        local heroSpell = HasSpell("Героизм") and "Героизм" or "Жажда крови"
        return DoSpell(heroSpell) 
    end, 
    function() 
        local heroSpell = HasSpell("Героизм") and "Героизм" or "Жажда крови"
        return not InGCD() and not IsReadySpell(heroSpell) 
    end
)

------------------------------------------------------------------------------------------------------------------
SetCommand("frostshock", 
    function() 
        if DoSpell("Ледяной шок", "target") then
            echo("Ледяной шок!", 1)
        end
    end, 
    function() 
        return not InCombatLockdown() or not CanControl("target") or HasDebuff("Ледяной шок", 0,1, "target") or not IsSpellNotUsed("Ледяной шок", 1) 
    end
)

------------------------------------------------------------------------------------------------------------------
SetCommand("wolf", 
    function() 
        if DoSpell("Дух дикого волка") then
            echo("Волки!", 1)
        end
    end, 
    function() 
        return not CanControl("target") or not IsSpellNotUsed("Дух дикого волка", 1) 
    end
)

------------------------------------------------------------------------------------------------------------------
SetCommand("root", 
    function() 
        echo("Root!",1)
        return TryTotems()
    end, 
    function() 
        if ForceRoot then
            if HasTotem("Тотем оков земли") then
                ForceRoot = false
                return true
            end
        else
            ForceRoot = true
        end
        return false  
    end
)

------------------------------------------------------------------------------------------------------------------
local druidForm = {"облик", "Древо Жизни"}
local hexTime = 0
SetCommand("hex", 
    function(target, force) 
        if force and HasSpell("Природная стремительность") then 
            DoSpell("Природная стремительность") 
        end
        echo("Сглаз",1)
        if DoSpell("Сглаз", "target") then 
            hexTime = GetTime()
        end
    end, 
    function(target) 
        if not CanControl(target) then 
            echo("Имунен к контролю!")
            return true 
        end
        if not IsSpellNotUsed("Сглаз", 1)  then 
            echo("Успещно прожали Сглаз!")
            return true 
        end
        if not UnitIsPlayer(target) then
            local creatureType = UnitCreatureType(target)
            if creatureType ~= "Гуманоид" or creatureType ~= "Животное" then 
                echo(creatureType .. ' - нельзя кинуть Сглаз!')
                return true 
            end
        else
            if GetClass(target) == "DRUID" and HasBuff(druidForm, 0.1, target) then 
                echo('Друид в форме, имунен к превращениям')
                return true 
            end 
        end
        if GetTime() - hexTime < 0.1 then
            hexTime = 0
            return true
        end
        return false
    end
)
------------------------------------------------------------------------------------------------------------------
local freedomItem
local freedomSpell = "Каждый за себя"
SetCommand("freedom", 
    function() 
        if HasSpell(freedomSpell) then
            DoSpell(freedomSpell)
            return
        end
        UseEquippedItem(freedomItem) 
    end, 
    function() 
        if IsPlayerCasting() then return true end
        if HasSpell(freedomSpell) and (not InGCD() and not IsReadySpell(freedomSpell)) then return true end
        if freedomItem == nil then
           freedomItem = (UnitFactionGroup("player") == "Horde" and "Медальон Орды" or "Медальон Альянса")
        end
        return not IsEquippedItem(freedomItem) or (not InGCD() and not IsReadyItem(freedomItem)) 
    end
)

------------------------------------------------------------------------------------------------------------------
SetCommand("silence", 
    function(target) 
        local spell = "Пронизывающий ветер"
        if DoSpell(spell, target) then
            echo(spell.."!",1)
        end
    end, 
    function(target) 
        if not CanMagicAttack(target) or HasBuff("Мастер аур", 0.1, target) then return true end
        local spell = "Пронизывающий ветер"
        if not InRange(spell, target) then
            chat(spell .. " - неверная дистанция!")
            return true
        end
        if not IsSpellNotUsed(spell, 1)  then
            chat(spell .. " - успешно сработало!")
            return true
        end
        return false
    end
)
------------------------------------------------------------------------------------------------------------------
SetCommand("dispel", 
    function(target) 
        local spell = "Развеивание магии"
        if DoSpell(spell, target) then
            echo(spell.."!",1)
        end
    end, 
    function(target) 
        if not HasBuff("Magic", 1, target) then 
            chat("Нет магических эффектов на цели")
            return true 
        end
        local spell = "Развеивание магии"
        if not InRange(spell, target) then
            chat(spell .. " - неверная дистанция!")
            return true
        end
        if not IsSpellNotUsed(spell, 1)  then
            chat(spell .. " - успешно сработало!")
            return true
        end
        return false
    end
)
------------------------------------------------------------------------------------------------------------------
local tryMount = false
SetCommand("mount",
    function(mamont) 
        --if InGCD() or IsPlayerCasting() then return end
        if (IsLeftControlKeyDown() or IsSwimming()) and not HasBuff("Хождение по воде", 1, "player") and DoSpell("Хождение по воде", "player") then 
            tryMount = true
            return 
        end
        if InCombatLockdown() or IsArena() or not PlayerInPlace() then
            DoSpell("Призрачный волк") 
            tryMount = true
            return 
        end
        if InCombatLockdown() or not IsOutdoors() then return end
        local mount = "Большая ракета любви"
        -- local mount = "Стремительный белый рысак"
        -- if IsFlyableArea() and not IsLeftControlKeyDown() then mount = "Черный дракон" end
        if mamont then mount = "Тундровый мамонт путешественника" end
        if UseMount(mount) then tryMount = true return end
    end, 
    function() 
        if (HasBuff("Призрачный волк") or IsMounted() or CanExitVehicle()) then return true end
        if tryMount then
            tryMount = false
            return true
        end
        return false 
    end
)

------------------------------------------------------------------------------------------------------------------
SetCommand("totems", 
    function() 
        echo("Тотемы!",1)
        return TryTotems(true)
    end, 
    function() 
        if InCombatLockdown() and not NeedTotems then 
            NeedTotems = true
            return true
        end
        if GetTime() - TotemTime < 1  then
            return true
        end
        return false
    end
)
------------------------------------------------------------------------------------------------------------------
SetCommand("untotems", 
    function() 
        echo("Убрать Тотемы!",1)
        return DoSpell("Возвращение тотемов")
    end, 
    function() 
        if NeedTotems then
            NeedTotems = false
        end
        return TotemCount() < 1 or not IsSpellNotUsed("Возвращение тотемов", 1)
    end
)
