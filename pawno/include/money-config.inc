/* 
	Include:
			money-config.inc

	* Functions for anti money hack

	* Author: (zile42O)
	* Created date: (13/8/2018)           

	(c) Copyright 2018
                                                                           
*/
#if defined _inc_money_config
	#endinput
#endif
#define _inc_money_config

#include "a_samp"

#define MC_RESOLUTION  1 

// RESOLUTION TYPES:
// 1 - 1980 x 1080 x 16
// 2 - 1024 x 728 x 32
// 3 - 800 x 600 x 32 

new mc_player_money[MAX_PLAYERS];
new mc_player_tick[MAX_PLAYERS];
new mc_player_color_money[MAX_PLAYERS];
new bool:mc_player_spawned[MAX_PLAYERS];

new PlayerText: MC_MONEY_TD[MAX_PLAYERS];
new PlayerText: MC_MONEY_INFO_TD[MAX_PLAYERS];

new const MAX_MONEY = 9999999999,
		  MIN_MONEY = -9999999999;		
new const 
	MONEY_BAR_COLOR = 0x005623FF, // Dark green
	MONEY_POSI_COL  = 0x11DD65FF, // Light green
	MONEY_NEGA_COL  = 0xDD1111FF; // Light red

forward SetMoneyInfo(playerid, amount, bool:type, timems);
forward OnPlayerTakeMoney(playerid, amount);

//


public OnPlayerConnect(playerid)
{
	mc_player_spawned[playerid] = false;
	mc_player_color_money[playerid] = MONEY_BAR_COLOR; //default
	mc_player_money[playerid] = 0;
	//TDs
	//Resolutions:
	//Res 1:
	#if MC_RESOLUTION == 1
	MC_MONEY_TD[playerid] = CreatePlayerTextDraw(playerid, 607.366943, 77.814590, "$00000000");
	PlayerTextDrawLetterSize(playerid, MC_MONEY_TD[playerid], 0.547333, 2.130961);
	//Res 2:
	#elseif MC_RESOLUTION == 2
	MC_MONEY_TD[playerid] = CreatePlayerTextDraw(playerid, 608.125000, 78.666564, "$00000000");
	PlayerTextDrawLetterSize(playerid, MC_MONEY_TD[playerid], 0.552501, 1.945835);
	#elseif MC_RESOLUTION == 3
	//Res 3:
	MC_MONEY_TD[playerid] = CreatePlayerTextDraw(playerid, 608.399658, 77.103370, "$00000000");
	PlayerTextDrawLetterSize(playerid, MC_MONEY_TD[playerid], 0.557600, 2.130131);
	#endif
	//Other
	PlayerTextDrawAlignment(playerid, MC_MONEY_TD[playerid], 3);
	PlayerTextDrawColor(playerid, MC_MONEY_TD[playerid], MONEY_BAR_COLOR);
	PlayerTextDrawSetShadow(playerid, MC_MONEY_TD[playerid], 0);
	PlayerTextDrawSetOutline(playerid, MC_MONEY_TD[playerid], 2);
	PlayerTextDrawBackgroundColor(playerid, MC_MONEY_TD[playerid], 255);
	PlayerTextDrawFont(playerid, MC_MONEY_TD[playerid], 3);
	PlayerTextDrawSetProportional(playerid, MC_MONEY_TD[playerid], 1);
	PlayerTextDrawSetShadow(playerid, MC_MONEY_TD[playerid], 0);	

	MC_MONEY_INFO_TD[playerid] = CreatePlayerTextDraw(playerid, 494.333282, 84.637123, "_");
	PlayerTextDrawLetterSize(playerid, MC_MONEY_INFO_TD[playerid], 0.264999, 1.085630);
	PlayerTextDrawAlignment(playerid, MC_MONEY_INFO_TD[playerid], 3);
	PlayerTextDrawColor(playerid, MC_MONEY_INFO_TD[playerid], -1);
	PlayerTextDrawSetShadow(playerid, MC_MONEY_INFO_TD[playerid], 0);
	PlayerTextDrawSetOutline(playerid, MC_MONEY_INFO_TD[playerid], 0);
	PlayerTextDrawBackgroundColor(playerid, MC_MONEY_INFO_TD[playerid], 255);
	PlayerTextDrawFont(playerid, MC_MONEY_INFO_TD[playerid], 3);
	PlayerTextDrawSetProportional(playerid, MC_MONEY_INFO_TD[playerid], 1);
	PlayerTextDrawSetShadow(playerid, MC_MONEY_INFO_TD[playerid], 0);



	#if defined MC_OnPlayerConnect
		return MC_OnPlayerConnect(playerid);
	#else
		return 1;
	#endif
}

public OnPlayerDisconnect(playerid, reason)
{
	mc_player_spawned[playerid] = false;
	PlayerTextDrawDestroy(playerid, MC_MONEY_TD[playerid]);
	PlayerTextDrawDestroy(playerid, MC_MONEY_INFO_TD[playerid]);
	mc_player_money[playerid] = 0;
	#if defined MC_OnPlayerDisconnect
		return MC_OnPlayerDisconnect(playerid, reason);
	#else
		return 1;
	#endif
}

public OnPlayerSpawn(playerid)
{
	mc_player_spawned[playerid] = true;
	PlayerTextDrawShow(playerid, MC_MONEY_TD[playerid]);
	PlayerTextDrawShow(playerid, MC_MONEY_INFO_TD[playerid]);
	#if defined MC_OnPlayerSpawn
		return MC_OnPlayerSpawn(playerid);
	#else
		return 1;
	#endif
}

stock ChangeColorMoneyForPlayer(playerid, newcolor)
{
	if(mc_player_spawned[playerid] == false) return false;
	if(GetPlayerMoney(playerid) < 0) return false;
	mc_player_color_money[playerid] = newcolor;

	PlayerTextDrawColor(playerid, MC_MONEY_TD[playerid], mc_player_color_money[playerid]);
	PlayerTextDrawHide(playerid, MC_MONEY_TD[playerid]);
	PlayerTextDrawShow(playerid, MC_MONEY_TD[playerid]);
	return true;
}
stock MC_GivePlayerMoney(playerid, money)
{	
	if(money == 0) return false;
	if(mc_player_spawned[playerid] == false) 
	{	
		printf("MoneyConfig: Can't set for id:%d  money: %d cause is player not spawned", playerid, money);
		return false;
	}
	if (money > MAX_MONEY) 
	{
		printf("MoneyConfig: Can't set for id:%d  money: %d cause is max limit %d", playerid, money, MAX_MONEY);
		return false;
	}
	if (money < MIN_MONEY) 
	{
		printf("MoneyConfig: Can't set for id:%d  money: %d cause is min limit %d", playerid, money, MIN_MONEY);
		return false;
	}	
	if (money > 0) 
	{
		SetMoneyInfo(playerid, money, true, 1500);
		mc_player_money[playerid] += money;
	}	
	else if (money < 0)
	{		
		SetMoneyInfo(playerid, money, false, 1500);	
		mc_player_money[playerid] -= abs(money);			
	}		
	ResetPlayerMoney(playerid);
	CallLocalFunction("OnPlayerTakeMoney", "id", playerid, mc_player_money[playerid]);
	return GivePlayerMoney(playerid, mc_player_money[playerid]);
}
stock abs( value )
{
	return ((value < 0 ) ? (-value) : (value));
}

#if defined _ALS_GivePlayerMoney
    #undef GivePlayerMoney
#else
    #define _ALS_GivePlayerMoney
#endif
#define GivePlayerMoney MC_GivePlayerMoney

public OnPlayerTakeMoney(playerid, amount)
{
	new arg[60];
	if(amount == 0)
	{
		format(arg,sizeof(arg),"$00000000");
		PlayerTextDrawSetString(playerid, MC_MONEY_TD[playerid], arg);
		PlayerTextDrawColor(playerid, MC_MONEY_TD[playerid], mc_player_color_money[playerid]);
		PlayerTextDrawHide(playerid, MC_MONEY_TD[playerid]);
	}	
	else if (amount > 0)	
	{	
		format(arg,sizeof(arg),"$%08d", amount);
		PlayerTextDrawSetString(playerid, MC_MONEY_TD[playerid], arg);
		PlayerTextDrawColor(playerid, MC_MONEY_TD[playerid], mc_player_color_money[playerid]);
		PlayerTextDrawHide(playerid, MC_MONEY_TD[playerid]);
	}	
	else if (amount < 0) 
	{
		format(arg,sizeof(arg),"$%08d", amount); 
		PlayerTextDrawSetString(playerid, MC_MONEY_TD[playerid], arg);
		PlayerTextDrawColor(playerid, MC_MONEY_TD[playerid], MONEY_NEGA_COL);
		PlayerTextDrawHide(playerid, MC_MONEY_TD[playerid]);
	}	
	PlayerTextDrawShow(playerid, MC_MONEY_TD[playerid]);
	return true;
}

public SetMoneyInfo(playerid, amount, bool:type, timems)
{
	new arg[60];
	if (mc_player_tick[playerid] < GetTickCount()) 
	{	
		mc_player_tick[playerid] = GetTickCount() + timems;

		if (type == true)
		{
			format(arg,sizeof(arg),"+$%d", amount);
			PlayerTextDrawColor(playerid, MC_MONEY_INFO_TD[playerid], MONEY_POSI_COL);
			PlayerTextDrawHide(playerid, MC_MONEY_INFO_TD[playerid]);
		}	
		else
		{
			format(arg,sizeof(arg),"$%d", amount);
			PlayerTextDrawColor(playerid, MC_MONEY_INFO_TD[playerid], MONEY_NEGA_COL);
			PlayerTextDrawHide(playerid, MC_MONEY_INFO_TD[playerid]);
		}	
		PlayerTextDrawSetString(playerid, MC_MONEY_INFO_TD[playerid], arg);
		PlayerTextDrawShow(playerid, MC_MONEY_INFO_TD[playerid]);
		SetTimerEx("InfoMoneyOff", timems, false, "i", playerid);
	}	
	return true;
}
forward InfoMoneyOff(playerid);
public InfoMoneyOff(playerid)
{
	PlayerTextDrawSetString(playerid, MC_MONEY_INFO_TD[playerid], "_");
	return true;
}

stock MC_ResetPlayerMoney(playerid)
{
	mc_player_money[playerid] = 0; //Reset 
	CallLocalFunction("OnPlayerTakeMoney", "id", playerid, mc_player_money[playerid]);
	return ResetPlayerMoney(playerid);
}
#if defined _ALS_ResetPlayerMoney
    #undef ResetPlayerMoney
#else
    #define _ALS_ResetPlayerMoney
#endif
#define ResetPlayerMoney MC_ResetPlayerMoney

stock MC_GetPlayerMoney(playerid)
{
	return mc_player_money[playerid];
}
#if defined _ALS_GetPlayerMoney
    #undef GetPlayerMoney
#else
    #define _ALS_GetPlayerMoney
#endif
#define GetPlayerMoney MC_GetPlayerMoney
//


#if defined _ALS_OnPlayerConnect
	#undef OnPlayerConnect
#else
	#define _ALS_OnPlayerConnect
#endif
#define OnPlayerConnect MC_OnPlayerConnect
#if defined MC_OnPlayerConnect
	forward MC_OnPlayerConnect(playerid);
#endif

#if defined _ALS_OnPlayerDisconnect
	#undef OnPlayerDisconnect
#else
	#define _ALS_OnPlayerDisconnect
#endif
#define OnPlayerDisconnect MC_OnPlayerDisconnect
#if defined MC_OnPlayerDisconnect
	forward MC_OnPlayerDisconnect(playerid);
#endif

#if defined _ALS_OnPlayerSpawn
	#undef OnPlayerSpawn
#else
	#define _ALS_OnPlayerSpawn
#endif
#define OnPlayerSpawn MC_OnPlayerSpawn
#if defined MC_OnPlayerSpawn
	forward MC_OnPlayerSpawn(playerid);
#endif



	