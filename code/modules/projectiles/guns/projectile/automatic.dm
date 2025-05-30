/obj/item/gun/projectile/automatic
	name = "old automatic projectile gun"
	desc = "A no longer produced hologram of the base of all moder day smgs. Uses .35 rounds."
	icon = 'icons/obj/guns/projectile/generic_smg.dmi'
	icon_state = "generic_smg"
	w_class = ITEM_SIZE_NORMAL
	load_method = SINGLE_CASING|SPEEDLOADER //Default is speedloader because all might not have magazine sprites.
	max_shells = 1 //Automatic quick fix idk why this was set to 22 but it was. Issue fixed
	caliber = CAL_PISTOL
	origin_tech = list(TECH_COMBAT = 4, TECH_MATERIAL = 2)
	slot_flags = SLOT_BELT
	ammo_type = /obj/item/ammo_casing/pistol_35
	burst_delay = 2
	fire_sound = 'sound/weapons/guns/fire/smg_fire.ogg'
	unload_sound = 'sound/weapons/guns/interact/smg_magout.ogg'
	reload_sound = 'sound/weapons/guns/interact/smg_magin.ogg'
	cocked_sound = 'sound/weapons/guns/interact/smg_cock.ogg'
	zoom_factors = list()
	gun_tags = list(GUN_PROJECTILE, GUN_INTERNAL_MAG)
	auto_rack = TRUE
	init_firemodes = list(
		FULL_AUTO_300,
		SEMI_AUTO_NODELAY,
		BURST_3_ROUND,
		BURST_5_ROUND
		)

	wield_delay = 1 SECOND
	wield_delay_factor = 0.3 // 30 vig for insta wield
	gun_parts = list(/obj/item/part/gun = 3 ,/obj/item/stack/material/steel = 15)


//Automatic firing
//Todo: Way more checks and safety here
/datum/firemode/automatic
	settings = list(burst = 1, suppress_delay_warning = TRUE, dispersion=null)
	//The full auto clickhandler we have
	var/datum/click_handler/fullauto/CH = null

/datum/firemode/automatic/update(var/force_state = null)
	var/mob/living/L
	if (gun && gun.is_held())
		L = gun.loc

	var/enable = FALSE
	//Force state is used for forcing it to be disabled in circumstances where it'd normally be valid
	if (!isnull(force_state))
		enable = force_state
	else if (L && L.client)

		//First of all, lets determine whether we're enabling or disabling the click handler


		//We enable it if the gun is held in the user's active hand and the safety is off
		if (L.get_active_hand() == gun)
			//Lets also make sure it can fire
			var/can_fire = TRUE

			//Safety stops it
			if (gun.safety)
				can_fire = FALSE

			//Projectile weapons need to have enough ammo to fire
			if(istype(gun, /obj/item/gun/projectile))
				var/obj/item/gun/projectile/P = gun
				if (!P.get_ammo())
					can_fire = FALSE

			//TODO: Centralise all this into some can_fire proc
			if (can_fire)
				enable = TRUE
		else
			enable = FALSE

	//Ok now lets set the desired state
	if (!enable)
		if (!CH)
			//If we're turning it off, but the click handler doesn't exist, then we have nothing to do
			return

		//Todo: make client click handlers into a list
		if (CH.owner) //Remove our handler from the client
			CH.owner.CH = null //wew
		QDEL_NULL(CH) //And delete it
		return

	else
		//We're trying to turn things on
		if (CH)
			return //The click handler exists, we dont need to do anything


		//Create and assign the click handler
		//A click handler intercepts mouseup/drag/down events which allow fullauto firing
		CH = new /datum/click_handler/fullauto()
		CH.receiver = gun //receiver is the gun that gets the fire events
		L.client.CH = CH //Put it on the client
		CH.owner = L.client //And tell it where it is

// This function stop one bug where the firemode stay on when it is in backpack
// But doesn't work when client's CH goes null (as in dropping while wielded).
// There's a separate check in shooting loop
/datum/firemode/automatic/force_deselect(mob/user)
	if(CH)
		if(CH.owner) //Remove our handler from the client
			CH.owner.CH = null
			QDEL_NULL(CH) //And delete it
	if(user.client)
		if(user.client.CH)
			user.client.CH = null
			QDEL_NULL(user.client.CH)
