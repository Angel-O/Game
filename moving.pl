:- module(moving, [n/0, s/0, w/0, e/0]).

/* ====================== Moving around the maze ==================================== */

/* GO SOMEWHERE PREDICATE TODO....make this private*/
/* if I am Here */
/* and the direction from the current location is clear */
/* I will end up to a place There connected to Here if I go this Direction */
/* so I will no longer be Here */
/* but I will be There instead */

go(Direction) :-
	i_am_at(Here), 
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