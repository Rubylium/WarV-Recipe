SharedConfig.callingCards = {
    {
        id = "default",
        dict = "callingcards",
        sprite = "default",
        label = "Default",
        description = "Available to every player.",
        requirements = {},
    },
    {
        id = "level_10",
        dict = "callingcards",
        sprite = "level_10",
        label = "Level 10",
        description = "Reach level 10.",
        requirements = {
            { stat = "level", target = 10, label = "Reach level 10" },
        },
    },
    {
        id = "level_30",
        dict = "callingcards",
        sprite = "level_30",
        label = "Level 30",
        description = "Reach level 30.",
        requirements = {
            { stat = "level", target = 30, label = "Reach level 30" },
        },
    },
    {
        id = "level_55",
        dict = "callingcards",
        sprite = "level_55",
        label = "Level 55",
        description = "Reach level 55.",
        requirements = {
            { stat = "level", target = 55, label = "Reach level 55" },
        },
    },
    {
        id = "100_headshots",
        dict = "callingcards",
        sprite = "100_headshots",
        label = "100 Headshots",
        description = "Get 100 headshot eliminations.",
        requirements = {
            { stat = "headshots", target = 100, label = "Headshot eliminations" },
        },
    },
    {
        id = "500_kills",
        dict = "callingcards",
        sprite = "500_kills",
        label = "500 Kills",
        description = "Get 500 eliminations.",
        requirements = {
            { stat = "kills", target = 500, label = "Eliminations" },
        },
    },
    {
        id = "nuclear",
        dict = "callingcards",
        sprite = "nuclear",
        label = "Nuclear",
        description = "Call in a Nuke scorestreak.",
        requirements = {
            { stat = "nukes", target = 1, label = "Nukes called in" },
        },
    },
    {
        id = "ember_watch",
        dict = "callingcards",
        sprite = "ember_watch",
        label = "Ember Watch",
        description = "Available to every player.",
        requirements = {},
    },
    {
        id = "sunset_stop",
        dict = "callingcards",
        sprite = "sunset_stop",
        label = "Sunset Stop",
        description = "Available to every player.",
        requirements = {},
    },
}

SharedConfig.Animated = {}
