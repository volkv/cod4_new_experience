#include code\file;

init()
{		
	thread code\events::addConnectEvent( ::onConnect );
	/#
	thread code\events::addSpawnEvent( ::onSpawn );
	#/
}

onSpawn()
{
	/#
	if( getDvarInt( "ending_editor" ) > 0 )
		self thread code\ending::editor();
	#/
}

onConnect()
{
	self endon( "disconnect" );	
	
	if( !isDefined( self.pers[ "fullbright" ] ) )
	{
		if( level.dvar[ "fs_players" ] )
			self thread FSLookup();
		else
			self thread statLookup();
	}
	
	if( !isDefined( self.pers[ "meleekills" ] ) )
	{
		self.pers[ "meleekills" ] = 0;
		self.pers[ "explosiveKills" ] = 0;
	}
	
	if( !isArray( self.pers[ "youVSfoe" ] ) )
	{
		self.pers[ "youVSfoe" ] = [];
		self.pers[ "youVSfoe" ][ "killedBy" ] = [];
		self.pers[ "youVSfoe" ][ "killed" ] = [];
	}
	
	self.pers[ "rads" ] = 0;
	
	self setClientDvar( "ui_ShowMenuOnly", "" ); // if admin rotates the map while in killcam
	
	/////////////////////////////////////////////////
	// Things we need to do on spawn but only once //
	/////////////////////////////////////////////////
	self waittill( "spawned_player" );
	
	if( level.dvar[ "geowelcome" ] && !isDefined( self.pers[ "welcomed" ] ) )
		self thread welcome();
	
	while( !isDefined( self.pers[ "hardpointSType" ] ) )
		wait .05;
	
	self thread userSettings();
	
	wait .05;
	
	if( level.dvar[ "gun_position" ] )
		self setClientDvars( "cg_gun_move_u", "1.5",
							 "cg_gun_move_f", "-1",
							 "cg_gun_ofs_u", "1",
							 "cg_gun_ofs_r", "-1",
							 "cg_gun_ofs_f", "-2" );
							 
	wait .05;
						 
	if( level.dvar[ "promod_sniper" ] )
		self setClientDvars( "player_breath_gasp_lerp", "0",
						 	 "player_breath_gasp_time", "0",
							 "player_breath_gasp_scale", "0", 
							 "cg_drawBreathHint", "0" );
							 
	if( level.dvar[ "fs_players" ] )
	{
		while( !isDefined( self.pers[ "sigma" ] ) )
			wait .05;

		guid = self getGuid();
		level.FSCD[ guid ] = [];
		level.FSCD[ guid ][ level.FSCD[ guid ].size ] = "fullbright;" + self.pers[ "fullbright" ];
		level.FSCD[ guid ][ level.FSCD[ guid ].size ] = "fov;" + self.pers[ "fov" ];
		level.FSCD[ guid ][ level.FSCD[ guid ].size ] = "promodTweaks;" + self.pers[ "promodTweaks" ];
		level.FSCD[ guid ][ level.FSCD[ guid ].size ] = "hardpointSType;" + self.pers[ "hardpointSType" ];
		level.FSCD[ guid ][ level.FSCD[ guid ].size ] = "killcamText;" + self.pers[ "killcamText" ];
		level.FSCD[ guid ][ level.FSCD[ guid ].size ] = "mu;" + self.pers[ "mu" ];
		level.FSCD[ guid ][ level.FSCD[ guid ].size ] = "sigma;" + self.pers[ "sigma" ];
	}
}

/*
Index:
	0 = Fullbright
	1 = Fov
	2 = Promod
	3 = ShopBtn
	4 = Mean
	5 = Variance
	6 = Killcam text
*/
FSLookup()
{
	path = "./ne_db/players/" + self getGuid() + ".db";
	array = readFile( path );
	
	if( !isArray( array ) || array.size < 7 )
	{
		FSDefault();
		return;
	}
	
	// Integer values
	n = 0;
	for( i = 0; i < 4; i++ )
	{
		tok = strTok( array[ i ], ";" );
		self.pers[ tok[ 0 ] ] = int( tok[ 1 ] );
		n++;
	}
	
	
	tok = strTok( array[ i ], ";" );
	self.pers[ tok[ 0 ] ] = tok[ 1 ];
	n++;
	
	
	for( i = n; i < array.size; i++ )
	{
		tok = strTok( array[ i ], ";" );
		self.pers[ tok[ 0 ] ] = code\trueskill::floatNoDvar( tok[ 1 ] );
	}
}

FSDefault()
{
	self.pers[ "fullbright" ] = level.dvar[ "default_fps" ];
	self.pers[ "fov" ] = level.dvar[ "default_fov" ];
	self.pers[ "promodTweaks" ] = level.dvar[ "default_promod" ];
	self.pers[ "hardpointSType" ] = level.dvar[ "shopbuttons_default" ];
	self.pers[ "killcamText" ] = level.dvar[ "kct_default" ];
	// Trueskill
	self.pers[ "mu" ] = 25;
	self.pers[ "sigma" ] = 25 / 3;
}

FSSave( guid )
{
	if( !isDefined( level.FSCD[ guid ] ) )
		return;

	path = "./ne_db/players/" + guid + ".db";
	
	writeToFile( path, level.FSCD[ guid ] );
	
	wait .05;
	
	level.FSCD[ guid ] = undefined;
}

statLookup()
{
	self endon( "disconnect" );
	
	if( level.dvar["cmd_fps"] )
		self.pers[ "fullbright" ] = self getStat( 3160 );
	else
		self.pers[ "fullbright" ] = level.dvar[ "default_fps" ];
		
	wait .05;
			
	if( level.dvar["cmd_fov"] )
		self.pers[ "fov" ] = self getStat( 3161 );
	else
		self.pers[ "fov" ] = level.dvar[ "default_fov" ];
		
	wait .05;
			
	if( level.dvar["cmd_promod"] )
		self.pers[ "promodTweaks" ] = self getStat( 3162 );
	else
		self.pers[ "promodTweaks" ] = level.dvar[ "default_promod" ];
		
	wait .05;
	
	if( level.dvar[ "shopbuttons_allowchange" ] )
		self.pers[ "hardpointSType" ] = self getStat( 3163 );
	else
		self.pers[ "hardpointSType" ] = level.dvar[ "shopbuttons_default" ];
		
	waittillframeend;
		
	if( abs( self.pers[ "fov" ] > 2 ) )
	{
		self.pers[ "fov" ] = 0;
		self setstat( 3161, 0 );
		self setClientDvar( "cg_fovscale", 1.0 );
		self setClientDvar( "cg_fov", 80 );
		self iprintlnbold( "Error: illegal fov value, setting 3161 to 0" );
	}
	
	waittillframeend;
		
	if( self.pers[ "fullbright" ] != 1 && self.pers[ "fullbright" ] != 0 )
	{
		self setstat( 3160, 0 );
		self.pers[ "fullbright" ] = 0;
		self iprintlnbold( "Error: illegal fullbright value, setting 3160 to 0" );
	}
	
	waittillframeend;
		
	if( self.pers[ "promodTweaks" ] != 1 && self.pers[ "promodTweaks" ] != 0 )
	{
		self setstat( 3162, 0 );
		self.pers[ "promodTweaks" ] = 0;
		self iprintlnbold( "Error: illegal promod value, setting 3162 to 0" );
	}
	
	waittillframeend;
			
	if( self.pers[ "hardpointSType" ] != 1 && self.pers[ "hardpointSType" ] != 0 )
	{
		self setstat( 3163, 0 );
		self.pers[ "hardpointSType" ] = 0;
		self iprintlnbold( "Error: illegal shop value, setting 3163 to 0" );
	}
}

userSettings()
{
	switch( self.pers[ "fov" ] )
	{
		case 0:
			self setClientDvar( "cg_fovscale", 1.0 );
			self setClientDvar( "cg_fov", 80 );
			break;
		case 1:
			self setClientDvar( "cg_fovscale", 1.125 );
			self setClientDvar( "cg_fov", 80 );
			break;
		case 2:
			self setClientDvar( "cg_fovscale", 1.25 );
			self setClientDvar( "cg_fov", 80 );
			break;
		default:
			self.pers[ "fov" ] = 0;
			self setstat( 3161, 0 );
			self setClientDvar( "cg_fovscale", 1.0 );
			self setClientDvar( "cg_fov", 80 );
			self iprintlnbold( "Error: illegal fov value, setting 3161 to 0" );
			break;
	}
	
	if( self.pers[ "fullbright" ] == 1 )
		self setClientDvar( "r_fullbright", 1 );
	else
		self setClientDvar( "r_fullbright", 0 );
		
	waittillframeend;
	
	if( self.pers[ "promodTweaks" ] == 1 )
		self SetClientDvars( "r_filmTweakInvert", "0",
                     	     "r_filmTweakBrightness", "0",
                     	     "r_filmusetweaks", "1",
                     	     "r_filmTweakenable", "1",
                      	     "r_filmtweakLighttint", "0.8 0.8 1",
                       	     "r_filmTweakContrast", "1.2",
                       	     "r_filmTweakDesaturation", "0",
                       	     "r_filmTweakDarkTint", "1.8 1.8 2" );
	else
		self SetClientDvars( "r_filmusetweaks", "0",
							 "r_filmTweakenable", "0" );
}

welcome()
{
	dvar = "welcome_" + self getEntityNumber();
	
	if( getDvar( dvar ) == self getPlayerID() ) // Player is already welcomed
	{
		self.pers[ "welcomed" ] = true;
		return;
	}
	
	exec( "say Welcome^5 " + self.name + " ^7from ^5" + self getGeoLocation( 2 ) );
	
	setDvar( dvar, self getPlayerID() );
	
	self.pers[ "welcomed" ] = true;
}

isVIP()
{
	vips = [];
	vips[ vips.size ] = "[U:12:345678]";
	
	player = self getPlayerID();
	
	for( i = 0; i < vips.size; i++ )
	{
		if( player == vips[ i ] )
			return true;
	}
	
	return false;
}