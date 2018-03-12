#define MISYS_META 		0
#define MISYS_WATCH 	1
#define MISYS_BUILDINGS 2
#define MISYS_PROPS 	3
#define MISYS_STATIC 	4
#define MISYS_COMPS 	5
#define MISYS_SPECIAL 	5
#define MGRIF_CONFIGROOT missionConfigFile


params [
	["_pos",[]],
	["_dir",0],
	["_compPos",[]],
	["_compDir",0],
	["_faction","Fia"],
	["_strength",1],
	["_compObjs",[]]
];

private ["_config","_veh", "_vehs"];

//TODO: create special component objs array in all components
_pad = (_compObjs select MISYS_SPECIAL) select 0;
_vehs = [];
_config = (MGRIF_CONFIGROOT >> "CfgMgrifFactions" >> _faction  >> "cars");

_groups = [];

// in base
{
	
	if((count _config)>0) then {
		_veh = [_faction,"cars",(position _x)] call mgrif_fnc_misys_createVehicle;
		//_veh setVariable ["BIS_enableRandomization", false];
		_veh setDir (getDir _x);
		_vehs pushBack _veh;
		
	};
} foreach (_compObjs select MISYS_SPECIAL);

_config = (MGRIF_CONFIGROOT >> "CfgMgrifFactions" >> _faction  >> "cars");
_mountedPatrols = [];

{
	_config = (MGRIF_CONFIGROOT >> "CfgMgrifFactions" >> _faction  >> "carsTurret");
	if(count _config  > 0) then {
		_mppos = [_pos, 4,33,false] call mgrif_fnc_misys_safePosCompound;
		_veh = [_faction,"carsTurret",_mppos,true] call mgrif_fnc_misys_createVehicle;
		_mpgrp = group ((crew _veh) select 0);
		_mountedPatrols pushBack _mpgrp;
	};
} forEach [1];

//out of base
// [Groups, loot vehicles, props]
// groups: [Local Compound Patrols, AO Patrols,Special groups]
[
	[
		[],
		_mountedPatrols,
		[]
	],
	_vehs,
	[]
]