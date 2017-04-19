/* <aMazeInMonkey>, by <Angelo Oparah>. */

set_prolog_flag(answer_write_options,[max_depth(0)]).

/* certain stuff will move around... */
:- dynamic(i_am_at/2).
:- dynamic(named/1). 
:- dynamic(locked/2).
:- dynamic(life/1).
:- dynamic(holding/1).

/* ========================== Importing files and modules ============================= */

/* this describes how rooms are conneted between them */
:- include('rooms.pl').
:- use_module(moving, [n/0, s/0, w/0, e/0]).


/* ================================== Start facts ===================================== */

/* this section will reset the game ot the initital state when the game is reloaded */
:- retractall(at(_, _)), retractall(i_am_at(_)), retractall(alive(_)), retractall(holding(_)).
i_am_at(grey_area). /* you start the game in a neboulous place called grey_area... */
named(player).
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

 
/* ====================== Find all paths between 2 locations ========================== */	
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

/* item types */
food(bananas).

/* items' location */	
at(room10, key_to_jungle).
at(room5, magic_wand).
at(room7, bananas).
at(room1, bananas).
at(room2, bananas).
at(room9, bananas).
at(room8, bananas). /*they will be rotten*/
at(room3, bananas). /* they will be infected */
at(room5, rotten_bananas_detector).
at(room6, key_to_safe).
at(room9, safe).



/* inspecting a place */
look :-
	i_am_at(Here),
	at(Here, Item),
	format("Looking, around...~sFound: ~w", ["\n", Item]).
	



/* picking and dropping items */
pick(Item):-
	i_am_at(Place),
	at(Place, Item),
	can_pick,
	assertz(holding(Item)),
	retract(at(Place, Item)), !.
	
drop(Item):-
	i_am_at(Place),
	holding(Item),
	retract(holding(Item)),
	assertz(at(Place, Item)), !. /*dbl check*/
	
can_pick:-
	still_space_in_pockets;
	write("Your pockets are full! Drop something or eat it!!"),
	fail.

still_space_in_pockets:-	
	aggregate_all(count, holding(_), Count),
	Count < 3.
	
empty_pockets:-
	aggregate_all(count, holding(_), Count),
	Count == 0.
	
holding(nothing):- fail.

/* interactions with items... to be fixed... */
infected(bananas, room8).
rotten(banans, room3).

health(Item):-
	i_am_at(Place),
	not(infected(Item, Place)).
	

does_damage(Item, Damage):-
	infected(Item, [5, 4, 3, 2, 1]);
	rotten(Item, [2, 1]).
	
damage(Life, Damage).


eat(Item):-
	is_food(Item).
	
	
unlock(Item):-
	Item == safe.




