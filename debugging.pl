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