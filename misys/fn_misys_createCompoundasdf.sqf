#define MISYS_META 		0
#define MISYS_WATCH 	1
#define MISYS_BUILDINGS 2
#define MISYS_PROPS 	3
#define MISYS_STATIC 	4
#define MISYS_COMPS 	5
#define MGRIF_CONFIGROOT missionconfigFile

//old faction system macros
#define MGRIF_TRAIT_S(FAC,TRAIT) getText MGRIF_FACTION_TRAIT(FAC,TRAIT)
#define MGRIF_FACTION_TRAIT_N(FAC,TRAIT) getNumber MGRIF_FACTION_TRAIT(FAC,TRAIT)
#define MGRIF_FACTION_TRAIT_A(FAC,TRAIT) getArray MGRIF_FACTION_TRAIT(FAC,TRAIT)
#define MGRIF_FACTION_TRAIT(FAC,TRAIT) (MGRIF_CONFIGROOT >> "cfgMgrifFactions" >> FAC >> TRAIT)


params [
	["_name",0],
	["_size",0],
	["_pos",0],
	["_dir",0],
	["_faction","FIA"],
	["_comps",[]],
	["_compNames", []],
	["_strength", 1],
	["_radius", 33]
];




private ["_file","_compound","_compSizes","_provided"];

//Load mission data
_file = getText(MGRIF_CONFIGROOT >> "CfgMisysCompounds" >> _size >> _name >> "file");
_compound = [_file,_pos,_dir] call mgrif_fnc_misys_createComposition;

_compSizes = getArray (MGRIF_CONFIGROOT >> "CfgMisysCompounds" >> _size >> _name >> "components");


if((count _compNames) == 0) then {
	_compNames = [];
	{_compNames pushback "rand"} foreach _compSizes;
};

_compReturns = [];


//
_provided = 
[
	[
		[],	//local patrols
		[], //AO Patrols
		[] // Special Groups
	],
	[], //loot vehicles
	[] //props
];

if(count (_compSizes) > 0) then {
	//pre-choose comp names if random, so a full component list can be provided to the component function call
	_compNames apply {
		if(_x == "rand") then {
			_comp = (MGRIF_CONFIGROOT >> "CfgMisysCompoundComponents" >> (_comps select _forEachIndex) >> _x);
			
			hint ("arr" + str _comp);
			configName ([_comp] call mgrif_fnc_misys_selectRandomConfig)
		} else {
			_x
		}
	};
	//hint str _compNames;
	{
		_comp = (MGRIF_CONFIGROOT >> "CfgMisysCompoundComponents" >> (_comps select _forEachIndex) >> _x);
		_compPos = position ((_compound select MISYS_COMPS) select _forEachIndex);
		_compDir = getDir ((_compound select MISYS_COMPS) select _forEachIndex);
		
		_compName = _compNames select _forEachIndex;
		_compFile = "";
		_compConfig = (_comp >> _compName);
		_compFile = getText (_compConfig >> "file");
		_compObjs = [
						_compFile,
						_compPos,
						_compDir
					] call mgrif_fnc_misys_createComposition;
		
		_compCustom = [_pos, _dir, _compPos, _compDir, _faction, _strength, _compObjs] call call compile getText (MGRIF_CONFIGROOT >> "CfgMisysCompoundComponents" >> (_comps select _forEachIndex) >> "function");
		
		
		//Set up provided
		//add local patrols
		{((_provided select 0) select _forEachIndex) append _x } forEach (_compCustom select 0);
		
		//add provided groups to groups provided by compound
		{(_provided select _x) append (_compCustom select _x)} forEach [1,2];

		{
			//TODO: edge case index 0 (should remain in array, instead of just being appended)
			(_compound select _forEachIndex) append _x;
		} foreach _compObjs;
	} foreach _compSizes;
	
	{deleteVehicle _x} foreach (_compound select MISYS_COMPS);
};

//AI
//------------------------------------------------------------------------------------------------------------
_buildingGroups = [];
{
	_buildingGroup = createGroup OPFOR;
	_bpos = (_x buildingPos -1);
	{
		if((random 1) >0.75) then {
			_unit = 	[
      			'rifleman',
      			_buildingGroup,
     			_x,
                _faction
                ] call mgrif_fnc_misys_createUnit;
        _unit setUnitPos "UP";
        doStop _unit;
		};
	} foreach _bpos;
	_buildingGroups pushBack _buildingGroup;
} foreach (_compound select MISYS_BUILDINGS); 


_watchGroup = createGroup OPFOR;
{
    
    _bpos = (_x buildingPos -1);
    _highest = _bpos select 0;
    {
        if(_highest select 2 == _x select 2 && random 1 >=0.5) then {
            _highest = _x;
        };
        if((_highest select 2)< (_x select 2)) then {
           // hint format ["old height %1 , new height %2",_highest select 2, _x select 2];
            _highest = _x;
            
        };
    } forEach _bpos;

    
    if(true) then { //random 1 >= 0.3
         _unit = 	[
      			'marksman',
      			_watchgroup,
     			_highest,
                _faction
                ] call mgrif_fnc_misys_createUnit;
       // [_unit] join _watchGroup; 
        _unit setDir random 359;
        _unit setPos _highest;
        _unit setUnitPos "UP";
        doStop _unit;
		_unit disableAI "PATH";
    };
    
    
   if(true) then { //_strength >0.75 && (random 1 > 0.5)
      _unit = 	[
      			'grenadier',
      			_watchgroup,
     			_bpos select (round random ((count _bpos)-1)),
                _faction
                ] call mgrif_fnc_misys_createUnit;
      //[_unit] join _watchGroup;
	  
      _unit setPos (_bpos select (round random ((count _bpos)-1)));
  	  _unit setDir random 359;
      _unit setUnitPos "UP";
      doStop _unit;
	  _unit disableAI "PATH";
   };
 
} foreach (_compound select MISYS_WATCH); 


//Spawn foot patrols
_patrolGroups = [];
_patrolCount = 2;
for "_i" from  1 to (round (_strength*(_patrolCount))) do {
    _patrolGroup = createGroup OPFOR;
    _patrolGroups pushBack _patrolGroup;
    _safePos = [_pos, _radius, _radius+10, 3, 0, 20, 0] call BIS_fnc_findSafePos;
    for "_i" from 1 to (_patrolCount) do {
      	 _unit = 	[
      			'rifleman',
      			_patrolGroup,
     			_safePos,
                _faction
                ] call mgrif_fnc_misys_createUnit;
                
    };
    //[_patrolgroup, _pos, 100] call BIS_fnc_taskPatrol;
};
{((_provided select 0) select 0) pushBack _x } forEach _patrolGroups; //todo: should probably append

{
	[_x, _compoundPos, 100,[[_compoundPos,33]]] call BIS_fnc_taskPatrol;
} forEach _patrolGroups;

_groups = [[_watchGroup],_buildingGroups];


[_compound,_groups,_provided]












