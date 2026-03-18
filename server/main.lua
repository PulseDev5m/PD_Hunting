local playerData = {}
local playerCash = {}

local function LoadPlayer(src)
    if playerData[src] then return end
    local identifier = GetPlayerIdentifierByType(src, 'license') or GetPlayerIdentifier(src, 0)
    if not identifier then return end

    DB_LoadPlayer(identifier, function(data)
        data.name       = GetPlayerName(src) or 'Unknown'
        data.discordId  = GetPlayerIdentifierByType(src, 'discord') or nil
        if data.discordId then
            data.discordId = data.discordId:gsub('discord:', '')
        end
        playerData[src] = data
        if Config.Framework == "standalone" then
            playerCash[src] = data.cash or 0
        end
    end)
end

local function SavePlayer(src)
    if not playerData[src] then return end
    local identifier = GetPlayerIdentifierByType(src, 'license') or GetPlayerIdentifier(src, 0)
    if not identifier then return end
    if Config.Framework == "standalone" then
        playerData[src].cash = playerCash[src] or 0
    end
    DB_SavePlayer(identifier, playerData[src])
end

AddEventHandler('playerJoining', function()
    LoadPlayer(source)
end)

AddEventHandler('playerDropped', function()
    local src = source
    SavePlayer(src)
    playerData[src] = nil
    playerCash[src] = nil
end)

CreateThread(function()
    while true do
        Wait(300000)
        for src in pairs(playerData) do
            SavePlayer(src)
        end
        print('[HuntScript] Auto-saved all player data.')
    end
end)

RegisterNetEvent('hunt:server:sellAnimals', function(animalList)
    local src = source
    if not playerData[src] then LoadPlayer(src) end
    local data = playerData[src]
    if not data then return end

    local totalEarnings = 0
    local totalCount    = 0
    local soldBreakdown = {}

    for animalModel, count in pairs(animalList) do
        local animalCfg = Config.AnimalValues[animalModel]
        if animalCfg and count > 0 then
            local value = animalCfg.price * count
            totalEarnings = totalEarnings + value
            totalCount    = totalCount + count
            data.animals_data[animalModel] = (data.animals_data[animalModel] or 0) + count
            soldBreakdown[#soldBreakdown + 1] = {
                label = animalCfg.label,
                icon  = animalCfg.icon,
                count = count,
                value = value,
            }
        end
    end

    if totalCount == 0 then return end

    data.total_sold     = data.total_sold + totalCount
    data.current_cycle  = data.current_cycle + totalCount
    data.total_earnings = data.total_earnings + totalEarnings

    GiveMoney(src, totalEarnings)

    local milestonesEarned = {}
    while data.current_cycle >= Config.Settings.AnimalsPerMilestone do
        data.current_cycle = data.current_cycle - Config.Settings.AnimalsPerMilestone
        data.milestones    = data.milestones + 1

        local reward = Config.MilestoneRewards[data.milestones]
        if reward then
            milestonesEarned[#milestonesEarned + 1] = reward
            GiveMoney(src, reward.money)
            if reward.item and Config.Settings.UseOxInventory then
                exports.ox_inventory:AddItem(src, reward.item, 1)
            end
        end

        DiscordLog('milestone', src, data, { breakdown = soldBreakdown, milestone = reward })
    end

    SavePlayer(src)

    DiscordLog('sell', src, data, { breakdown = soldBreakdown, totalCount = totalCount, totalEarnings = totalEarnings })

    TriggerClientEvent('hunt:client:sellResult', src, {
        breakdown      = soldBreakdown,
        totalEarnings  = totalEarnings,
        totalCount     = totalCount,
        milestones     = milestonesEarned,
        playerData     = GetPublicData(src, data),
    })
end)

RegisterNetEvent('hunt:server:requestData', function()
    local src = source
    if not playerData[src] then LoadPlayer(src) end
    local data = playerData[src]
    if not data then return end
    TriggerClientEvent('hunt:client:receiveData', src, GetPublicData(src, data))
end)

RegisterNetEvent('hunt:server:requestLeaderboard', function()
    local src = source
    DB_GetLeaderboard(function(rows)
        TriggerClientEvent('hunt:client:receiveLeaderboard', src, rows)
    end)
end)

function GiveMoney(src, amount)
    if Config.Framework == "qbcore" then
        local QBCore = exports['qb-core']:GetCoreObject()
        local Player = QBCore.Functions.GetPlayer(src)
        if Player then Player.Functions.AddMoney('cash', amount) end
    elseif Config.Framework == "esx" then
        local ESX = exports['es_extended']:getSharedObject()
        local xPlayer = ESX.GetPlayerFromId(src)
        if xPlayer then xPlayer.addMoney(amount) end
    else
        playerCash[src] = (playerCash[src] or 0) + amount
    end
end

function DiscordLog(event, src, data, extra)
    if not Config.Discord.Enabled or not Config.Discord.Webhook then return end

    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    local discordMention = "Not linked"

    if data.discordId and data.discordId ~= "" then
        discordMention = "<@" .. data.discordId .. ">"
    end

    local embed = {}

    if event == 'sell' then
        local lines = {}
        for _, b in ipairs(extra.breakdown or {}) do
            lines[#lines + 1] = string.format(
                '%dx %s — %s%d',
                b.count or 0,
                b.label or "Unknown",
                Config.Settings.Currency,
                b.value or 0
            )
        end

        embed = {
            title = "Animal Sale",
            color = 3066993,
            description = string.format(
                "%s sold **%d animal%s** and earned **%s%d**",
                discordMention,
                extra.totalCount or 0,
                (extra.totalCount or 0) ~= 1 and 's' or '',
                Config.Settings.Currency,
                extra.totalEarnings or 0
            ),
            fields = {
                { name = "Breakdown", value = (#lines > 0 and table.concat(lines, "\n") or "None"), inline = false },
                { name = "Total Sold", value = tostring(data.total_sold or 0), inline = true },
                { name = "Total Earned", value = Config.Settings.Currency .. tostring(data.total_earnings or 0), inline = true },
                { name = "Discord", value = discordMention, inline = false },
            },
            footer = { text = "Hunting Logs • " .. timestamp },
        }

    elseif event == 'milestone' then
        local reward = extra.milestone or {}

        embed = {
            title = "Milestone Reached",
            color = 15844367,
            description = string.format(
                "%s hit milestone **#%d** with **%d total animals sold**",
                discordMention,
                data.milestones or 0,
                data.total_sold or 0
            ),
            fields = {
                { name = "Title", value = reward.label or "Hunter", inline = true },
                { name = "Bonus", value = reward.money and (Config.Settings.Currency .. reward.money) or "None", inline = true },
                { name = "Item", value = reward.item or "None", inline = true },
                { name = "Discord", value = discordMention, inline = false },
            },
            footer = { text = "Hunting Logs • " .. timestamp },
        }
    end

    if not embed.title then return end

    local payload = {
        username = Config.Discord.BotName or "Hunting Logs",
        avatar_url = Config.Discord.BotAvatar or "",
        embeds = { embed },
        allowed_mentions = { parse = { "users" } }
    }

    local payloadJson = json.encode(payload)

    PerformHttpRequest(Config.Discord.Webhook, function(statusCode, text, headers)
        print(("[HuntScript] Discord webhook response: %s | %s"):format(statusCode, text or ""))
    end, "POST", payloadJson, { ["Content-Type"] = "application/json" })
end

function GetPublicData(src, data)
    local nextMilestone         = nil
    local remainingForMilestone = Config.Settings.AnimalsPerMilestone - data.current_cycle
    local upcomingMilestoneNum  = data.milestones + 1

    for milestone, reward in pairs(Config.MilestoneRewards) do
        if milestone >= upcomingMilestoneNum then
            if not nextMilestone or milestone < nextMilestone.num then
                nextMilestone = { num = milestone, data = reward }
            end
        end
    end

    return {
        total_sold          = data.total_sold,
        milestones          = data.milestones,
        current_cycle       = data.current_cycle,
        total_earnings      = data.total_earnings,
        animals_data        = data.animals_data,
        remaining           = remainingForMilestone,
        nextMilestone       = nextMilestone,
        animalsPerMilestone = Config.Settings.AnimalsPerMilestone,
        cash                = Config.Framework == "standalone" and (playerCash[src] or 0) or nil,
    }
end
