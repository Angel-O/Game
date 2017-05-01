:- module(enemy, [place_enemy/0, equip_enemy/0, enemy_holds/2, enemy_moves/1]).

:- dynamic(enemy_holds/2).


/* =============================== PLACING ENEMIES ==================================== */

/* randomly placing enemies in the maze */ /* TODO verify... */
place_enemy:-

	retractall(user:at_area(_, _, _)),
	
	/* sorting all enemies in the game from the most to the less dangerous */	
	sort_enemies([		
		enemy(gorilla, g1, 26, aggressive), enemy(gorilla, g2, 23, aggressive),
		enemy(gorilla, g3, 26, aggressive), enemy(gorilla, g4, 22, aggressive),
		enemy(evil_bat, b1, 8, aggressive), enemy(evil_bat, b2, 9, aggressive),
		enemy(evil_bat, b3, 7, aggressive), enemy(evil_bat, b4, 12, aggressive),
		enemy(zoo_keeper, z1, 14, aggressive), enemy(zoo_keeper, z2, 22, aggressive),
		enemy(zoo_keeper, z3, 16, aggressive), enemy(zoo_keeper, z4, 15, aggressive)], 
	Sorted),
	
	reverse(Sorted, Enemies),
	
	Enemies = [_, _, _, _|Remaining_Enemies], 
	
	subtract(Enemies, Remaining_Enemies, Four_Most_Dangerous),
	
	/* all rooms that can host an enemy: excluding jungle and grey_area */
	scrumble_locations([
		room1, room2, room3, room4, room5, room6, room7, room8, room9, room10],
		Locations),	
	
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
		
	not(fail).


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
	%random_member(Location, Locations),
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

/* enemies holding precious objects should be away from the shortest path */
/* enemies that tend to react(aggressive behaviour) and have more life points should be 
on the shortest path */

equip_enemy:-
	assert(enemy_holds(b1, object(lens, _))), assert(enemy_holds(b2, object(shield, _))), 
	assert(enemy_holds(b3, object(lens, _))), 
	assert(enemy_holds(b4, food(apple, infected))),
	assert(enemy_holds(g1, object(mirror, _))), assert(enemy_holds(g2, object(shield, _))),
	assert(enemy_holds(g3, object(key_to_safe, _))),
	assert(enemy_holds(g4, drink(elisir, _))), assert(enemy_holds(z1, object(lens, _))),
	assert(enemy_holds(z2, object(shield, _))), assert(enemy_holds(z3, object(lens, _))), 
	assert(enemy_holds(z4, food(banana, rotten))).
	
/* =============================== ENEMIES MOVING ===================================== */	

/* if an aggressive enemy is close to the shortest path to the jungle it will move there
to make your life harder. This will happen only for the first aggressive enemy found */
enemy_moves(UserLocation):-
	shortest(UserLocation, jungle, Path), /* get the shortest path */
	user:at_area(EnemyPlace, Area, Enemy),
	Enemy = enemy(Type, Id, Life, aggressive),
	connected(AnotherLocation, _, EnemyPlace), /* another place connected to current 
												enemy's location */
	member(AnotherLocation, Path), /* another location is on the path */
	connected(AnotherLocation, Direction, UserLocation), /* another location is the next
															location in the path */
	retract(user:at_area(EnemyPlace, Area, Enemy)),
	assert(user:at_area(AnotherLocation, Direction, enemy(Type, Id, Life, aggressive))),
	
	/* only the first aggressive one TODO: remove the output */ 
	format("~w moved from ~w to ~w...", [Id, EnemyPlace, AnotherLocation ]), nl, !. 

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

/* testing */
do_sort:-
	sort_enemies([enemy(gorilla, g1, 26, aggressive),enemy(gorilla, g2, 23, aggressive),
		enemy(gorilla, g3, 26, aggressive), enemy(gorilla, g4, 22, aggressive),
		enemy(evil_bat, b1, 8, aggressive), enemy(evil_bat, b2, 9, aggressive),
		enemy(evil_bat, b3, 7, aggressive), enemy(evil_bat, b4, 12, aggressive),
		enemy(zoo_keeper, z1, 14, aggressive), enemy(zoo_keeper, z2, 22, aggressive),
		enemy(zoo_keeper, z3, 16, aggressive), enemy(zoo_keeper, z4, 15, aggressive)], 
	Enemies),
	list_out(Enemies).
list_out([]):- nl.	
list_out([H|T]):-
	write(H), nl, list_out(T).

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
	


















/* ====================================== UNUSED ====================================== */

all_locations_have_at_least_one_enemy([]).
all_locations_have_at_least_one_enemy([H]):-
	user:at_area(H, _, _).
all_locations_have_at_least_one_enemy([H|T]):-
	user:at_area(H, _, _),
	all_locations_have_at_least_one_enemy(T).
	

/* items values */
value(key_to_jungle, 10).
value(door_key, 9).
value(elisir, 8).
value(key_to_safe, 7).
value(shield, 6).
value(_, 0).

/*GET RID OF THIS */
/* holding more valuable items */	
more_valuable(A, B, A):-
	A = enemy(_, Id_a, _, _),
	B = enemy(_, Id_b, _, _),
	enemy_holds(Id_a, object(Item_a, _)),
	enemy_holds(Id_b, object(Item_b, _)), 
	value(Item_a, Value_a), value(Item_b, Value_b),
	Value_a >= Value_b, !.
	
more_valuable(A, B, B):-
	A = enemy(_, Id_a, _, _),
	B = enemy(_, Id_b, _, _),
	enemy_holds(Id_a, object(Item_a, _)),
	enemy_holds(Id_b, object(Item_b, _)), 
	value(Item_a, Value_a), value(Item_b, Value_b),
	Value_a < Value_b, !.

/* holding vs not holding */	
more_valuable(A, B, A):-
	A = enemy(_, Id_a, _, _),
	B = enemy(_, Id_b, _, _),
	enemy_holds(Id_a, object(Item, _)),
	value(Item, Value), Value > 0,
	not(enemy_holds(Id_b, _)), !.
more_valuable(A, B, B):-
	A = enemy(_, Id_a, _, _),
	B = enemy(_, Id_b, _, _),
	enemy_holds(Id_b, object(Item, _)),
	value(Item, Value), Value > 0,
	not(enemy_holds(Id_a, _)), !.

%more_valuable(A, _, A).	




	
find_most_valuable(EnemyList, Most):-
	EnemyList = [H|T], Current_Most = H,
	find_most_valuable(T, Current_Most, Most).	
find_most_valuable(EnemyList, Current_Most, Most):-
	EnemyList = [H|[]],
	more_valuable(H, Current_Most, Most).
find_most_valuable(EnemyList, Current_Most, Absolute_Most):-
	EnemyList = [H|T],
	more_valuable(H, Current_Most, New_Most),
	find_most_valuable(T, New_Most, Absolute_Most), !.




	
	

/* sorting, reversing... */
place_enemies(Enemies):-
	shortest(grey_area, jungle, Path), /* or before the jungle... */
	reverse(Path, ReversedPath),
	sort_enemies(Enemies, Sorted),
	reverse(Sorted, ReversedEnemies),
	All_Locations = [room1, room2, room3, room4, room4, room5, room6, room7, room8, room9,
					 room10],
	place_enemies(ReversedEnemies, All_Locations, ReversedPath).

/* start... */
place_enemies(Enemies, All_Locations):-
	Enemies = [H|[]],
	random_area(Area),
	random_location(All_Locations, Location),
	assertz(at_area(Location, Area, H)).
	
/* Placing the remaining enemies in the remaining locations */	
place_enemies(Enemies, All_Locations):-
	Enemies = [H|T],
	random_area(Area),
	random_location(All_Locations, Location),
	assertz(at_area(Location, Area, H)),
	place_enemies(T, All_Locations). /* no one in the jungle */

/* only one locations left: the jungle. Nothing will go there */
place_enemies(Enemies, All_Locations, Path):-
	Path = [jungle|[]],
	shortest(grey_area, jungle, Initial),
	subtract(All_Locations, Initial, Remaining_Localtions),
	place_enemies(Enemies, Remaining_Localtions).

/* only two locations left: the jungle and an adjacent room, whichever */
place_enemies(Enemies, All_Locations, Path):-
	Path = [F,S|[]],
	Enemies = [H|T],
	connected(F, Direction, S),
	assertz(at_area(F, Direction, H)),
	place_enemies(T, All_Locations, [S]). /* no one in the jungle */

/* placing most dangerous enemies on the shortest path */
place_enemies(Enemies, All_Locations, Path):-
	list_out(Path),
	Enemies = [H|T],
	Path = [F,S|R], /* first, second, rest */
	connected(S, Direction, F), /* find the direction between F and S */
	list_out(Enemies),
	assertz(at_area(F, Direction, H)), /* place the enemy on the path */
	place_enemies(T, All_Locations, [S|R]). /* place the remaining enemies */

