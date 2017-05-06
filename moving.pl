/*
 This module defines helpers predicates to move around the maze. It uses the fighting
 module because enemies can attack the player as he(she) moves.
*/

:- module(moving, [n/0, s/0, w/0, e/0, moved/1]).

use_module(fight, [fighting/1, assaulted/0]).
use_module(enemy, [enemy_moves/1]).
use_module(helpers, [game_is_still_on/0]).

/* ====================================== aliases ==================================== */
/* moving north */
n :- 
	game_is_still_on, !, n(_), !.
n(_) :- go(north), !.

/* moving south */
s :- 
	game_is_still_on, !, s(_), !.
s(_) :- go(south), !.

/* moving west */
w :- 
	game_is_still_on, !, w(_), !.
w(_) :- go(west), !.

/* moving east */
e :- 
	game_is_still_on, !, e(_), !.
e(_) :- go(east), !.

/* =============================== going somewhere ==================================== */

go(Direction) :-
	retractall(fight:fighting(_)),
	retractall(moved(_)),
	assert(moved(Direction)),	
	i_am_at(Here), 
	not(fight:assaulted), !,
	life_points(Life), Life > 0, !, /* additional check necessary to prevent moving to 
										next area */
	can_go_from_here(Here, Direction), 
	connected(Here, Direction, There),
	retract(i_am_at(Here)), 
	assert(i_am_at(There)),
	retract(moved(Direction)),
	assert(moved(just_arrived)),
	format("You moved to: ~w\n\n", [There]),
	enemy:enemy_moves(There),
	infection_damage,
	not(goal_reached),
	look, !.

/* =========================== secondary helper predicates ============================= */

/* checking we arrived at the jungle */
goal_reached :- 
	i_am_at(jungle),
	retractall(i_am_at(_)),
	assert(i_am_at(jungle)), /* asserting again because of backtracking */
	named(Name),
	assert(user:game_is_finished),
	format("\nGreat ~w! You made it out of the maze!!!", [Name]), nl,
	write("Thanks for playing <aMazeInMonkey>."), nl, !.

/* checking that I can actually go in the specified direction: if I the direction is not 
valid the second sub-goal won't be evaluated */ 		
can_go_from_here(Here, Direction):-
 	direction_is_valid(Here, Direction), !,
 	door_is_not_locked(Here, Direction). 

/* if infected the player will keep losing life points each time they move */	
infection_damage:-
	health(infected),
	life_points(Life),
	New_life is Life - 1,
	retract(life_points(Life)),
	assert(life_points(New_life)),
	write("You are under the effects of an infection"), nl,
	format("You will need the elisir to heal. New Life: ~w\n\n", [New_life]).
infection_damage. /* making the predicate always successful  */

/* =========================== helpers of secondary helpers ============================ */

/* The direction leads to somewhere (not needed if I make the go predicate 
completely unaccessible) */
direction_is_valid(Here, Direction) :-
 	connected(Here, Direction, _) ;
 	write("You can't go there."), fail.

/* The door is not locked */
door_is_not_locked(Here, Direction) :-
	not(locked(Here, Direction)).	
door_is_not_locked(Here, Direction) :-
	locked(Here, Direction),
 	write("That door is locked."), fail.		



