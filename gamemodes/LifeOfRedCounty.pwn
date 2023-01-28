/*

	Гейммод: Life of Red County
	Автор: sTrIx
	Разработван през: 2023г.

*/
/*================================================================================

	PLUGINS:
	MySQL		R41-4 	https://github.com/pBlueG/SA-MP-MySQL/releases/tag/R41-4
	Streamer	2.7.7	https://github.com/samp-incognito/samp-streamer-plugin/releases/tag/v2.9.5
	sscanf		2.13.8	https://github.com/Y-Less/sscanf/releases/tag/v2.13.8
	Whirlpool	1.0  	https://github.com/Southclaws/samp-whirlpool/releases

	OTHER RESOURCES:
	foreach		19		https://github.com/karimcambridge/samp-foreach
	i-zcmd		0.2.2   https://github.com/YashasSamaga/I-ZCMD
================================================================================*/

/*
	Списък със задачи:
	- Да направя въвеждане на пол на персонажа [Готово]
	- Да оправя въведените данни при регистриран персонаж [Готово]
	- Да оправя възможноста друг човек да си създаде персонаж, който съществува вече [Готово]
	- При изтриване на персонаж, да се трият и оръжията му [Работено върху | Статус: Тест]
	- Да зарежда оръжията на играча при Spawn [Работено върху | Статус: Тест]
	- Да зарежда оръжията на играча от базата данни при Login [Работено върху | Статус: Тест]
	- При смърт за възстановява оръжията на играча [Работено върху | Статус: Тест]
	
	//---------------------------------------------------//
	
	Възможни бъгове:
	- Запаметяването и зареждането на оръжията на даден играч от базата данни
	
*/

#include <a_samp>

#include <streamer>
#include <sscanf2>
#include <foreach>
#include <a_mysql>
#include <zcmd>
#include <easyDialog>
#include <memory>
#include <sort>
#include <tommyb_lookup>
#include <eSelection>
#include <d-connector>

//SERVER INFORMATION:

#define SERVER_RCON "12345678"
#define SERVER_NAME "[BG] Life of Red County [0.3.7]"
#define SERVER_VERSION "0.1"
#define SERVER_GAMEMODE "LRC: " SERVER_VERSION
#define SERVER_AUTHOR "sTrIx"
#define SERVER_SITE "OFFICIAL SITE: SOON"

//DATABASE INFORMATION:

#define DB_SERVER_LOCAL   0
#define DB_SERVER_DEV     1
#define DB_SERVER_MAIN    2

#define DB_SERVER   DB_SERVER_LOCAL

//DATABASE CONNECTION INFORMATION:

#if DB_SERVER == DB_SERVER_LOCAL
	#define DB_HOST "localhost"
	#define DB_USER "root"
	#define DB_NAME "lrc"
	#define DB_PASSWORD ""
#elseif DB_SERVER == DB_SERVER_DEV
	#define DB_HOST "localhost"
	#define DB_USER "root"
	#define DB_NAME "lrc"
	#define DB_PASSWORD ""
#elseif DB_SERVER == DB_SERVER_MAIN
	#define DB_HOST "localhost"
	#define DB_USER "root"
	#define DB_NAME "lrc"
	#define DB_PASSWORD ""
#endif

//CLIENT MESSAGES
#define SendClientMessageF(%1,%2,%3) SendClientMessage(%1, %2, (format(sgstr, sizeof(sgstr), %3), sgstr))

//PLAYER CHARACTERS
#define MAX_PLAYER_CHARACTERS 3

//GENDERS:
#define GENDER_MALE 0
#define GENDER_FEMALE 1

//MAX DEFINES
#define MAX_ATMS 17

//COLORS:

#define COLOR_RED 			0xE60000FF
#define COLOR_WHITE 		0xFFFFFFFF
#define COLOR_GOLD			0xFFD700FF
#define COLOR_GREEN			0x40BF00FF
#define COLOR_FADE3			0xAAAAAAAA
#define COLOR_LIGHTGREEN	0x00FF00FF

//TEXTDRAWS
new Text:SelectCharacter_1;
new Text:SelectCharacter_2;
new Text:SelectCharacter_3;
new Text:SelectCharacter_BTN[MAX_PLAYER_CHARACTERS][MAX_PLAYERS];
new Text:SelectCharacter_CHAR[MAX_PLAYER_CHARACTERS][MAX_PLAYERS];
new Text:DeleteCharacter_BTN[MAX_PLAYER_CHARACTERS][MAX_PLAYERS];
new Text: Clock;
new Text: Website;

//PLAYER INFORMATION:
new bool: selectedCharacter[MAX_PLAYERS] = false;
new bool: Logged[MAX_PLAYERS] = false;
new LoginScreenID[MAX_PLAYERS][2];
new wrongPassword[MAX_PLAYERS] = 0;
new characterName[MAX_PLAYERS][MAX_PLAYER_CHARACTERS][MAX_PLAYER_NAME];
new characterDelete[MAX_PLAYERS];

//TEMPORARY PLAYER INFORMATION:
new newCharacter_Name[MAX_PLAYERS][MAX_PLAYER_NAME];
new birthday_year[MAX_PLAYERS];
new nationality[MAX_PLAYERS][30];
new gender[MAX_PLAYERS];

//TIMERS
new OneSecondTimer;

enum pInfo
{
	ORM: ORM_ID,
	ID,
	CharacterID[MAX_PLAYER_CHARACTERS],
	CurrentCharacterID,
	Name[MAX_PLAYER_NAME],
	Cache:Data,
	pPassword[32],
	pAdmin
}
new PlayerInfo[MAX_PLAYERS][pInfo];

enum CHARACTER_INFO
{
	ID,
	cFaction,
	cSkin,
	cYear,
	cMonth,
	cDay,
	cHour,
	cMinute,
	cSecond,
	cBirthday,
	cNationality[30],
	cGender,
	Float: cX,
	Float: cY,
	Float: cZ,
	Float: cAngle,
	cInterior,
	cVirtualWorld
}
new CharacterInfo[MAX_PLAYERS][CHARACTER_INFO];

enum WEAPON_DATA
{
	WeaponID,
	Weapon,
	WeaponAmmo
};
new PlayerWeaponData[MAX_PLAYERS][12][WEAPON_DATA];

//DB INFORMATION:
new MySQL:Database;

//SERVER INFORMATION:
new Float:ClassSelectionData[13][12] =
{
	{1439.0410, -221.8372, 22.7985, 1440.0046, -221.5518, 22.6933, 1636.5062, -66.9961, 70.3919, 1635.6693, -66.4367, 70.2167},
	{180.9195, 1138.8217, 27.7668, 181.3019, 1139.7499, 27.6417, -270.1440, 1205.6362, 46.1036, -271.0848, 1205.2869, 45.9885},
	{-174.8245, 341.1865, 16.5733, -174.5815, 342.1605, 16.4633, -210.2901, -118.1688, 46.9579, -209.3116, -117.9448, 46.6678},
	{182.8430, -404.5717, 14.6186, 183.8444, -404.6406, 14.5386, 427.5617, -154.8631, 41.8298, 426.5782, -154.6632, 41.4898},
	{1004.3258, -376.9207, 94.2813, 1005.0281, -376.2045, 93.9662, 1312.7808, 79.5683, 59.5385, 1312.6805, 80.5663, 59.2334},
	{1317.0122, 477.7603, 29.6383, 1317.8527, 477.2135, 29.6082, 1454.9969, 225.1299, 50.8671, 1453.9943, 225.1293, 50.6120},
	{1833.4757, -130.9368, 50.2288, 1834.3181, -130.3933, 50.0187, 2347.2859, 224.9401, 63.6775, 2347.0322, 223.9702, 63.2974},
	{2248.0591, 453.6871, 21.3100, 2247.5483, 452.8203, 21.3448, 2076.9285, -166.3638, 29.7962, 2077.4338, -165.4950, 29.5760},
	{932.2772, -574.8990, 116.6781, 932.6947, -573.9850, 116.3879, 597.8068, -477.2111, 42.7448, 598.6305, -477.7866, 42.3495},
	{-69.3941, 302.7461, 13.7824, -70.2654, 302.2455, 13.7571, -477.1172, -199.8384, 95.6078, -477.7337, -199.0445, 95.3326},
	{-1486.9976, 755.0239, 62.4289, -1486.0818, 755.4375, 62.3287, -319.6878, 1481.4557, 107.3692, -319.9124, 1480.4750, 107.0441},
	{416.0463, 2537.4595, 19.3093, 415.3760, 2536.7065, 19.2141, 82.3415, 2306.4563, 50.6167, 81.5734, 2307.1150, 50.5914},
	{-2048.1794, -2572.1389, 38.6077, -2048.5913, -2571.2131, 38.5520, -2250.4536, -1491.6262, 690.8711, -2250.4121, -1492.6443, 690.0442}
};
new serverYear;
new serverMonth;
new serverDay;
new serverHr;
new serverMn;
new serverSec;
new sgstr[256];
new AtmObjectID[MAX_ATMS];

//TIMERS:
forward InterpolateCameraOnLogin(playerid);
forward KickPlayer(playerid);
forward Spawn(playerid);
forward OneSecTimer();
forward SelectedCharacterSpawn(playerid);

//SERVER FORWARDS:
forward OnPlayerLogin(playerid);
forward OnPlayerRegister(playerid);
forward OnPlayerDataLoaded(playerid);
forward OnPlayerLoadCharacter(playerid);
forward ShowPlayerCharacterSelection(playerid);
forward OnPlayerSelectCharacter(playerid, character);
forward OnPlayerCreatingCharacter(playerid, character);
forward OnCreateCharacter(playerid);
forward JustConnected(playerid);
forward OnDeleteCharacter(playerid, character);

main()
{
	print("\n----------------------------------");
	print("" SERVER_NAME " " SERVER_VERSION" | Author: "SERVER_AUTHOR"");
	print("----------------------------------\n");
}

public OnGameModeInit()
{
	SendRconCommand("hostname "SERVER_NAME"");
	SendRconCommand("rcon_password "SERVER_RCON"");
	//SendRconCommand("loadfs Maps1");
	//SendRconCommand("loadfs Maps2");
	//SendRconCommand("loadfs MapsLS");
	SetGameModeText(SERVER_GAMEMODE);
	ConnectToDB();
	DisableInteriorEnterExits();
	EnableStuntBonusForAll(0);
	AddPlayerClass(0, 1958.3783, 1343.1572, 15.3746, 269.1425, 0, 0, 0, 0, 0, 0);
	DefineTextDraws();
	CreateAllObjects();
	
	new hr, mn, sec, y, m, d;
	gettime(hr, mn, sec);
	getdate(y, m, d);
	serverYear = y;
	serverMonth = m;
	serverDay = d;
	serverHr = hr;
	serverMn = mn;
	serverSec = sec;
	
	OneSecondTimer = SetTimer("OneSecTimer", 1000, 1);
	return 1;
}

public OnGameModeExit()
{
	printf("OnGameModeExit in process..");
	KillTimer(OneSecondTimer);
	return 1;
}

public OnPlayerRequestClass(playerid, classid)
{
	new Float: X, Float: Y, Float: Z, Float: Angle;
	X = CharacterInfo[playerid][cX];
	Y = CharacterInfo[playerid][cY];
	Z = CharacterInfo[playerid][cZ];
	Angle = CharacterInfo[playerid][cAngle];
	new skin = CharacterInfo[playerid][cSkin];
	SetSpawnInfo(playerid, 0, skin, X, Y, Z, Angle, 0, 0, 0, 0, 0, 0);
	return 1;
}

public OnPlayerConnect(playerid)
{
	DefinePlayerTextDraws(playerid);
	ResetAllPlayerData(playerid);
	JustConnectedScreens(playerid);
	SetTimerEx("JustConnected", 500, false, "i", playerid);
	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	DestroyPlayerTextDraws(playerid);
	SavePlayerStats(playerid);
	ExitFromCharacter(playerid);
	ResetAllPlayerData(playerid);
	return 1;
}

public OnPlayerSpawn(playerid)
{
	if(!selectedCharacter[playerid])
	{
		TogglePlayerSpectating(playerid, 1);
		SetTimerEx("ShowPlayerCharacterSelection", 500, false, "i", playerid);
		return 0;
	}
	ArmPlayerWeapons(playerid);
	return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
	SavePlayerWeapons(playerid);
	return 1;
}

public OnVehicleSpawn(vehicleid)
{
	return 1;
}

public OnVehicleDeath(vehicleid, killerid)
{
	return 1;
}

public OnPlayerText(playerid, text[])
{
	if(!Logged[playerid]) return false;
	if(!selectedCharacter[playerid]) return false;
	
	format(sgstr, sizeof(sgstr),"%s says: %s", PlayerRPName(playerid), text);
	foreach(new i: Player)
	{
		SendSplitMessage(i, COLOR_FADE3, sgstr);
	}
	return 0;
}

public OnPlayerEnterVehicle(playerid, vehicleid, ispassenger)
{
	return 1;
}

public OnPlayerExitVehicle(playerid, vehicleid)
{
	return 1;
}

public OnPlayerStateChange(playerid, newstate, oldstate)
{
	return 1;
}

public OnPlayerEnterCheckpoint(playerid)
{
	return 1;
}

public OnPlayerLeaveCheckpoint(playerid)
{
	return 1;
}

public OnPlayerEnterRaceCheckpoint(playerid)
{
	return 1;
}

public OnPlayerLeaveRaceCheckpoint(playerid)
{
	return 1;
}

public OnRconCommand(cmd[])
{
	return 1;
}

public OnPlayerRequestSpawn(playerid)
{
	
	return 1;
}

public OnObjectMoved(objectid)
{
	return 1;
}

public OnPlayerObjectMoved(playerid, objectid)
{
	return 1;
}

public OnPlayerPickUpPickup(playerid, pickupid)
{
	return 1;
}

public OnVehicleMod(playerid, vehicleid, componentid)
{
	return 1;
}

public OnVehiclePaintjob(playerid, vehicleid, paintjobid)
{
	return 1;
}

public OnVehicleRespray(playerid, vehicleid, color1, color2)
{
	return 1;
}

public OnPlayerSelectedMenuRow(playerid, row)
{
	return 1;
}

public OnPlayerExitedMenu(playerid)
{
	return 1;
}

public OnPlayerInteriorChange(playerid, newinteriorid, oldinteriorid)
{
	return 1;
}

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	return 1;
}

public OnRconLoginAttempt(ip[], password[], success)
{
	return 1;
}

public OnPlayerUpdate(playerid)
{
	return 1;
}

public OnPlayerStreamIn(playerid, forplayerid)
{
	return 1;
}

public OnPlayerStreamOut(playerid, forplayerid)
{
	return 1;
}

public OnVehicleStreamIn(vehicleid, forplayerid)
{
	return 1;
}

public OnVehicleStreamOut(vehicleid, forplayerid)
{
	return 1;
}

public OnPlayerClickPlayer(playerid, clickedplayerid, source)
{
	 
	return 1;
}

public OnPlayerClickTextDraw(playerid, Text:clickedid)
{
	if(!selectedCharacter[playerid])
	{
		for(new i=0; i<MAX_PLAYER_CHARACTERS; i++)
		{
			//Enter in Character
			if(clickedid == SelectCharacter_BTN[i][playerid])
			{
				if(GetPlayerCharacter(playerid, i) == -1)
				{
					OnPlayerCreatingCharacter(playerid, i);
				}
				else
				{
					new query[256];
					mysql_format(Database, query, sizeof(query), "SELECT * FROM characters WHERE name = '%e'", characterName[playerid][i]);
					mysql_pquery(Database, query, "OnPlayerSelectCharacter", "dd", playerid, i);
				}
			}
			
			//Delete Character
			if(clickedid == DeleteCharacter_BTN[i][playerid])
			{
				if(GetPlayerCharacter(playerid, i) == -1)
				{
					OnPlayerCreatingCharacter(playerid, i);
				}
				else
				{
					characterDelete[playerid] = i;
					new string[256];
					format(string, sizeof(string), "Вие сте напът да изтриете своя персонаж!\n\nВажно: Няма връщане назад и след като изтриете персонажа си губите неговата статистика завинаги!");
					Dialog_Show(playerid, DeleteCharacter, DIALOG_STYLE_MSGBOX, "{FFFFFF}Delete Character", string, "Напред", "Откажи");
				}
			}
		}
	}
}

Dialog:DeleteCharacter(playerid, response, listitem, inputtext[])
{
	if(!response)
	{
		ShowPlayerCharacterSelection(playerid);
		return 1;
	}
	new character = characterDelete[playerid];
	new query[256];
	mysql_format(Database, query, sizeof(query), "DELETE FROM characters WHERE `characters`.`name` = '%e'", characterName[playerid][character]);
	mysql_pquery(Database, query, "OnDeleteCharacter", "dd", playerid, character);
	return 0;
}

Dialog:Login(playerid, response, listitem, inputtext[])
{
	if(!response)
	{
		SendClientMessage(playerid, COLOR_RED, "SERVER: Ти пожела да напуснеш сървъра, без да влезеш в профила си!");
		return 1;
	}
	new passLen = strlen(inputtext);
	if(passLen == 0)
	{
		ShowLoginBox(playerid);
		return 1;
	}
	new query[256];
	mysql_format(Database, query, sizeof(query), "SELECT * FROM players WHERE name = '%e' AND password = MD5('%e')", PlayerInfo[playerid][Name], inputtext);
	mysql_pquery(Database, query, "OnPlayerLogin", "d", playerid);
	return 0;
}

Dialog:Register(playerid, response, listitem, inputtext[])
{
	if(!response)
	{
		SendClientMessage(playerid, COLOR_RED, "SERVER: Ти пожела да напуснеш сървъра, без да се регистрираш!");
		return 1;
	}
	new passLen = strlen(inputtext);
	if(passLen == 0)
	{
		ShowRegisterBox(playerid);
		return 1;
	}
	else if(passLen < 4)
	{
		SendClientMessage(playerid, COLOR_RED, "SERVER: Паролата трябва да бъде с дължина поне 4 символа!");
		ShowRegisterBox(playerid);
		return 1;
	}
	new query[128];
	mysql_format(Database, query, sizeof(query), "INSERT INTO players (name, password) VALUES ('%e', MD5('%e'))", PlayerInfo[playerid][Name], inputtext);
	mysql_pquery(Database, query, "OnPlayerRegister", "d", playerid);
	return 0;
}

Dialog:Name(playerid, response, listitem, inputtext[])
{
	if(!response)
	{
		ShowPlayerCharacterSelection(playerid);
		return 1;
	}
	if(!IsValidCharacter(inputtext))
	{
		SendClientMessage(playerid, COLOR_RED, "Въведеното от вас име за персонаж съдържа забранени символи!");
		ShowPlayerCharacterSelection(playerid);
		return 1;
	}
	if(!IsRpName(inputtext))
	{
		SendClientMessage(playerid, COLOR_RED, "Въведеното от вас име задължително трябва да съдържа символа '_', разделящ името от фамилията!");
		ShowPlayerCharacterSelection(playerid);
		return 1;
	}
	if(!AvailableCharacterName(inputtext))
	{
		SendClientMessage(playerid, COLOR_RED, "Въведеното име от вас е заето от друг играч!");
		ShowPlayerCharacterSelection(playerid);
		return 1;
	}
	if(!IsAvailableNickname(inputtext))
	{
		SendClientMessage(playerid, COLOR_RED, "Въведеното име от вас е заето от друг играч!");
		ShowPlayerCharacterSelection(playerid);
		return 1;
	}
	if(strlen(inputtext) < 6 || strlen(inputtext) >= MAX_PLAYER_NAME)
	{
		SendClientMessage(playerid, COLOR_RED, "Въведеното от вас име за персонаж е с неподходяща дължина!");
		ShowPlayerCharacterSelection(playerid);
		return 1;
	}
	strunpack(newCharacter_Name[playerid], inputtext);
	new string[256];
	format(string, sizeof(string), "Избери мъжки пол\nИзбери женски пол");
	Dialog_Show(playerid, Gender, DIALOG_STYLE_LIST, "{FFFFFF}Gender", string, "Въведи", "Излез");
	return 0;
}

Dialog:Gender(playerid, response, listitem, inputtext[])
{
	if(!response)
	{
		ShowPlayerCharacterSelection(playerid);
		return 1;
	}
	switch(listitem)
	{
		case 0:
		{
			gender[playerid] = GENDER_MALE;
		}
		case 1:
		{
			gender[playerid] = GENDER_FEMALE;
		}
	}
	new string[256];
	format(string, sizeof(string), "Вие успешно въведохте желания от вас пол\nМоля, въведете и неговата година на раждане, съобразете се, че персонажът трябва да е на поне 18 години");
	Dialog_Show(playerid, Birthday_Year, DIALOG_STYLE_INPUT, "{FFFFFF}Birthday Year", string, "Въведи", "Излез");
	return 0;
}

Dialog:Birthday_Year(playerid, response, listitem, inputtext[])
{
	if(!response)
	{
		ShowPlayerCharacterSelection(playerid);
		return 1;
	}
	new year = strval(inputtext);
	if(year < 1950)
	{
		SendClientMessage(playerid, COLOR_RED, "Годината на раждане трябва да е след 1950-та");
		ShowPlayerCharacterSelection(playerid);
		return 1;
	}
	if(serverYear-year < 18)
	{
		SendClientMessage(playerid, COLOR_RED, "Вашата възраст не може да бъде под 18 години! Моля, въведете друга дата на раждане");
		ShowPlayerCharacterSelection(playerid);
		return 1;
	}
	birthday_year[playerid] = year;
	new string[128];
	format(string, sizeof(string), "Вие сте на последната стъпка от създаването на нов персонаж!\nНапишете държавата, където е роден персонажът");
	Dialog_Show(playerid, Nationality, DIALOG_STYLE_INPUT, "{FFFFFF}Nationality", string, "Въведи", "Излез");
	return 0;
}

Dialog:Nationality(playerid, response, listitem, inputtext[])
{
	if(!response)
	{
		ShowPlayerCharacterSelection(playerid);
	}
	new len = strlen(inputtext);
	if(len < 3 || len > 30)
	{
		SendClientMessage(playerid, COLOR_RED, "Дължината на държавата трябва да е между 3 и 30 символа!");
		ShowPlayerCharacterSelection(playerid);
		return 1;
	}
	strunpack(nationality[playerid], inputtext);
	OnCreateCharacter(playerid);
	return 0;
}

CMD:help(playerid, params[])
{
	if(!Logged[playerid]) return true;
	if(!selectedCharacter[playerid]) return true;
	
	if(isnull(params))
	{
		SendClientMessage(playerid, COLOR_LIGHTGREEN, "Life of Red County Help - Usage: /Help [Section]");
		SendClientMessage(playerid, COLOR_WHITE, "Sections: General, Chats, Faction, Bizz, House, Motel, Furniture, Vehicle, Job, Fish, Phone, Crate, Donator, Bank, Helper");
		return true;
	}
	
	return true;
}

stock CreateAllObjects()
{
	//t0mbXD house grass
	new tmpobjid;
	tmpobjid = CreateDynamicObject(19552, 2239.027587, 41.496765, 24.090850, 90.600028, 0.100000, 0.000000, 159753, 5, -1, 300.00, 300.00);
	SetDynamicObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "ferry_build14", 0x00000000);
//	new grass = CreateDynamicObject(11524, -1731.61719, 1916.03906, 8.00881, 0.00000, 0.00000, 0.00000, -1, -1, -1, 200.0, 200.0, SilverRectangle);
//	SetDynamicObjectMaterial(grass, 0, 8463, "vgseland", "Grass_128HV");
//Placas com nome
	CreateDynamicObject(6189, 668.85333251953, -480.76791381836, 1917.4122314453, 0.0, 0.0, 0.0); // Post Office Ground
	CreateDynamicObject(14707, 1208.40527344, -2.27636719, 1160.51879883, 0.0, 0.0, 0.0); // Icy house ground
	CreateDynamicObject(6189, 1258.9625244141, 264.68673706055, 1272.8072509766, 0.0, 0.0, 0.0); //EMS ground
	CreateDynamicObject(14596, -672.10375977, 2618.67211914, 63.06771469, 0.0, 0.0, 180.0); // Aperture Base Ground
	CreateDynamicObject(5154, 1213.193359375, 291.5390625, 1327.5843505859, 0.0, 0.0, 0.0); //Ambulance ground
	CreateDynamicObject(6300, 1248.8973388672, 103.31694030762, 3165.6589355469, 0.0, 0.0, 0.0); // DMV Avard Ground
	CreateDynamicObject(7301, -208.80000305, 1053.19995117, 22.17000008, 45.0, 90.0, 0.0); // FC elec shop roof glitch fix
	CreateDynamicObject(8613,930.6300049,1658.8120117,11.4099998,0.0,0.0,0.0, 0, 0); //object(vgssstairs03_lvs) (1) fbi hq roof access stair
	CreateDynamicObject(1498, 308.67001342773, 312.10000610352, 1002.299987793, 0.0, 0.0, 0.0, 12345, 4); // komars object for blue dynasty roof room

	CreateDynamicObject(3337, 948.59997559, -186.39999390, 10.0, 0.0, 0.0, 176.0);
	new signage = CreateDynamicObject(3337, 948.59997559, -186.39999390, 10.0, 0.0, 0.0, 176.0);
	SetDynamicObjectMaterialText(signage, 1, "CAUTION\n\nBlind Summit\nSLOW", OBJECT_MATERIAL_SIZE_256x128, "Arial", 32, 1, 0xFFFFFFFF, 0, OBJECT_MATERIAL_TEXT_ALIGN_CENTER);

	CreateDynamicObject(3337,-301.79998779,-2797.30004883,55.50000000,0.0,0.0,343.99996948); //service stn 1
	new serviceStn1 = CreateDynamicObject(3337,-301.79998779,-2797.30004883,55.50000000,0.0,0.0,343.99996948);
	SetDynamicObjectMaterialText(serviceStn1, 1, "FLINT COUNTY HWY\n\nServices 1 Mile\nAngel Pine 2 Miles", OBJECT_MATERIAL_SIZE_256x128, "Arial", 24, 1, 0xFFFFFFFF, 0, OBJECT_MATERIAL_TEXT_ALIGN_CENTER);

	CreateDynamicObject(3337,-1013.09997559,-2843.19995117,66.19999695,0.0,0.0,357.99841309); //service stn 1
	new serviceStn2 = CreateDynamicObject(3337,-1013.09997559,-2843.19995117,66.19999695,0.0,0.0,357.99841309);
	SetDynamicObjectMaterialText(serviceStn2, 1, "Angel Pine Service Station\nFood - Fuel - Motel\n\n>> Next Right >>", OBJECT_MATERIAL_SIZE_256x128, "Arial", 24, 1, 0xFFFFFFFF, 0, OBJECT_MATERIAL_TEXT_ALIGN_CENTER);

	CreateDynamicObject(3337,-117.69999695,1548.09997559,16.39999962,0.0,0.0,276.0); //aperture rules
	new aperSign1 = CreateDynamicObject(3337,-117.69999695,1548.09997559,16.39999962,0.0,0.0,276.0);
	SetDynamicObjectMaterialText(aperSign1, 1, "NOTICE\nHAVE ID READY FOR INSPECTION\nSTRICTLY NO PHOTOGRAPHY\nAUTHORIZED PERSONNEL ONLY", OBJECT_MATERIAL_SIZE_256x128, "Impact", 18, 1, 0xFFFFFFFF, 0, OBJECT_MATERIAL_TEXT_ALIGN_CENTER);

	CreateDynamicObject(3337,-101.50000000,1549.80004883,16.39999962,0.0,0.0,275.99853516); //aperture sign
	new aperSign2 = CreateDynamicObject(3337,-101.50000000,1549.80004883,16.39999962,0.0,0.0,275.99853516);
	SetDynamicObjectMaterialText(aperSign2, 1, "Aperture CORPORATION\nSan Andreas\nResearch Facility", OBJECT_MATERIAL_SIZE_256x128, "Impact", 28, 1, 0xFFFFFFFF, 0, OBJECT_MATERIAL_TEXT_ALIGN_CENTER);

	// ATM Bank Machines
	AtmObjectID[0] = CreateDynamicObject(2942, 2334.31900000, 57.43700000, 26.12700000, 0.0, 0.0, -270.0);
	AtmObjectID[1] = CreateDynamicObject(2942, 1289.75200000, 273.56800000, 19.19800000, 0.0, 0.0, -293.359);
	AtmObjectID[2] = CreateDynamicObject(2942, 1341.81347656, 215.34375000, 19.19000053, 0.0, 0.0, 156.63757324);
	AtmObjectID[3] = CreateDynamicObject(2942, 256.54600000, -62.21300000, 1.22100000, 0.0, 0.0, -720.859);
	AtmObjectID[4] = CreateDynamicObject(2942, 703.02148438, -494.71777344, 15.97900009, 0.0, 0.0, 179.13757324);
	AtmObjectID[5] = CreateDynamicObject(2942, 661.34863281, -554.77050781, 15.97900009, 0.0, 0.0, 269.13757324);
	AtmObjectID[6] = CreateDynamicObject(2942, 242.53222656, -184.89648438, 1.22099996, 0.0, 0.0, 270.85693359);
	AtmObjectID[7] = CreateDynamicObject(2942, -131.19999695, 1188.59997559, 19.39999962, 0.0, 0.0, 180.0);
	AtmObjectID[8] = CreateDynamicObject(2942, -856.50976562, 1533.20898438, 22.22994232, 0.0, 0.0, 90.0);
	AtmObjectID[9] = CreateDynamicObject(2942, -1215.40844727, 1825.91003418, 41.36164856, 0.0, 0.0, 45.67);
	AtmObjectID[10] = CreateDynamicObject(2942, -1475.02624512, 2610.81567383, 55.47883606, 0.0, 0.0, 0.0);
	AtmObjectID[11] = CreateDynamicObject(2942, 666.40185547, 1720.49011230, 6.83039951, 0.0, 0.0, 220.42041016);
	AtmObjectID[12] = CreateDynamicObject(2942, -1569.48681641, -2727.05493164, 48.38635635, 0.0, 0.0, 325.52026367);
	AtmObjectID[13] = CreateDynamicObject(2942, -2102.25488281, -2344.01367188, 30.26789856, 0.0, 0.0, 321.63574219);
	AtmObjectID[14] = CreateDynamicObject(2942, -2175.36132812, -2327.61328125, 30.24289894, 0.0, 0.0, 51.36108398);
	AtmObjectID[15] = CreateDynamicObject(2942, -2490.62890625, 2341.37695312, 4.62727451, 0.0, 0.0, 0.0);
	AtmObjectID[16] = CreateDynamicObject(19324, 1231.685, 184.435, 2090.9982, 0.000, 0.000, 90.000);

	// Speed Cameras
	CreateDynamicObject(18880, 1369.40234375, -10.28515625, 32.73462677, 0.0, 0.0, 131.99523920, 0, 0); //montgomery view
	CreateDynamicObject(18880, 1378.34667969, -19.87597656, 32.75024796, 0.0, 0.0, 311.99523926, 0, 0); //montgomery view
	CreateDynamicObject(18880, 820.33007812, -162.55371094, 17.70354652, 0.0, 0.0, 83.99597168, 0, 0); //highway 48 (fern ridge area)
	CreateDynamicObject(18880, 831.44335938, -176.01562500, 17.38158417, 0.0, 0.0, 264.24316406, 0, 0); //highway 48 (fern ridge area)
	CreateDynamicObject(18880, 402.91210938, 150.30175781, 6.69789505, 0.0, 0.0, 129.99572754, 0, 0); //highway 46 (blueberry area)
	CreateDynamicObject(18880, 412.17871094, 138.59960938, 6.67972755, 0.0, 0.0, 311.99523926, 0, 0); //highway 46 (blueberry area)
	CreateDynamicObject(18880, 330.92172241, 1374.40954590, 6.48725891, 0.0, 0.0, 164.0, 0, 0); //route 7 (near the oil refinery)
	CreateDynamicObject(18880, 344.32153320, 1370.46325684, 6.48395348, 0.0, 0.0, 343.99841309, 0, 0); //route 7 (near the oil refinery)
	CreateDynamicObject(18880, 1837.73315430, 378.55950928, 18.10695457, 0.0, 0.0, 69.5, 0, 0); //highway 46 (between monty and pc)
	CreateDynamicObject(18880, 1833.79199219, 366.68319702, 17.95963478, 0.0, 0.0, 251.49951172, 0, 0); //highway 46 (between monty and pc)
	CreateDynamicObject(18880, 2053.50561523, 48.21620178, 26.32803345, 0.0, 0.0, 91.49902344, 0, 0); //pc red bridge
	CreateDynamicObject(18880, 2054.16333008, 33.18312836, 26.27503586, 0.0, 0.0, 271.49414062, 0, 0); //pc red bridge
	return true;
}

stock ArmPlayerWeapons(playerid)
{
	new slot, weapon, ammo;
	for (new i = 0; i < 12; i++)
	{
		slot = i;
		if (PlayerWeaponData[playerid][slot][Weapon] != 0)
		{
			weapon = PlayerWeaponData[playerid][slot][Weapon];
			ammo = PlayerWeaponData[playerid][slot][WeaponAmmo];
			GivePlayerWeapon(playerid, weapon, ammo);
		}
	}
}

stock DeleteAllPlayerWeapons(playerid)
{
	new slot;
	for(new i=0; i<12; i++)
	{
		slot = i;
		DeletePlayerWeaponFromDB(playerid, slot);
	}
}

stock DeletePlayerWeaponFromDB(playerid, slot)
{
	new query[256], rows, Cache:result;
	if(PlayerWeaponData[playerid][slot][Weapon] != 0)
	{
		//CHECK IF PLAYER HAS WEAPON IN DB:
		mysql_format(Database, query, sizeof(query), "SELECT * FROM player_weapons WHERE id = '%d'",
			PlayerWeaponData[playerid][slot][WeaponID]);
		result = mysql_query(Database, query);
		
		
		cache_get_row_count(rows);
		cache_delete(result);
		//DELETE WEAPON FROM DB:
		if(rows != 0)
		{
			mysql_format(Database, query, sizeof(query), "DELETE FROM player_weapons WHERE `player_weapons`.`id` = '%d'", PlayerWeaponData[playerid][slot][WeaponID]);
			mysql_pquery(Database, query);
		}
	}
}

stock SendSplitMessage(playerid, color, const msg[])
{
	new ml = 115, result[160], len = strlen(msg), repeat;
	if(len > ml)
	{
		repeat = (len / ml);
		for(new i = 0; i <= repeat; i++)
		{
			result[0] = 0;
			if(len - (i * ml) > ml)
			{
				strmid(result, msg, ml * i, ml * (i+1));
				format(result, sizeof(result), "%s", result);
			}
			else
			{
				strmid(result, msg, ml * i, len);
				format(result, sizeof(result), "%s", result);
			}
			SendClientMessage(playerid, color, result);
		}
	}
	else
	{
		SendClientMessage(playerid, color, msg);
	}
	return true;
}

stock ShowPlayerMainTextDraws(playerid)
{
	TextDrawShowForPlayer(playerid, Clock);
	TextDrawShowForPlayer(playerid, Website);
}

stock HidePlayerMainTextDraws(playerid)
{
	TextDrawHideForPlayer(playerid, Clock);
	TextDrawHideForPlayer(playerid, Website);
}

stock randomex(min, max)
{
	//Credits to y_less
	new rand = random(max - min) + min;
	return rand;
}

stock ChooseRandomSkin(playerid)
{
	new rndSkin = randomex(0, 3);
	new skin;
	if(CharacterInfo[playerid][cGender] == GENDER_MALE)
	{
		switch(rndSkin)
		{
			case 0:
			{
				skin = 1;
			}
			case 1:
			{
				skin = 3;
			}
			case 2:
			{
				skin = 7;
			}
		}
	}
	else
	{
		switch(rndSkin)
		{
			case 0:
			{
				skin = 9;
			}
			case 1:
			{
				skin = 69;
			}
			case 2:
			{
				skin = 12;
			}
		}
	}
	CharacterInfo[playerid][cSkin] = skin;
}

stock IsAvailableNickname(const nickname[])
{
	foreach(new p: Player)
	{
		if(!strcmp(nickname, GetPlayerNickname(p)))
		{
			return false;
		}
	}
	return true;
}

stock AvailableCharacterName(const nickname[])
{
	new query[256];
	mysql_format(Database, query, sizeof(query), "SELECT * FROM characters WHERE name = '%e'", nickname);
	new Cache:result = mysql_query(Database, query);
	new rows = -1;
	cache_get_row_count(rows);
	cache_delete(result);
	if(rows == 0)
	{
		return true;
	}
	return false;
}

stock IsValidCharacter(const fname[])
{
	if(strfind(fname, " ") != -1 || strfind(fname, "\\") != -1 || strfind(fname, "/") != -1 || strfind(fname, ":") != -1 || strfind(fname, "*") != -1 || strfind(fname, "?") != -1 || strfind(fname, "\"") != -1 || strfind(fname, "<") != -1 || strfind(fname, ">") != -1 || strfind(fname, "|") != -1 || strfind(fname, ".") != -1) return false; //"
	return true;
}

stock IsRpName(const text[])
{
	if(strfind(text, "_", true) != -1)
	{
		return true;
	}
	return false;
}

stock JustConnectedScreens(playerid)
{
	new query[128];
	GetPlayerName(playerid, PlayerInfo[playerid][Name], MAX_PLAYER_NAME);
	mysql_format(MYSQL_DEFAULT_HANDLE, query, sizeof(query), "SELECT * FROM `players` WHERE `name` = '%e' LIMIT 1", PlayerInfo[playerid][Name]);
	mysql_tquery(MYSQL_DEFAULT_HANDLE, query, "OnPlayerDataLoaded", "d", playerid);
	
	TogglePlayerSpectating(playerid, 1);
	SetTimerEx("InterpolateCameraOnLogin", 100, false, "i", playerid);
}

stock ShowRegisterBox(playerid)
{
	new string[128];
	format(string, sizeof(string), "{FFFFFF}Вашият профил не е регистриран!\nЗа да го регистирате трябва да въведете паролата ви отдолу");
	Dialog_Show(playerid, Register, DIALOG_STYLE_PASSWORD, "{FFFFFF}Register", string, "Въведи", "Излез");
}

stock ShowLoginBox(playerid)
{
	new string[128];
	format(string, sizeof(string), "{FFFFFF}Вашият профил е регистриран!\nТрябва да въведете паролата ви отдолу");
	Dialog_Show(playerid, Login, DIALOG_STYLE_PASSWORD, "{FFFFFF}Login", string, "Въведи", "Излез");
}

stock CloseDB()
{
	mysql_close(Database);
}

stock ConnectToDB()
{
	mysql_log(ALL);
	Database = mysql_connect(
		DB_HOST, // Host
		DB_USER, // User
		DB_PASSWORD, // Password
		DB_NAME		//DataBase Name
	);
	printf("[MYSQL]: Connecting to `%s` ...", DB_NAME);
	if(mysql_errno(Database) != 0)
	{
		print("[MYSQL]: Connection not successfull!");
		printf("[MYSQL ERROR]: %d", mysql_errno(Database));
		return 1;
	}
	else
	{
		print("[MYSQL]: Connection is successfull!");
	}
	return 0;
}

stock ResetCharacterData(playerid)
{
	CharacterInfo[playerid][cFaction] = 0;
	CharacterInfo[playerid][cSkin] = 0;
	CharacterInfo[playerid][cYear] = 0;
	CharacterInfo[playerid][cMonth] = 0;
	CharacterInfo[playerid][cDay] = 0;
	CharacterInfo[playerid][cHour] = 0;
	CharacterInfo[playerid][cMinute] = 0;
	CharacterInfo[playerid][cBirthday] = 0;
	CharacterInfo[playerid][cSecond] = 0;
}

stock ResetPlayerData(playerid)
{
	ResetCharacterData(playerid);
	PlayerInfo[playerid][pAdmin] = 0;
	for(new i=0; i<MAX_PLAYER_CHARACTERS; i++)
	{
		PlayerInfo[playerid][CharacterID][i] = -1;
	}
}

stock ResetPlayerVariables(playerid)
{
	selectedCharacter[playerid] = false;
	Logged[playerid] = false;
	for(new i=0; i<2; i++)
	{
		LoginScreenID[playerid][i] = 0;
	}
	for(new i=0; i<MAX_PLAYER_CHARACTERS; i++)
	{
		format(characterName[playerid][i], MAX_PLAYER_NAME, " ");
	}
	wrongPassword[playerid]=0;
}

stock ResetAllPlayerData(playerid)
{
	cache_delete(PlayerInfo[playerid][Data]);
	ResetPlayerData(playerid);
	ResetPlayerVariables(playerid);
}

stock GetPlayerNickname(playerid)
{
	new name[MAX_PLAYER_NAME];
	GetPlayerName(playerid, name, sizeof(name));
	return name;
}

stock LoadCharacterWeapons(playerid)
{
	new query[256], rows;
	new Cache: result;
	for(new i=0; i<12; i++)
	{
		mysql_format(Database, query, sizeof(query), "SELECT * FROM player_weapons WHERE player = '%e'",
					GetPlayerNickname(playerid));
		result = mysql_query(Database, query);
		cache_get_row_count(rows);
		
		//LOAD WEAPONS DATA:
		cache_get_value_name_int(0, "weapon_id", PlayerWeaponData[playerid][i][Weapon]);
		cache_get_value_name_int(0, "weapon_ammo", PlayerWeaponData[playerid][i][WeaponAmmo]);
		
		//DELETE CACHE:
		cache_delete(result);
	}
}

stock SavePlayerWeapons(playerid)
{
	new slot;
	for(new i=0; i<12; i++)
	{
		slot = i;
		GetPlayerWeaponData(playerid, slot, PlayerWeaponData[playerid][slot][Weapon], PlayerWeaponData[playerid][slot][WeaponAmmo]);
	}
}

stock SaveCharacterWeaponsDB(playerid)
{
	new weapon, ammo, slot, query[256];
	new Cache: result, rows;
	for(new i=0; i<12; i++)
	{
		slot = i;
		GetPlayerWeaponData(playerid, slot, weapon, ammo);
		if(ammo > 0)
		{
			//CHECK IF PLAYER HAS WEAPON IN DB:
			mysql_format(Database, query, sizeof(query), "SELECT * FROM player_weapons WHERE id = '%d'",
				PlayerWeaponData[playerid][slot][WeaponID]);
			result = mysql_query(Database, query);
			
			cache_get_row_count(rows);
			cache_delete(result);
			if(rows == 0)
			{
				//INSERT WEAPON INTO DB:
				mysql_format(Database, query, sizeof(query), "INSERT INTO player_weapons (player) VALUES ('%e')",
					GetPlayerNickname(playerid));
				mysql_query(Database, query);
			}
			
			//UPDATE PLAYER WEAPONS:
			mysql_format(Database, query, sizeof(query), "UPDATE player_weapons SET weapon_id = '%d', weapon_ammo = '%d', player = '%e' WHERE id = '%d' ",
				PlayerWeaponData[playerid][slot][Weapon], PlayerWeaponData[playerid][slot][WeaponAmmo], GetPlayerNickname(playerid),
				PlayerWeaponData[playerid][slot][WeaponID]);
			mysql_pquery(Database, query);
		}
		else
		{
			if(PlayerWeaponData[playerid][slot][Weapon] != 0)
			{
				DeletePlayerWeaponFromDB(playerid, slot);
			}
		}
	}
	return 0;
}

stock SaveCharacterCoords(playerid)
{
	new Float: X, Float: Y, Float: Z, Float: Angle;
	GetPlayerPos(playerid, X, Y, Z);
	GetPlayerFacingAngle(playerid, Angle);
	CharacterInfo[playerid][cX] = X;
	CharacterInfo[playerid][cY] = Y;
	CharacterInfo[playerid][cZ] = Z;
	CharacterInfo[playerid][cAngle] = Angle;
	CharacterInfo[playerid][cInterior] = GetPlayerInterior(playerid);
	CharacterInfo[playerid][cVirtualWorld] = GetPlayerVirtualWorld(playerid);
}

stock SaveCharacterStats(playerid)
{
	SaveCharacterCoords(playerid);
	SaveCharacterWeaponsDB(playerid);
	if(!selectedCharacter[playerid]) return 1;
	new query[2048];
	mysql_format(Database, query, sizeof(query), "UPDATE characters SET faction = '%d', skin = '%d', last_year = '%d', last_month = '%d', last_day = '%d', last_hour = '%d', last_minute = '%d', last_second = '%d' WHERE id = '%d' ",
			CharacterInfo[playerid][cFaction],
			CharacterInfo[playerid][cSkin],
			CharacterInfo[playerid][cYear],
			CharacterInfo[playerid][cMonth],
			CharacterInfo[playerid][cDay],
			CharacterInfo[playerid][cHour],
			CharacterInfo[playerid][cMinute],
			CharacterInfo[playerid][cSecond],
			PlayerInfo[playerid][CurrentCharacterID]);
	mysql_query(Database, query);
	
	mysql_format(Database, query, sizeof(query), "UPDATE characters SET birthday_year = '%d', nationality = '%e', gender = '%d' WHERE id = '%d' ",
			CharacterInfo[playerid][cBirthday],
			CharacterInfo[playerid][cNationality],
			CharacterInfo[playerid][cGender],
			PlayerInfo[playerid][CurrentCharacterID]);
	mysql_query(Database, query);
	
	mysql_format(Database, query, sizeof(query), "UPDATE characters SET pos_x = '%f', pos_y = '%f', pos_z = '%f', pos_angle = '%f', interior = '%d', virtual_world = '%d' WHERE id = '%d' ",
			CharacterInfo[playerid][cX],
			CharacterInfo[playerid][cY],
			CharacterInfo[playerid][cZ],
			CharacterInfo[playerid][cAngle],
			CharacterInfo[playerid][cInterior],
			CharacterInfo[playerid][cVirtualWorld],
			PlayerInfo[playerid][CurrentCharacterID]);
	mysql_query(Database, query);
	return 0;
}

stock SavePlayerStats(playerid)
{
	if(!Logged[playerid]) return 1;

	new query[256];
	mysql_format(Database, query, sizeof(query), "UPDATE users SET admin = '%d' WHERE id = '%d'",
		PlayerInfo[playerid][pAdmin], PlayerInfo[playerid][ID]);
	mysql_pquery(Database, query);
	return 0;
}

stock LoadPlayerCharacters(playerid)
{
	new query[256];
	mysql_format(Database, query, sizeof(query), "SELECT * FROM characters WHERE player = '%e'", PlayerInfo[playerid][Name]);
	mysql_pquery(Database, query, "OnPlayerLoadCharacter", "d", playerid);
}

stock ExitFromCharacter(playerid)
{
	SetPlayerName(playerid, PlayerInfo[playerid][Name]);
	SaveCharacterStats(playerid);
}

stock DestroyPlayerTextDraws(playerid)
{
	for(new i=0; i<MAX_PLAYER_CHARACTERS; i++)
	{
		TextDrawDestroy(SelectCharacter_BTN[i][playerid]);
		TextDrawDestroy(SelectCharacter_CHAR[i][playerid]);
		TextDrawDestroy(DeleteCharacter_BTN[i][playerid]);
	}
}

stock DefinePlayerTextDraws(playerid)
{
	SelectCharacter_BTN[0][playerid] = TextDrawCreate(190.000000, 289.000000, "John Ivanov");
	TextDrawFont(SelectCharacter_BTN[0][playerid], 2);
	TextDrawLetterSize(SelectCharacter_BTN[0][playerid], 0.258332, 1.750000);
	TextDrawTextSize(SelectCharacter_BTN[0][playerid], 16.500000, 90.500000);
	TextDrawSetOutline(SelectCharacter_BTN[0][playerid], 1);
	TextDrawSetShadow(SelectCharacter_BTN[0][playerid], 0);
	TextDrawAlignment(SelectCharacter_BTN[0][playerid], 2);
	TextDrawColor(SelectCharacter_BTN[0][playerid], -1);
	TextDrawBackgroundColor(SelectCharacter_BTN[0][playerid], 255);
	TextDrawBoxColor(SelectCharacter_BTN[0][playerid], 200);
	TextDrawUseBox(SelectCharacter_BTN[0][playerid], 1);
	TextDrawSetProportional(SelectCharacter_BTN[0][playerid], 1);
	TextDrawSetSelectable(SelectCharacter_BTN[0][playerid], 1);

	SelectCharacter_BTN[1][playerid] = TextDrawCreate(321.000000, 289.000000, "John Ivanov 2");
	TextDrawFont(SelectCharacter_BTN[1][playerid], 2);
	TextDrawLetterSize(SelectCharacter_BTN[1][playerid], 0.258332, 1.750000);
	TextDrawTextSize(SelectCharacter_BTN[1][playerid], 16.500000, 90.500000);
	TextDrawSetOutline(SelectCharacter_BTN[1][playerid], 1);
	TextDrawSetShadow(SelectCharacter_BTN[1][playerid], 0);
	TextDrawAlignment(SelectCharacter_BTN[1][playerid], 2);
	TextDrawColor(SelectCharacter_BTN[1][playerid], -1);
	TextDrawBackgroundColor(SelectCharacter_BTN[1][playerid], 255);
	TextDrawBoxColor(SelectCharacter_BTN[1][playerid], 200);
	TextDrawUseBox(SelectCharacter_BTN[1][playerid], 1);
	TextDrawSetProportional(SelectCharacter_BTN[1][playerid], 1);
	TextDrawSetSelectable(SelectCharacter_BTN[1][playerid], 1);

	SelectCharacter_BTN[2][playerid] = TextDrawCreate(439.000000, 289.000000, "John Ivanov 3");
	TextDrawFont(SelectCharacter_BTN[2][playerid], 2);
	TextDrawLetterSize(SelectCharacter_BTN[2][playerid], 0.258332, 1.750000);
	TextDrawTextSize(SelectCharacter_BTN[2][playerid], 16.500000, 90.500000);
	TextDrawSetOutline(SelectCharacter_BTN[2][playerid], 1);
	TextDrawSetShadow(SelectCharacter_BTN[2][playerid], 0);
	TextDrawAlignment(SelectCharacter_BTN[2][playerid], 2);
	TextDrawColor(SelectCharacter_BTN[2][playerid], -1);
	TextDrawBackgroundColor(SelectCharacter_BTN[2][playerid], 255);
	TextDrawBoxColor(SelectCharacter_BTN[2][playerid], 200);
	TextDrawUseBox(SelectCharacter_BTN[2][playerid], 1);
	TextDrawSetProportional(SelectCharacter_BTN[2][playerid], 1);
	TextDrawSetSelectable(SelectCharacter_BTN[2][playerid], 1);

	SelectCharacter_CHAR[0][playerid] = TextDrawCreate(149.000000, 173.000000, "Preview_Model");
	TextDrawFont(SelectCharacter_CHAR[0][playerid], 5);
	TextDrawLetterSize(SelectCharacter_CHAR[0][playerid], 0.600000, 2.000000);
	TextDrawTextSize(SelectCharacter_CHAR[0][playerid], 84.000000, 110.500000);
	TextDrawSetOutline(SelectCharacter_CHAR[0][playerid], 0);
	TextDrawSetShadow(SelectCharacter_CHAR[0][playerid], 0);
	TextDrawAlignment(SelectCharacter_CHAR[0][playerid], 1);
	TextDrawColor(SelectCharacter_CHAR[0][playerid], -1);
	TextDrawBackgroundColor(SelectCharacter_CHAR[0][playerid], 125);
	TextDrawBoxColor(SelectCharacter_CHAR[0][playerid], 255);
	TextDrawUseBox(SelectCharacter_CHAR[0][playerid], 0);
	TextDrawSetProportional(SelectCharacter_CHAR[0][playerid], 1);
	TextDrawSetSelectable(SelectCharacter_CHAR[0][playerid], 0);
	TextDrawSetPreviewModel(SelectCharacter_CHAR[0][playerid], 0);
	TextDrawSetPreviewRot(SelectCharacter_CHAR[0][playerid], -6.000000, 0.000000, -4.000000, 1.129999);
	TextDrawSetPreviewVehCol(SelectCharacter_CHAR[0][playerid], 1, 1);

	SelectCharacter_CHAR[1][playerid] = TextDrawCreate(279.000000, 173.000000, "Preview_Model");
	TextDrawFont(SelectCharacter_CHAR[1][playerid], 5);
	TextDrawLetterSize(SelectCharacter_CHAR[1][playerid], 0.600000, 2.000000);
	TextDrawTextSize(SelectCharacter_CHAR[1][playerid], 84.000000, 110.500000);
	TextDrawSetOutline(SelectCharacter_CHAR[1][playerid], 0);
	TextDrawSetShadow(SelectCharacter_CHAR[1][playerid], 0);
	TextDrawAlignment(SelectCharacter_CHAR[1][playerid], 1);
	TextDrawColor(SelectCharacter_CHAR[1][playerid], -1);
	TextDrawBackgroundColor(SelectCharacter_CHAR[1][playerid], 125);
	TextDrawBoxColor(SelectCharacter_CHAR[1][playerid], 255);
	TextDrawUseBox(SelectCharacter_CHAR[1][playerid], 0);
	TextDrawSetProportional(SelectCharacter_CHAR[1][playerid], 1);
	TextDrawSetSelectable(SelectCharacter_CHAR[1][playerid], 0);
	TextDrawSetPreviewModel(SelectCharacter_CHAR[1][playerid], 0);
	TextDrawSetPreviewRot(SelectCharacter_CHAR[1][playerid], -6.000000, 0.000000, -4.000000, 1.129999);
	TextDrawSetPreviewVehCol(SelectCharacter_CHAR[1][playerid], 1, 1);

	SelectCharacter_CHAR[2][playerid] = TextDrawCreate(396.000000, 173.000000, "Preview_Model");
	TextDrawFont(SelectCharacter_CHAR[2][playerid], 5);
	TextDrawLetterSize(SelectCharacter_CHAR[2][playerid], 0.600000, 2.000000);
	TextDrawTextSize(SelectCharacter_CHAR[2][playerid], 84.000000, 110.500000);
	TextDrawSetOutline(SelectCharacter_CHAR[2][playerid], 0);
	TextDrawSetShadow(SelectCharacter_CHAR[2][playerid], 0);
	TextDrawAlignment(SelectCharacter_CHAR[2][playerid], 1);
	TextDrawColor(SelectCharacter_CHAR[2][playerid], -1);
	TextDrawBackgroundColor(SelectCharacter_CHAR[2][playerid], 125);
	TextDrawBoxColor(SelectCharacter_CHAR[2][playerid], 255);
	TextDrawUseBox(SelectCharacter_CHAR[2][playerid], 0);
	TextDrawSetProportional(SelectCharacter_CHAR[2][playerid], 1);
	TextDrawSetSelectable(SelectCharacter_CHAR[2][playerid], 0);
	TextDrawSetPreviewModel(SelectCharacter_CHAR[2][playerid], 0);
	TextDrawSetPreviewRot(SelectCharacter_CHAR[2][playerid], -6.000000, 0.000000, -4.000000, 1.129999);
	TextDrawSetPreviewVehCol(SelectCharacter_CHAR[2][playerid], 1, 1);
	
	DeleteCharacter_BTN[0][playerid] = TextDrawCreate(190.000000, 316.000000, "DELETE 1");
	TextDrawFont(DeleteCharacter_BTN[0][playerid], 2);
	TextDrawLetterSize(DeleteCharacter_BTN[0][playerid], 0.258332, 1.750000);
	TextDrawTextSize(DeleteCharacter_BTN[0][playerid], 16.500000, 90.500000);
	TextDrawSetOutline(DeleteCharacter_BTN[0][playerid], 1);
	TextDrawSetShadow(DeleteCharacter_BTN[0][playerid], 0);
	TextDrawAlignment(DeleteCharacter_BTN[0][playerid], 2);
	TextDrawColor(DeleteCharacter_BTN[0][playerid], -1);
	TextDrawBackgroundColor(DeleteCharacter_BTN[0][playerid], 255);
	TextDrawBoxColor(DeleteCharacter_BTN[0][playerid], -1962934142);
	TextDrawUseBox(DeleteCharacter_BTN[0][playerid], 1);
	TextDrawSetProportional(DeleteCharacter_BTN[0][playerid], 1);
	TextDrawSetSelectable(DeleteCharacter_BTN[0][playerid], 1);

	DeleteCharacter_BTN[1][playerid] = TextDrawCreate(321.000000, 316.000000, "DELETE 2");
	TextDrawFont(DeleteCharacter_BTN[1][playerid], 2);
	TextDrawLetterSize(DeleteCharacter_BTN[1][playerid], 0.258332, 1.750000);
	TextDrawTextSize(DeleteCharacter_BTN[1][playerid], 16.500000, 90.500000);
	TextDrawSetOutline(DeleteCharacter_BTN[1][playerid], 1);
	TextDrawSetShadow(DeleteCharacter_BTN[1][playerid], 0);
	TextDrawAlignment(DeleteCharacter_BTN[1][playerid], 2);
	TextDrawColor(DeleteCharacter_BTN[1][playerid], -1);
	TextDrawBackgroundColor(DeleteCharacter_BTN[1][playerid], 255);
	TextDrawBoxColor(DeleteCharacter_BTN[1][playerid], -1962934142);
	TextDrawUseBox(DeleteCharacter_BTN[1][playerid], 1);
	TextDrawSetProportional(DeleteCharacter_BTN[1][playerid], 1);
	TextDrawSetSelectable(DeleteCharacter_BTN[1][playerid], 1);

	DeleteCharacter_BTN[2][playerid] = TextDrawCreate(440.000000, 316.000000, "DELETE 3");
	TextDrawFont(DeleteCharacter_BTN[2][playerid], 2);
	TextDrawLetterSize(DeleteCharacter_BTN[2][playerid], 0.258332, 1.750000);
	TextDrawTextSize(DeleteCharacter_BTN[2][playerid], 16.500000, 90.500000);
	TextDrawSetOutline(DeleteCharacter_BTN[2][playerid], 1);
	TextDrawSetShadow(DeleteCharacter_BTN[2][playerid], 0);
	TextDrawAlignment(DeleteCharacter_BTN[2][playerid], 2);
	TextDrawColor(DeleteCharacter_BTN[2][playerid], -1);
	TextDrawBackgroundColor(DeleteCharacter_BTN[2][playerid], 255);
	TextDrawBoxColor(DeleteCharacter_BTN[2][playerid], -1962934142);
	TextDrawUseBox(DeleteCharacter_BTN[2][playerid], 1);
	TextDrawSetProportional(DeleteCharacter_BTN[2][playerid], 1);
	TextDrawSetSelectable(DeleteCharacter_BTN[2][playerid], 1);
}

stock DefineTextDraws()
{
	Website = TextDrawCreate(36.0,429.0, SERVER_SITE);
	TextDrawAlignment(Website,0);
	TextDrawBackgroundColor(Website,0x000000FF);
	TextDrawFont(Website,2);
	TextDrawLetterSize(Website,0.199999,1.0);
	TextDrawColor(Website, 0x999999FF);
	TextDrawSetOutline(Website,1);
	TextDrawSetProportional(Website,1);
	TextDrawSetShadow(Website,1);

	Clock=TextDrawCreate(528.000000,25.500000,"  ~w~15:16:24");
	TextDrawBackgroundColor(Clock, 250);
	TextDrawFont(Clock, 1);
	TextDrawLetterSize(Clock, 0.5299,1.8999);
	TextDrawColor(Clock, -1);
	TextDrawSetOutline(Clock, 1);
	TextDrawSetProportional(Clock, 1);
	
	SelectCharacter_1 = TextDrawCreate(318.000000, 95.000000, "_");
	TextDrawFont(SelectCharacter_1, 1);
	TextDrawLetterSize(SelectCharacter_1, 0.895833, 29.150005);
	TextDrawTextSize(SelectCharacter_1, 293.500000, 356.000000);
	TextDrawSetOutline(SelectCharacter_1, 1);
	TextDrawSetShadow(SelectCharacter_1, 0);
	TextDrawAlignment(SelectCharacter_1, 2);
	TextDrawColor(SelectCharacter_1, -1);
	TextDrawBackgroundColor(SelectCharacter_1, 255);
	TextDrawBoxColor(SelectCharacter_1, 135);
	TextDrawUseBox(SelectCharacter_1, 1);
	TextDrawSetProportional(SelectCharacter_1, 1);
	TextDrawSetSelectable(SelectCharacter_1, 0);

	SelectCharacter_2 = TextDrawCreate(388.000000, 112.000000, "Character Selection");
	TextDrawFont(SelectCharacter_2, 3);
	TextDrawLetterSize(SelectCharacter_2, 0.404165, 1.449998);
	TextDrawTextSize(SelectCharacter_2, 400.000000, 17.000000);
	TextDrawSetOutline(SelectCharacter_2, 0);
	TextDrawSetShadow(SelectCharacter_2, 0);
	TextDrawAlignment(SelectCharacter_2, 3);
	TextDrawColor(SelectCharacter_2, -1);
	TextDrawBackgroundColor(SelectCharacter_2, 255);
	TextDrawBoxColor(SelectCharacter_2, 50);
	TextDrawUseBox(SelectCharacter_2, 0);
	TextDrawSetProportional(SelectCharacter_2, 1);
	TextDrawSetSelectable(SelectCharacter_2, 0);

	SelectCharacter_3 = TextDrawCreate(314.000000, 54.000000, "Life of Red County");
	TextDrawFont(SelectCharacter_3, 3);
	TextDrawLetterSize(SelectCharacter_3, 0.404165, 1.449998);
	TextDrawTextSize(SelectCharacter_3, 400.000000, 17.000000);
	TextDrawSetOutline(SelectCharacter_3, 2);
	TextDrawSetShadow(SelectCharacter_3, 0);
	TextDrawAlignment(SelectCharacter_3, 2);
	TextDrawColor(SelectCharacter_3, 1296911871);
	TextDrawBackgroundColor(SelectCharacter_3, 255);
	TextDrawBoxColor(SelectCharacter_3, 50);
	TextDrawUseBox(SelectCharacter_3, 0);
	TextDrawSetProportional(SelectCharacter_3, 1);
	TextDrawSetSelectable(SelectCharacter_3, 0);
}

stock HidePlayerCharacterSelection(playerid)
{
	CancelSelectTextDraw(playerid);
	for(new i=0; i<MAX_PLAYER_CHARACTERS; i++)
	{
		TextDrawHideForPlayer(playerid, SelectCharacter_BTN[i][playerid]);
		TextDrawHideForPlayer(playerid, SelectCharacter_CHAR[i][playerid]);
		TextDrawHideForPlayer(playerid, DeleteCharacter_BTN[i][playerid]);
	}
	TextDrawHideForPlayer(playerid, SelectCharacter_1);
	TextDrawHideForPlayer(playerid, SelectCharacter_2);
	TextDrawHideForPlayer(playerid, SelectCharacter_3);
}

stock GetPlayerCharacter(playerid, id)
{
	return PlayerInfo[playerid][CharacterID][id];
}

stock PlayerRPName(playerid)
{
	new newname[MAX_PLAYER_NAME];
	format(newname, MAX_PLAYER_NAME, GetPlayerNickname(playerid));
	for(new j; j < MAX_PLAYER_NAME; j++)
	{
		if(newname[j] == '_') newname[j] = ' ';
	}
	return newname;
}

stock RPName(name[])
{
	new newname[MAX_PLAYER_NAME];
	format(newname, MAX_PLAYER_NAME, name);
	for(new j; j < MAX_PLAYER_NAME; j++)
	{
		if(newname[j] == '_') newname[j] = ' ';
	}
	return newname;
}

stock ClearPlayerChat(playerid)
{
	for (new i; i < 125; i++)
	{
		SendClientMessage(playerid, COLOR_WHITE, "");
	}
}

public JustConnected(playerid)
{
	ClearPlayerChat(playerid);
	SetPlayerTime(playerid, serverHr, serverMn);
	SetPlayerSkillLevel(playerid, WEAPONSKILL_PISTOL, 1);
	SetPlayerSkillLevel(playerid, WEAPONSKILL_PISTOL_SILENCED, 1);
	SetPlayerSkillLevel(playerid, WEAPONSKILL_DESERT_EAGLE, 1);
	SetPlayerSkillLevel(playerid, WEAPONSKILL_SHOTGUN, 1);
	SetPlayerSkillLevel(playerid, WEAPONSKILL_SAWNOFF_SHOTGUN, 1);
	SetPlayerSkillLevel(playerid, WEAPONSKILL_SPAS12_SHOTGUN, 1);
	SetPlayerSkillLevel(playerid, WEAPONSKILL_MICRO_UZI, 1);
	SetPlayerSkillLevel(playerid, WEAPONSKILL_MP5, 1);
	SetPlayerSkillLevel(playerid, WEAPONSKILL_AK47, 1);
	SetPlayerSkillLevel(playerid, WEAPONSKILL_M4, 1);
	SetPlayerSkillLevel(playerid, WEAPONSKILL_SNIPERRIFLE, 1);
	SendClientMessageF(playerid, COLOR_GOLD, "Welcome to Life of Red County, %s {FFFFFF}[Version %s (C) sTrIx %i - site: soon]", GetPlayerNickname(playerid), SERVER_VERSION, serverYear);
}

public InterpolateCameraOnLogin(playerid)
{
	LoginScreenID[playerid][0] = random(sizeof(ClassSelectionData));
	LoginScreenID[playerid][1] = 120;
	InterpolateCameraPos(playerid, ClassSelectionData[LoginScreenID[playerid][0]][0], ClassSelectionData[LoginScreenID[playerid][0]][1], ClassSelectionData[LoginScreenID[playerid][0]][2], ClassSelectionData[LoginScreenID[playerid][0]][6], ClassSelectionData[LoginScreenID[playerid][0]][7], ClassSelectionData[LoginScreenID[playerid][0]][8], 120000, CAMERA_MOVE);
	InterpolateCameraLookAt(playerid, ClassSelectionData[LoginScreenID[playerid][0]][3], ClassSelectionData[LoginScreenID[playerid][0]][4], ClassSelectionData[LoginScreenID[playerid][0]][5], ClassSelectionData[LoginScreenID[playerid][0]][9], ClassSelectionData[LoginScreenID[playerid][0]][10], ClassSelectionData[LoginScreenID[playerid][0]][11], 120000, CAMERA_MOVE);
	return 1;
}

public OnPlayerRegister(playerid)
{
	new string[64];
	PlayerInfo[playerid][ID] = cache_insert_id();
	Logged[playerid] = true;
	format(string, sizeof(string), "SERVER: Ти създаде нов акаунт с име {40BF00}%s", GetPlayerNickname(playerid));
	SendClientMessage(playerid, COLOR_WHITE, string);
	LoadPlayerCharacters(playerid);
	SetTimerEx("ShowPlayerCharacterSelection", 500, false, "i", playerid);
	return 1;
}

public OnPlayerLogin(playerid)
{
	new string[128];
	new rows;
	cache_get_row_count(rows);
	if(rows == 0)
	{
		wrongPassword[playerid]++;
		new chances = 3-wrongPassword[playerid];
		if(chances == 0)
		{
			SendClientMessage(playerid, COLOR_RED, "SERVER: Ти беше автоматично Kick-нат, защото сгреши паролата си 3 пъти!");
			SetTimerEx("KickPlayer", 1000, false, "i", playerid);
			return 1;
		}
		ShowLoginBox(playerid);
		format(string, sizeof(string), "SERVER: Имаш още {FF0000}%d от 3 {FFFFFF}oпита да влезеш в сървъра", chances);
		SendClientMessage(playerid, COLOR_WHITE, string);
	}
	else
	{
		Logged[playerid] = true;
		format(string, sizeof(string), "SERVER: Ти влезе в своя акаунт {40BF00}%s", GetPlayerNickname(playerid));
		SendClientMessage(playerid, COLOR_WHITE, string);
		LoadPlayerCharacters(playerid);
		cache_get_value_name_int(0, "id", PlayerInfo[playerid][ID]);
		cache_get_value_name_int(0, "admin", PlayerInfo[playerid][pAdmin]);
		SetTimerEx("ShowPlayerCharacterSelection", 500, false, "i", playerid);
	}
	return 0;
}

public OnPlayerLoadCharacter(playerid)
{
	new dest[128];
	new num, characterNum;
	new result_count;
	cache_get_result_count(result_count);
	for(new r; r < result_count; r++)
	{
		cache_set_result(r);
		new rows = cache_num_rows();
		
		for(new i=0; i<rows; i++)
		{
			cache_get_value_name(i, "skin", dest);
			num = strval(dest);
			TextDrawSetPreviewModel(SelectCharacter_CHAR[i][playerid], num);
			
			cache_get_value_name(i, "name", dest);
			TextDrawSetString(SelectCharacter_BTN[i][playerid], dest);
			TextDrawSetString(DeleteCharacter_BTN[i][playerid], "DELETE");
			
			strunpack(characterName[playerid][i], dest);
			cache_get_value_name(i, "id", dest);
			
			characterNum = strval(dest);
			PlayerInfo[playerid][CharacterID][i] = characterNum;
			TextDrawShowForPlayer(playerid, DeleteCharacter_BTN[i][playerid]);
		}
		for(new i=rows; i<MAX_PLAYER_CHARACTERS; i++)
		{
			TextDrawSetPreviewModel(SelectCharacter_CHAR[i][playerid], 312);
			TextDrawSetString(SelectCharacter_BTN[i][playerid], "EMPTY");
			PlayerInfo[playerid][CharacterID][i] = -1;
			format(characterName[playerid][i], MAX_PLAYER_NAME, " ");
			TextDrawHideForPlayer(playerid, DeleteCharacter_BTN[i][playerid]);
		}
	}
}

public OnPlayerDataLoaded(playerid)
{
	if(cache_num_rows() == 1)
	{
		PlayerInfo[playerid][Data] = cache_save();
		ShowLoginBox(playerid);
	}
	else
	{
		ShowRegisterBox(playerid);
	}
	return 1;
}

public ShowPlayerCharacterSelection(playerid)
{
	TogglePlayerSpectating(playerid, 1);
	HidePlayerMainTextDraws(playerid);
	SelectTextDraw(playerid, 0x33AA33FF);
	for(new i=0; i<MAX_PLAYER_CHARACTERS; i++)
	{
		TextDrawShowForPlayer(playerid, SelectCharacter_BTN[i][playerid]);
		TextDrawShowForPlayer(playerid, SelectCharacter_CHAR[i][playerid]);
	}
	TextDrawShowForPlayer(playerid, SelectCharacter_1);
	TextDrawShowForPlayer(playerid, SelectCharacter_2);
	TextDrawShowForPlayer(playerid, SelectCharacter_3);
}

public OnPlayerCreatingCharacter(playerid, character)
{
	new string[128];
	SendClientMessage(playerid, COLOR_WHITE, "Ти избра да си създадеш нов персонаж! Сега трябва да въведеш неговите данни!");
	format(string, sizeof(string), "Посочете името на персонажа, който желаете да създадете в полето долу\n\nВажно: Не използвайте SPACE при въвеждане на името");
	Dialog_Show(playerid, Name, DIALOG_STYLE_INPUT, "{FFFFFF}Name", string, "Въведи", "Излез");
	HidePlayerCharacterSelection(playerid);
}

public OnPlayerSelectCharacter(playerid, character)
{
	//Load Character Information
	cache_get_value_name_int(0, "id", PlayerInfo[playerid][CurrentCharacterID]);
	cache_get_value_name_int(0, "faction", CharacterInfo[playerid][cFaction]);
	cache_get_value_name_int(0, "skin", CharacterInfo[playerid][cSkin]);
	cache_get_value_name_int(0, "last_year", CharacterInfo[playerid][cYear]);
	cache_get_value_name_int(0, "last_month", CharacterInfo[playerid][cMonth]);
	cache_get_value_name_int(0, "last_day", CharacterInfo[playerid][cDay]);
	cache_get_value_name_int(0, "last_hour", CharacterInfo[playerid][cHour]);
	cache_get_value_name_int(0, "last_minute", CharacterInfo[playerid][cMinute]);
	cache_get_value_name_int(0, "last_second", CharacterInfo[playerid][cSecond]);
	cache_get_value_name_float(0, "pos_x", CharacterInfo[playerid][cX]);
	cache_get_value_name_float(0, "pos_y", CharacterInfo[playerid][cY]);
	cache_get_value_name_float(0, "pos_z", CharacterInfo[playerid][cZ]);
	cache_get_value_name_float(0, "pos_angle", CharacterInfo[playerid][cAngle]);
	cache_get_value_name_int(0, "interior", CharacterInfo[playerid][cInterior]);
	cache_get_value_name_int(0, "virtual_world", CharacterInfo[playerid][cVirtualWorld]);
	
	SetPlayerName(playerid, characterName[playerid][character]);
	LoadCharacterWeapons(playerid);
	selectedCharacter[playerid] = true;
	SendClientMessage(playerid, COLOR_WHITE, "");
	SendClientMessageF(playerid, COLOR_WHITE, "Ти избра да влезеш в своя персонаж {40BF00}%s", GetPlayerNickname(playerid));
	new lastYear = CharacterInfo[playerid][cYear];
	new lastMonth = CharacterInfo[playerid][cMonth];
	new lastDay = CharacterInfo[playerid][cDay];
	new lastHour = CharacterInfo[playerid][cHour];
	new lastMinute = CharacterInfo[playerid][cMinute];
	new lastSecond = CharacterInfo[playerid][cSecond];
	SendClientMessageF(playerid, COLOR_WHITE, "Последното ти влизане в този персонаж е било на %d/%d/%d в %d:%d:%d", lastMonth, lastDay, lastYear, lastHour, lastMinute, lastSecond);
	HidePlayerCharacterSelection(playerid);
	
	CharacterInfo[playerid][cYear] = serverYear;
	CharacterInfo[playerid][cMonth] = serverMonth;
	CharacterInfo[playerid][cDay] = serverDay;
	CharacterInfo[playerid][cHour] = serverHr;
	CharacterInfo[playerid][cMinute] = serverMn;
	CharacterInfo[playerid][cSecond] = serverSec;
	SetTimerEx("SelectedCharacterSpawn", 1000, false, "i", playerid);
	ShowPlayerMainTextDraws(playerid);
}

public Spawn(playerid)
{
	SpawnPlayer(playerid);
}

public KickPlayer(playerid)
{
	Kick(playerid);
}

public OnCreateCharacter(playerid)
{
	SetPlayerName(playerid, newCharacter_Name[playerid]);
	selectedCharacter[playerid] = true;
	SendClientMessageF(playerid, COLOR_WHITE, "Ти успешно създаде своя нов персонаж на име {40BF00}%s", newCharacter_Name[playerid]);
	
	new query[256];
	mysql_format(Database, query, sizeof(query), "INSERT INTO characters (name, player) VALUES ('%e', '%e')", newCharacter_Name[playerid], PlayerInfo[playerid][Name]);
	mysql_query(Database, query);
	
	PlayerInfo[playerid][CurrentCharacterID] = cache_insert_id();
	
	CharacterInfo[playerid][cYear] = serverYear;
	CharacterInfo[playerid][cMonth] = serverMonth;
	CharacterInfo[playerid][cDay] = serverDay;
	CharacterInfo[playerid][cHour] = serverHr;
	CharacterInfo[playerid][cMinute] = serverMn;
	CharacterInfo[playerid][cSecond] = serverSec;
	
	CharacterInfo[playerid][cBirthday] = birthday_year[playerid];
	strunpack(CharacterInfo[playerid][cNationality], nationality[playerid]);
	CharacterInfo[playerid][cGender] = gender[playerid];	
	ChooseRandomSkin(playerid);
	ShowPlayerMainTextDraws(playerid);
	
	SaveCharacterStats(playerid);
	
	CharacterInfo[playerid][cX] = 1282.4677;
	CharacterInfo[playerid][cY] = 177.9870;
	CharacterInfo[playerid][cZ] = 20.1551;
	CharacterInfo[playerid][cAngle] = 153.8265;
	SetTimerEx("SelectedCharacterSpawn", 1000, false, "i", playerid);
}

public OneSecTimer()
{
	new string[256];
	//Get Real Life Time
	new hr, mn, sec, y, m, d;
	gettime(hr, mn, sec);
	getdate(y, m, d);
	serverYear = y;
	serverMonth = m;
	serverDay = d;
	serverHr = hr;
	serverMn = mn;
	serverSec = sec;
	
	//Update Clock
	format(string, sizeof(string), "  ~w~%s%d:%s%d:%s%d", (hr<10) ? ("0") : (""), hr, (mn<10) ? ("0") : (""), mn, (sec<10) ? ("0") : (""), sec);
	TextDrawSetString(Clock, string);
}

public OnDeleteCharacter(playerid, character)
{
	DeleteAllPlayerWeapons(playerid);
	LoadPlayerCharacters(playerid);
	SetTimerEx("ShowPlayerCharacterSelection", 500, false, "i", playerid);
}

public SelectedCharacterSpawn(playerid)
{
	new Float: X, Float: Y, Float: Z, Float: Angle;
	X = CharacterInfo[playerid][cX];
	Y = CharacterInfo[playerid][cY];
	Z = CharacterInfo[playerid][cZ];
	Angle = CharacterInfo[playerid][cAngle];
	new skin = CharacterInfo[playerid][cSkin];
	TogglePlayerSpectating(playerid, 0);
	SetSpawnInfo(playerid, 0, skin, X, Y, Z, Angle, 0, 0, 0, 0, 0, 0);
	SetTimerEx("Spawn", 100, false, "i", playerid);
}

/*

	Гейммод: Life of Red County
	Автор: sTrIx
	Разработван през: 2023г.

*/