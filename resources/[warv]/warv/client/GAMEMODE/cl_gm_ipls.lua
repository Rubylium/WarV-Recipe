Gm.Ipls = {}
Gm.Ipls.iplsToLoad = {
    "hei_carrier",
    "hei_carrier_int1",
    "hei_carrier_int1_lod",
    "hei_carrier_int2",
    "hei_carrier_int2_lod",
    "hei_carrier_int3",
    "hei_carrier_int3_lod",
    "hei_carrier_int4",
    "hei_carrier_int4_lod",
    "hei_carrier_int5",
    "hei_carrier_int5_lod",
    "hei_carrier_int6",
    "hei_carrier_int6_lod",
    "hei_carrier_lod",
    "hei_carrier_slod",

    "hei_yacht_heist",
    "hei_yacht_heist_bar",
    "hei_yacht_heist_bar_lod",
    "hei_yacht_heist_bedrm",
    "hei_yacht_heist_bedrm_lod",
    "hei_yacht_heist_bridge",
    "hei_yacht_heist_bridge_lod",
    "hei_yacht_heist_enginrm",
    "hei_yacht_heist_enginrm_lod",
    "hei_yacht_heist_lod",
    "hei_yacht_heist_lounge",
    "hei_yacht_heist_lounge_lod",
    "hei_yacht_heist_slod"
}

function Gm.Ipls.Load()
    for k,v in pairs(Gm.Ipls.iplsToLoad) do
        RequestIpl(v)
        Wait(1)
    end
end