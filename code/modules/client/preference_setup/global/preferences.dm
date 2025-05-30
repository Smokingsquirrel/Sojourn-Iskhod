GLOBAL_VAR_CONST(PREF_YES, "Yes")
GLOBAL_VAR_CONST(PREF_NO, "No")
GLOBAL_VAR_CONST(PREF_ALL_SPEECH, "All Speech")
GLOBAL_VAR_CONST(PREF_NEARBY, "Nearby")
GLOBAL_VAR_CONST(PREF_ALL_EMOTES, "All Emotes")
GLOBAL_VAR_CONST(PREF_ALL_CHATTER, "All Chatter")
GLOBAL_VAR_CONST(PREF_SHORT, "Short")
GLOBAL_VAR_CONST(PREF_LONG, "Long")
GLOBAL_VAR_CONST(PREF_SHOW, "Show")
GLOBAL_VAR_CONST(PREF_HIDE, "Hide")
GLOBAL_VAR_CONST(PREF_FANCY, "Fancy")
GLOBAL_VAR_CONST(PREF_PLAIN, "Plain")
GLOBAL_VAR_CONST(PREF_PRIMARY, "Primary")
GLOBAL_VAR_CONST(PREF_ALL, "All")
GLOBAL_VAR_CONST(PREF_OFF, "Off")
GLOBAL_VAR_CONST(PREF_BASIC, "Basic")
GLOBAL_VAR_CONST(PREF_FULL, "Full")
GLOBAL_VAR_CONST(PREF_MIDDLE_CLICK, "middle click")
GLOBAL_VAR_CONST(PREF_ALT_CLICK, "alt click")
GLOBAL_VAR_CONST(PREF_CTRL_CLICK, "ctrl click")
GLOBAL_VAR_CONST(PREF_CTRL_SHIFT_CLICK, "ctrl shift click")
GLOBAL_VAR_CONST(PREF_HEAR, "Hear")
GLOBAL_VAR_CONST(PREF_SILENT, "Silent")
GLOBAL_VAR_CONST(PREF_SHORTHAND, "Shorthand")

var/list/_client_preferences
var/list/_client_preferences_by_key
var/list/_client_preferences_by_type

/proc/get_client_preferences()
	if(!_client_preferences)
		_client_preferences = list()
		for(var/ct in subtypesof(/datum/client_preference))
			var/datum/client_preference/client_type = ct
			if(initial(client_type.description))
				_client_preferences += new client_type()
	return _client_preferences

/proc/get_client_preference(var/datum/client_preference/preference)
	if(istype(preference))
		return preference
	if(ispath(preference))
		return get_client_preference_by_type(preference)
	return get_client_preference_by_key(preference)

/proc/get_client_preference_by_key(var/preference)
	if(!_client_preferences_by_key)
		_client_preferences_by_key = list()
		for(var/ct in get_client_preferences())
			var/datum/client_preference/client_pref = ct
			_client_preferences_by_key[client_pref.key] = client_pref
	return _client_preferences_by_key[preference]

/proc/get_client_preference_by_type(var/preference)
	if(!_client_preferences_by_type)
		_client_preferences_by_type = list()
		for(var/ct in get_client_preferences())
			var/datum/client_preference/client_pref = ct
			_client_preferences_by_type[client_pref.type] = client_pref
	return _client_preferences_by_type[preference]

/datum/client_preference
	var/description
	var/key
	var/list/options = list(GLOB.PREF_YES, GLOB.PREF_NO)
	var/default_value

/datum/client_preference/New()
	. = ..()

	if(!default_value)
		default_value = options[1]

/datum/client_preference/proc/may_set(var/mob/preference_mob)
	return TRUE

/datum/client_preference/proc/changed(var/mob/preference_mob, var/new_value)
	return

/*********************
* Player Preferences *
*********************/

/datum/client_preference/play_admin_midis
	description ="Play admin midis"
	key = "SOUND_MIDI"

/datum/client_preference/play_lobby_music
	description ="Play lobby music"
	key = "SOUND_LOBBY"

/datum/client_preference/play_lobby_music/changed(var/mob/preference_mob, var/new_value)
	if(new_value == GLOB.PREF_YES)
		if(isnewplayer(preference_mob))
			GLOB.lobbyScreen.play_music(preference_mob.client)
	else
		GLOB.lobbyScreen.stop_music(preference_mob.client)

/datum/client_preference/change_to_examine_tab
	description = "Switch to examine tab upon examining a object"
	key = "SWITCHEXAMINE"

/datum/client_preference/play_ambiance
	description ="Play ambience"
	key = "SOUND_AMBIENCE"

/datum/client_preference/play_ambiance/changed(var/mob/preference_mob, var/new_value)
	if(new_value == GLOB.PREF_NO)
		sound_to(preference_mob, sound(null, repeat = 0, wait = 0, volume = 0, channel = GLOB.ambience_sound_channel))

/datum/client_preference/ghost_ears
	description ="Ghost ears"
	key = "CHAT_GHOSTEARS"
	options = list(GLOB.PREF_ALL_SPEECH, GLOB.PREF_NEARBY)

/datum/client_preference/ghost_ears_plus
	description ="Ghost Psionics/Cruciform"
	key = "CHAT_GHOST_EARS_PLUS"
	options = list(GLOB.PREF_YES, GLOB.PREF_NO)

/datum/client_preference/ghost_sight
	description ="Ghost sight"
	key = "CHAT_GHOSTSIGHT"
	options = list(GLOB.PREF_ALL_EMOTES, GLOB.PREF_NEARBY)

/datum/client_preference/ghost_radio
	description ="Ghost radio"
	key = "CHAT_GHOSTRADIO"
	options = list(GLOB.PREF_ALL_CHATTER, GLOB.PREF_NEARBY)

/datum/client_preference/language_display
	description = "Display Language Names"
	key = "LANGUAGE_DISPLAY"
	options = list(GLOB.PREF_FULL, GLOB.PREF_SHORTHAND, GLOB.PREF_OFF)
/*
/datum/client_preference/ghost_follow_link_length
	description ="Ghost Follow Links"
	key = "CHAT_GHOSTFOLLOWLINKLENGTH"
	options = list(GLOB.PREF_SHORT, GLOB.PREF_LONG)
*/
/datum/client_preference/chat_tags
	description ="Chat tags"
	key = "CHAT_SHOWICONS"
	options = list(GLOB.PREF_SHOW, GLOB.PREF_HIDE)

/datum/client_preference/show_typing_indicator
	description ="Typing indicator"
	key = "SHOW_TYPING"
	options = list(GLOB.PREF_SHOW, GLOB.PREF_HIDE)

/datum/client_preference/show_ooc
	description ="OOC chat"
	key = "CHAT_OOC"
	options = list(GLOB.PREF_SHOW, GLOB.PREF_HIDE)
/*
/datum/client_preference/show_aooc
	description ="AOOC chat"
	key = "CHAT_AOOC"
	options = list(GLOB.PREF_SHOW, GLOB.PREF_HIDE)
*/
/datum/client_preference/show_looc
	description ="LOOC chat"
	key = "CHAT_LOOC"
	options = list(GLOB.PREF_SHOW, GLOB.PREF_HIDE)

/datum/client_preference/show_dsay
	description ="Dead chat"
	key = "CHAT_DEAD"
	options = list(GLOB.PREF_SHOW, GLOB.PREF_HIDE)

/datum/client_preference/show_progress_bar
	description ="Progress Bar"
	key = "SHOW_PROGRESS"
	options = list(GLOB.PREF_SHOW, GLOB.PREF_HIDE)

/datum/client_preference/floating_messages
	description ="Floating chat messages"
	key = "FLOATING_CHAT"
	options = list(GLOB.PREF_HIDE, GLOB.PREF_SHOW)

/datum/client_preference/browser_style
	description = "Fake NanoUI Browser Style"
	key = "BROWSER_STYLED"
	options = list(GLOB.PREF_FANCY, GLOB.PREF_PLAIN)
/*
/datum/client_preference/autohiss
	description = "Autohiss"
	key = "AUTOHISS"
	options = list(GLOB.PREF_OFF, GLOB.PREF_BASIC, GLOB.PREF_FULL)
*/
/datum/client_preference/hardsuit_activation
	description = "Hardsuit Module Activation Key"
	key = "HARDSUIT_ACTIVATION"
	options = list(GLOB.PREF_MIDDLE_CLICK, GLOB.PREF_CTRL_CLICK, GLOB.PREF_ALT_CLICK, GLOB.PREF_CTRL_SHIFT_CLICK)
/*
/datum/client_preference/show_credits
	description = "Show End Titles"
	key = "SHOW_CREDITS"
*/
/*
/datum/client_preference/play_instruments
	description ="Play instruments"
	key = "SOUND_INSTRUMENTS"
*/

/datum/client_preference/ambient_occlusion
	description = "Ambient occlusion"
	key = "AMBIENT_OCCLUSION"

/datum/client_preference/play_instruments
	description ="Play instruments"
	key = "SOUND_INSTRUMENTS"

/datum/client_preference/gun_cursor
	description = "Enable gun crosshair"
	key = "GUN_CURSOR"

/datum/client_preference/play_jukebox
	description = "Play jukebox music"
	key = "SOUND_JUKEBOX"

/datum/client_preference/play_jukebox/changed(var/mob/preference_mob, var/new_value)
	if(new_value == GLOB.PREF_NO)
		preference_mob.stop_all_music()
	else
		preference_mob.update_music()

/datum/client_preference/stay_in_hotkey_mode
	description = "Keep hotkeys on mob change"
	key = "KEEP_HOTKEY_MODE"
	default_value = GLOB.PREF_YES

/datum/client_preference/fullscreen
	description = "Enable fullscreen"
	key = "FULLSCREEN"
	default_value = GLOB.PREF_NO

/datum/client_preference/fullscreen/changed(mob/preference_mob, new_value)
	if(preference_mob.client)
		preference_mob.client.fullscreen_check()

/datum/client_preference/area_info_blurb
	description = "Show area narration."
	key = "AREA_INFO"

/datum/client_preference/tgui_fancy
	description ="Enable/Disable tgui fancy mode"
	key = "tgui_fancy"

/datum/client_preference/tgui_fancy/changed(mob/preference_mob, new_value)
	for (var/datum/tgui/tgui as anything in preference_mob?.tgui_open_uis)
		// Force it to reload either way
		tgui.send_full_update()

/datum/client_preference/tgui_lock
	description ="TGUI Lock"
	key = "tgui_lock"

/datum/client_preference/tgui_lock/changed(mob/preference_mob, new_value)
	for (var/datum/tgui/tgui as anything in preference_mob?.tgui_open_uis)
		// Force it to reload either way
		tgui.send_full_update()

/datum/client_preference/tgui_toaster
	description ="TGUI Performance Mode (Disables images/etc)"
	key = "tgui_toaster"
	default_value = GLOB.PREF_NO

/datum/client_preference/tgui_toaster/changed(mob/preference_mob, new_value)
	for (var/datum/tgui/tgui as anything in preference_mob?.tgui_open_uis)
		// Force it to reload either way
		tgui.send_full_update()


/datum/client_preference/tgui_input
	description = "TGUI Input: Use TGUI for basic input boxes"
	key = "tgui_input"
	default_value = GLOB.PREF_YES

/datum/client_preference/tgui_input_large
	description = "TGUI Input: Use Larger Buttons"
	key = "tgui_input_large"
	default_value = GLOB.PREF_NO

/datum/client_preference/tgui_input_swapped
	description = "TGUI Input: Swap Submit/Cancel buttons"
	key = "tgui_input_swapped"
	default_value = GLOB.PREF_NO

/datum/client_preference/tgui_say
	description = "TGUI Say: Use TGUI For Say Input"
	key = "tgui_say"
	default_value = GLOB.PREF_YES

/datum/client_preference/tgui_say_light_mode
	description = "TGUI Say: Use Light Mode"
	key = "tgui_say_light_mode"
	default_value = GLOB.PREF_NO

/datum/client_preference/tgui_say_light_mode/changed(mob/preference_mob, new_value)
	preference_mob?.client?.tgui_say?.load()

/datum/client_preference/status_bar
	description = "Disable built-in status bar"
	key = "disable_status_bar"
	default_value = GLOB.PREF_NO

/datum/client_preference/status_bar/changed(mob/preference_mob, new_value)
	winset(preference_mob, "status_bar", "is-visible=[new_value == GLOB.PREF_YES ? "false" : "true"]")

/********************
* General Staff Preferences *
********************/

/datum/client_preference/staff
	var/flags

/datum/client_preference/staff/may_set(var/mob/preference_mob)
	if(flags)
		return check_rights(flags, 0, preference_mob)
	else
		return preference_mob && preference_mob.client && preference_mob.client.holder

/datum/client_preference/staff/show_chat_prayers
	description = "Chat Prayers"
	key = "CHAT_PRAYER"
	options = list(GLOB.PREF_SHOW, GLOB.PREF_HIDE)

/datum/client_preference/staff/play_adminhelp_ping
	description = "Adminhelps"
	key = "SOUND_ADMINHELP"
	options = list(GLOB.PREF_HEAR, GLOB.PREF_SILENT)

/datum/client_preference/staff/show_rlooc
	description ="Remote LOOC chat"
	key = "CHAT_RLOOC"
	options = list(GLOB.PREF_SHOW, GLOB.PREF_HIDE)

/datum/client_preference/staff/split_admin_tabs
	description = "Split Admin Tabs"
	key = "CHAT_SPLIT_TABS"
	default_value = GLOB.PREF_NO

/datum/client_preference/staff/fast_mc_refresh
	description = "Fast MC Tab Refresh"
	key = "fast_mc_refresh"
	default_value = GLOB.PREF_NO

/********************
* Admin Preferences *
********************/

/datum/client_preference/staff/show_attack_logs
	description = "Attack Log Messages"
	key = "CHAT_ATTACKLOGS"
	options = list(GLOB.PREF_SHOW, GLOB.PREF_HIDE)
	flags = R_ADMIN
	default_value = GLOB.PREF_HIDE

/********************
* Debug Preferences *
********************/

/datum/client_preference/staff/show_debug_logs
	description = "Debug Log Messages"
	key = "CHAT_DEBUGLOGS"
	options = list(GLOB.PREF_SHOW, GLOB.PREF_HIDE)
	default_value = GLOB.PREF_HIDE
	flags = R_ADMIN|R_DEBUG
