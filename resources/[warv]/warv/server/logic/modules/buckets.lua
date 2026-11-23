Buckets = {}
Buckets.used = {}

SetRoutingBucketPopulationEnabled(0, false)

function Buckets.SetPlayer(source, id)
    SetRoutingBucketPopulationEnabled(id, false)
    SetPlayerRoutingBucket(source, id)
end

function Buckets.UseBucket(id)
    Buckets.used[id] = true
end

function Buckets.LeaveBucket(id)
    if Buckets.used[id] ~= nil then
        Buckets.used[id] = nil
    end
end

function Buckets.IsBucketUsed(id)
    return Buckets.used[id] ~= nil
end

function Buckets.GetFreeBucket()
    local bucket = math.random(1,10000)
    while Buckets.used[bucket] ~= nil do
        bucket = math.random(1,99999999)
    end
    Buckets.UseBucket(bucket)
    return bucket
end