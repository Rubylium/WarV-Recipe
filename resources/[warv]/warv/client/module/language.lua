local selectedLanguage = "EN"
local Language = {
    ["FR"] = {
        ["name"] = "Français",
        ["description"] = "Langue française",
        ["help"] = "Ceci est un message d'aide",
        ["MP_MATCH"] = "MULTIJOUEUR",
        ["CREATE_CLASS"] = "CREER UNE CLASSE",
        ["STATS"] = "STATISTIQUE",
        ["LEADERBOARD"] = "CLASSEMENT",
        ["SUPPLY_DROPS"] = "SUPPLY DROPS",
        ["MUSIC_PLAYER"] = "LECTEUR DE MUSIQUE",
        ["MATCH_HISTORY"] = "HISTORIQUE DES MATCHS",
    },
    ["EN"] = {
        ["name"] = "English",
        ["description"] = "English language",
        ["help"] = "This is a help message",
        ["MP_MATCH"] = "MULTIPLAYER MATCH",
        ["CREATE_CLASS"] = "CREATE CLASS",
        ["STATS"] = "STATS",
        ["LEADERBOARD"] = "LEADERBOARD",
        ["SUPPLY_DROPS"] = "SUPPLY DROPS",
        ["MUSIC_PLAYER"] = "MUSIC PLAYER",
        ["MATCH_HISTORY"] = "MATCH HISTORY",
    },
    ["JP"] = {
        ["name"] = "日本語",
        ["description"] = "日本語です",
        ["help"] = "これはヘルプメッセージです",
        ["MP_MATCH"] = "マルチプレイヤー対戦",
        ["CREATE_CLASS"] = "クラス作成",
        ["STATS"] = "統計",
        ["LEADERBOARD"] = "リーダーボード",
        ["SUPPLY_DROPS"] = "サプライ・ドロップ",
        ["MUSIC_PLAYER"] = "ミュージックプレーヤー",
        ["MATCH_HISTORY"] = "試合の歴史",
    },
}

function getLanguage()
    return Language[selectedLanguage]
end

function setLanguage(language)
    selectedLanguage = language
end

function getLanguageName()
    return Language[selectedLanguage]["name"]
end


function UpdateLanguage()
    if Language[selectedLanguage] ~= nil then
        for k,v in pairs(Language[selectedLanguage]) do
            AddTextEntry(k, v)
        end
    end
end
UpdateLanguage()
