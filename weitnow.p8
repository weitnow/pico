pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
--variables

function _init()
	player={
		sp=1,
		x=659,
		y=59,
		w=8,
		h=8,
		flp=false,
		dx=0,
		dy=0,
		max_dx=2,
		max_dy=3,
		acc=0.5,
		boost=4,
		anim=0,
  running=false,
  falling=false,
  sliding=false,
  landed=false,
  punching=false,
	}
	gravity=0.3
	friction=0.85

	--simple camera
	cam_x = 0

	walking_sound = 5

	--map limits
	map_start = 0
	map_end=1024

	-------------test------
	x1r=0 y1r=0 x2r=0 y2r=0
	collide_l = "no"
	collide_r = "no"
	collide_u = "no"
	collide_d = "no"
	-----------------------

 music(0)

end

-->8
--update and draw

function _update()
	player_update()
	player_animate()

	--simple camera
	cam_x=player.x-64+(player.w/2)
	
	if cam_x < map_start then
		cam_x = map_start
	elseif cam_x > map_end - 128 then
		cam_x = map_end - 128
	end
	camera(cam_x,0)
end

function _draw()
	cls()
	map(0,0)
	spr(player.sp,player.x,player.y,1,1,player.flp)

	-------test---------
	rect(x1r, y1r, x2r, y2r, 7)
	print("⬅️= " .. collide_l, player.x, player.y-10)
	print("➡️= " .. collide_r, player.x, player.y-16)
	print("⬆️= " .. collide_u, player.x, player.y-22)
	print("⬇️= " .. collide_d, player.x, player.y-28)
	--------------------
end
-->8
--collisions

function collide_map(obj,aim,flag)
	--obj = table needs x,y,w,h
	--aim = left,right,up,down
	
	local x=obj.x local y = obj.y
	local w=obj.w local h = obj.h

	local x1=0	local y1=0
	local x2=0	local y2=0

	if aim=="left" then
		x1=x-1		y1=y
		x2=x		y2=y+h-1

	elseif aim=="right" then
		x1=x+w-1	y1=y
		x2=x+w		y2=y+h-1

	elseif aim=="up" then
		x1=x+1		y1=y-1
		x2=x+w-2	y2=y
	
	elseif aim=="down" then
		x1=x+2		y1=y+h
		x2=x+w-2	y2=y+h
	end

	-----test-----draw collision shap to screen ------
	x1r = x1; y1r = y1; 
	x2r = x2; y2r = y2;
	-------------------------------------------------

	--pixels to tiles
	x1/=8	y1/=8
	x2/=8	y2/=8

	if fget(mget(x1,y2), flag )
	or fget(mget(x1,y1), flag )
	or fget(mget(x2,y1), flag )
	or fget(mget(x2,y2), flag ) then
		return true
	else
		return false
	end
end

-->8
--player

function player_update()
	--adjust physics to map-enviroment accordingly

	
	if collide_map(player,"down",2) then -- if player collides with sand-tiles then
		friction=0.50
		player.boost=2.5
	elseif collide_map(player, "down", 3) then -- if player collides with ice-tile then
		friction=0.94
		player.max_dx=3
	else friction=0.85 -- default setting
		player.boost=4
		player.max_dx=2
	end
	




	--physics
	player.dy+=gravity
	player.dx*=friction

	--controls
	if btn(0) then
		player.dx-=player.acc
		player.dx=limit_speed(player.dx, player.max_dx)
		player.running=true
		player.flp=true
		play_walk_sound()
	end
	if btn(1) then
		player.dx+=player.acc
		player.dx=limit_speed(player.dx, player.max_dx)
		player.running=true
		player.flp=false
		play_walk_sound()
	end
	if btn(5) then
		player.punching=true
	else
		player.punching=false
	end

	function play_walk_sound()
		if player.landed then
			if walking_sound == 5 then
				sfx(6)
				walking_sound -= 0.5
			elseif walking_sound < 0 then 
				walking_sound = 5
			else
				walking_sound -= 0.5
			end
		end
	end

	--slide
	if player.running 
	and not btn(0)
	and not btn(1)
	and not player.falling
	and not player.jumping then
		player.running=false
		player.sliding=true
	end

	--jump
	if btnp(2)
	and player.landed then
		player.dy-=player.boost
		player.landed = false
		sfx(4)	
	end

	--check collision up and down
	if player.dy>0 then --if player moving downwards
		player.falling = true
		player.landed=false
		player.jumping=false

		player.dy=limit_speed(player.dy, player.max_dy)
		if collide_map(player, "down", 0) then
			player.landed=true
			player.falling=false
			player.dy=0
			player.y-=((player.y+player.h+1)%8)-1

			--------test--------
			collide_d="yes"
			else collide_d="no"
			-------------------
		end
	elseif player.dy<0 then -- if player moving updwards
		player.jumping=true
		if collide_map(player, "up", 1) then
			player.dy=0

			--------test--------
			collide_u="yes"
			else collide_u="no"
			-------------------
		end
	end

	--check collision left and right
	if player.dx < 0 then 
		player.dx=limit_speed(player.dx, player.max_dx)
		if collide_map(player, "left", 1) then
			player.dx = 0

			--------test--------
			collide_l="yes"
			else collide_l="no"
			-------------------
		end
	elseif player.dx > 0 then
		player.dx=limit_speed(player.dx, player.max_dx)
		if collide_map(player, "right", 1) then
			player.dx = 0

			--------test--------
			collide_r="yes"
			else collide_r="no"
			-------------------
		end
	end

	-- stop sliding
	if player.sliding then
		if abs(player.dx)<.2
		or player.running then
			player.dx = 0
			player.sliding = false
		end
	end

	player.x += player.dx
	player.y += player.dy

	--limit player to map
	if player.x <= map_start then
		player.x = map_start
	elseif player.x >= map_end - player.w then
		player.x = map_end - player.w
	end
end

function player_animate()
	printh(player.sp)
	if player.punching then
		if player.sp ~= 17
		or player.sp ~= 18 
		or player.sp ~= 19 then
			player.sp = 17

		end
		if time()-player.anim>0.3 then
			player.anim=time()
			player.sp+=1
			player.sp = 19
		end
	
	elseif player.jumping then
		player.sp=7
	elseif player.falling then
		player.sp=8
	elseif player.sliding then
		player.sp=9
	elseif player.running then
		if time()-player.anim>.1 then
			player.anim=time()
			player.sp+=1
			if player.sp>6 then
				player.sp=3
			end
		end
	else --player idle
		if time()-player.anim>.5 then
			player.anim=time()
			player.sp+=1
			if player.sp>2 then
				player.sp=1
			end
		end
	end
end

function limit_speed(num, maximum)
	return mid(-maximum, num, maximum) -- mid always return the middle, so if -5 6 5..it will order it like -5 5 6 and return 5
end
__gfx__
0000000000444440004444400004444400044444000444440004444400044444c004444400000000000000000000000000000000000000000000000000000000
0000000000ccccc000ccccc00ccccccc0c0cccccc00cccccc0cccccc00cccccc0ccccccc04444400000000000000000000000000000000000000000000000000
007007000cf72f200cf72f20c00ff72fc0cff72f0ccff72f0c0ff72f0c0ff72f000ff72f0ccccc00000000000000000000000000000000000000000000000000
000770000cfffff00cfffef0000ffffe000ffffe000ffffe000ffffec00ffffe000ffffecf72f200000000000000000000000000000000000000000000000000
00077000000cc00000cccc000fccc0000fccc0000fccc0000fccc00000ccc0000000ccc0cfffef00000000000000000000000000000000000000000000000000
0070070000cccc000f0cc0f0000cc000000cc000000cc000000cc0000f0cc0000000cc0f00ccccf0000000000000000000000000000000000000000000000000
000000000f0cd0f0000cd0000cc0d00000cd00000dd0c00000dc000000dc000000000cd00f0ccd00000000000000000000000000000000000000000000000000
0000000000c00d0000c00d000000d00000cd00000000c00000dc00000dcc0000000000cd0000ccdd000000000000000000000000000000000000000000000000
00000000004444400044444000444440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000ccccc000ccccc000ccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000cf72f200cf72f200cf72f20000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000cfffff0c0fffff00cfffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000ccccf000ccc80000ccccf000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000fcc000000cc800000cc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000cd000000cd000000cd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000c00d0000c00d0000c00d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbbbbbbbbbb00bbbbbbbbbbbb00f999999ff999999fcc7cccccccc7cccc00000000000000000000000000000000000000000000000000000000
3bbb3bbb3bbb3bbbb333bb3b0bbb3bb3b333bbb09ff99ff99ff99ff9c7cccc7ccc7ccc7c00000000000000000000000000000000000000000000000000000000
33b333b33bb343b3bbb33333bbb333333b33bbbb999ff999999ff9997cccc7ccc7ccc7cc00000000000000000000000000000000000000000000000000000000
4b3444343bb444343b343434bb33333433333bbb999999999999f999cccc7ccccccccccc00000000000000000000000000000000000000000000000000000000
4b3424443b3449443b344434bb334444333433bbf9ffff9ff9ff9f997cccccc7ccccccc700000000000000000000000000000000000000000000000000000000
43444444434444444344444433344449434444334f9999f44f999ff4477cc774777ccc7400000000000000000000000000000000000000000000000000000000
44444d44444444444449444d344444444444444d4499994444999944447777444477774400000000000000000000000000000000000000000000000000000000
49444444444d447444444444444c4444464444444444444444444444444774444444444400000000000000000000000000000000000000000000000000000000
4444444444444444444444440000000000000000bbb9999ff99999bbbbbcccc66cccccbb00000000000000000000000000000000000000000000000000000000
4444444444444444444c44440000000000000000bbb99ff99ff99333bbbcc66cc66cc33300000000000000000000000000000000000000000000000000000000
44494444444444449444474400000000000000003b3ff999999ff4443b366cccccc6644400000000000000000000000000000000000000000000000000000000
4744444444454444444447740000000000000000439999999999444443cccccccccc444400000000000000000000000000000000000000000000000000000000
4444444445665444444476440000000000000000444fff9ff9ff4444444666c66c66444400000000000000000000000000000000000000000000000000000000
44444464445664444477644400000000000000004c4449f44f4444944c444c644644449400000000000000000000000000000000000000000000000000000000
444444444445544444474444000000000000000044444444444c444444444444444c444400000000000000000000000000000000000000000000000000000000
44e44444444444444444444400000000000000004444e474444444444444e4744444444400000000000000000000000000000000000000000000000000000000
33333333333333334444444444444444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbb3bbbbb3bbbbb9999499999499999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b3bbbbbbb3bbbbbb9499999994999999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33333333333333334444444444444444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b3bbbb3bbbbb3bbb9499994999994999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bb3bbb3bbbbbb3bb9949994999999499000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33333333333333334444444444444444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
003bb300000000000049940000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
003bb300000330000049940000033000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
003b3300003bb3000049440000499400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
003bb300003b33000049940000494400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0033b300003bb3000044940000499400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
003bb300003bb3000049940000499400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
003bb3000033b3000049940000449400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
003bb300003bb3000049940000499400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
003b3300003b33000049440000494400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000030303030307070b0b00000000000000030303000007070b0b000000000000000101010100000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
7171000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7070000000000000000000000000000000000000000000000000000000000000000000000000616161606061616100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7070000000000000000000000000000000000000000000000000000000000000000000000000000000707000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7070000000000000000000000000000000000000000000000000000000000000000000000000000000606000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7070000000000000000000000000000000000000000000000000000000000000000000000000000000707000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7070000000000000000000000000000000000000000000000000000000000000000000000000000000606000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7070000000000000000000000000000000000000000000000000000000000000000000000000000000707000000000000000000000000000006363000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7070000000000000000000000000000000000000000000000073000000004242424242004242000000606000000000000000000000000000636363630000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7070000073000000000000000000000000000000000000000072000000005050505051005050000000707000000000000000000000000063630000636300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7070636262000000007100000000000000000063626300000072000000005052505050005150000000606000000000000000000000006363000000006363000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7070007272000000616061606100000000000000720000000072000000005050505050005050000000707000000000000000000000636300000000000063630000000000000000000060600000616100000061610000616100616161610000000000000000000000000000000000000000000000000000000000000000000000
7070004344000000007000700000000000000000720000000072000000000000000000000000000000606000000000000000000063630000007070000000636300000000000000000070700000000000000000000000000000707000000000000000000000000000007070000000000000000000000000000070700000000000
7070435150440000007000700000007100000000724342440072000000000000000000000000000000707000000000000000006363000000007070000000006363000000000000000070700000000000000000000000000000707000000000000000000000000000007070000000000000000000000000000070700000000000
4041505052504241414042424240424240414242415152504042414240414140414240404140424041404242404141404142404041404240414042424041414041424040414042404140424240414140414240404140424041404242404141554546454645464546564042424057474847484748475842404140424240414140
5050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050
__sfx__
011800000c043000000000000000246150000000000000000c043000000000000000246150000000000000000c043000000000000000246150000000000000000c04300000000000000024615000000000000000
011800000010000100001000010000100001000010000100001000010000100001000010000100001000010000000000000000000000000000000000000000000000000000000000000000000000000000000000
01180000000000f0551204514035160250d0150f0551204514035160250d0150000000000000000000000000000000f0551204514035160250d0150f0551204514035160250d0150000000000000000000000000
011800000345506345082350a4250d3150325506445083350a3250d215084000a400296332762300000000000345506345082350a4250d3150325506445083350a3250d215000000000029633276230000000000
0103000020030200301f3301f3301f3301f33020330213302333024330253302633027330293302b3302c33000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300002b660276602465022650206401e6301b620186201662013610116100e6100c6100a610096000860008600396000760000000000000000000000000000000000000000000000000000000000000000000
010300002261022610226102261000000126101261000000000000000000000000000000022610226100000012620126200000000000000000000000000000000000000000000000000000000000000000000000
__music__
03 00010203

