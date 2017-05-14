/*
 testing and debugging
*/

:- module(debugging, [place_items_debug/0]).

place_items_debug:-
	%assert(i_am_at(room8)), 
	assert(user:at(room8, object(key, door))),
	
	assertz(user:at(grey_area, object(shield, 10))), 
	assertz(user:at(grey_area, food(banana, rotten))), 
	assertz(user:at(grey_area, liquid(elisir, _))), 
	assertz(user:at(grey_area, liquid(elisir, _))), 
	assertz(user:at(grey_area, food(banana, infected))), 
	assertz(user:at(grey_area, food(apple, healthy))),
	assertz(user:at(grey_area, object(key, safe))), 
	
	assertz(user:at(grey_area, object(specs, unpaired))),
	assertz(user:at(grey_area, object(lens, _))),
	assertz(user:at(grey_area, safe(lens, locked))),
	 
	assertz(user:at(grey_area, object(key, door))), 
	assertz(user:at(grey_area, object(key, jungle))),
	
	
	assertz(user:at(grey_area, object(specs))),
	assertz(user:at(grey_area, object(lens))),
	%assertz(user:at(grey_area, object(bag, 2))),
	
	 
	assertz(user:at_area(grey_area, north, enemy(gorilla, deb1, 1, aggressive))), 
	assertz(user:at_area(grey_area, north, enemy(gorilla, deb2, 2, aggressive))), 
	assertz(user:at_area(grey_area, north, enemy(gorilla, deb3, 3, aggressive))),
	
	assertz(enemy_holds(deb3, object(bbb, kkk))).
	
	
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