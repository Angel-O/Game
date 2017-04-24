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
%attacked:- attacked_by(_).

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

drop_item:-
	holding(Container),
	contains(Container, Item),
	drop(Item),
	format("That punch made you lose a: ~w", [Item]).
drop_item. /*even if we have nothing to drop this predicate is always true as the attack needs to be successful*/

/* fight !*/	
punch:-
	life_points(Life),
	punch_power(Life, Power),
	i_am_at(Place),
	at(Place, enemy(Type, Enemy_life)),
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

/* get the punch power depending on the life level */
punch_power(Life, _):-
	Life < 0,
	write("you are to weak to fight...eat some fruit, son!"), fail.	
punch_power(Life, Power):-
	Life < 5, Power is 1, !.
punch_power(Life, Power):-
	Life < 10, Power is 2, !.
punch_power(Life, Power):-
	Life < 15, Power is 3, !.
punch_power(_, 4).