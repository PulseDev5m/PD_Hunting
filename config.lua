Config = {}

Config.Framework = "standalone" -- "standalone", "qbcore", "esx"

Config.Discord = {
    Enabled    = true,
    Webhook    = "https://discord.com/api/webhooks/discordid/change_me",
    BotName    = "Hunting System",
    BotAvatar  = "https://www.freepik.com/premium-vector/deer-hunting-logo_19208644.htm",
    EmbedColor = 3066993,
}

Config.HuntingAreas = {
    {
        name       = "Chiliad Wilderness",
        label      = "Chiliad Wilderness",
        coords     = vector3(-302.0, 5595.0, 234.0),
        radius     = 300.0,
        animals    = {"a_c_deer", "a_c_boar", "a_c_rabbit_01", "a_c_coyote"},
        spawnRate  = 30,
        maxAnimals = 20,
    },
    {
        name       = "Alamo Sea Badlands",
        label      = "Alamo Badlands",
        coords     = vector3(1100.0, 2700.0, 40.0),
        radius     = 250.0,
        animals    = {"a_c_coyote", "a_c_rabbit_01", "a_c_crow"},
        spawnRate  = 25,
        maxAnimals = 15,
    },
    {
        name       = "Paleto Forest",
        label      = "Paleto Forest",
        coords     = vector3(-1390.0, 5200.0, 70.0),
        radius     = 350.0,
        animals    = {"a_c_deer", "a_c_boar", "a_c_coyote", "a_c_rabbit_01"},
        spawnRate  = 20,
        maxAnimals = 25,
    },
    {
        name       = "Grand Senora Desert",
        label      = "Grand Senora Desert",
        coords     = vector3(1700.0, 3200.0, 35.0),
        radius     = 400.0,
        animals    = {"a_c_coyote", "a_c_rabbit_01"},
        spawnRate  = 35,
        maxAnimals = 15,
    },
    {
        name       = "Vinewood Hills",
        label      = "Vinewood Hills",
        coords     = vector3(-900.0, 800.0, 200.0),
        radius     = 200.0,
        animals    = {"a_c_deer", "a_c_rabbit_01"},
        spawnRate  = 45,
        maxAnimals = 12,
    },
}

Config.SellSpots = {
    {
        name       = "Paleto Bay Butcher",
        label      = "Paleto Bay Butcher",
        coords     = vector3(-64.01, 6276.95, 31.36),
        blipSprite = 272,
        blipColor  = 5,
        blipScale  = 0.8,
    },
    {
        name       = "Sandy Shores Market",
        label      = "Sandy Shores Market",
        coords     = vector3(1965.8, 3747.41, 32.34),
        blipSprite = 272,
        blipColor  = 5,
        blipScale  = 0.8,
    },
    {
        name       = "Grapeseed Market",
        label      = "Grapeseed Market",
        coords     = vector3(1702.55, 4914.85, 42.08),
        blipSprite = 272,
        blipColor  = 5,
        blipScale  = 0.8,
    },
}

Config.AnimalValues = {
    ["a_c_deer"]      = { label = "Deer",   price = 250 },
    ["a_c_boar"]      = { label = "Boar",   price = 180 },
    ["a_c_rabbit_01"] = { label = "Rabbit", price = 80 },
    ["a_c_coyote"]    = { label = "Coyote", price = 150 },
    ["a_c_crow"]      = { label = "Crow",   price = 50 },
    ["a_c_hen"]       = { label = "Hen",    price = 60 },
}

Config.MilestoneRewards = {
    [1]  = { label = "Novice Hunter",    money = 1000,  item = nil             },
    [5]  = { label = "Skilled Hunter",   money = 3000,  item = nil  },
    [10] = { label = "Expert Hunter",    money = 7500,  item = nil },
    [25] = { label = "Master Hunter",    money = 20000, item = nil },
    [50] = { label = "Legendary Hunter", money = 50000, item = nil  },
}

Config.Spawning = {
    MaxAnimals      = 50,
    RespawnInterval = 60,
}

Config.Settings = {
    AnimalsPerMilestone = 20,
    UseOxInventory      = false,
    EnableBlips         = true,
    EnableMarkers       = true,
    MarkerType          = 1,
    MarkerColor         = { r = 34, g = 197, b = 94, a = 150 },
    SellRadius          = 5.0,
    Currency            = "$",
}