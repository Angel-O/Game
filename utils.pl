:- module(utils, [shortest/3]). 

:-dynamic(shortest_so_far/1).

:-retractall(shortest_so_far(_)).

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
	connected(Start, _, Next),
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
	connected(Start, Direction, Next),
	not(member(Next, Accumulator)),
	append(Accumulator, [Direction, Next], NewAccumulator),
	all_paths_dir_aux(Next, Finish, NewAccumulator, Path).
	
/* getting the shortest path between two locations!!! */
shortest(Start, Finish, Shortest):-
	shortest(Start, Finish, _, _);
	shortest_so_far(Shortest), !.
	
shortest(Start, Finish, _, _):-
	retractall(shortest_so_far(_)),
	all_paths_dir(Start, Finish, First),
	assert(shortest_so_far(First)),
	shortest(Start, Finish, First, _, _).
	
shortest(Start, Finish, First, _, _):-
	all_paths_dir(Start, Finish, Next),
	Next \= First,
	length(Next, Next_Length),
	shortest_so_far(Current_shortest),
	length(Current_shortest, Current_length),	
	Next_Length < Current_length,
	retractall(shortest_so_far(_)),
	assert(shortest_so_far(Next)), fail.


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
	