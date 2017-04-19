/* <aMazeInMonkey>, by <Angelo Oparah>. */

set_prolog_flag(answer_write_options,[max_depth(0)]).

/* certain stuff will move around... */
:- dynamic(i_am_at/1).
:- dynamic(named/1). 
:- dynamic(locked/2).
:- dynamic(life/1).

/* this section will reset the game ot the initital state when the game is reloaded */
:- retractall(at(_, _)), retractall(i_am_at(_)), retractall(alive(_)).
i_am_at(grey_area). /* you start the game in a neboulous place called grey_area... */
named(player).

/* ================================================================================== */
/* this section describes which locations are connected between them and in what 
direction */
path(grey_area, south, room1).
path(grey_area, west, room1).
path(grey_area, north, room1).
path(grey_area, east, room1).

path(room1, south, grey_area).
path(room1, west, room3).
path(room1, north, room2).
path(room1, east, room4).

path(room2, south, room1).
path(room2, west, room6).
path(room2, north, room9).
path(room2, east, room4).

path(room3, south, room1).
path(room3, north, room6).
 
path(room4, south, room1).
path(room4, west, room2).
path(room4, east, room8).

path(room5, south, room9).
path(room5, west, room7).
path(room5, north, room8).

path(room6, south, room3).
path(room6, north, room7).
path(room6, east, room2).

path(room7, south, room6).
path(room7, west, grey_area).
path(room7, north, room10).
/* path(room7, east, room5). */

path(room8, south, room9).
/* path(room8, west, room6). */
path(room8, north, jungle).
path(room8, east, room4).

/* path(room9, south, room1). */
path(room9, west, room5).
path(room9, north, room10).
path(room9, east, room8).

path(room10, south, room9).
path(room10, west, room7).
path(room10, east, key_room).

path(jungle, north, sroom).


/* ================================================================================== */
/* ====================== Moving around the maze ==================================== */

/* Go somewhere:
1. no longer being where I was 
2. being somewhere new 
3. being allowed move in sunch direction from here*/
go(Direction) :-
	i_am_at(Here), /* if I am Here */
	can_go_from_here(Here, Direction), /* and the direction from the current location is clear */
	path(Here, Direction, There), /* I will end up There if I go this Direction */
	retract(i_am_at(Here)), /* so I will no longer be Here */
	assert(i_am_at(There)), /* but I will be There */
	format("You are in ~w", [There]).

/* Aliases */
n :- go(north).
s :- go(south).
w :- go(west).
e : go(east).
 
 can_go_from_here(Here, Direction):-
 	not(locked(Here, Direction)) ; /*using disjunction to evaluate second goal and print a friendly message*/
 	write("That door is locked."),
 	fail. /* since I used disjunction ONLY to evaluate the second goal I need to report a fail
 			otherwise the rule will be succesful */ 
 
/*fix r4 r8...east..*/





/* ================================================================================== */
/* ==================== Find all paths between 2 locations ========================== */	
/* 
a location B can be reached from a location A if:
1. A is adjacent to a location C, C is adjacent to a location D, 
D is adjacent to E...so on and so forth....until we get to B
2. The intermediate locations are different from start and end
3. You are not moving to the same location
4. The final location is a location adjacent to B
5. You are never going back to the same initial location
*/

/* finds all paths between two arbitrary locations using auxiliary
function with accumulator */
all_paths(Start, Finish, Path):-
	all_paths_aux(Start, Finish, [Start], Path).
all_paths_aux(Start, Start, [Start|[]], Path):-
	Path = "you are already there, aren't you?!", !.	
all_paths_aux(Finish, Finish, Accumulator, Path):-
	Path = Accumulator.
all_paths_aux(Start, Finish, Accumulator, Path):-
	path(Start, _, Next),
	append(Accumulator, [Next], NewAccumulator),
	is_set(NewAccumulator),
	all_paths_aux(Next, Finish, NewAccumulator, Path).
	
/* this variant adds the direction between locations */
all_paths_dir(Start, Finish, Path):-
	all_paths_dir_aux(Start, Finish, [Start], Path).
all_paths_dir_aux(Start, Start, [Start|[]], Path):-
	Path = "you are already there, aren't you?!", !.	
all_paths_dir_aux(Finish, Finish, Accumulator, Path):-
	Path = Accumulator.
all_paths_dir_aux(Start, Finish, Accumulator, Path):-
	path(Start, Direction, Next),
	not(member(Next, Accumulator)),
	append(Accumulator, [Direction, Next], NewAccumulator),
	all_paths_dir_aux(Next, Finish, NewAccumulator, Path).

/* this rule determines if two rooms are adjacent. Note how
the comparison must come after the path rule is called
since it is not bound before that
 */
%adjacent(RoomA, RoomB) :-
%	path(RoomA, _ , RoomB),
%	RoomA \= RoomB.
	
%not_circular([]).
%not_circular([_|[]]).
%not_circular([H|T]):-
%	not(member(H, T)).
	
/* ================================================================================== */
	
/* start facts */

locked(room8, north). /* locking the door to the jungle */
locked(room1, north). /* to be removed.... */

life(Value) :- Value = 20.

win :- i_am_at(jungle). /* more to come...being alive... */

first_name :-
	write("type your name (\"in double qoutes\"): "),
	read(X),
	retract(named(me, _)),
	assert(named(me, X)),
	format(`welcome to aMazeInMonkey, ~w`, [X]).





