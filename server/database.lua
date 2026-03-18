local function CreateTables()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `hunting_players` (
            `identifier` VARCHAR(60) NOT NULL,
            `name` VARCHAR(100) DEFAULT 'Unknown',
            `total_sold` INT DEFAULT 0,
            `milestones` INT DEFAULT 0,
            `current_cycle` INT DEFAULT 0,
            `total_earnings` BIGINT DEFAULT 0,
            `cash` BIGINT DEFAULT 0,
            `animals_data` LONGTEXT DEFAULT '{}',
            `last_seen` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`identifier`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
end

CreateTables()

function DB_LoadPlayer(identifier, callback)
    MySQL.query('SELECT * FROM hunting_players WHERE identifier = ?', { identifier }, function(result)
        if result and result[1] then
            local data = result[1]
            data.animals_data = json.decode(data.animals_data) or {}
            callback(data)
        else
            MySQL.query(
                'INSERT INTO hunting_players (identifier) VALUES (?)',
                { identifier },
                function()
                    callback({
                        identifier     = identifier,
                        total_sold     = 0,
                        milestones     = 0,
                        current_cycle  = 0,
                        total_earnings = 0,
                        cash           = 0,
                        animals_data   = {},
                    })
                end
            )
        end
    end)
end

function DB_SavePlayer(identifier, data)
    MySQL.query([[
        UPDATE hunting_players
        SET total_sold = ?, milestones = ?, current_cycle = ?,
            total_earnings = ?, cash = ?, animals_data = ?, name = ?
        WHERE identifier = ?
    ]], {
        data.total_sold,
        data.milestones,
        data.current_cycle,
        data.total_earnings,
        data.cash or 0,
        json.encode(data.animals_data or {}),
        data.name or "Unknown",
        identifier
    })
end

function DB_GetLeaderboard(callback)
    MySQL.query(
        'SELECT name, total_sold, milestones, total_earnings FROM hunting_players ORDER BY total_sold DESC LIMIT 10',
        {},
        function(result)
            callback(result or {})
        end
    )
end
