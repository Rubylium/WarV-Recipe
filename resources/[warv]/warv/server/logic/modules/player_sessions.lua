PlayerSessions = {
    bySource = {},
    sourceByUid = {},
    nextGeneration = 0,
}

local function NextGeneration()
    PlayerSessions.nextGeneration = PlayerSessions.nextGeneration + 1
    return PlayerSessions.nextGeneration
end

local function RemoveUidIndex(session)
    local reservation = session.uid and PlayerSessions.sourceByUid[session.uid]
    if reservation and reservation.generation == session.generation then
        PlayerSessions.sourceByUid[session.uid] = nil
    end
end

function PlayerSessions.BeginConnection(source, identity)
    local previous = PlayerSessions.bySource[source]
    if previous ~= nil then
        previous.state = "closing"
        local reservation = previous.uid and PlayerSessions.sourceByUid[previous.uid] or nil
        if reservation ~= nil and reservation.generation == previous.generation then
            reservation.state = "closing"
        end
    end

    local session = {
        source = source,
        generation = NextGeneration(),
        identity = identity,
        state = "connecting",
        player = nil,
        uid = nil,
    }

    PlayerSessions.bySource[source] = session
    return session, previous
end

function PlayerSessions.StartLoading(source, identity)
    local session = PlayerSessions.bySource[source]

    if session ~= nil and session.identity.license == identity.license then
        if session.state == "loading" or session.state == "ready" then
            return session, false
        end

        session.state = "loading"
        return session, true
    end

    local newSession, previous = PlayerSessions.BeginConnection(source, identity)
    newSession.state = "loading"
    return newSession, true, previous
end

function PlayerSessions.IsCurrent(source, generation, license)
    local session = PlayerSessions.bySource[source]
    return session ~= nil
        and session.generation == generation
        and session.identity.license == license
        and session.state ~= "closing"
end

function PlayerSessions.Publish(source, generation, player)
    local session = PlayerSessions.bySource[source]
    if session == nil or session.generation ~= generation or session.state ~= "loading" then
        return false, "stale_session"
    end

    local uid = tonumber(player.uid)
    local reservation = PlayerSessions.sourceByUid[uid]
    if reservation ~= nil and reservation.generation ~= session.generation then
        return false, "uid_already_online", reservation.source
    end

    session.state = "ready"
    session.player = player
    session.uid = uid
    PlayerSessions.sourceByUid[uid] = {
        source = source,
        generation = generation,
        state = "ready",
    }
    return true
end

function PlayerSessions.Fail(source, generation)
    local session = PlayerSessions.bySource[source]
    if session == nil or session.generation ~= generation then
        return false
    end

    RemoveUidIndex(session)
    PlayerSessions.bySource[source] = nil
    return true
end

function PlayerSessions.Detach(source)
    local session = PlayerSessions.bySource[source]
    if session == nil then
        return nil
    end

    session.state = "closing"
    local reservation = session.uid and PlayerSessions.sourceByUid[session.uid] or nil
    if reservation ~= nil and reservation.generation == session.generation then
        reservation.state = "closing"
    end
    PlayerSessions.bySource[source] = nil
    return session
end

function PlayerSessions.ReleaseUid(uid, generation)
    local numericUid = tonumber(uid)
    local reservation = PlayerSessions.sourceByUid[numericUid]
    if reservation == nil or reservation.generation ~= generation then
        return false
    end

    PlayerSessions.sourceByUid[numericUid] = nil
    return true
end

function PlayerSessions.IsUidReservedByOther(uid, generation)
    local reservation = PlayerSessions.sourceByUid[tonumber(uid)]
    return reservation ~= nil and reservation.generation ~= generation
end

function PlayerSessions.GetUidReservation(uid)
    return PlayerSessions.sourceByUid[tonumber(uid)]
end

function PlayerSessions.Get(source)
    return PlayerSessions.bySource[source]
end

function PlayerSessions.GetSourceByUid(uid)
    local reservation = PlayerSessions.sourceByUid[tonumber(uid)]
    if reservation ~= nil and reservation.state == "ready" then
        return reservation.source
    end

    return nil
end
