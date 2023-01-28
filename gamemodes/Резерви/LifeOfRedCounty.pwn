/*

	Гейммод: Life of Red County
	Автор: sTrIx
	Разработван през: 2023г.

*/
/*================================================================================

	PLUGINS:
	MySQL		R41-4 	https://github.com/pBlueG/SA-MP-MySQL/releases/tag/R41-4
	Streamer	2.9.5	https://github.com/samp-incognito/samp-streamer-plugin/releases/tag/v2.9.5
	sscanf		2.13.8	https://github.com/Y-Less/sscanf/releases/tag/v2.13.8
	Whirlpool	1.0  	https://github.com/Southclaws/samp-whirlpool/releases

	OTHER RESOURCES:
	foreach		19		https://github.com/karimcambridge/samp-foreach
	i-zcmd		0.2.2   https://github.com/YashasSamaga/I-ZCMD
================================================================================*/

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

//COLORS:

#define COLOR_RED 			0xE60000FF
#define COLOR_WHITE 		0xFFFFFFFF
#define COLOR_GOLD			0xFFD700FF
#define COLOR_GREEN			0x40BF00FF

//TEXTDRAWS
new Text:SelectCharacter_1;
new Text:SelectCharacter_2;
new Text:SelectCharacter_3;
new Text:SelectCharacter_BTN[MAX_PLAYER_CHARACTERS][MAX_PLAYERS];
new Text:SelectCharacter_CHAR[MAX_PLAYER_CHARACTERS][MAX_PLAYERS];

//PLAYER INFORMATION:
new bool: selectedCharacter[MAX_PLAYERS] = false;
new bool: Logged[MAX_PLAYERS] = false;
new LoginScreenID[MAX_PLAYERS][2];
new wrongPassword[MAX_PLAYERS] = 0;
new characterName[MAX_PLAYERS][MAX_PLAYER_CHARACTERS][MAX_PLAYER_NAME];

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

enum charInfo
{
	cFaction,
	cSkin,
	cYear,
	cMonth,
	cDay,
	cHour,
	cMinute,
	cSecond
}
new CharacterInfo[MAX_PLAYERS][charInfo];

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

//TIMERS:
forward InterpolateCameraOnLogin(playerid);
forward KickPlayer(playerid);

//SERVER FORWARDS:
forward OnPlayerLogin(playerid);
forward OnPlayerRegister(playerid);
forward OnPlayerDataLoaded(playerid);
forward OnPlayerLoadCharacter(playerid);
forward ShowPlayerCharacterSelection(playerid);
forward OnPlayerSelectCharacter(playerid, character);

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
	SetGameModeText(SERVER_GAMEMODE);
	ConnectToDB();
	DisableInteriorEnterExits();
	EnableStuntBonusForAll(0);
	AddPlayerClass(0, 1958.3783, 1343.1572, 15.3746, 269.1425, 0, 0, 0, 0, 0, 0);
	DefineTextDraws();
	
	new hr, mn, sec, y, m, d;
	gettime(hr, mn, sec);
	getdate(y, m, d);
	serverYear = y;
	serverMonth = m;
	serverDay = d;
	serverHr = hr;
	serverMn = mn;
	serverSec = sec;
	return 1;
}

public OnGameModeExit()
{
	return 1;
}

public OnPlayerRequestClass(playerid, classid)
{
	SetPlayerPos(playerid, 1958.3783, 1343.1572, 15.3746);
	SetPlayerCameraPos(playerid, 1958.3783, 1343.1572, 15.3746);
	SetPlayerCameraLookAt(playerid, 1958.3783, 1343.1572, 15.3746);
	return 1;
}

public OnPlayerConnect(playerid)
{
	DefinePlayerTextDraws(playerid);
	ResetAllPlayerData(playerid);
	JustConnected(playerid);
	JustConnectedScreens(playerid);
	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	DestroyPlayerTextDraws(playerid);
	SavePlayerStats(playerid);
	SaveCharacterStats(playerid);
	ResetAllPlayerData(playerid);
	return 1;
}

public OnPlayerSpawn(playerid)
{
	if(!selectedCharacter[playerid])
	{
		TogglePlayerSpectating(playerid, 1);
		SetTimerEx("ShowPlayerCharacterSelection", 500, false, "i", playerid);
	}
	return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
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
	return 1;
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
			if(clickedid == SelectCharacter_BTN[i][playerid])
			{
				if(GetPlayerCharacter(playerid, i) == -1)
				{
					SendClientMessage(playerid, COLOR_WHITE, "Ти избра да си създадеш нов персонаж! Сега трябва да въведеш неговите данни!");
				}
				else
				{
					new query[256];
					mysql_format(Database, query, sizeof(query), "SELECT * FROM characters WHERE name = '%e'", characterName[playerid][i]);
					mysql_pquery(Database, query, "OnPlayerSelectCharacter", "dd", playerid, i); //TODO
				}
			}
		}
	}
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

stock CreatePlayerORM(playerid)
{
	new ORM: ormid = PlayerInfo[playerid][ORM_ID] = orm_create("players", Database);
	orm_addvar_int(ormid, PlayerInfo[playerid][ID], "id");
	orm_addvar_int(ormid, PlayerInfo[playerid][pPassword], "password");
	orm_addvar_int(ormid, PlayerInfo[playerid][pAdmin], "admin");
	orm_setkey(ormid, "name");
	
	orm_load(ormid, "OnPlayerDataLoaded", "dd", playerid, g_MysqlRaceCheck[playerid]);
}

stock JustConnected(playerid)
{
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

stock SaveCharacterStats(playerid)
{
	if(!selectedCharacter[playerid]) return 1;
	new query[256];
	mysql_format(Database, query, sizeof(query), "UPDATE characters SET faction = '%d', skin = '%d', last_year = '%d', last_month = '%d', last_day = '%d' WHERE id = '%d'",
		GetPlayerNickname(playerid), CharacterInfo[playerid][cFaction], CharacterInfo[playerid][cSkin],
		CharacterInfo[playerid][cYear], CharacterInfo[playerid][cMonth], CharacterInfo[playerid][cDay], PlayerInfo[playerid][CurrentCharacterID]);
	mysql_pquery(Database, query);
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

stock DestroyPlayerTextDraws(playerid)
{
	TextDrawDestroy(SelectCharacter_BTN[0][playerid]);
	TextDrawDestroy(SelectCharacter_BTN[1][playerid]);
	TextDrawDestroy(SelectCharacter_BTN[2][playerid]);
	TextDrawDestroy(SelectCharacter_CHAR[0][playerid]);
	TextDrawDestroy(SelectCharacter_CHAR[1][playerid]);
	TextDrawDestroy(SelectCharacter_CHAR[2][playerid]);
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
	TextDrawSetPreviewRot(SelectCharacter_CHAR[0][playerid], -10.000000, 0.000000, -20.000000, 1.000000);
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
	TextDrawSetPreviewRot(SelectCharacter_CHAR[1][playerid], -10.000000, 0.000000, -20.000000, 1.000000);
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
	TextDrawSetPreviewRot(SelectCharacter_CHAR[2][playerid], -10.000000, 0.000000, -20.000000, 1.000000);
	TextDrawSetPreviewVehCol(SelectCharacter_CHAR[2][playerid], 1, 1);
}

stock DefineTextDraws()
{
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

stock GetPlayerCharacter(playerid, id)
{
	return PlayerInfo[playerid][CharacterID][id];
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
		SetTimerEx("ShowPlayerCharacterSelection", 500, false, "i", playerid);
		cache_get_value_name_int(0, "id", PlayerInfo[playerid][ID]);
		cache_get_value_name_int(0, "admin", PlayerInfo[playerid][pAdmin]);
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
			num = strval(dest);
			cache_get_value_name(i, "skin", dest);
			TextDrawSetPreviewModel(SelectCharacter_CHAR[i][playerid], num);
			cache_get_value_name(i, "name", dest);
			TextDrawSetString(SelectCharacter_BTN[i][playerid], dest);
			strunpack(characterName[playerid][i], dest);
			cache_get_value_name(i, "id", dest);
			characterNum = strval(dest);
			PlayerInfo[playerid][CharacterID][i] = characterNum;
		}
		for(new i=rows; i<MAX_PLAYER_CHARACTERS; i++)
		{
			TextDrawSetPreviewModel(SelectCharacter_CHAR[i][playerid], 312);
			TextDrawSetString(SelectCharacter_BTN[i][playerid], "EMPTY");
			PlayerInfo[playerid][CharacterID][i] = -1;
			format(characterName[playerid][i], MAX_PLAYER_NAME, " ");
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
	SelectTextDraw(playerid, 0x33AA33FF);
	TextDrawShowForPlayer(playerid, SelectCharacter_BTN[0][playerid]);
	TextDrawShowForPlayer(playerid, SelectCharacter_BTN[1][playerid]);
	TextDrawShowForPlayer(playerid, SelectCharacter_BTN[2][playerid]);
	TextDrawShowForPlayer(playerid, SelectCharacter_CHAR[0][playerid]);
	TextDrawShowForPlayer(playerid, SelectCharacter_CHAR[1][playerid]);
	TextDrawShowForPlayer(playerid, SelectCharacter_CHAR[2][playerid]);
	TextDrawShowForPlayer(playerid, SelectCharacter_1);
	TextDrawShowForPlayer(playerid, SelectCharacter_2);
	TextDrawShowForPlayer(playerid, SelectCharacter_3);
}

public OnPlayerSelectCharacter(playerid, character)
{
	cache_get_value_name_int(0, "id", PlayerInfo[playerid][CurrentCharacterID]);
	cache_get_value_name_int(0, "faction", CharacterInfo[playerid][cFaction]);
	cache_get_value_name_int(0, "skin", CharacterInfo[playerid][cSkin]);
	cache_get_value_name_int(0, "last_year", CharacterInfo[playerid][cYear]);
	cache_get_value_name_int(0, "last_month", CharacterInfo[playerid][cMonth]);
	cache_get_value_name_int(0, "last_day", CharacterInfo[playerid][cDay]);
	cache_get_value_name_int(0, "last_hour", CharacterInfo[playerid][cHour]);
	cache_get_value_name_int(0, "last_minute", CharacterInfo[playerid][cMinute]);
	cache_get_value_name_int(0, "last_second", CharacterInfo[playerid][cSecond]);
	
	SetPlayerName(playerid, characterName[playerid][character]);
	SendClientMessageF(playerid, COLOR_WHITE, "Ти влезе успешно в своя персонаж {40BF00}%s", GetPlayerNickname(playerid));
	SendClientMessage(playerid, COLOR_WHITE, "");
	new lastYear = CharacterInfo[playerid][cYear];
	new lastMonth = CharacterInfo[playerid][cMonth];
	new lastDay = CharacterInfo[playerid][cDay];
	new lastHour = CharacterInfo[playerid][cHour];
	new lastMinute = CharacterInfo[playerid][cMinute];
	new lastSecond = CharacterInfo[playerid][cSecond];
	SendClientMessageF(playerid, COLOR_WHITE, "Последното ти влизане в този персонаж е било на %d/%d/%d в %d:%d:%d", lastMonth, lastDay, lastYear, lastHour, lastMinute, lastSecond);
}

public KickPlayer(playerid)
{
	Kick(playerid);
}
/*

	Гейммод: Life of Red County
	Автор: sTrIx
	Разработван през: 2023г.

*/