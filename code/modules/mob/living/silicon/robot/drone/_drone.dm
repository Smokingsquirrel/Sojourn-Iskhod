var/list/mob_hat_cache = list()
/proc/get_hat_icon(var/obj/item/hat, var/offset_x = 0, var/offset_y = 0)
	var/t_state = hat.icon_state
	if(hat.item_state_slots && hat.item_state_slots[slot_head_str])
		t_state = hat.item_state_slots[slot_head_str]
	else if(hat.item_state)
		t_state = hat.item_state
	var/key = "[t_state]_[offset_x]_[offset_y]"
	if(!mob_hat_cache[key])            // Not ideal as there's no guarantee all hat icon_states
		var/t_icon = INV_HEAD_DEF_ICON // are unique across multiple dmis, but whatever.
		if(hat.icon_override)
			t_icon = hat.icon_override
		else if(hat.item_icons && (slot_head_str in hat.item_icons))
			t_icon = hat.item_icons[slot_head_str]
		var/image/I = image(icon = t_icon, icon_state = t_state)
		I.pixel_x = offset_x
		I.pixel_y = offset_y
		mob_hat_cache[key] = I
	return mob_hat_cache[key]

/mob/living/silicon/robot/drone
	name = "drone"
	real_name = "drone"
	icon = 'icons/mob/robots.dmi'
	icon_state = "repairbot"
	maxHealth = 35
	health = 35
	cell_emp_mult = 1
	universal_speak = 0
	universal_understand = 1
	gender = NEUTER
	pass_flags = PASSTABLE
	braintype = "Robot"
	lawupdate = 0
	density = FALSE
	req_access = list(access_robotics) //We are robotics based!
	integrated_light_power = 3
	local_transmit = 1
	possession_candidate = 1
	speed = -0.25

//	can_pull_size = ITEM_SIZE_NORMAL SoJ change, we can drag normal things around to not get soft lock/QoL
//	can_pull_mobs = MOB_PULL_SMALLER SoJ change, we can drag mobs that need to be dragged, QoL

	mob_bump_flag = SIMPLE_ANIMAL
	mob_swap_flags = SIMPLE_ANIMAL
	mob_push_flags = SIMPLE_ANIMAL
	mob_always_swap = 1

	//If you update this mob size, remember to update the fall damage too
	mob_size = MOB_MEDIUM // Small mobs can't open doors, it's a huge pain for drones.

	//Used for self-mailing.
	var/mail_destination = ""
	var/obj/machinery/drone_fabricator/master_fabricator
	var/law_type = /datum/ai_laws/drone
	var/module_type = /obj/item/robot_module/drone
	var/obj/item/hat
	var/hat_x_offset = 0
	var/hat_y_offset = -13
	var/eyecolor = "blue"
	var/armguard = ""
	var/communication_channel = LANGUAGE_DRONE
	var/station_drone = TRUE
	holder_type = /obj/item/holder/drone

/mob/living/silicon/robot/drone/can_be_possessed_by(var/mob/observer/ghost/possessor)
	if(!istype(possessor) || !possessor.client || !possessor.ckey)
		return 0
	if(!config.allow_drone_spawn)
		to_chat(src, SPAN_DANGER("Playing as drones is not currently permitted."))
		return 0
	if(too_many_active_drones())
		to_chat(src, SPAN_DANGER("The maximum number of active drones has been reached.."))
		return 0
	if(jobban_isbanned(possessor,"Robot"))
		to_chat(usr, SPAN_DANGER("You are banned from playing synthetics and cannot spawn as a drone."))
		return 0
	if(!possessor.MayRespawn(0,MINISYNTH))
		return 0
	return 1

/mob/living/silicon/robot/drone/do_possession(var/mob/observer/ghost/possessor)
	if(!(istype(possessor) && possessor.ckey))
		return 0
	if(src.ckey || src.client)
		to_chat(possessor, SPAN_WARNING("\The [src] already has a player."))
		return 0
	message_admins("<span class='adminnotice'>[key_name_admin(possessor)] has taken control of \the [src].</span>")
	log_admin("[key_name(possessor)] took control of \the [src].")
	transfer_personality(possessor.client)
	qdel(possessor)
	return 1

/mob/living/silicon/robot/drone/Destroy()
	if(hat)
		hat.loc = get_turf(src)
	GLOB.drones.Remove(src)
	. = ..()

/mob/living/silicon/robot/drone/construction
	icon_state = "constructiondrone"
	law_type = /datum/ai_laws/construction_drone
	module_type = /obj/item/robot_module/drone/construction
	hat_x_offset = 1
	hat_y_offset = -12
//	can_pull_size = ITEM_SIZE_HUGE Soj chnge, same as base
//	can_pull_mobs = MOB_PULL_SAME Soj chnge, same as base

/mob/living/silicon/robot/drone/New()

	..()

	//Stats must be initialised before creating the module
	if(!module) module = new module_type(src)

	add_verb(src, /mob/living/proc/hide)
	remove_language(LANGUAGE_ROBOT)
	add_language(LANGUAGE_ROBOT, 0)
	add_language(LANGUAGE_DRONE, 1)

	//They are unable to be upgraded, so let's give them a bit of a better battery.
	cell.maxcharge = 10000
	cell.charge = 10000

	// NO BRAIN.
	mmi = null

	//We need to screw with their HP a bit. They have around one fifth as much HP as a full borg.
	for(var/V in components) if(V != "power cell")
		var/datum/robot_component/C = components[V]
		C.max_damage = 10

	remove_verb(src, /mob/living/silicon/robot/verb/Namepick)
	//choose_overlay()
	updateicon()

	if(station_drone)
		GLOB.drones |= src

/mob/living/silicon/robot/drone/init()
	aiCamera = new/obj/item/device/camera/siliconcam/drone_camera(src)
	additional_law_channels["Drone"] = "d"
	if(!laws) laws = new law_type

	locked = !locked //We spawn unlocked. This is for repairing them.

	flavor_text = "It's a tiny little repair drone. The casing is stamped with an corporate logo and the subscript: '[company_name] Recursive Repair Systems: Fixing Tomorrow's Problem, Today!'"
	playsound(src.loc, 'sound/machines/twobeep.ogg', 50, 0)
//	recalibrate_hotkeys()

//Redefining some robot procs...
/mob/living/silicon/robot/drone/SetName(pickedName as text)
	// Would prefer to call the grandparent proc but this isn't possible, so..
	real_name = pickedName
	name = real_name
//	recalibrate_hotkeys()

/mob/living/silicon/robot/drone/updatename()
	if(controlling_ai)
		real_name = "remote drone ([controlling_ai.name])"
		name = real_name
	else
		real_name = "[initial(name)] ([random_id(type,100,999)])"
		name = real_name

/mob/living/silicon/robot/drone/updateicon()

	cut_overlays()
	if(stat == CONSCIOUS && eyecolor)
		add_overlay("eyes-drone[eyecolor]")

	if(armguard)
		add_overlay("model-[armguard]")

	if(hat) // Let the drones wear hats.
		add_overlay(get_hat_icon(hat, hat_x_offset, hat_y_offset))

/mob/living/silicon/robot/drone/choose_icon()
	return

/mob/living/silicon/robot/drone/pick_module()
	return

/mob/living/silicon/robot/drone/proc/wear_hat(var/obj/item/new_hat)
	if(hat)
		return
	hat = new_hat
	new_hat.forceMove(src)
	updateicon()

//Drones cannot be upgraded with borg modules so we need to catch some items before they get used in ..().
/mob/living/silicon/robot/drone/attackby(var/obj/item/W, var/mob/user)

	if(user.a_intent == I_HELP && istype(W, /obj/item/clothing/head))
		if(hat)
			to_chat(user, SPAN_WARNING("\The [src] is already wearing \the [hat]."))
			return
		user.unEquip(W)
		wear_hat(W)
		user.visible_message(SPAN_NOTICE("\The [user] puts \the [W] on \the [src]."))
		return
	else if(istype(W, /obj/item/borg/upgrade/))
		to_chat(user, SPAN_DANGER("\The [src] is not compatible with \the [W]."))
		return

	else if (istype(W, /obj/item/card/id)||istype(W, /obj/item/modular_computer))

		if(stat == 2)

			if(!config.allow_drone_spawn || HasTrait(CYBORG_TRAIT_EMAGGED) || health < -35) //It's dead, Dave.
				to_chat(user, SPAN_DANGER("The interface is fried, and a distressing burned smell wafts from the robot's interior. You're not rebooting this one."))
				return

			if(!allowed(usr))
				to_chat(user, SPAN_DANGER("Access denied."))
				return

			if(src.health < 0) //Are we able to even be revived?
				to_chat(usr, "You have to repair the robot before using this module!")
				return

			user.visible_message(SPAN_DANGER("\The [user] swipes \his ID card through \the [src], attempting to reboot it."), SPAN_DANGER(">You swipe your ID card through \the [src], attempting to reboot it."))
			request_player() //Tell the player they are alive again.
			we_live_again() //Do the revive!
			updatehealth() //Check are hp, and refresh are huds
			return

		else
			user.visible_message(SPAN_DANGER("\The [user] swipes \his ID card through \the [src], attempting to shut it down."), SPAN_DANGER("You swipe your ID card through \the [src], attempting to shut it down."))

			if(HasTrait(CYBORG_TRAIT_EMAGGED))
				return

			if(allowed(usr))
				shut_down()
			else
				to_chat(user, SPAN_DANGER("Access denied."))

		return

	..()

/mob/living/silicon/robot/drone/emag_act(var/remaining_charges, var/mob/user)
	if(!client || stat == 2)
		to_chat(user, SPAN_DANGER("There's not much point subverting this heap of junk."))
		return

	if(HasTrait(CYBORG_TRAIT_EMAGGED))
		to_chat(src, SPAN_DANGER("\The [user] attempts to load subversive software into you, but your hacked subroutines ignore the attempt."))
		to_chat(user, SPAN_DANGER("You attempt to subvert [src], but the sequencer has no effect."))
		return

	to_chat(user, SPAN_DANGER("You swipe the sequencer across [src]'s interface and watch its eyes flicker."))
	to_chat(src, SPAN_DANGER("You feel a sudden burst of malware loaded into your execute-as-root buffer. Your tiny brain methodically parses, loads and executes the script."))

	message_admins("[key_name_admin(user)] emagged drone [key_name_admin(src)].  Laws overridden.")
	log_game("[key_name(user)] emagged drone [key_name(src)].  Laws overridden.")
	var/time = time2text(world.realtime,"hh:mm:ss")
	lawchanges.Add("[time] <B>:</B> [user.name]([user.key]) emagged [name]([key])")

	AddTrait(CYBORG_TRAIT_EMAGGED)
	lawupdate = 0
	connected_ai = null
	clear_supplied_laws()
	clear_inherent_laws()
	laws = new /datum/ai_laws/syndicate_override
	set_zeroth_law("Only [user.real_name] and people \he designates as being such are operatives.")

	to_chat(src, "<b>Obey these laws:</b>")
	laws.show_laws(src)
	to_chat(src, SPAN_DANGER("ALERT: [user.real_name] is your new master. Obey your new laws and \his commands."))
	return 1

//DRONE LIFE/DEATH

//For some goddamn reason robots have this hardcoded. Redefining it for our fragile friends here.
/mob/living/silicon/robot/drone/updatehealth()
	if(status_flags & GODMODE)
		health = maxHealth
		stat = CONSCIOUS
		return
	health = maxHealth - (getBruteLoss() + getFireLoss())
	if(health <= death_threshold && stat != DEAD) //stops constantly procing death
		death()
	return

//Easiest to check this here, then check again in the robot proc.
//Standard robots use config for crit, which is somewhat excessive for these guys.
//Drones killed by damage will gib.
/mob/living/silicon/robot/drone/handle_regular_status_updates()
	var/turf/T = get_turf(src)
	if((!T || health <= death_threshold) && src.stat != DEAD)
		timeofdeath = world.time
		death() //Possibly redundant, having trouble making death() cooperate.
		gib()
		return
	..()

//DRONE MOVEMENT.
/mob/living/silicon/robot/drone/slip_chance(var/prob_slip)
	return 0

//CONSOLE PROCS
/mob/living/silicon/robot/drone/proc/law_resync()
	if(stat != 2)
		if(HasTrait(CYBORG_TRAIT_EMAGGED))
			to_chat(src, SPAN_DANGER("You feel something attempting to modify your programming, but your hacked subroutines are unaffected."))
		else
			to_chat(src, SPAN_DANGER("A reset-to-factory directive packet filters through your data connection, and you obediently modify your programming to suit it."))
			full_law_reset()
			show_laws()

/mob/living/silicon/robot/drone/proc/shut_down()
	if(stat != 2)
		if(HasTrait(CYBORG_TRAIT_EMAGGED))
			to_chat(src, SPAN_DANGER("You feel a system kill order percolate through your tiny brain, but it doesn't seem like a good idea to you."))
		else
			to_chat(src, SPAN_DANGER("You feel a system kill order percolate through your tiny brain, and you obediently destroy yourself."))
			death()

/mob/living/silicon/robot/drone/proc/full_law_reset()
	clear_supplied_laws(1)
	clear_inherent_laws(1)
	clear_ion_laws(1)
	laws = new law_type

//Reboot procs.

/mob/living/silicon/robot/drone/proc/we_live_again(var/mob/living/silicon/robot/R) //we shall live again!
	//..() //Can never go wrong with one of these!
	//Hex: Yes you can! STOP MAKING LINTER CHAN CRY!

	R.stat = CONSCIOUS //We live again!
	GLOB.dead_mob_list -= R //Were not dead...
	GLOB.living_mob_list |= R //Were infact alive
	R.death_notified = FALSE //un-notifie us!
	R.notify_ai(ROBOT_NOTIFICATION_NEW_UNIT) //Tell our big brother were back in action!
	return  //for safty!

/mob/living/silicon/robot/drone/proc/request_player()
	if(too_many_active_drones())
		return
	var/datum/ghosttrap/G = get_ghost_trap("maintenance drone")
	G.request_player(src, "Someone is attempting to reboot a maintenance drone.", MINISYNTH, 30 SECONDS)

/mob/living/silicon/robot/drone/proc/transfer_personality(var/client/player)
	if(!player) return
	src.ckey = player.ckey

	if(player.mob && player.mob.mind)
		player.mob.mind.transfer_to(src)

	lawupdate = 0
	to_chat(src, "<b>Systems rebooted</b>. Loading base pattern maintenance protocol... <b>loaded</b>.")
	full_law_reset()
	welcome_drone()

/mob/living/silicon/robot/drone/proc/welcome_drone()
	if(controlling_ai)
		to_chat( src, "<b> You are now controlling a drone. Your former laws still apply.</b>")
	else
		to_chat(src, "<b>You are a maintenance drone, a tiny-brained robotic repair machine</b>.")
		to_chat(src, "You have no individual will, no personality, and no drives or urges other than your laws.")
		to_chat(src, "Remember,  you are <b>lawed against interference with the crew</b>. Also remember, <b>you DO NOT take orders from the AI.</b>")
		to_chat(src, "Use <b>say ;Hello</b> to talk to other drones and <b>say Hello</b> to speak silently to your nearby fellows.")

/mob/living/silicon/robot/drone/add_robot_verbs()
	return

/mob/living/silicon/robot/drone/remove_robot_verbs()
	return

/mob/living/silicon/robot/drone/construction/welcome_drone()
	to_chat(src, "<b>You are a construction drone, an autonomous engineering and fabrication system.</b>.")
	to_chat(src, "You are assigned to a Sol Central construction project. The name is irrelevant. Your task is to complete construction and subsystem integration as soon as possible.")
	to_chat(src, "You generally should not leave the construction site unless absolutely required for the completion of the Sol Central construction project.")
	to_chat(src, "Use <b>:d</b> to talk to other drones and <b>say</b> to speak silently to your nearby fellows.")
	to_chat(src, "<b>You do not follow orders from anyone; not the AI, not humans, and not other synthetics.</b>.")

/mob/living/silicon/robot/drone/construction/init()
	..()
	flavor_text = "It's a bulky construction drone stamped with a Sol Central glyph."

/mob/living/silicon/robot/drone/construction/updatename()
	real_name = "construction drone ([rand(100,999)])"
	name = real_name

/mob/living/silicon/robot/drone/construction/updateicon()
	cut_overlays()
	if(stat == CONSCIOUS)
		add_overlay("eyes-[module_sprites[icontype]]")

/proc/too_many_active_drones()
	var/drones = 0
	for(var/mob/living/silicon/robot/drone/D in SSmobs.mob_list)
		if(D.key && D.client)
			drones++
	return drones >= config.max_maint_drones

/mob/living/silicon/robot/drone/show_laws(var/everyone = 0)
	if(!controlling_ai)
		return..()
	to_chat(src, "<b>Obey these laws:</b>")
	controlling_ai.laws_sanity_check()
	controlling_ai.laws.show_laws(src)

/mob/living/silicon/robot/drone/robot_checklaws()
	set category = "Silicon Commands"
	set name = "State Laws"

	if(!controlling_ai)
		return ..()
	controlling_ai.open_subsystem(/datum/nano_module/law_manager)

/mob/living/silicon/robot/drone/verb/choose_eyecolor()
	set name = "Choose Light Color"
	set category = "Silicon Commands"
	var/list/colors = list( "blue", "red", "orange", "green", "violet")

	eyecolor = input("Please, select a color!", "color", null) as null|anything in colors

	if(!colors)
		eyecolor = "blue"
		return

/mob/living/silicon/robot/drone/verb/choose_armguard()
	set name = "Choose Armguards"
	set category = "Silicon Commands"
	var/list/colors = list( "blue", "red", "brown", "orange", "green", "none")

	armguard = input("Please, select armguards!", "color", null) as null|anything in colors

	if(!colors)
		armguard = ""
		return

	remove_verb(src, /mob/living/silicon/robot/drone/verb/choose_armguard)
	to_chat(src, "Your armguard has been set.")
