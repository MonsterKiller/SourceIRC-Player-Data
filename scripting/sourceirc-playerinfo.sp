#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <sourceirc>
#pragma semicolon 1

/* TODO: 
    - Show Frags, class etc?
    - Use StrCat to add to string rather than long format?
 */

public Plugin:myinfo = 
{
	name = "SourceIRC -> Player Info",
	author = "Monster Killer",
	description = "Get player details from IRC",
	version = "1.0.1",
	url = "https://MonsterProjects.org"
};

public OnPluginStart() {	
	LoadTranslations("common.phrases");
}

public OnAllPluginsLoaded() {
	if (LibraryExists("sourceirc"))
		IRC_Loaded();
}

public OnLibraryAdded(const String:name[]) {
	if (StrEqual(name, "sourceirc"))
		IRC_Loaded();
}

public OnPluginEnd() {
    if (LibraryExists("sourceirc"))
        IRC_CleanUp();
}

IRC_Loaded() {
	IRC_CleanUp();
	IRC_RegCmd("playerinfo", Command_PlayerInfo, "playerinfo <#id|name> Gets a players details");
}

public Action:Command_PlayerInfo(const String:nick[], args) {
	if (args < 1)
	{
		IRC_ReplyToCommand(nick, "Usage: playerinfo <#userid|name>");
		return Plugin_Handled;
	}
	
	decl String:destination[64], String:text[IRC_MAXLEN], String:playeradmim[15], String:teamname[IRC_MAXLEN], String:name[64], String:auth[64], String:ip[32], String:dead[6], String:hostmask[512], String:szAuth[IRC_MAXLEN], time, mins, secs, latency;
	IRC_GetCmdArgString(text, sizeof(text));
	BreakString(text, destination, sizeof(destination));
	new target = FindTarget(0, destination, true, false);
	
	if (target == -1) {
		IRC_ReplyToCommand(nick, "Unable to find %s", destination);
		return Plugin_Handled;
	}
	
	IRC_GetHostMask(hostmask, sizeof(hostmask));
	new bool:isadmin = IRC_GetAdminFlag(hostmask, AdminFlag:ADMFLAG_GENERIC);

	GetClientName(target, name, sizeof(name));
	GetClientAuthString(target, auth, sizeof(auth));
	new playerid = GetClientUserId(target);
	
	if(GetUserFlagBits(target) & ADMFLAG_GENERIC || GetUserFlagBits(target) & ADMFLAG_ROOT)
		playeradmim = "*\x0303Is Admin\x03*";
	else 
		playeradmim = "";
		
	GetClientIP(target, ip, sizeof(ip), false);
	new team;
	if (target != 0)
		team = IRC_GetTeamColor(GetClientTeam(target));
	else
		team = 0;
	
	new teamnumber = GetClientTeam(target);
	if(teamnumber == 2)
	{
		teamname = "Red";
	} else if(teamnumber == 3)
	{
		teamname = "Blue";
	} else {
		teamname = "Spectate";
	}
	
	if (!IsPlayerAlive(target) && teamnumber != 1)
		dead = "*DEAD* ";
	else
		dead = "";
	
	if (IsClientInGame(target) && !IsFakeClient(target)) {
		time = RoundToFloor(GetClientTime(target));
		mins = time / 60;
		secs = time % 60;
		latency = RoundToFloor(GetClientAvgLatency(target, NetFlow_Both)*1000.0);
	}
	else {
		mins = 0;
		secs = 0;
		latency = -1;
	}
	
	GetClientAuthString(target, szAuth, sizeof(szAuth));
		
	if (isadmin) {
		IRC_ReplyToCommand(nick, "Player: #%d %s\x03%02d%s\x03 (%s) Team: \x03%02d%s\x03, IP: %s, Connection Time: %d:%02d, Latency: %d. %s", playerid, dead, team, name, auth, team, teamname, ip, mins, secs, latency, playeradmim);
	} else {
		IRC_ReplyToCommand(nick, "Player: #%d %s\x03%02d%s\x03 (%s) Team: \x03%02d%s\x03 Time: %d:%02d Latency: %d. %s", playerid, dead, team, name, auth, team, teamname, mins, secs, latency, playeradmim);
	}
	return Plugin_Handled;
}