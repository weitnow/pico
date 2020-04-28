pico-8 cartridge // http://www.pico-8.com
version 18
__lua__

function _init()
    player={
        sp=1,
        x=59,
        y=59
    }

    --music(0)
end

function _update()


end
function _draw()
    cls()
    print("time() -> " .. time() , 10, 10)
    print("time() -> " .. time() , 10, 20)
    spr(player.sp, player.x, player.y, 1, 1)
end

__gfx__
00000000000080000008800008888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000880000080080000000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700008080000800008000000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000080000000080008888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000080000000800000000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000080000008000000000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000080000080000008888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000080000888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
011800000c043000000000000000246150000000000000000c043000000000000000246150000000000000000c043000000000000000246150000000000000000c04300000000000000024615000000000000000
011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01180000000000f0551204514035160250d0150f0551204514035160250d0150000000000000000000000000000000f0551204514035160250d0150f0551204514035160250d0150000000000000000000000000
011800000345506345082350a4250d3150325506445083350a3250d215084000a400296332762300000000000345506345082350a4250d3150325506445083350a3250d215000000000029633276230000000000
__music__
03 00010203

