/*
 This module defines predicates to engage in fights with the enemies. Each enemy has their
 own style of fighting that depends on life and behaviour and can vary during the fight.
*/

:- module(fight, [fighting/1, punch/0, assaulted/0]).

:- dynamic(fighting/1).

/* ================================ enemy attacking =================================== */

/* enemies will hide and attempt to assault you, preventing you from accessing a new room. 
Unless you wear the specs (fully equipped) you won't be able to anticipate their attack */

assaulted:-
	i_am_at(Place),
	moved(Direction),
	at_area(Place, Direction, enemy(Type, Id, _, _)),
	assaulted_by(Type, Id, Direction).
	
assaulted_by(Type, Id, Direction):-	
	unexpected_assault(Type, Id, _); /* note the disjunction */
	expected_assault(Type, Id, Direction).

/* unexpected assault */
unexpected_assault(Type, Id, _):-
	not(holding(object(specs, lens))),
	attacked_by(Type, Id), !. 

/* expected assault */	
expected_assault(Type, Id, Direction):-
	holding(object(specs, lens)),
	assert(fighting(Id)),
	format("Well done, you spot a: ~w !!\n", [Type]),
	format("(...but you can't go ~w without fighting!)", [Direction]), nl, !.
	
/* max power depends on enemy type */	
maxPower(evil_bat, Value):- Value is 3.
maxPower(zoo_keeper, Value):- Value is 4.
maxPower(gorilla, Value):- Value is 6.
	
/* ============================= enemy dodging attacks ================================ */

/* enemies can dodge your punches: TODO change chances of dodging based on player life points */
dodge(Type):-
	dodge_chances(Type, Value),
	dodge(Type, Value).
/* bats have 50% chances to dodge a hit */
dodge_chances(evil_bat, Chance):-
	random(0, 2, Chance).
/* zoo_keepers have 30% */
dodge_chances(zoo_keepers, Chance):-
	random(0, 3, Chance).	
/* gorillas have 25% */
dodge_chances(gorilla, Chance):-
	random(0, 5, Chance).
/* helper */
dodge(Type, 1):- 
	format("Ouch!! The ~w dodged your punch!", [Type]).
dodge(_, _):- 
	fail.

/* ========================= enemy responding to attacks ============================== */

/* enemies can react to your punches depending on life points and behaviour: 
if they run out of life points they will die and drop everything */
reaction(_, Id, Enemy_life, _):-
	Enemy_life =< 0,
	i_am_at(Place),
	enemy_drops(Place, Id).
reaction(Enemy_type, Id, Enemy_life, Behaviour):-
	Enemy_life > 0,
	attack_chances(Behaviour, Chance),
	reaction_type(Reaction_Type),
	react(Enemy_type, Id, Reaction_Type , Chance).	
	
/* reaction types: fighting back (see attacked_by predicate), 
stealing (see steal predicate) or bailing out (see bail predicate) */	
reaction_type(Reaction):-
	random(0, 10, Value),
	select_reaction(Reaction, Value).
		
/* helper predicate to select a reaction type */
select_reaction(Reaction, _):-
	Reaction = fight.
select_reaction(Reaction, _):-
	Reaction = steal.
select_reaction(Reaction, 1):-
	Reaction = bail.
	
/* aggressive gorillas will fight back if it has a higher life than mine fix comment or change this */
react(Enemy_type, Id, Reaction_Type, Chance):- 	
	Chance == 1,
	Reaction_Type == fight,
	format("Careful! This ~w is fighting back!~s", [Enemy_type, "\n"]),
	attacked_by(Enemy_type, Id),
	alive(Alive), Alive == true, !.
react(Enemy_type, Id, Reaction_Type, Chance):- 	
	Chance == 1,
	Reaction_Type == steal,
	steal(Enemy_type, Id), !.
react(Enemy_type, Id, Reaction_Type, Chance):- 	
	Chance == 1,
	Reaction_Type == bail,
	bail(Enemy_type, Id), !.
react(_, _, _, _).

/* enemy attacking */	
attacked_by(Type, Id):-
	life_points(Life),
	maxPower(Type, Value),
	random(1, Value, Enemy_power),
	NewLife is Life - Enemy_power,
	retract(life_points(_)),
	assert(life_points(NewLife)),
	format("You have been attacked by: ~w...\n", [Type]),
	format("New life: ~w~s", [NewLife, "\n"]),
	moved(Direction),
	format("(You can't go ~w without fighting!)", [Direction]), nl,
	assert(fighting(Id)),
	alive(Alive), Alive == true, !,
	drop_item(Enemy_power). /* depending on the power of the attack you may lose items */

/* enemies running away */
bail(Enemy_type, Id):-
	i_am_at(Place),
	moved(Area), /* or fighting */
	at_area(Place, Area, enemy(Enemy_type, Id, Life, Behaviour)),
	retract(at_area(Place, Area, enemy(Enemy_type, Id, Life, Behaviour))),
	connected(Place, Area, Next_Place),
	not(locked(Place, Area)),
	connected(_, Random_Area, _), !, /* they will move to a random area in th next room */
	assert(at_area(Next_Place, Random_Area, enemy(Enemy_type, Id, Life, Behaviour))),
	retractall(fighting(_)),
	format("...The ~w just ran away!!~s", [Enemy_type, "\n"]).
bail(_, _).

/* enemies stealing your items */
steal(Type, Id):-
	holding(Item),
	contains(Item, Content),
	retract(holding(Item)),
	assertz(enemy_holds(Id, Item)),
	format("The ~w just robbed you!~sSay goodbye to your ~w", [Type, "\n", Content]), !.
steal(_,_).


/* punch aftermaths: you will drop an item if the blow was too strong */
drop_item(Enemy_power):-
	Enemy_power >= 4,
	holding(Container),
	contains(Container, Item),
	write("That hit made you drop an item!!\n"),
	drop(Item), !.
drop_item(_). /* even if we have nothing to drop this predicate 
				 is always true as the attack needs to be successful */


/* the probability to be attacked depends on the enemy's behaviour */
attack_chances(aggressive, Chance):-
	random(0, 2, Chance). /* there is 50% chance that an aggressive enemy will fight back */
attack_chances(quiet, Chance):-
	random(0, 3, Chance). /* there is 30% chance that an wary enemy will fight back */
attack_chances(evasive, Chance):-
	random(0, 5, Chance). /* there is 25% chance that an evasive enemy will fight back */


/* ==================================== user attacking ================================ */
/* hitting the enemy */
punch:- 
	alive(Alive),
	Alive = true, punch(_), !.
punch:-
	alive(Alive),
	Alive = true,
	i_am_at(Place),
	moved(Area),
	not(at_area(Place, Area, _)), !,
	format("What are you doing? No one is around...\n"), fail.
punch:-
	alive(Alive),
	Alive = true,
	not(fighting(_)),
	not(holding(object(specs, lens))),
	format("What are you doing? No one is around...\n"), fail.
punch:-
	alive(Alive),
	Alive = true,
	not(fighting(_)),
	holding(object(specs, lens)),
	i_am_at(Place),
	at_area(Place, _, _), !,
	format("Move towards the enemy to hit them...\n"), fail.
punch(_):-
	life_points(Life),	
	punch_power(Life, Power),
	Power > 0, !,
	i_am_at(Place),
	moved(Direction),
	fighting(Id),
	at_area(Place, Direction, enemy(Type, Id, Enemy_life, Behaviour)), !, /* only hit one enemy at a time */
	not(dodge(Type)), !,
	New_enemy_life is Enemy_life - Power,
	damage_enemy(Type, Id, Enemy_life, New_enemy_life, Behaviour),
	reaction(Type, Id, New_enemy_life, Behaviour), !.
	
/* helper predicate to damage the enemy following a punch */
damage_enemy(Type, Id, Old_life, New_enemy_life, Behaviour):-
	New_enemy_life > 0,
	i_am_at(Place),
	moved(Direction),
	retract(at_area(Place, Direction, enemy(Type, Id, Old_life, Behaviour))),
	change_attitude(New_enemy_life, NewBehaviour, Behaviour),
	assert(at_area(Place, Direction, enemy(Type, Id, New_enemy_life, NewBehaviour))),
	format("You punched a ~w. ~w life: ~w~s", [Type, Type, New_enemy_life, "\n"]), !.
damage_enemy(Type, Id, Old_life, _, Behaviour):-
	i_am_at(Place),
	moved(Direction),
	enemy_drops(Place, Id), /* if the enemy dies it will drop everything it holds */
	retract(at_area(Place, Direction, enemy(Type, Id, Old_life, Behaviour))),
	retractall(fighting(_)),
	format("Well done! You just got rid of a: ~w.", [Type, "\n"]), !.
	
/* when running low on life points enemies will change their behaviour and less dangerous */	
change_attitude(Enemy_life, NewBehaviour, _):-
	Enemy_life < 5,
	NewBehaviour = quiet.
change_attitude(_, NewBehaviour, Behaviour):-
	NewBehaviour = Behaviour.
		
/* getting the user's punch power depending on their life level */
punch_power(Life, Power):-
	Life < 3, Power is 0,
	write("You are to weak to fight...eat some fruit, son!\n"), !, fail.	
punch_power(Life, Power):-
	Life < 5, Power is 1, !.
punch_power(Life, Power):-
	Life < 10, Power is 2, !.
punch_power(Life, Power):-
	Life < 15, Power is 3, !.
punch_power(_, 4).

/* when defeated the enemy will drop all items */
enemy_drops(Place, Id):-
	enemy_holds(Id, Item),
	assertz(user:at(Place, Item)), /* user qualifier to prevent creating a 
									   new predicate scoped to this file */
	retract(enemy_holds(Id, Item)),
	enemy_drops(Place, Id).
enemy_drops(_, _). /* the predicate will always be true */
