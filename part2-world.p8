pico-8 cartridge // http://www.pico-8.com
version 23
__lua__

debug = true

outside = {}
outside.x  = 0 -- in tiles
outside.y = 0
outside.w = 21
outside.h = 11
outside.bg = 3

shop = {}
shop.x = 21 -- in tiles
shop.y = 0 
shop.w = 11
shop.h = 8
shop.bg = 2

currentroom = outside

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

function newinventory(s,v,x,y,items)
    local i = {}
    i.size = s
    i.x = x
    i.y = y
    i.items = items
    return i
end

function newdialogue()
    local d = {}
    d.text = {}
    d.timed = false
    d.timerremaining = 0
    d.cursor = 0
    d.set = function(text, timed)
        d.text[0] = sub(text,0,15)
        d.text[1] = sub(text,16,#text)
        d.timed = timed
        d.cursor = 0
        if timed then d.timerremaining = 75 end
    end
    return d
end

function newbounds(xoff, yoff, w, h)
    local b = {}
    b.xoff = xoff
    b.yoff = yoff
    b.w = w
    b.h = h
    return b
end

function newtrigger(xoff, yoff, w, h, f, type)
    local t= {}
    t.xoff = xoff
    t.yoff = yoff
    t.w = w
    t.h = h
    t.f = f
    -- type ='once' 'always' and 'wait'
    t.type = type
    t.active = false
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

function newentity(compontenttable)
    local e = compontenttable
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
        if ent.position and ent.bounds then
            local newx = ent.position.x
            local newy = ent.position.y

            if ent.intention then
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
                if o ~= ent and o.position and o.bounds and
                touching(newx+ent.bounds.xoff, ent.position.y+ent.bounds.yoff, ent.bounds.w, ent.bounds.h,
                        o.position.x+o.bounds.xoff, o.position.y+o.bounds.yoff, o.bounds.w, o.bounds.h)then
                        canmovex = false
                end
            end

                --check y
            for o in all(entities) do
                if o ~= ent and o.position and o.bounds and
                touching(ent.position.x+ent.bounds.xoff, newy+ent.bounds.yoff, ent.bounds.w, ent.bounds.h,
                        o.position.x+o.bounds.xoff, o.position.y+o.bounds.yoff, o.bounds.w, o.bounds.h)then
                        canmovey = false
                end
            end

            if canmovex then ent.position.x = newx end
            if canmovey then ent.position.y = newy end
        end
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

dialoguesystem = {}
dialoguesystem.update = function()
    for ent in all(entities) do
        if ent.dialogue and ent.dialogue.text[0] then

            -- calculate length of text
            local len = #ent.dialogue.text[0]
            if #ent.dialogue.text[1] then
                len += #ent.dialogue.text[1]
            end

            if ent.dialogue.cursor < len then 
                ent.dialogue.cursor += 1
            end
            if ent.dialogue.timed and 
            ent.dialogue.timerremaining > 0 then
                ent.dialogue.timerremaining -= 1
            end
        end
    end
end

triggersystem = {}
triggersystem.update = function()
    for ent in all(entities) do
        if ent.trigger and ent.position then
            local triggered = false
            for o in all (entities) do
                if ent ~= o and o.bounds and o.position and ent.trigger then
                    if touching(ent.position.x+ent.trigger.xoff, ent.position.y+ent.trigger.yoff, ent.trigger.w, ent.trigger.h,
                    o.position.x+o.bounds.xoff, o.position.y+o.bounds.yoff, o.bounds.w, o.bounds.h) then
                        --trigger is actiated
                        triggered = true
                        
                        if ent.trigger.type=='once' then
                            ent.trigger.f(ent,o)
                            ent.trigger = nil
                        
                        elseif ent.trigger.type=='always' then
                            ent.trigger.f(ent,o)
                            ent.trigger.active = true

                        elseif ent.trigger.type=='wait' then
                            if ent.trigger.active == false then
                                ent.trigger.f(ent,o)
                                ent.trigger.active = true
                            end
                        end
                    end
                end
            end
            if triggered == false then 
                ent.trigger.active = false
            end
        end
    end
end
    

gs = {}
gs.update = function()
    cls()
    sort(entities, ycomparison)

    local camerax = -64+player.position.x+(player.position.w/2)
    local cameray = -64+player.position.y+(player.position.h/2)

    camera(camerax,cameray)
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
                local color = 10
                if ent.trigger.active then color = 11 end
                rect(ent.position.x+ent.trigger.xoff,
                     ent.position.y+ent.trigger.yoff,
                     ent.position.x+ent.trigger.xoff+ent.trigger.w-1,
                     ent.position.y+ent.trigger.yoff+ent.trigger.h-1,
                     color
                    )
            end
        end
    end

    camera()

    --top border
    rectfill(-1,-1,128,(currentroom.y*8)-cameray-1,currentroom.bg)
    --left border
    rectfill(-1,-1,(currentroom.x*8)-camerax-1,128,currentroom.bg)
    --reight border
    rectfill((currentroom.x+currentroom.w)*8-camerax,-1,128,128,currentroom.bg)
    --bottom border
    rectfill(-1, (currentroom.y+currentroom.h)*8-cameray,128,128,currentroom.bg)

    camera(camerax,cameray)

    -- draw dialogue boxes
    for ent in all(entities) do
        if ent.dialogue and ent.position then
            if ent.dialogue.text[0] then
                if (ent.dialogue.timed == false) or (ent.dialogue.timed and ent.dialogue.timerremaining > 0) then
                    --draw line 1
                    local textdraw = sub(ent.dialogue.text[0],0,ent.dialogue.cursor)
                    --draw the outline
                    for x=-1,1 do
                        for y=-1,1 do
                            print(textdraw,ent.position.x - 10+x,ent.position.y - 10+y-8,0)
                        end
                    end

                    --draw text
                    print(textdraw,ent.position.x - 10,ent.position.y - 10-8,7)

                    --draw line 2
                    if #ent.dialogue.text[1] then
                         local textdraw = sub(ent.dialogue.text[1],0,max(0,ent.dialogue.cursor - #ent.dialogue.text[0]))
                        --draw the outline
                        for x=-1,1 do
                            for y=-1,1 do
                                print(textdraw,ent.position.x - 10+x,ent.position.y - 10+y,0)
                            end
                        end
                         --draw text
                        print(textdraw,ent.position.x - 10,ent.position.y - 10,7)
                    end

                end
            end
        end
    end

    camera()
    
end

function _init()
    --create a player entity
    player = newentity({
        --create a position component
        position = newposition(10,10,4,8),
        --create a sprite component
        sprite = newsprite({{8,0},{12,0},{16,0},{20,0}},1),
        --create a control component
        control = newcontrol(0,1,2,3, playerinput),
        --create a intention component
        intention = newintention(),
        --create a bounding box component
        bounds = newbounds(0,6,4,2),
        --create a animation component
        animation = newanimation(3, 'walk'),
        --dialogue component
        dialogue = newdialogue()
    })
    add(entities,player)

    --create a tree entity
    add(entities, newentity({
        position = newposition(20,20,16,16),
        sprite = newsprite({{8,16}},1),
        bounds = newbounds(6,12,4,4),
        trigger = newtrigger(4,10,8,8,
            function(self, other)
                if other == player then
                    other.dialogue.set("oh look, a tree! Beautiful", true)
                end
            end, 'wait')
    })
    )

    --create a shop entity
    add(entities, newentity({
        position = newposition(36,40,16,16),
        sprite = newsprite({{40,0}},1),
        bounds = newbounds(0,8,16,8),
        trigger = newtrigger(9,16,5,3,
            function(self, other) 
                if other == player then
                    currentroom = shop 
                    other.position.x = 230 
                    other.position.y = 50 
                end 
            end, 'always')
    })
    )

    --create a shop door exit trigger entity
    add(entities, newentity({
        position = newposition(224,62,16,3),
        trigger = newtrigger(0,0,16,3,
            function(self, other) 
                if other == player then 
                    currentroom = outside
                    other.position.x = 45 
                    other.position.y = 55
                end 
            end, 'always')
    })
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
    -- update dialogue
    dialoguesystem.update()
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
