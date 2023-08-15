#using scripts\codescripts\struct;

#using scripts\zm\_zm_perks;

#using scripts\shared\array_shared;
#using scripts\shared\callbacks_shared;
#using scripts\shared\clientfield_shared;
#using scripts\shared\compass;
#using scripts\shared\exploder_shared;
#using scripts\shared\flag_shared;
#using scripts\shared\laststand_shared;
#using scripts\shared\math_shared;
#using scripts\shared\scene_shared;
#using scripts\shared\util_shared;
#using scripts\shared\system_shared;

#insert scripts\shared\shared.gsh;
#insert scripts\shared\version.gsh;

#using scripts\zm\_zm;
#using scripts\zm\_load;
#using scripts\zm\_zm_power;
#using scripts\zm\_zm_score;
#using scripts\zm\_zm_audio;
#using scripts\zm\_zm_powerups;
#using scripts\zm\_zm_utility;
#using scripts\zm\_zm_weapons;
#using scripts\zm\_zm_zonemgr;

#using scripts\zm\zm_purchase;

#using scripts\shared\ai\zombie_utility;
#using scripts\shared\ai\zombie_death;

#insert scripts\zm\zm_electric_trap.gsh;

#namespace zm_electric_trap;

//electric_trap_fx (structs)
//electric_trap_damage (trigger)

REGISTER_SYSTEM_EX( "zm_electric_trap", &__init__, &__main__, undefined )

function __init__(){
    clientfield::register( "scriptmover", LIGHTNING_FX, VERSION_SHIP, 1, "int" );
}

function __main__(){
    // get traps
    electric_traps = struct::get_array("electric_trap");

    foreach(trap in electric_traps){
        trap thread electric_trap_thread();
    }
}

// self = trap struct
function electric_trap_thread(){
    self.on = false;
    self.sfx = util::spawn_model( "tag_origin", self.origin, self.angles );

    exploder::stop_exploder("trap_fx_a_red"); // turn off lights
    exploder::stop_exploder("trap_fx_a_green"); // turn off lights


    electric_trap_structs = struct::get_array(self.target);
    array::thread_all(electric_trap_structs, &electric_trap_fx_thread, self);

    parts = getentarray(self.target, "targetname");

    activate_triggers = [];
    curr_activ_trig_count = 0;

    handles = [];
    curr_handle_count = 0;

    foreach(part in parts){
        switch (part.script_string){
            case "trigger_damage":
                damage_trigger = part;
                break;
            case "trigger_activate":
                activate_triggers[curr_activ_trig_count] = part;
                curr_activ_trig_count++;
                break;
            case "handle":
                handles[curr_handle_count] = part;
                curr_handle_count++;
                break;
        }
    }

    damage_trigger thread electric_trap_damage_thread(self);

    foreach (trig in activate_triggers){
	    trig SetCursorHint("HINT_NOICON");
        trig SetHintString(TRAP_HINT_STRING_NO_POWER);
    }

    level waittill("power_on");

    foreach(trig in activate_triggers){
        trig thread trap_trigger_thread(self);
    }

    while(1){
        exploder::exploder("trap_fx_a_green"); // trun on lights

        foreach(trig in activate_triggers){
            trig TriggerEnable(true);
            trig SetHintString(TRAP_HINT_STRING);
        }

        self waittill("electric_trap_init");
        exploder::stop_exploder("trap_fx_a_green");
        exploder::exploder("trap_fx_a_red");

        // Trap on
        damage_trigger PlaySound("electric_trap_start");

        // Disable triggers
        foreach(trig in activate_triggers){
            trig TriggerEnable(false);
        }

        // Move handles down
        foreach(handle in handles){
            handle PlaySound("electric_trap_flip");
            handle RotatePitch(90, .25);
        }
        wait .25;
        foreach(handle in handles){
            handle RotatePitch(90, .25);
        }
        wait .25;
        
        // Manage Timing and Sounds
        self.on = true;
        self notify("electric_trap_on");
        self.sfx PlayLoopSound("electric_trap_loop", 1);

        // Slowly move handles up
        foreach(handle in handles){
            handle PlaySound("electric_trap_flip");
            handle RotatePitch(-90, TRAP_DURATION/2);
        }
        wait TRAP_DURATION/2;
        foreach(handle in handles){
            handle RotatePitch(-90, TRAP_DURATION/2);
        }
        wait TRAP_DURATION/2;

        // Turn off trap
        self.sfx StopLoopSound(1);
        self.on = false;
        self notify("electric_trap_off");

        wait TRAP_COOLDOWN;
        exploder::stop_exploder("trap_fx_a_red");
        
        // play ready sound
    }
}

// self = trigger_use
function trap_trigger_thread(trap){
    while(1){
        self waittill("trigger", player);
        // Purchace
        if(player try_purchase(TRAP_COST)){
            trap notify("electric_trap_init");
            trap waittill("electric_trap_off");
        }
    }
}

// Self = trigger_multiple
function electric_trap_damage_thread(trap){
    while(1){
        if(trap.on){
            zombies = GetAiSpeciesArray( "all" );
            foreach(zombie in zombies){
                if(zombie IsTouching(self)){
                    zombie PlaySound("electric_trap_pop");
                    zombie PlaySound("electric_trap_sizzle");
                    zombie Kill();
                }
            }
            players = GetPlayers();
            foreach(player in players){
                if(player IsTouching(self)){
                    if(isdefined(player.electric_cooldown)){
                        if(!player.electric_cooldown){
                            player thread damage_player();
                        }
                    }
                    else{
                        player thread damage_player();
                    }
                }
            }
        }
        wait .1;
    }
}

// self = player
function damage_player(){
    self.electric_cooldown = true;
    self PlaySound("electric_trap_sizzle");
    self SetMoveSpeedScale(0.5);
    self DoDamage(TRAP_DAMAGE, self.origin);
    self SetElectrified(1.5);
    wait TRAP_PLAYER_DAMAGE_COOLDOWN;
    self.electric_cooldown = false;
    self SetMoveSpeedScale(1);
}


// Self = fx_struct
function electric_trap_fx_thread(trap){
    while(1){
        trap waittill("electric_trap_on");
        self.fx = util::spawn_model("tag_origin", self.origin);
        self.fx clientfield::set( LIGHTNING_FX, 1 );
        trap waittill("electric_trap_off");
        self.fx delete();
    }
}

// for buying it
function try_purchase(cost){
    // self = player
	if(self.score < cost)
	{
		self playsound("evt_perk_deny");
		self zm_audio::create_and_play_dialog( "general", "outofmoney" );
        return false;
	}

	self zm_score::minus_to_player_score(cost);
    self playsound("zmb_cha_ching");
    return true;
}
