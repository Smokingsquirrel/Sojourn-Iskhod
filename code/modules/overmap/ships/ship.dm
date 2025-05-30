/obj/effect/overmap/ship
	name = "generic ship"
	desc = "Space faring vessel."
	icon_state = "ship"
	var/vessel_mass = 100 				//tonnes, arbitrary number, affects acceleration provided by engines
	var/default_delay = 6 SECONDS 		//time it takes to move to next tile on overmap
	var/speed_mod = 10					//multiplier for how much ship's speed reduces above time
	var/list/speed = list(0,0)			//speed in x,y direction
	var/last_burn = 0					//worldtime when ship last acceleated
	var/burn_delay = 10					//how often ship can do burns
	var/list/last_movement = list(0,0)	//worldtime when ship last moved in x,y direction
	var/fore_dir = NORTH				//what dir ship flies towards for purpose of moving stars effect procs

	var/obj/machinery/computer/helm/nav_control
	var/list/engines = list()
	var/engines_state = 1 //global on/off toggle for all engines
	var/thrust_limit = 1 //global thrust limit for all engines, 0..1
	var/triggers_events = 1


	Crossed(var/obj/effect/overmap_event/movable/ME)
		..()
		if(ME)
			if(istype(ME, /obj/effect/overmap_event/movable))
				if(ME.OE)
					if(istype(src, /obj/effect/overmap/ship))
						ME.OE:enter(src)

	Uncrossed(var/obj/effect/overmap_event/movable/ME)
		..()
		if(ME)
			if(istype(ME, /obj/effect/overmap_event/movable))
				if(ME.OE)
					if(istype(src, /obj/effect/overmap/ship))
						ME.OE:leave(src)

/obj/effect/overmap/ship/Initialize()
	. = ..()
	for(var/datum/ship_engine/E in ship_engines)
		if (E.holder.z in map_z)
			engines |= E
	for(var/obj/machinery/computer/engines/E in GLOB.computer_list)
		if (E.z in map_z)
			E.linked = src
			//testing("Engines console at level [E.z] linked to overmap object '[name]'.")

	for(var/obj/machinery/computer/helm/H in GLOB.computer_list)
		if (H.z in map_z)
			nav_control = H
			H.linked = src
			H.get_known_sectors()
			//testing("Helm console at level [H.z] linked to overmap object '[name]'.")
	for(var/obj/machinery/computer/navigation/N in GLOB.computer_list)
		if (N.z in map_z)
			N.linked = src
			//testing("Navigation console at level [N.z] linked to overmap object '[name]'.")

	START_PROCESSING(SSobj, src)

/obj/effect/overmap/ship/relaymove(mob/user, direction)
	accelerate(direction)

/obj/effect/overmap/ship/proc/is_still()
	return !(speed[1] || speed[2])

//Projected acceleration based on information from engines
/obj/effect/overmap/ship/proc/get_acceleration()
	return round(get_total_thrust()/vessel_mass, 0.1)

//Does actual burn and returns the resulting acceleration
/obj/effect/overmap/ship/proc/get_burn_acceleration()
	return round(burn() / vessel_mass, 0.1)

/obj/effect/overmap/ship/proc/get_speed()
	return round(sqrt(speed[1]*speed[1] + speed[2]*speed[2]), 0.1)

/obj/effect/overmap/ship/proc/get_heading()
	var/res = 0
	if(speed[1])
		if(speed[1] > 0)
			res |= EAST
		else
			res |= WEST
	if(speed[2])
		if(speed[2] > 0)
			res |= NORTH
		else
			res |= SOUTH
	return res

/obj/effect/overmap/ship/proc/adjust_speed(n_x, n_y)
	speed[1] = round(CLAMP(speed[1] + n_x, -default_delay, default_delay),0.1)
	speed[2] = round(CLAMP(speed[2] + n_y, -default_delay, default_delay),0.1)
	for(var/zz in map_z)
		if(is_still())
			toggle_move_stars(zz)
		else
			toggle_move_stars(zz, fore_dir)
	update_icon()

/obj/effect/overmap/ship/proc/get_brake_path()
	if(!get_acceleration())
		return INFINITY
	var/num_burns = get_speed()/get_acceleration() + 2 //some padding in case acceleration drops form fuel usage
	var/burns_per_grid = (default_delay - speed_mod*get_speed())/burn_delay
	return round(num_burns/burns_per_grid)

/obj/effect/overmap/ship/proc/decelerate()
	if(!is_still() && can_burn())
		if (speed[1])
			adjust_speed(-sign(speed[1]) * min(get_burn_acceleration(),abs(speed[1])), 0)
		if (speed[2])
			adjust_speed(0, -sign(speed[2]) * min(get_burn_acceleration(),abs(speed[2])))
		last_burn = world.time

/obj/effect/overmap/ship/proc/accelerate(direction)
	if(can_burn())
		last_burn = world.time

		if(direction & EAST)
			adjust_speed(get_burn_acceleration(), 0)
		if(direction & WEST)
			adjust_speed(-get_burn_acceleration(), 0)
		if(direction & NORTH)
			adjust_speed(0, get_burn_acceleration())
		if(direction & SOUTH)
			adjust_speed(0, -get_burn_acceleration())

/obj/effect/overmap/ship/Process()
	if(!is_still())
		var/list/deltas = list(0,0)
		for(var/i=1, i<=2, i++)
			if(speed[i] && world.time > last_movement[i] + default_delay - speed_mod*abs(speed[i]))
				deltas[i] = speed[i] > 0 ? 1 : -1
				last_movement[i] = world.time
		var/turf/newloc = locate(x + deltas[1], y + deltas[2], z)
		if(newloc)
			Move(newloc)
			handle_wraparound()
		update_icon()

/obj/effect/overmap/ship/update_icon()
	if(!is_still())
		icon_state = "ship_moving"
		dir = get_heading()
	else
		icon_state = "ship"

/obj/effect/overmap/ship/proc/burn()

	for(var/datum/ship_engine/E in engines)
		. += E.burn()

/obj/effect/overmap/ship/proc/get_total_thrust()

	for(var/datum/ship_engine/E in engines)
		. += E.get_thrust()

/obj/effect/overmap/ship/proc/can_burn()

	if (world.time < last_burn + burn_delay)
		return 0
	for(var/datum/ship_engine/E in engines)
		. |= E.can_burn()


//deciseconds to next step
/obj/effect/overmap/ship/proc/ETA()
	. = INFINITY
	for(var/i=1, i<=2, i++)
		if(speed[i])
			. = min(last_movement[i] + default_delay - speed_mod*abs(speed[i]) - world.time, .)
	. = max(.,0)

/obj/effect/overmap/ship/proc/handle_wraparound()
	var/nx = x
	var/ny = y
	var/low_edge = 1
	var/high_edge = GLOB.maps_data.overmap_size - 1

	if(dir == WEST && x == low_edge)
		nx = high_edge
	else if(dir == EAST && x == high_edge)
		nx = low_edge
	else if(dir == SOUTH  && y == low_edge)
		ny = high_edge
	else if(dir == NORTH && y == high_edge)
		ny = low_edge
	else
		return //we're not flying off anywhere

	var/turf/T = locate(nx,ny,z)
	if(T)
		forceMove(T)

/obj/effect/overmap/ship/Bump(var/atom/A)
	if(istype(A,/turf/unsimulated/map/edge))
		handle_wraparound()
	..()