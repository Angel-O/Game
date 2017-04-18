/* <aMazeInMonkey>, by <Angelo Oparah>. */

/* certain stuff will move around... */
:- dynamic(i_am_at/1).
:- dynamic(named/1). 

/* this section will reset the game ot the initital state when the game is reloaded */
:- retractall(at(_, _)), retractall(i_am_at(_)), retractall(alive(_)).
i_am_at(grey_area). /* you start the game in a neboulous place called grey_area... */
named(player).

/* this section describes how locations are connected  between them */
path(grey_area, so, room1).
path(grey_area, we, room1).
path(grey_area, nr, room1).
path(grey_area, ea, room1).

path(room1, so, grey_area).
path(room1, we, room3).
path(room1, nr, room2).
path(room1, ea, room4).

path(room3, so, room1).
path(room3, nr, room6).
 
path(room2, so, room1).
path(room2, we, room6).
path(room2, nr, room9).
path(room2, ea, room4).

path(room4, so, room1).
path(room4, we, room2).
path(room4, ea, room8).

path(room6, so, room3).
path(room6, nr, room7).
path(room6, ea, room2).

/* path(room9, so, room1). */
path(room9, we, room5).
path(room9, nr, room10).
path(room9, ea, room8).

path(room8, so, room9).
/* path(room8, we, room6). */
path(room8, nr, jungle).
path(room8, ea, room4).

path(room7, so, room6).
path(room7, we, grey_area).
path(room7, nr, room10).
/* path(room7, ea, room5). */

path(room5, so, room9).
path(room5, we, room7).
path(room5, nr, room8).

path(room10, so, room9).
path(room10, we, room7).
path(room10, ea, key_room).

path(jungle, nr, sroom).

/* this rule determines if two rooms are adjacent. Note how
the comparison must come after the path rule is called
since it is not bound before that
 */
 
adjacent(RoomA, RoomB) :-
	path(RoomA, _ , RoomB),
	RoomA \= RoomB.
	
/* 
a location B can be reached from a location A if:
1. A is adjacent to a location C, C is adjacent to a location D, 
D is adjacent to E...so on and so forth....until we get to B
2. The intermediate locations are different from start and end
3. You are not moving to the same location
4. The final location is a location adjacent to B
5. You are never going back to the same initial location
*/

not_circular([]).
not_circular([_|[]]).
not_circular([H|T]):-
	not(member(H, T)).


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
	
/* start facts */

first_name :-
	write("type your name (\"in double qoutes\"): "),
	read(X),
	retract(named(me, _)),
	assert(named(me, X)),
	format(`welcome to aMazeInMonkey, ~w`, [X]).

/* this section describes how to move */




