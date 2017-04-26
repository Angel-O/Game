:- module(moving, [n/0, s/0, w/0, e/0, punch/0]).

/* ====================== Moving around the maze ==================================== */

/* GO SOMEWHERE PREDICATE TODO....make this private*/
/* if I am Here */
/* and the direction from the current location is clear */
/* I will end up to a place There connected to Here if I go this Direction */
/* so I will no longer be Here */
/* but I will be There instead */

go(Direction) :-
	i_am_at(Here), 
	not(attacked_by(_, Alive)), Alive == true, !, 
	can_go_from_here(Here, Direction), 
	connected(Here, Direction, There),
	retract(i_am_at(Here)), 
	assert(i_am_at(There)),
	format("You are in ~w", [There]), !.

/* NOTE: if I the direction is not valid we don't want to evaluate
the second sub-goal */ 		
can_go_from_here(Here, Direction):-
 	direction_is_valid(Here, Direction), !,
 	door_is_not_locked(Here, Direction). 

/* NOTE: using disjunction to evaluate the second goal and print a friendly message.
beacause of that I need to report a fail, otherwise the predicate will be successful 
when it shouldn't */ 		
direction_is_valid(Here, Direction) :-
 	connected(Here, Direction, _) ;
 	write("You can't go there."), fail.

door_is_not_locked(Here, Direction) :-
	not(locked(Here, Direction)) ; 
 	write("That door is locked."), fail.
 			
 /* Aliases */
n :- 
	alive(Alive),
	Alive = true, n(_).
n(_) :- go(north).
s :- 
	alive(Alive),
	Alive = true, s(_).
s(_) :- go(south).
w :- 
	alive(Alive),
	Alive = true, w(_).
w(_) :- go(west).
e :- 
	alive(Alive),
	Alive = true, e(_).
e(_) :- go(east).


/* enemies on the way (ambush) */

attacked_by(evil_bat, Alive):-
	i_am_at(Place),
	at(Place, enemy(evil_bat, _, _)),
	life_points(Life),
	random(1, 3, Enemy_power),
	NewLife is Life - Enemy_power,
	retract(life_points(_)),
	assert(life_points(NewLife)),
	alive(Alive), Alive == true,
	format("You have been bitten by an ~w...You can't go anywhere without fighting! New life: ~w~s", [evil_bat, NewLife, "\n"]).
	
attacked_by(zoo_keeper, Alive):-
	i_am_at(Place),
	at(Place, enemy(zoo_keeper, _, _)),
	life_points(Life),
	random(1, 4, Enemy_power),
	NewLife is Life - Enemy_power,
	retract(life_points(_)),
	assert(life_points(NewLife)),
	alive(Alive), Alive == true,
	format("You have shot by a ~w...You can't go anywhere without fighting! New life: ~w~s", [zoo_keeper, NewLife, "\n"]).

attacked_by(gorilla, Alive):-
	i_am_at(Place),
	at(Place, enemy(gorilla, _, _)),
	life_points(Life),
	random(3, 6, Enemy_power),
	NewLife is Life - Enemy_power,
	retract(life_points(_)),
	assert(life_points(NewLife)),
	alive(Alive), Alive == true,
	format("You have been punched by a ~w...You can't go anywhere without fighting (good luck son!) New life: ~w~s", [gorilla, NewLife, "\n"]),
	drop_item. /* a gorilla punch will make you drop items */

/* a gorilla punch aftermaths */
drop_item:-
	holding(Container),
	contains(Container, Item),
	drop(Item),
	format("That punch made you lose a: ~w", [Item]).
drop_item. /*even if we have nothing to drop this predicate is always true as the attack needs to be successful*/

/* enemies dodging: to do change chances of dodging based on player life points */
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

/* TODO enemy reaction based on their own behaviours and their life points */
reaction(_, Enemy_life, _):-
	Enemy_life =< 0.
reaction(Enemy_type, Enemy_life, Behaviour):-
	Enemy_life > 0,
	react(Enemy_type, Behaviour).	
/* aggressive gorillas will fight back if it has a higher life than mine */
react(Type, Behaviour):- 
	attack_chances(Behaviour, Chance),
	Chance == 1,
	format("Careful! This ~w is fighting back!~s", [Type, "\n"]),
	attacked_by(Type, Alive), Alive == true, !.
react(_, _).

/* there is 50% chance that an aggressive enemy will fight back */
attack_chances(aggressive, Chance):-
	random(0, 2, Chance).
/* there is 30% chance that an wary enemy will fight back */
attack_chances(wary, Chance):-
	random(0, 3, Chance).
/* there is 25% chance that an evasive enemy will fight back */
attack_chances(evasive, Chance):-
	random(0, 5, Chance).
	

/* fight !*/
punch:- 
	alive(Alive),
	Alive = true, punch(_).	
punch(_):-
	life_points(Life),
	punch_power(Life, Power),
	i_am_at(Place),
	at(Place, enemy(Type, Enemy_life, Behaviour)), !, /* only hit one enemy at a time */
	not(dodge(Type)), !,
	New_enemy_life is Enemy_life - Power,
	damage_enemy(Type, Enemy_life, New_enemy_life, Behaviour),
	reaction(Type, New_enemy_life, Behaviour), !.

/* punch helper */
damage_enemy(Type, Old_life, New_enemy_life, Behaviour):-
	New_enemy_life > 0,
	i_am_at(Place),
	retract(at(Place, enemy(Type, Old_life, Behaviour))),
	change_attitude(New_enemy_life, NewBehaviour, Behaviour),
	assert(at(Place, enemy(Type, New_enemy_life, NewBehaviour))),
	format("You punched a ~w. ~w life: ~w~s", [Type, Type, New_enemy_life, "\n"]), !.
damage_enemy(Type, Old_life, _, Behaviour):-
	i_am_at(Place),
	retract(at(Place, enemy(Type, Old_life, Behaviour))),
	format("Well done! You just got rid of a: ~w.", [Type, "\n"]), !.
change_attitude(Enemy_life, NewBehaviour, _):-
	Enemy_life < 5,
	NewBehaviour = quiet.
change_attitude(_, NewBehaviour, Behaviour):-
	NewBehaviour = Behaviour.
	
/* get the punch power depending on life level */
punch_power(Life, Power):-
	Life < 3, Power is 0,
	write("you are to weak to fight...eat some fruit, son!"), fail.	
punch_power(Life, Power):-
	Life < 5, Power is 1, !.
punch_power(Life, Power):-
	Life < 10, Power is 2, !.
punch_power(Life, Power):-
	Life < 15, Power is 3, !.
punch_power(_, 4).