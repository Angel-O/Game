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
	