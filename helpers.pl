/*
 This module defines helpers predicates for the predicates defined in the main file.
 Ideally these predicates should not be used directly from the player.
*/

:- module(helpers, [there_is_something/1, item_is_near_me/2, can_pick/0, count_item_in_pockets/1, 
 still_space_in_pockets/1, max_reached/1, edible/1, does_damage/2, i_hold_anything/0, list_enemy_items/2,
 pick_from_safe/2, holding/1, is_there_even_a_safe/0, item_is_actually_there/3, alive/1]).

:- dynamic(holding/1).
	
/* ==================================== look helpers =================================== */

/* look helper */
there_is_something(Place) :-
	at(Place, _); 
	write("nothing in the area"), fail.

/* ================================= inspect helpers =================================== */
	
list_enemy_items(Id, Item):-
	enemy_holds(Id, Stuff),
	contains(Stuff, Item).

/* ==================================== pick helpers =================================== */

/* there is not an item item in the room you are: print a friendly message */	
item_is_near_me(Place, Item):-
	at(Place, Item);
	format("nothing else to pick here...~s", ["\n"]),
	fail.
/* the item is in the same room as you */
item_is_actually_there(Place, Container, Content):-
	at(Place, Container);
	format("~w? ...are you dreaming??!", [Content]),
	fail.
/* can only pick an item if the pockets are not full */
can_pick:-
	count_item_in_pockets(Count), 
	still_space_in_pockets(Count), !,
	not(max_reached(Count)),
	Count < 3.
/* helper predicates to count how many times the holding predicate succeeds */
count_item_in_pockets(Count):-	
	aggregate_all(count, holding(_), Count).
still_space_in_pockets(Count):- Count =< 3.
/* the max nomber of items allowed was reached, print friendly message */
max_reached(Count):-
	Count == 3,
	write("Your pockets are full! Drop something or eat it!!\n"),
	fail, !.
	
/* ==================================== eat helpers =================================== */

/* checking that the item collected is edible */
edible(Item):-
	contains(Item, Content),
	Item = food(Content, Status),
	does_damage(Content, Status).
	
/* not eveything is good to eat!! */	
does_damage(Content, infected):-
	life_points(Life),
	NewLife is Life - 3,
	retract(life_points(_)),
	assert(life_points(NewLife)),
	format("You ate: ~s ~w. New life: ~w", [infected, Content, NewLife]),
	alive(Alive), Alive == true, !.
does_damage(Content, rotten):- 
	life_points(Life),
	NewLife is Life - 2,
	retract(life_points(_)),
	assert(life_points(NewLife)),
	format("You ate: ~s ~W. New life: ~w", [rotten, Content, NewLife]),
	alive(Alive), Alive == true, !.
	
/* good stuff to eat */
does_damage(_, healthy):- 
	life_points(Life),
	NewLife is Life + 1,
	retract(life_points(_)),
	assert(life_points(NewLife)),
	format("Yummy! New life: ~w", [NewLife]), !.
	
/* this double wild card will be matched no matter what, even 
if the alive predicate fails, therefore I am checking the life points directly*/
does_damage(_, _):-
	life_points(Life), Life > 0,
	write("You can't eat that!"), fail. /*random damage...todo*/

/* ================================= pockets helpers =================================== */

/* checking that the player holds anything, print friendly message if not */	
i_hold_anything:-
	holding(_);
	write("You have nothing, mate...keep looking."), fail.
	
/* ==================================== grab helpers =================================== */

/* grabbing an item from a safe */
pick_from_safe(Item, Place):-
	can_pick, 
	Stuff = object(Item, Item),
	assertz(holding(Stuff)),
	retract(at(Place, safe(Item, unlocked))),
	assertz(at(Place, safe(empty, unlocked))),
	format("Picked: ~w~s", [Item, "\n"]), !.
	
/* ============================= shared helpers (unlock & grab) ======================== */

/* unlock and grab only make sense if ther is a safe around, 
print friendly message if not */	
is_there_even_a_safe:-
	i_am_at(Place),
	safe_is_not_there(Place).
safe_is_not_there(Place):-
	not(at(Place, safe(_, _))),
	write("There isn't even a safe here..., try another place"), nl, fail, !.
	
/* ========== shared helpers (all top level predicates defined in main file) =========== */

/* life check: when the game is over you won't be allowed to use the main predicates */
alive(Alive):-
	life_points(Points),
	alive(Points, Alive).
alive(Points, Alive):-
	Points =< 0,
	format("~sGame Over, thanks for playing <aMazeInMonkey>.~sStats >>> ", ["\n", "\n\n"]),
	me, 
	Alive = false, fail. 
alive(Points, Alive):-
	Points > 0,
	Alive = true.	