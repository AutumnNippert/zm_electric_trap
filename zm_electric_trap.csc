#using scripts\codescripts\struct;

#using scripts\shared\audio_shared;
#using scripts\shared\callbacks_shared;
#using scripts\shared\clientfield_shared;
#using scripts\shared\scene_shared;
#using scripts\shared\util_shared;
#using scripts\shared\system_shared;

#insert scripts\shared\shared.gsh;
#insert scripts\shared\version.gsh;

#insert scripts\zm\_zm_utility.gsh;
#insert scripts\zm\zm_electric_trap.gsh;

#using scripts\zm\_load;

#namespace zm_electric_trap;

#precache( "client_fx", LIGHTNING_FX );

REGISTER_SYSTEM_EX( "zm_electric_trap", &__init__, &__main__, undefined )

function __init__(){
	clientfield::register( "scriptmover", LIGHTNING_FX, VERSION_SHIP, 1, "int", &electric_fx, !CF_HOST_ONLY, !CF_CALLBACK_ZERO_ON_NEW_ENT );
}

function __main__(){}

// self = fx
function electric_fx( localClientNum, oldVal, newVal, bNewEnt, bInitialSnap, fieldName, bWasTimeJump )
{
    if( newVal )
        if( !isdefined( self.fx ) )
            self.fx = PlayFXOnTag( localClientNum, LIGHTNING_FX , self, "tag_origin" );
    else
    {
        if( isdefined( self.fx ) )
            DeleteFX( localClientNum, self.fx );
        self.fx = undefined;
    }
}