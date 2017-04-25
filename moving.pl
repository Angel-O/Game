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
	not(attacked_by(_)), !, 
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
n :- go(north).
s :- go(south).
w :- go(west).
e :- go(east).


/* enemies on the way */

attacked_by(evil_bat):-
	i_am_at(Place),
	at(Place, enemy(evil_bat, _)),
	life_points(Life),
	NewLife is Life - 1,
	retract(life_points(_)),
	assert(life_points(NewLife)),
	format("You have been bitten by an ~w...You can't go anywhere without fighting! New life: ~w~s", [evil_bat, NewLife, "\n"]).
	
attacked_by(zoo_keeper):-
	i_am_at(Place),
	at(Place, enemy(zoo_keeper, _)),
	life_points(Life),
	NewLife is Life - 2,
	retract(life_points(_)),
	assert(life_points(NewLife)),
	format("You have shot by a ~w...You can't go anywhere without fighting! New life: ~w~s", [zoo_keeper, NewLife, "\n"]).

attacked_by(gorilla):-
	i_am_at(Place),
	at(Place, enemy(gorilla, _)),
	life_points(Life),
	NewLife is Life - 4,
	retract(life_points(_)),
	assert(life_points(NewLife)),
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
dodge_chances(gorilla, Chance):-
	random(0, 3, Chance).	
/* gorillas have 25% */
dodge_chances(gorilla, Chance):-
	random(0, 5, Chance).
/* helper */
dodge(Type, 1):- 
	format("the ~w dodged your punch!", [Type]).
dodge(_, _):- 
	fail.

/* TODO enemy reaction based on their own behaviours and their life points */
reaction(Type):-
	react_chances(Type, Value),
	react(Type, Value).
/* bats have 50% chances to dodge a hit */
react_chances(evil_bat, Chance):-
	random(0, 2, Chance).
/* zoo_keepers have 30% */
react_chances(gorilla, Chance):-
	random(0, 3, Chance).	
/* gorillas have 25% */
react_chances(gorilla, Chance):-
	random(0, 5, Chance).
/* helper */
react(Type, 1):- 
	format("the ~w dodged your punch!", [Type]).
react(_, _):- 
	fail.

%reaction(evil_bat):-
%	random(0,1, Value),
%	react(evil_bat, Value).
	
%react(evil_bat, 0).
%react(evil_bat, 1):-
%	attacked_by(evil_bat).
	

/* fight !*/	
punch:-
	life_points(Life),
	punch_power(Life, Power),
	i_am_at(Place),
	at(Place, enemy(Type, Enemy_life)), !, /* only hit one enemy at a time */
	not(dodge(Type)), !,
	New_enemy_life is Enemy_life - Power,
	damage_enemy(Type, Enemy_life, New_enemy_life), !.

/* punch helper */
damage_enemy(Type, Old_life, New_enemy_life):-
	New_enemy_life > 0,
	i_am_at(Place),
	retract(at(Place, enemy(Type, Old_life))),
	assert(at(Place, enemy(Type, New_enemy_life))),
	format("You punched a ~w. ~w life: ~w~s", [Type, Type, New_enemy_life, "\n"]), !.
damage_enemy(Type, Old_life, _):-
	i_am_at(Place),
	retract(at(Place, enemy(Type, Old_life))),
	format("Well done! You just got rid of a: ~w.", [Type, "\n"]), !.

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