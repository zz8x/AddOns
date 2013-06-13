﻿-- Rotation Helper Library by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
function SellGray()
    for b=0,4 do                                   
      for s=1, GetContainerNumSlots(b) do          
        local n=GetContainerItemLink(b,s)
        if n and string.find(n, "ff9d9d9d") then                                 
            UseContainerItem(b,s)                   
        end                                        
      end                                          
    end                                            
end

------------------------------------------------------------------------------------------------------------------
function buy(name,q) 
    local c = 0
    for i=0,3 do 
        local numberOfFreeSlots = GetContainerNumFreeSlots(i);
        if numberOfFreeSlots then c = c + numberOfFreeSlots end
    end
    if c < 1 then return end
    if q == nil then q = 255 end
    for i=1,100 do 
        if name == GetMerchantItemInfo(i) then
            local s = c*GetMerchantItemMaxStack(i) 
            if q > s then q = s end
            BuyMerchantItem(i,q)
        end 
    end
end

------------------------------------------------------------------------------------------------------------------
function sell(name) 
    if not name then name = "" end
    for bag = 0,4,1 do 
        for slot = 1, GetContainerNumSlots(bag), 1 do 
            local item = GetContainerItemLink(bag,slot)
            if item and string.find(item,name) then 
                UseContainerItem(bag,slot) 
            end
        end
    end
end

------------------------------------------------------------------------------------------------------------------
-- Update Debug Frame
local notifyFrame = nil
local notifyFrameTime = 0
local function notifyFrame_OnUpdate()
        if (notifyFrameTime > 0 and notifyFrameTime < GetTime() - 5) then
                local alpha = notifyFrame:GetAlpha()
                if (alpha ~= 0) then notifyFrame:SetAlpha(alpha - .02) end
                if (aplha == 0) then 
					notifyFrame:Hide() 
					notifyFrameTime = 0
				end
        end
end
-- Debug & Notification Frame
notifyFrame = CreateFrame('Frame')
notifyFrame:ClearAllPoints()
notifyFrame:SetHeight(300)
notifyFrame:SetWidth(300)
notifyFrame:SetScript('OnUpdate', notifyFrame_OnUpdate)
notifyFrame:Hide()
notifyFrame.text = notifyFrame:CreateFontString(nil, 'BACKGROUND', 'PVPInfoTextFont')
notifyFrame.text:SetAllPoints()
notifyFrame:SetPoint('CENTER', 0, 200)

-- Debug messages.
function Notify(message)
        notifyFrame.text:SetText(message)
        notifyFrame:SetAlpha(1)
        notifyFrame:Show()
        notifyFrameTime = GetTime()
end

------------------------------------------------------------------------------------------------------------------
function echo(msg, cls)
    if (cls ~= nil) then UIErrorsFrame:Clear() end
    UIErrorsFrame:AddMessage(msg, 0.0, 1.0, 0.0, 53, 2);
end

------------------------------------------------------------------------------------------------------------------
function chat(msg)
    DEFAULT_CHAT_FRAME:AddMessage(msg, 1.0, 0.5, 0.5);
end

------------------------------------------------------------------------------------------------------------------
function printtable(t, indent)
  indent = indent or 0;
  local keys = {};
  for k in pairs(t) do
    keys[#keys+1] = k;
    table.sort(keys, function(a, b)
      local ta, tb = type(a), type(b);
      if (ta ~= tb) then
        return ta < tb;
      else
        return a < b;
      end
    end);
  end
  print(string.rep('  ', indent)..'{');
  indent = indent + 1;
  for k, v in pairs(t) do
    local key = k;
    if (type(key) == 'string') then
      if not (string.match(key, '^[A-Za-z_][0-9A-Za-z_]*$')) then
        key = "['"..key.."']";
      end
    elseif (type(key) == 'number') then
      key = "["..key.."]";
    end
    if (type(v) == 'table') then
      if (next(v)) then
        print(format("%s%s =", string.rep('  ', indent), tostring(key)));
        printtable(v, indent);
      else
        print(format("%s%s = {},", string.rep('  ', indent), tostring(key)));
      end 
    elseif (type(v) == 'string') then
      print(format("%s%s = %s,", string.rep('  ', indent), tostring(key), "'"..v.."'"));
    else
      print(format("%s%s = %s,", string.rep('  ', indent), tostring(key), tostring(v)));
    end
  end
  indent = indent - 1;
  print(string.rep('  ', indent)..'}');
end

------------------------------------------------------------------------------------------------------------------
function tContainsKey(table, key)
    for name,value in pairs(table) do 
        if key == name then return true end
    end
    return false
end

function sContains(str, sub)
    if (not str or not sub) then
      return false
    end
    return (strlower(str):find(strlower(sub), 1, true) ~= nil)
end