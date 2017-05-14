/*
 This module define the enemies: what type of enemies are in the game.
 their characteristics (type, Id, life, behaviour) what objects they hold and so on.
 It also defines criteria to establish which ones are the most dangerous and the rules
 they follow to move aroud the maze.
*/

:- module(enemy, [place_enemy/0, equip_enemy/0, enemy_holds/2, enemy_moves/1]).

:- dynamic(enemy_holds/2).

/* =============================== PLACING ENEMIES ==================================== */

/* randomly placing enemies in the maze */
place_enemy:-

	retractall(user:at_area(_, _, _)),
	
	/* sorting all enemies in the game */	
	sort_enemies([
		enemy(gorilla, g5, 26, aggressive), enemy(gorilla, g6, 23, aggressive),
		enemy(zoo_keeper, z5, 16, aggressive), enemy(zoo_keeper, z6, 18, aggressive),
		enemy(evil_bat, b5, 12, aggressive), enemy(evil_bat, b6, 8, aggressive),		
		enemy(gorilla, g1, 26, aggressive), enemy(gorilla, g2, 23, aggressive),
		enemy(gorilla, g3, 26, aggressive), enemy(gorilla, g4, 22, aggressive),
		enemy(evil_bat, b1, 8, aggressive), enemy(evil_bat, b2, 9, aggressive),
		enemy(evil_bat, b3, 7, aggressive), enemy(evil_bat, b4, 12, aggressive),
		enemy(zoo_keeper, z1, 14, aggressive), enemy(zoo_keeper, z2, 22, aggressive),
		enemy(zoo_keeper, z3, 16, aggressive), enemy(zoo_keeper, z4, 15, aggressive)], 
	Sorted),
	
	/* reversing the order from the most to the less dangerous */
	reverse(Sorted, Enemies),
	
	Enemies = [_, _, _, _|Remaining_Enemies], 
	
	subtract(Enemies, Remaining_Enemies, Four_Most_Dangerous),
	
	/* all rooms that can host an enemy: excluding jungle and grey_area */
	locations_no_ends(Trimmed_locations), scrumble_locations(Trimmed_locations, Locations),	
	
	/* get the shortest path from start to end point */
	shortest(grey_area, jungle, Path),
	
	subtract(Path, [grey_area, jungle], Allowed_locations_in_path),
	
	/* placing the most dangerous enemies on the shortest path */
	place_most_dangerous(
		Four_Most_Dangerous,
		Allowed_locations_in_path,
		[north, south, west, east]), /* all possible directions */
			
	/* placing the rest randomly on the maze */
	place_enemy(	
		Remaining_Enemies,			
		Locations,						
		[north, south, west, east]); /* all possible directions */
		
	not(fail). /* with the current constraints this should always be succesfull */


/* selecting a random enemy ad random locations and areas (in each location) where 
the enemies will be hiding */
place_most_dangerous(Most_dangerous, Path, Directions):-
	place_enemy(Most_dangerous, Path, Directions).
	
place_most_dangerous(_, _, _). /* making the predicate always successful to 
								be able to place the remaining enemiess */


/* selecting a random enemy ad random locations and areas (in each location) where 
the enemies will be hiding */
place_enemy(Enemies, Locations, Directions):-
	random_select(Enemy, Enemies, Other_enemies),
	/* random_member(Location, Locations), using a custom function (next_location) 
										to spread enemies more evenly */
	next_location(Location, Locations),
	random_member(Area, Directions), !,
	area_is_valid(Area, Location, Valid_area, Directions), !,
	assertz(user:at_area(Location, Valid_area, Enemy)), /* randomly placing enemies */
	place_enemy(Other_enemies, Locations, Directions).

/* when picking a random area we need to make sure that the area(direction) actually
makes sense, that is it actually connects to another room: not all directions lead to 
room */	
area_is_valid(Area, Location, Valid_area, Directions):-
	random_select(Valid_area, Directions, _),
	connected(Location, Valid_area, _);
	area_is_valid(Area, Location, Valid_area, Directions), !.
	
next_location(Location, Locations):-
	random_member(Location, Locations),
	not(user:at_area(Location, _, _)); /* pick another location if the one 
									selected already have an enemy anywhere */
	random_select(Location, Locations, Others),
	next_location(Location, Others);
	random_member(Location, Locations), !.

scrumble_locations(Locations, Scrumbled):-
	random_permutation(Locations, Scrumbled).


/* ============================= EQUIPPING ENEMIES ==================================== */

/* enemies that tend to react(aggressive behaviour) and have more life points should be 
on the shortest path */

/* TODO: enemies holding precious objects should be away from the shortest path */

equip_enemy:-
	assert(enemy_holds(g5, liquid(elisir, _))), assert(enemy_holds(g6, object(shield, 6))), 
	assert(enemy_holds(b5, liquid(elisir, _))), 
	assert(enemy_holds(b6, food(banana, healthy))), 
	assert(enemy_holds(z5, object(lens, _))), assert(enemy_holds(z6, object(key, safe))), 
	assert(enemy_holds(b1, object(lens, _))), assert(enemy_holds(b2, object(shield, 6))), 
	assert(enemy_holds(b3, object(lens, _))), 
	assert(enemy_holds(b4, food(apple, infected))),
	assert(enemy_holds(g1, object(key, door))), assert(enemy_holds(g2, object(shield, 10))),
	assert(enemy_holds(g3, object(key, safe))),
	assert(enemy_holds(g4, liquid(elisir, _))), assert(enemy_holds(z1, object(lens, _))),
	assert(enemy_holds(z2, object(shield, 8))), assert(enemy_holds(z3, object(lens, _))), 
	assert(enemy_holds(z4, food(banana, rotten))).
	
/* =============================== ENEMIES MOVING ===================================== */	

/* each time the user changes location, if an aggressive enemy is close to the shortest 
path from the user's location to the jungle it will move there to make game harder. 
This will happen only for the first aggressive enemy found */
enemy_moves(UserLocation):-
	shortest(UserLocation, jungle, Path), /* get the shortest path from the user's place */
	user:at_area(EnemyPlace, Area, Enemy),
	UserLocation \= EnemyPlace, /* if the enemy is already there, it will stay */
	Enemy = enemy(Type, Id, Life, aggressive),
	connected(AnotherLocation, _, EnemyPlace), /* another place connected to current 
												enemy's location */
	member(AnotherLocation, Path), /* another location is on the path */
	connected(AnotherLocation, _, UserLocation), /* another location is the next
															location in the path */
	retract(user:at_area(EnemyPlace, Area, Enemy)),
	connected(AnotherLocation, Direction, NextLocationInPath), /* in the direction
																  towards the jungle */
	member(NextLocationInPath, Path),
	NextLocationInPath \= UserLocation, /* next location in the path different from
										   the user location leads to the jungle */
	assert(user:at_area(AnotherLocation, Direction, enemy(Type, Id, Life, aggressive))),
	
	/* only the first aggressive one TODO: remove the output */ 
	%format("~w moved from ~w to ~w...", [Id, EnemyPlace, AnotherLocation]), nl, !. 
	write("(...sinister sounds...)"), nl, nl, !. 

enemy_moves(_). /* the predicate will always succeed */
	
/* =============================== SORTING ENEMIES ==================================== */

/* sorting the enemies based on the criteria defined below */	
sort_enemies(Unsorted, Sorted):-
	sort_enemies(Unsorted, [], Sorted).
sort_enemies(Unsorted, Accumulator, Sorted):-
	Unsorted = [H|[]],
	append([H], Accumulator, Sorted).	
sort_enemies(Unsorted, Accumulator, Sorted):-
	Unsorted = [_|_],
	find_most_dangerous(Unsorted, Most),
	append([Most], Accumulator, NewAccumulator),
	subtract(Unsorted, NewAccumulator, NewUnsorted),
	sort_enemies(NewUnsorted, NewAccumulator, Sorted), !.

/* finding the most dangerous enemies in a list of enemies */	
find_most_dangerous(EnemyList, Most):-
	EnemyList = [H|T], Current_Most = H,
	find_most_dangerous(T, Current_Most, Most).	
find_most_dangerous(EnemyList, Current_Most, Most):-
	EnemyList = [H|[]],
	more_dangerous(H, Current_Most, Most).
find_most_dangerous(EnemyList, Current_Most, Absolute_Most):-
	EnemyList = [H|T],
	more_dangerous(H, Current_Most, New_Most),
	find_most_dangerous(T, New_Most, Absolute_Most), !.	

/* =============================== SORTING CRITERIA =================================== */

/* TODO,  make it independent of the type...adding a weight */
/* gorilla are more dangerous than any other enemy */
more_dangerous(A, B, Dangerous):-
	A = enemy(gorilla, _, _, _),
	B = enemy(Type, _, _, _),
	Type \= gorilla, Dangerous = A.
more_dangerous(A, B, Dangerous):-
	A = enemy(Type, _, _, _),
	B = enemy(gorilla, _, _, _),
	Type \= gorilla, Dangerous = B.
/* zoo_keeper are more dangerous than evil_bats */
more_dangerous(A, B, A):-
	A = enemy(zoo_keeper, _, _, _),
	B = enemy(Type, _, _, _),
	Type == evil_bat, !.
more_dangerous(A, B, B):-
	B = enemy(zoo_keeper, _, _, _),
	A = enemy(Type, _, _, _),
	Type == evil_bat, !.
/* for enemies of the same type the one with the highest life score is the most 
dangerous */
more_dangerous(A, B, A):-
	A = enemy(Type, _, A_life, _),
	B = enemy(Type, _, B_life, _),
	A_life > B_life, !.
more_dangerous(A, B, B):-
	A = enemy(Type, _, A_life, _),
	B = enemy(Type, _, B_life, _),
	A_life =< B_life, !.
/* for enemies of the same type with the same life score the most 
dangerous is the aggressive one */
more_dangerous(A, B, A):-
	A = enemy(Type, _, Life, aggressive),
	B = enemy(Type, _, Life, Behaviour),
	Behaviour \= aggressive, !.
more_dangerous(A, B, B):-
	A = enemy(Type, _, Life, Behaviour),
	B = enemy(Type, _, Life, aggressive),
	Behaviour \= aggressive, !.