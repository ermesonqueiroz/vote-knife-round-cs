#include <amxmodx>
#include <fun>
#include <cstrike>

#define PLUGIN  "Votação de Round Faca"
#define VERSION "1.0"
#define AUTHOR  "Ermeson Sampaio"

#define VOTE_PERCENTAGE 0.8
/*
Percentual de votos necessários para iniciar o round faca

Valor de 0 até 1

Exemplos:
- 0.8 = 80% dos Jogadores
- 0.5 = 50% dos Jogadores
- 0.1 = 10% dos Jogadores
*/

new playersCounter, votesCounter, votes[32], requiredVotes, canResetVotes = false;


public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	register_clcmd("say vrf", "handle_vote");
	register_logevent ("round_start", 2, "1=Round_Start");
	register_logevent ("round_end", 2, "1=Round_End");
}

public client_connect(id)
{
	updatePlayersCounter(playersCounter + 1);
}

public client_disconnected(id)
{
	updatePlayersCounter(playersCounter - 1);

	if (votes[id - 1] == id) removeVote(id);
}

public remove_weapons_and_give_knife(id)
{
	strip_user_weapons(id);
	give_item(id, "weapon_knife");
}

public round_start()
{
	if (votesCounter != requiredVotes) {
		canResetVotes = false;
		return PLUGIN_CONTINUE;
	}

	canResetVotes = true;

	show_dhudmessage(0, "ROUND FACA!");

	new players[32], count;
	get_players(players, count);

	for (new i = 0; i < count; i++) {
		new id = players[i];
		remove_weapons_and_give_knife(id);
	}

	return PLUGIN_CONTINUE;
}

public round_end()
{
	if (!canResetVotes) return PLUGIN_CONTINUE;

	new players[32], count;
	get_players(players, count);

	for (new i = 0; i < count; i++) {
		new id = players[i];
		removeVote(id);
	}

	return PLUGIN_CONTINUE;
}

public CS_OnBuy(id)
{
	if (votesCounter == requiredVotes) return PLUGIN_HANDLED;
	return PLUGIN_CONTINUE;
}

public updatePlayersCounter(counter)
{
	playersCounter = counter;
	requiredVotes = max(floatround(counter * VOTE_PERCENTAGE, floatround_floor), 1);
}

public addVote(id)
{
	votes[id - 1] = id;
	votesCounter++;
}

public removeVote(id)
{
	votes[id - 1] = 0;
	votesCounter--;
}

public handle_vote(id)
{
	new name[32];
	get_user_name(id, name, charsmax(name));

	if (votes[id - 1] == id) {
		removeVote(id);

		client_print_color(
			0,
			print_team_default,
			"^4%s^1 removeu seu voto. Agora faltam ^4%i^1 votos para iniciar o round faca!",
			name,
			requiredVotes - votesCounter
		);

		return PLUGIN_CONTINUE;
	}

	addVote(id);

	server_print("%d == %d", votesCounter, requiredVotes);

	if (votesCounter == requiredVotes) {
		client_print_color(
			0,
			print_team_default,
			"^4%s^1 adicinou seu voto. ^4Próximo round será somente faca!^1",
			name,
			requiredVotes - votesCounter
		);

		return PLUGIN_CONTINUE;
	}

	client_print_color(
		0,
		print_team_default,
		"^4%s^1 adicinou seu voto. Agora faltam ^4%i^1 votos para iniciar o round faca!",
		name,
		requiredVotes - votesCounter
	);

	return PLUGIN_CONTINUE;
}
