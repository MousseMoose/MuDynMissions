#define MUCONFIGROOT missionConfigFile


/*_class = _this select 0;
_group = _this select 1;
_pos = _this select 2;
_faction = _this select 3;*/
params [
		"_group",
		"_pos",
		"_faction"];



_class = (getArray (MUCONFIGROOT >> "CfgMgrifFactions" >> _faction >> "availableStandardLoadouts")) selectRandomWeighted  (getArray (MUCONFIGROOT >> "CfgMgrifFactions" >> _faction >>"standardLoadoutWeights"));
_unit = [_class, _group, _pos, _faction] call mgrif_fnc_misys_createUnit;
_unit


