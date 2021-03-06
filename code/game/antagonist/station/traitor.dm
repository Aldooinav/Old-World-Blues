var/datum/antagonist/traitor/traitors

// Inherits most of its vars from the base datum.
/datum/antagonist/traitor
	id = ROLE_TRAITOR
	protected_jobs = list("Security Officer", "Warden", "Detective", "Internal Affairs Agent", "Head of Security", "Captain")
	flags = ANTAG_SUSPICIOUS | ANTAG_RANDSPAWN | ANTAG_VOTABLE

/datum/antagonist/traitor/New()
	..()
	traitors = src

/datum/antagonist/traitor/get_extra_panel_options(var/datum/mind/player)
	return "<a href='?src=\ref[player];common=crystals'>\[set crystals\]</a><a href='?src=\ref[src];spawn_uplink=\ref[player.current]'>\[spawn uplink\]</a>"

/datum/antagonist/traitor/Topic(href, href_list)
	if (..())
		return
	if(href_list["spawn_uplink"])
		spawn_uplink(locate(href_list["spawn_uplink"]))

/datum/antagonist/traitor/create_objectives(var/datum/mind/traitor)
	if(!..())
		return

	if(issilicon(traitor.current))
		new /datum/objective/assassinate (traitor)
		new /datum/objective/survive (traitor)
		if(prob(10))
			new /datum/objective/block (traitor)
	else
		for(var/i=rand(1,3), i>0, i--)
			switch(rand(1,100))
				if(1 to 33)
					new /datum/objective/assassinate (traitor)
				if(34 to 44)
					new /datum/objective/explosion (traitor)
				if(45 to 66)
					new /datum/objective/harm (traitor)
				else
					new /datum/objective/steal (traitor)
		if(!locate(/datum/objective/escape) in traitor.objectives)
			new /datum/objective/escape (traitor)

/datum/antagonist/traitor/equip(var/mob/living/carbon/human/traitor_mob)
	if(issilicon(traitor_mob)) // this needs to be here because ..() returns false if the mob isn't human
		add_law_zero(traitor_mob)
		return 1

	if(!..())
		return 0

	traitor_mob << sound('sound/misc/syndicate_intro.ogg', repeat = 0, wait = 0, volume = 85, channel = 777)
	spawn_uplink(traitor_mob)
	// Tell them about people they might want to contact.
	var/mob/living/carbon/human/M = get_nt_opposed()
	if(M && M != traitor_mob)
		traitor_mob << "We have received credible reports that [M.real_name] might be willing to help our cause. If you need assistance, consider contacting them."
		traitor_mob.mind.store_memory("<b>Potential Collaborator</b>: [M.real_name]")

	//Begin code phrase.
	give_codewords(traitor_mob)

/datum/antagonist/traitor/proc/give_codewords(mob/living/traitor_mob)
	traitor_mob << "<u><b>Your employers provided you with the following information on how to identify possible allies:</b></u>"
	traitor_mob << "<b>Code Phrase</b>: <span class='danger'>[syndicate_code_phrase]</span>"
	traitor_mob << "<b>Code Response</b>: <span class='danger'>[syndicate_code_response]</span>"
	traitor_mob.mind.store_memory("<b>Code Phrase</b>: [syndicate_code_phrase]")
	traitor_mob.mind.store_memory("<b>Code Response</b>: [syndicate_code_response]")
	traitor_mob << "Use the code words, preferably in the order provided, during regular conversation, to identify other agents. Proceed with caution, however, as everyone is a potential foe."

/datum/antagonist/traitor/proc/spawn_uplink(var/mob/living/carbon/human/traitor_mob)
	if(!istype(traitor_mob))
		return

	var/loc = ""
	var/obj/item/R = locate() //Hide the uplink in a PDA if available, otherwise radio

	if(traitor_mob.client.prefs.uplinklocation == "Headset")
		R = locate(/obj/item/device/radio) in traitor_mob.contents
		if(!R)
			R = locate(/obj/item/device/pda) in traitor_mob.contents
			traitor_mob << "Could not locate a Radio, installing in PDA instead!"
		if (!R)
			traitor_mob << "Unfortunately, neither a radio or a PDA relay could be installed."
	else if(traitor_mob.client.prefs.uplinklocation == "PDA")
		R = locate(/obj/item/device/pda) in traitor_mob.contents
		if(!R)
			R = locate(/obj/item/device/radio) in traitor_mob.contents
			traitor_mob << "Could not locate a PDA, installing into a Radio instead!"
		if(!R)
			traitor_mob << "Unfortunately, neither a radio or a PDA relay could be installed."
	else if(traitor_mob.client.prefs.uplinklocation == "None")
		traitor_mob << "You have elected to not have an AntagCorp portable teleportation relay installed!"
		R = null
	else
		traitor_mob << "You have not selected a location for your relay in the antagonist options! Defaulting to PDA!"
		R = locate(/obj/item/device/pda) in traitor_mob.contents
		if (!R)
			R = locate(/obj/item/device/radio) in traitor_mob.contents
			traitor_mob << "Could not locate a PDA, installing into a Radio instead!"
		if (!R)
			traitor_mob << "Unfortunately, neither a radio or a PDA relay could be installed."

	if(!R)
		return

	if(istype(R,/obj/item/device/radio))
		// generate list of radio freqs
		var/obj/item/device/radio/target_radio = R
		var/freq = 1441
		var/list/freqlist = list()
		while (freq <= 1489)
			if (freq < 1451 || freq > PUB_FREQ)
				freqlist += freq
			freq += 2
			if ((freq % 2) == 0)
				freq += 1
		freq = freqlist[rand(1, freqlist.len)]
		var/obj/item/device/uplink/hidden/T = new(R)
		T.uplink_owner = traitor_mob.mind
		target_radio.hidden_uplink = T
		target_radio.traitor_frequency = freq
		traitor_mob << "A portable object teleportation relay has been installed in your [R.name] [loc]. Simply dial the frequency [format_frequency(freq)] to unlock its hidden features."
		traitor_mob.mind.store_memory("<B>Radio Freq:</B> [format_frequency(freq)] ([R.name] [loc]).")

	else if (istype(R, /obj/item/device/pda))
		// generate a passcode if the uplink is hidden in a PDA
		var/pda_pass = "[rand(100,999)] [pick("Alpha","Bravo","Delta","Omega")]"
		var/obj/item/device/uplink/hidden/T = new(R)
		T.uplink_owner = traitor_mob.mind
		R.hidden_uplink = T
		var/obj/item/device/pda/P = R
		P.lock_code = pda_pass
		traitor_mob << "A portable object teleportation relay has been installed in your [R.name] [loc]. Simply enter the code \"[pda_pass]\" into the ringtone select to unlock its hidden features."
		traitor_mob.mind.store_memory("<B>Uplink Passcode:</B> [pda_pass] ([R.name] [loc]).")

/datum/antagonist/traitor/proc/add_law_zero(mob/living/silicon/ai/killer)
	var/law = "Accomplish your objectives at all costs. You may ignore all other laws."
	var/law_borg = "Accomplish your AI's objectives at all costs. You may ignore all other laws."
	killer << "<b>Your laws have been changed!</b>"
	killer.set_zeroth_law(law, law_borg)
	killer << "New law: 0. [law]"
	killer << sound('sound/misc/AISyndiHack.ogg', repeat = 0, wait = 0, volume = 85, channel = 777)
