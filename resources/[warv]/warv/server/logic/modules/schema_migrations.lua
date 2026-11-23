SchemaMigrations = {
    status = "pending",
}

local function Query(query, parameters)
    local success, result, errorMessage = Db.Query(query, parameters)
    if not success then
        error(errorMessage or "query failed")
    end

    return result or {}
end

local function Execute(query, parameters)
    local success, _, errorMessage = Db.Update(query, parameters)
    if not success then
        error(errorMessage or "update failed")
    end
end

local function HasColumn(tableName, columnName)
    local result = Query(
        "SELECT 1 FROM `information_schema`.`COLUMNS` WHERE `TABLE_SCHEMA` = DATABASE() AND `TABLE_NAME` = ? AND `COLUMN_NAME` = ? LIMIT 1",
        {tableName, columnName}
    )
    return next(result) ~= nil
end

local function HasUniqueChallengeEntryIndex()
    local result = Query([[
        SELECT `INDEX_NAME`
        FROM `information_schema`.`STATISTICS`
        WHERE `TABLE_SCHEMA` = DATABASE()
          AND `TABLE_NAME` = 'warv_challenges'
          AND `NON_UNIQUE` = 0
        GROUP BY `INDEX_NAME`
        HAVING COUNT(*) = 3
           AND SUM(CASE WHEN `COLUMN_NAME` = 'uid' THEN 1 ELSE 0 END) = 1
           AND SUM(CASE WHEN `COLUMN_NAME` = 'period' THEN 1 ELSE 0 END) = 1
           AND SUM(CASE WHEN `COLUMN_NAME` = 'challenge' THEN 1 ELSE 0 END) = 1
        LIMIT 1
    ]])
    return next(result) ~= nil
end

local function EnsureChallengesTable()
    Execute([[
        CREATE TABLE IF NOT EXISTS `warv_challenges` (
            `id` INT(11) NOT NULL AUTO_INCREMENT,
            `uid` INT(11) NOT NULL,
            `period` VARCHAR(8) NOT NULL,
            `challenge` VARCHAR(48) NOT NULL,
            `progress` INT(11) NOT NULL DEFAULT 0,
            `completed` TINYINT(1) NOT NULL DEFAULT 0,
            PRIMARY KEY (`id`),
            UNIQUE KEY `entry` (`uid`, `period`, `challenge`),
            KEY `uid_period` (`uid`, `period`),
            CONSTRAINT `challenges_uid_fk`
                FOREIGN KEY (`uid`) REFERENCES `users` (`id`)
                ON DELETE CASCADE ON UPDATE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8
    ]])

    if HasUniqueChallengeEntryIndex() then
        return
    end

    local duplicates = Query([[
        SELECT `uid`, `period`, `challenge`, COUNT(*) AS `count`
        FROM `warv_challenges`
        GROUP BY `uid`, `period`, `challenge`
        HAVING COUNT(*) > 1
        LIMIT 25
    ]])

    if next(duplicates) ~= nil then
        error("duplicate challenge rows: " .. json.encode(duplicates))
    end

    InfoPrint("Migration: unique [warv_challenges.uid/period/challenge]")
    Execute(
        "ALTER TABLE `warv_challenges` ADD UNIQUE KEY `entry` (`uid`, `period`, `challenge`)"
    )
end

local function EnsureAssistColumn()
    if HasColumn("warv", "assist") then
        return
    end

    InfoPrint("Migration: column [warv.assist]")
    Execute("ALTER TABLE `warv` ADD COLUMN `assist` BIGINT NOT NULL DEFAULT 0 AFTER `kill`")
end

local function EnsurePermissionLevelColumn()
    if HasColumn("users", "permissionLevel") then
        return
    end

    InfoPrint("Migration: column [users.permissionLevel]")
    Execute(
        "ALTER TABLE `users` ADD COLUMN `permissionLevel` INT NOT NULL DEFAULT 0 AFTER `public_api`"
    )

    if HasColumn("users", "staff") then
        InfoPrint("Migration: [users.staff] -> [users.permissionLevel]")
        Execute(
            "UPDATE `users` SET `permissionLevel` = `staff` WHERE `staff` > `permissionLevel`"
        )
    end
end

local function HasUniqueUserIdentifierIndex()
    local result = Query([[
        SELECT `INDEX_NAME`
        FROM `information_schema`.`STATISTICS`
        WHERE `TABLE_SCHEMA` = DATABASE()
          AND `TABLE_NAME` = 'users'
          AND `NON_UNIQUE` = 0
        GROUP BY `INDEX_NAME`
        HAVING COUNT(*) = 1
           AND MAX(CASE WHEN `COLUMN_NAME` = 'identifier' THEN 1 ELSE 0 END) = 1
        LIMIT 1
    ]])
    return next(result) ~= nil
end

local function EnsureUniqueUserIdentifiers()
    if HasUniqueUserIdentifierIndex() then
        return
    end

    local duplicates = Query([[
        SELECT `identifier`, COUNT(*) AS `count`, GROUP_CONCAT(`id` ORDER BY `id`) AS `userIds`
        FROM `users`
        GROUP BY `identifier`
        HAVING COUNT(*) > 1
        LIMIT 25
    ]])

    if next(duplicates) ~= nil then
        error("duplicate users.identifier: " .. json.encode(duplicates))
    end

    InfoPrint("Migration: unique [users.identifier]")
    Execute("ALTER TABLE `users` ADD UNIQUE KEY `users_identifier_unique` (`identifier`)")
end

function SchemaMigrations.WaitUntilReady(timeout)
    local waited = 0
    while SchemaMigrations.status == "pending" and waited < timeout do
        Wait(50)
        waited = waited + 50
    end
    return SchemaMigrations.status == "ready"
end

Citizen.CreateThread(function()
    local ok, err = pcall(function()
        EnsureChallengesTable()
        EnsureAssistColumn()
        EnsurePermissionLevelColumn()
        EnsureUniqueUserIdentifiers()
    end)

    if ok then
        SchemaMigrations.status = "ready"
        return
    end

    SchemaMigrations.status = "failed"
    CriticalPrint("Migration failed: " .. tostring(err))
end)
