pico-8 cartridge // http://www.pico-8.com
version 23
__lua__

debug = true
entities = {}

function ycomparison(a,b)
    if a.position == nil or b.position == nil then return false end
    return a.position.y+a.position.h > 
           b.position.y+b.position.h
end

function sort(list, comparison)

    for i = 2,#list do
        local j = i
        while j > 1 and comparison(list[j-1], list[j]) do
            list[j], list[j-1] = list[j-1], list[j]
            j -= 1
        end
    end
end

function canwalk(x,y)
    return not fget(mget(x/8,y/8),7)
end

function touching(x1,y1,w1,h1,x2,y2,w2,h2)
    return x1+w1 > x2 and
    x1 < x2+w2 and
    y1+h1 > y2 and
    y1 < y2+h2
end

function newbounds(xoff, yoff, w, h)
    local b = {}
    b.xoff = xoff
    b.yoff = yoff
    b.w = w
    b.h = h
    return b
end

function newtrigger(xoff, yoff, w, h, f)
    local t= {}
    t.xoff = xoff
    t.yoff = yoff
    t.w = w
    t.h = h
    t.f = f
    return t
end


function newcontrol(left,right,up,down,input)
    local c = {}
    c.left = left
    c.right = right
    c.up = up
    c.down = down
    c.input = input
    return c
end

function newintention()
    local i = {}
    i.left = false
    i.right = false
    i.up = false
    i.down = false
    i.moving = false
    return i
end

function newposition(x,y,w,h)
    local p = {}
    p.x = x
    p.y = y
    p.w = w
    p.h = h
    return p
end

function newsprite(sl, i)
    local s = {}
    s.spritelist = sl
    s.index = i
    s.flip = false
    return s
end

function newentity(position,sprite,control, intention, bounds, animation, trigger)
    local e = {}
    e.position = position
    e.sprite = sprite
    e.control = control
    e.intention = intention
    e.bounds = bounds
    e.animation = animation
    e.trigger = trigger
    return e
end

function newanimation(d, t)
    local a = {}
    a.timer = 0
    a.delay = d
    a.type = t
    return a
end

function playerinput(ent)
    ent.intention.left =  btn(ent.control.left)
    ent.intention.right =  btn(ent.control.right)
    ent.intention.up =  btn(ent.control.up)
    ent.intention.down =  btn(ent.control.down)
    ent.intention.moving = ent.intention.left or ent.intention.right or 
                           ent.intention.up or ent.intention.down
end

controlsystem = {}
controlsystem.update = function()
    for ent in all(entities) do
        if ent.control ~= nil and ent.intention ~= nil then
            ent.control.input(ent)
        end
    end
end

physicssystem = {}
physicssystem.update = function()
    for ent in all(entities) do
        local newx = ent.position.x
        local newy = ent.position.y

        if ent.position ~= nil and ent.intention ~= nil then
            if ent.intention.left then newx -= 1 end
            if ent.intention.right then newx += 1 end
            if ent.intention.up then newy -= 1 end
            if ent.intention.down then newy += 1 end
        end

        local canmovex = true
        local canmovey = true

        -- map collisions -- 

        --update x position if allowd to move
        if not canwalk(newx+ent.bounds.xoff,ent.position.y+ent.bounds.yoff) or
           not canwalk(newx+ent.bounds.xoff,ent.position.y+ent.bounds.yoff+ent.bounds.h-1) or 
           not canwalk(newx+ent.bounds.xoff+ent.bounds.w-1,ent.position.y+ent.bounds.yoff) or 
           not canwalk(newx+ent.bounds.xoff+ent.bounds.w-1,ent.position.y+ent.bounds.yoff+ent.bounds.h-1) then
            canmovex = false
        end

        --update y position if allowd to move
        if not canwalk(ent.position.x+ent.bounds.xoff,newy+ent.bounds.yoff) or
           not canwalk(ent.position.x+ent.bounds.xoff,newy+ent.bounds.yoff+ent.bounds.h-1) or 
           not canwalk(ent.position.x+ent.bounds.xoff+ent.bounds.w-1,newy+ent.bounds.yoff) or 
           not canwalk(ent.position.x+ent.bounds.xoff+ent.bounds.w-1,newy+ent.bounds.yoff+ent.bounds.h-1) then
            canmovey = false
        end

        -- entity collisions -- 

        --check x
        for o in all(entities) do
            if o ~= ent and 
            touching(newx+ent.bounds.xoff, ent.position.y+ent.bounds.yoff, ent.bounds.w, ent.bounds.h,
                    o.position.x+o.bounds.xoff, o.position.y+o.bounds.yoff, o.bounds.w, o.bounds.h)then
                    canmovex = false
            end
        end

            --check y
        for o in all(entities) do
            if o ~= ent and 
            touching(ent.position.x+ent.bounds.xoff, newy+ent.bounds.yoff, ent.bounds.w, ent.bounds.h,
                    o.position.x+o.bounds.xoff, o.position.y+o.bounds.yoff, o.bounds.w, o.bounds.h)then
                    canmovey = false
            end
        end

        if canmovex then ent.position.x = newx end
        if canmovey then ent.position.y = newy end
    end
end

animationsystem = {}
animationsystem.update = function()
    for ent in all(entities) do
        if ent.sprite and ent.animation then
            if ent.animation.type == 'always' or (ent.intention and ent.animation.type == 'walk' and ent.intention.moving) then
                -- increment the animation timer 
                ent.animation.timer += 1
                -- if the timer is higher then delay then
                if ent.animation.timer > ent.animation.delay then
                    -- increment the index and reset the timer
                    ent.sprite.index += 1
                    if ent.sprite.index > #ent.sprite.spritelist then
                        ent.sprite.index = 1
                    end
                    ent.animation.timer = 0
                end
            else
                ent.sprite.index = 1
            end
        end
    end
end

triggersystem = {}
triggersystem.update = function()
    for ent in all(entities) do
        if ent.trigger and ent.position then
            for o in all (entities) do
                if o.bounds and o.position then
                    if touching(ent.position.x+ent.trigger.xoff, ent.position.y+ent.trigger.yoff, ent.trigger.w, ent.trigger.h,
                    o.position.x+o.bounds.xoff, o.position.y+o.bounds.yoff, o.bounds.w, o.bounds.h) then
                        ent.trigger.f(ent,o)
                    end
                end
            end
        end
    end
end
    

gs = {}
gs.update = function()
    cls()

    sort(entities, ycomparison)

    camera(-64+player.position.x+(player.position.w/2),
           -64+player.position.y+(player.position.h/2))
    map()

    -- draw all entities with sprites
    for ent in all(entities) do

        -- flip sprites?
        if ent.sprite and ent.intention then
            if ent.sprite.flip == false and ent.intention.left then ent.sprite.flip = true end
            if ent.sprite.flip and ent.intention.right then ent.sprite.flip = false end
        end

        if ent.sprite ~= nil and ent.position ~= nil then
            sspr(ent.sprite.spritelist[ent.sprite.index][1],
                 ent.sprite.spritelist[ent.sprite.index][2],
                 ent.position.w, ent.position.h,
                 ent.position.x, ent.position.y,
                 ent.position.w, ent.position.h,
                 ent.sprite.flip, false)
        end

        --drawing bounding boxes
        if debug then

            --bounding boxes
            if ent.position and ent.bounds then
                rect(ent.position.x+ent.bounds.xoff, 
                    ent.position.y+ent.bounds.yoff,
                    ent.position.x+ent.bounds.xoff+ent.bounds.w-1,
                    ent.position.y+ent.bounds.yoff+ent.bounds.h-1,
                    9 -- color orange
                    )
            end
            --trigger boxes
            if ent.trigger then
                rect(ent.position.x+ent.trigger.xoff,
                     ent.position.y+ent.trigger.yoff,
                     ent.position.x+ent.trigger.xoff+ent.trigger.w-1,
                     ent.position.y+ent.trigger.yoff+ent.trigger.h-1,
                     10
                    )
            end
        end
    end
    camera()
end

function _init()
    --create a player entity
    player = newentity(
        --create a position component
        newposition(10,10,4,8),
        --create a sprite component
        newsprite({{8,0},{12,0},{16,0},{20,0}},1),
        --create a control component
        newcontrol(0,1,2,3, playerinput),
        --create a intention component
        newintention(),
        --create a bounding box component
        newbounds(0,6,4,2),
        --create a animation component
        newanimation(3, 'walk'),
        --create a trigger component
        nil
    )
    add(entities,player)

    --create a tree entity
    add(entities, newentity(
        newposition(20,20,16,16),
        newsprite({{8,16}},1),
        nil,
        nil,
        newbounds(6,12,4,4),
        nil,
        nil
    )
    )

    --create a shop entity
    add(entities, newentity(
        newposition(36,40,16,16),
        newsprite({{40,0}},1),
        nil,
        nil,
        newbounds(0,8,16,8),
        nil,
        newtrigger(9,16,5,3,function(self, other) if other == player then other.position.x = 10 other.positiony = 10 end end)
    )
    )

end

function _update()
    --check player input
    controlsystem.update()
    --move entities
    physicssystem.update()
    --animate entities
    animationsystem.update()
    --check triggers
    triggersystem.update()
end

function _draw()
    gs.update()
end

__gfx__
0000000088888888888888880000000000000000000000055500000033333333cccccccccccc33333333cccc3333cccccccc3333333333333333333333333333
000000008fff8fff8fff8fff0000000000000000000000555550000033333333cccccccccc333333333333cc33cccccccccccc33333443333334433333344333
007007008fff8fff8fff8fff0000000000000000000005555555000033333333ccccccccc33333333333333c3cccccccccccccc3334554333345543333455433
0007700081118111811181110000000000000000000055555555500033333333ccccccccc33333333333333c3cccccccccccccc3345445444454454344544544
0007700011111111111111110000000000000000000555555555550033333333cccccccc3333333333333333cccccccccccccccc345445444454454344544544
0070070011f1111f11f11f110000000000000000005555555555555033333333cccccccc3333333333333333cccccccccccccccc334554333345543333455433
0000000011111111111111110000000000000000055555555555555533333333cccccccc3333333333333333cccccccccccccccc333443333334433333344333
0000000002202020020000020000000000000000555555555555555533333333cccccccc3333333333333333cccccccccccccccc333443333334433333333333
0000000000000000000000000000000000000000444444444444444433333333cccccccc3333333333333333cccccccccccccccc333443333334433333344333
0000000000000000000000000000000000000000444444444444444433733333cccc55cc3333333333333333cccccccccccccccc333443333334433333344333
0000000000000000000000000000000000000000446666664555554437773333cc5555cc3333333333333333cccccccccccccccc334554333345543333455433
0000000000000000000000000000000000000000446676664566654433733333cc5555cc3333333333333333cccccccccccccccc345445444454454334544543
00000000000000000000000000000000000000004467666645666544333333a3cc555dccc33333333333333c3cccccccccccccc3345445444454454334544543
0000000000000000000000000000000000000000446666664555554433333333c7ddd77cc33333333333333c3cccccccccccccc3334554333345543333455433
000000000000000000000000000000000000000044444444455565443333a333c77777cccc333333333333cc33cccccccccccc33333443333334433333344333
0000000000000000000000000000000000000000444444444555554433333333cccccccccccc33333333cccc3333cccccccc3333333333333333333333344333
000000000000bbbbbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006677667756555555
000000000000b0bbbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006677667756555555
00000000000bbbb00bbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007766776656555555
000000000000bbbbbbb00b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007766776666666666
00000000000bbbb0bbbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006677667755555655
000000000000bb0bbbbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006677667755555655
0000000000000bbbbb04000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007766776655555655
00000000000000bbb004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007766776666666666
00000000000000044040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000044400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000044000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000044000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000044444444
00000000000000044000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000044444444
00000000000000044000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000044444444
00000000000000444400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000004444440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000000000000800080808080808000008080000000008000008080808080000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0d0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0e2f2f2f2f2f2f2f2f2f2f2f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1f070707070717070707070707070707070707071f2f2e2e2e2e2e2e2e2e2e2f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1f070707070707070707070707070707070707071f2f2e2e2e2e2e2e2e2e2e2f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1f070707070707071a0b0c1907070707070707071f2f2e2e2e2e2e2e2e2e2e2f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1f0707070707071a0b1808080c070707070717071f2f2e2e2e2e2e2e2e2e2e2f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1f0707070707070b080808181c070707070707071f2f2e2e2e2e2e2e2e2e2e2f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1f070707070707080808081c09070707070707071f2f2e2e2e2e2e2e2e2e2e2f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1f0707070717071b181c090707070707070707071f2f2f2f2f2f2f2f3f3f2f2f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1f070707070707070707070707070707170707071f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1f070707070707070707070707070707070707071f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1d0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f1e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
