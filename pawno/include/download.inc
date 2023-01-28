/*
	##############################################
	##			Manipulação de Downloads		##
	##				   by Locky					##	
	##############################################
	
		* Funções [Player]
	native IsPlayerDownloading(playerid);
	native GetPlayerDownloadTime(playerid);
	native GetPlayerDownloadedFiles(playerid);
	native GetPlayerDownloadedTextures(playerid);
	native GetPlayerDownloadedModels(playerid);
	native GetPlayerDownloadVirtualWorld(playerid);	
	native GetPlayerDownloadTimeString(playerid);
	
	native Float:GetPlayerDownloadProgress(playerid);
	native GetPlayerDownloadedBytes(playerid);
	native IsPlayerUseRedirectDownload(playerid);
	
		* Funções [Server]
	native IsServerUseArtwork();
	native GetServerArtworkFolder(folder[]);
	
	native GetArtworkGlobalSimpleModels();
	native GetArtworkGlobalCharModels();
	native GetArtworksModelFiles();
	native GetArtworksTextureFiles();
	
	native GetArtworkModelFilesInVW(virtualworld);
	native GetArtworkTextureFilesInVW(virtualworld);
	native GetArtworkSimpleModelInVW(virtualworld);	
	
		* Callback
	OnPlayerStartedDownload(playerid, virtualworld);

*/

#if !defined _samp_included
    #error "Defina a include SA-MP"
#else
    #if !defined OnPlayerFinishedDownloading
        #error "SA-MP 0.3.DL Requerido"
    #endif
#endif
#if defined _samp_downloading
	#endinput
#endif
#define _samp_downloading

// Player
enum _down {
	bool:_Started,
	bool:_Redirected,
	_TimeCount,
	_VirtualWorld,
	_FilesTXD,
	_FilesDFF,
	_Bytes
};
static PlayerDownload[MAX_PLAYERS][_down],
		GlobalFilesDFF, 
		GlobalFilesTXD,
		GlobalCountChars,
		GlobalCountObjects;



stock d_AddSimpleModel(vw, bid, nid, dff[], txd[]) {
	if(vw == -1) {
		if(!GetSVarInt(dff)) {
			SetSVarInt(dff, 1);
			GlobalFilesDFF++;
		}
		if(!GetSVarInt(txd)) {
			SetSVarInt(txd, 1);
			GlobalFilesTXD++;
		}
	} else {
		static viw[20];
		format(viw, sizeof(viw), "models_world_%i", vw);
		SetSVarInt(viw, GetSVarInt(viw)+1);
		
		if(!GetSVarInt(dff)) {
			SetSVarInt(dff, 1);
			format(viw, sizeof(viw), "dff_world_%i", vw);
			SetSVarInt(viw, GetSVarInt(viw)+1);
		}
		if(!GetSVarInt(txd)) {
			SetSVarInt(txd, 1);
			format(viw, sizeof(viw), "txd_world_%i", vw);
			SetSVarInt(viw, GetSVarInt(viw)+1);
		}
	}
	return AddSimpleModel(vw, bid, nid, dff, txd);
}
stock d_AddSimpleModelTimed(vw, bid, nid, dff[], txd[], ton, toff) {
	if(vw == -1) {
		if(!GetSVarInt(dff)) {
			SetSVarInt(dff, 1);
			GlobalFilesDFF++;
		}
		if(!GetSVarInt(txd)) {
			SetSVarInt(txd, 1);
			GlobalFilesTXD++;
		}
	} else {
		static viw[20];
		format(viw, sizeof(viw), "models_world_%i", vw);
		SetSVarInt(viw, GetSVarInt(viw)+1);
		
		if(!GetSVarInt(dff)) {
			SetSVarInt(dff, 1);
			format(viw, sizeof(viw), "dff_world_%i", vw);
			SetSVarInt(viw, GetSVarInt(viw)+1);
		}
		if(!GetSVarInt(txd)) {
			SetSVarInt(txd, 1);
			format(viw, sizeof(viw), "txd_world_%i", vw);
			SetSVarInt(viw, GetSVarInt(viw)+1);
		}
	}
	return AddSimpleModelTimed(vw, bid, nid, dff, txd, ton, toff);
}
stock d_AddCharModel(bid, nid, dff[], txd[]) {
	if(!GetSVarInt(dff)) {
		SetSVarInt(dff, 1);
		GlobalFilesDFF++;
	}
	if(!GetSVarInt(txd)) {
		SetSVarInt(txd, 1);
		GlobalFilesTXD++;
	}
	return AddCharModel(bid, nid, dff, txd);
}
#if defined _ALS_AddSimpleModel
	#undef AddSimpleModel
#else
	#define _ALS_AddSimpleModel
#endif
#define AddSimpleModel d_AddSimpleModel

#if defined _ALS_AddSimpleModelTimed
	#undef AddSimpleModelTimed
#else
	#define _ALS_AddSimpleModelTimed
#endif
#define AddSimpleModelTimed d_AddSimpleModelTimed

#if defined _ALS_AddCharModel
	#undef AddCharModel
#else
	#define _ALS_AddCharModel
#endif
#define AddCharModel d_AddCharModel

stock d_RedirectDownload(playerid, url[]) {
	PlayerDownload[playerid][_Redirected]=true;
	return RedirectDownload(playerid, url);
}
#if defined _ALS_RedirectDownload
	#undef RedirectDownload
#else
	#define _ALS_RedirectDownload
#endif
#define RedirectDownload d_RedirectDownload

public OnPlayerConnect(playerid)
{
	PlayerDownload[playerid][_Started] = false;	
	return CallLocalFunction("d_OnPlayerConnect", "d", playerid);	
}
#if defined _ALS_OnPlayerConnect
	#undef OnPlayerConnect
#else
	#define _ALS_OnPlayerConnect
#endif
#define OnPlayerConnect d_OnPlayerConnect
forward d_OnPlayerConnect(playerid);
public OnPlayerDisconnect(playerid, reason) {	
	for(new _down:e; e < _down; e++)
		PlayerDownload[playerid][e] = 0;
	return CallLocalFunction("d_OnPlayerDisconnect", "dd", playerid, reason);	
}
#if defined _ALS_OnPlayerDisconnect
	#undef OnPlayerDisconnect
#else
	#define _ALS_OnPlayerDisconnect
#endif
#define OnPlayerDisconnect d_OnPlayerDisconnect
forward d_OnPlayerDisconnect(playerid, reason);

public OnPlayerRequestDownload(playerid, type, crc) {
	if(!PlayerDownload[playerid][_Started]) {
		PlayerDownload[playerid][_Started] = true;
		PlayerDownload[playerid][_TimeCount] = gettime();
		PlayerDownload[playerid][_VirtualWorld] = GetPlayerVirtualWorld(playerid);		
		PlayerDownload[playerid][_Bytes] = NetStats_BytesSent(playerid);
		CallLocalFunction("OnPlayerStartedDownloading", "dd", playerid, PlayerDownload[playerid][_VirtualWorld]);
	}
	switch(type) 
	{
		case DOWNLOAD_REQUEST_TEXTURE_FILE: PlayerDownload[playerid][_FilesTXD]++;
		case DOWNLOAD_REQUEST_MODEL_FILE: PlayerDownload[playerid][_FilesDFF]++;
	}	
	PlayerDownload[playerid][_Redirected]=false;
	if(funcidx("d_OnPlayerRequestDownload") != -1)
		return CallLocalFunction("d_OnPlayerRequestDownload", "ddd", playerid, type, crc);
	else 
		return 1;	
}
#if defined _ALS_OnPlayerRequestDownload
	#undef OnPlayerRequestDownload
#else
	#define _ALS_OnPlayerRequestDownload
#endif
#define OnPlayerRequestDownload d_OnPlayerRequestDownload
forward d_OnPlayerRequestDownload(playerid, type, crc);

public OnPlayerFinishedDownloading(playerid, virtualworld)
{    		
	CallLocalFunction("d_OnPlayerFinishDownload", "dd", playerid, virtualworld);	
	SetTimerEx("FlushDownloadInfo", 1000, false, "d", playerid);
	return 1;
}
#if defined _ALS_OnPlayerFinishDownload
    #undef OnPlayerFinishedDownloading
#else
    #define _ALS_OnPlayerFinishDownload
#endif
#define OnPlayerFinishedDownloading d_OnPlayerFinishDownload
forward d_OnPlayerFinishDownload(playerid, virtualworld);

forward FlushDownloadInfo(playerid);
public FlushDownloadInfo(playerid) {
	static down[32];
	format(down, sizeof(down), "down_dff_world_%i", PlayerDownload[playerid][_VirtualWorld]);
	SetPVarInt(playerid, down, PlayerDownload[playerid][_FilesDFF]);
	format(down, sizeof(down), "down_txd_world_%i", PlayerDownload[playerid][_VirtualWorld]);
	SetPVarInt(playerid, down, PlayerDownload[playerid][_FilesTXD]);
	format(down, sizeof(down), "down_bytes_world_%i", PlayerDownload[playerid][_VirtualWorld]);
	SetPVarInt(playerid, down, (NetStats_BytesSent(playerid) - PlayerDownload[playerid][_Bytes]));
	
	PlayerDownload[playerid][_Started]=PlayerDownload[playerid][_Redirected]=false;
	PlayerDownload[playerid][_TimeCount]=PlayerDownload[playerid][_VirtualWorld]=PlayerDownload[playerid][_FilesTXD]=PlayerDownload[playerid][_FilesDFF]=PlayerDownload[playerid][_Bytes]=0;
	return 1;
}



/////////////////////////////////////////////////////////////////////////////////////////
// Player
stock IsPlayerDownloading(playerid) return PlayerDownload[playerid][_Started];
stock GetPlayerDownloadTime(playerid) return (PlayerDownload[playerid][_Started] ? (gettime()-PlayerDownload[playerid][_TimeCount]) : 0);

stock GetPlayerDownloadedTextures(playerid, virtualworld=0) {
	if(PlayerDownload[playerid][_Started]) return PlayerDownload[playerid][_FilesTXD];
	static down[32];
	format(down, sizeof(down), "down_txd_world_%i", virtualworld);
	return GetPVarInt(playerid, down);
}
stock GetPlayerDownloadedModels(playerid, virtualworld=0) {
	if(PlayerDownload[playerid][_Started]) return PlayerDownload[playerid][_FilesDFF];
	static down[32];
	format(down, sizeof(down), "down_dff_world_%i", virtualworld);
	return GetPVarInt(playerid, down);	
}
stock GetPlayerDownloadedFiles(playerid, virtualworld=0) return (GetPlayerDownloadedTextures(playerid, virtualworld) + GetPlayerDownloadedModels(playerid, virtualworld));
stock GetPlayerDownloadVirtualWorld(playerid) return PlayerDownload[playerid][_VirtualWorld];

stock GetPlayerDownloadTimeString(playerid) {
	new timestr[14], hor, mi, seg = (gettime()-PlayerDownload[playerid][_TimeCount]);
	if(seg >= 3600) {
		hor = seg / 3600;
		seg -= hor * 3600;
	}
	if(seg >= 60) {
		mi = seg / 60;
		seg -= mi * 60;
	}
	format(timestr, sizeof(timestr), "%02d:%02d:%02d", hor, mi, seg);
	return timestr;
}

stock Float:GetPlayerDownloadProgress(playerid) {
	if(!PlayerDownload[playerid][_Started]) return 0.0;
	if(PlayerDownload[playerid][_VirtualWorld] == 0)
		return (floatdiv(float(PlayerDownload[playerid][_FilesTXD] + PlayerDownload[playerid][_FilesDFF]),float(GlobalFilesDFF + GlobalFilesTXD))*100);
	else {
		static dffs, txds, viw[20], virtualworld;
		virtualworld = PlayerDownload[playerid][_VirtualWorld];
		format(viw, sizeof(viw), "dff_world_%i", virtualworld);
		dffs=GetSVarInt(viw);
		format(viw, sizeof(viw), "txd_world_%i", virtualworld);
		txds=GetSVarInt(viw);
		return (floatdiv(float(PlayerDownload[playerid][_FilesTXD] + PlayerDownload[playerid][_FilesDFF]),float(dffs + txds))*100);
	}	 
}

stock GetPlayerDownloadedBytes(playerid, virtualworld=0) {
	if(PlayerDownload[playerid][_Redirected]) return 0;
	if(!PlayerDownload[playerid][_Started]) {
		static down[32];
		format(down, sizeof(down), "down_bytes_world_%i", virtualworld);
		return GetPVarInt(playerid, down);
	}
	return NetStats_BytesSent(playerid) - PlayerDownload[playerid][_Bytes];
}

stock IsPlayerUseRedirectDownload(playerid) return PlayerDownload[playerid][_Redirected];

// Server
stock IsServerUseArtwork() return GetConsoleVarAsBool("useartwork");
stock GetServerArtworkFolder(folder[]) return GetConsoleVarAsString("artpath", folder, 64);

stock GetArtworkGlobalSimpleModels() return GlobalCountObjects;
stock GetArtworkGlobalCharModels() return GlobalCountChars;
stock GetArtworksModelFiles() return GlobalFilesDFF;
stock GetArtworksTextureFiles() return GlobalFilesTXD;

stock GetArtworkSimpleModelInVW(virtualworld) {
	static viw[20];
	format(viw, sizeof(viw), "models_world_%i", virtualworld);
	return GetSVarInt(viw);
}
stock GetArtworkModelFilesInVW(virtualworld) {
	static viw[20];
	format(viw, sizeof(viw), "dff_world_%i", virtualworld);
	return GetSVarInt(viw);
}
stock GetArtworkTextureFilesInVW(virtualworld) {
	static viw[20];
	format(viw, sizeof(viw), "txd_world_%i", virtualworld);
	return GetSVarInt(viw);
}

// Callback
forward OnPlayerStartedDownloading(playerid, virtualworld);


/*
	Include criada por Locky
	www.brasilmegatrucker.com
*/
