/*
 This module defines helpers predicates for the predicates defined in the main file.
 Ideally these predicates should not be used directly from the player.
*/

:- module(helpers, [there_is_something/1, item_is_near_me/2, can_pick/0, 
	count_item_in_pockets/1, still_space_in_pockets/1, max_reached/1, edible/1,
	drinkable/1, does_damage/2, i_hold_anything/0, list_enemy_items/2, pick_from_safe/2, 
	holding/1, is_there_even_a_safe/0, item_is_actually_there/3, alive/1, can_be_picked/1,
	item_is_inside_open_safe/2, process_name/2, does_damage/2]).

:- dynamic(holding/1).
	
/* ==================================== look helpers =================================== */

/* checking that there is something in the area */
there_is_something(Place) :-
	at(Place, _); 
	write("nothing in the area"), fail.

/* ================================= inspect helpers =================================== */

/* extracting the item held by the enemy */	
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
	at(Place, Container),
	contains(Container, Content), !.
item_is_actually_there(Place, Container, Content):-
	not(at(Place, Container)),
	format("~w? ...are you dreaming??!~s", [Content, "\n"]),
	fail.
/* the item is inside un unlocked safe */
item_is_inside_open_safe(Place, Item):-
	at(Place, safe(Item, unlocked)),
	Item \= empty.
/* can only pick an item if the pockets are not full */
can_pick:-
	count_item_in_pockets(Count), 
	still_space_in_pockets(Count), !,
	not(max_reached(Count)),
	Count < 3.
/* helper to check there is still spcae TODO...needs improvement... */
still_space_in_pockets(Count):- Count =< 3.
/* the max nomber of items allowed was reached, print friendly message */
max_reached(Count):-
	Count == 3,
	write("Your pockets are full! Drop something or eat it!!\n"), nl,
	fail, !.
	
/* defining what items can be picked */
can_be_picked(Item):-
	Item = food(_, _);
	Item = object(_, _);
	Item = liquid(_, _).
	
/* ==================================== eat helpers =================================== */

/* checking that the item collected is edible */
edible(Item):- Item = food(_, _).	
	
/* ==================================== drink helpers ================================== */

/* checking that the item collected is drinkable */
drinkable(Item):- Item = liquid(_, _).

/* the elisir will bring you back to the original state and heal any infection */
heal:-
	%user:health(Current_status),
	%retract(user:health(Current_status)),
	retractall(user:health(_)),
	assert(user:health(healthy)),
	retractall(life_points(_)),
	max_life(Max),
	assert(life_points(Max)),
	write("Drank: elisir"), nl,
	write("Wow, that elisir made miracles! You are brand new!\n"),
	format("New life: ~w~s", [Max,"\n"]).

/* ================================= pockets helpers =================================== */

/* checking that the player holds anything, print friendly message if not */	
i_hold_anything:-
	holding(_);
	write("You have nothing inside your pockets, mate...keep looking."), fail.
	
/* ==================================== grab helpers =================================== */

/* grabbing an item from a safe */
pick_from_safe(Item, Place):-
	Item \= empty,
	can_pick, 
	Stuff = object(Item, Item),
	assertz(holding(Stuff)),
	retract(at(Place, safe(Item, unlocked))),
	assertz(at(Place, safe(empty, unlocked))),
	format("Picked: ~w~s", [Item, "\n"]), !.

/* trying to grab from an empty safe */
pick_from_safe(empty, _):-
	named(Name),
	format("Hey ~w wake up! The safe is empty !!!~s", [Name, "\n"]), fail, !.
	
/* ======================= Player queries predicates helpers =========================== */

/* using default name or name specifed by user */
process_name(Value, Name):-
	Value = anything_really, /* checking if the value is bound the actual 
								value is not important */
	Name = "monkey lover", !.
process_name(Value, Name):-	Name = Value.

/* ============================= shared helpers (eat & drink) ========================== */
	
/* good stuff to drink */
does_damage(elisir, _):- heal, !.
	
/* not eveything is good to eat: rotten food will cause a one time drop of 3 life pts. */	
does_damage(Content, rotten):-
	life_points(Life),
	NewLife is Life - 3,
	retract(life_points(_)),
	assert(life_points(NewLife)),
	format("You ate: ~s ~w. New life: ~w", [rotten, Content, NewLife]),
	alive(Alive), Alive == true, !.

/* infected food will cause a progressive drop (-1) of life pts suffered each time the
player moves to a new area or room. */	
does_damage(Content, infected):- 
	retractall(health(_)),
	assert(user:health(infected)),
	format("You ate: ~s ~w.\n", [infected, Content]),
	write("Find the elisir to heal or you will constantly lose life points."),
	alive(Alive), Alive == true, !.
	
/* good stuff to eat will add +1 to the life points */
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
	write("You can't have that!"), !, fail. /*random damage...todo*/	
	
/* ============================= shared helpers (unlock & grab) ======================== */

/* unlock and grab only make sense if ther is a safe around, 
print friendly message if not */	
is_there_even_a_safe:-
	i_am_at(Place),
	safe_is_not_there(Place).
safe_is_not_there(Place):-
	not(at(Place, safe(_, _))),
	write("There isn't even a safe here..., try another place"), nl, fail, !.
	
/* ============================ shared helpers (pick & pockets) ======================== */
	
/* helper predicates to count how many times the holding predicate succeeds */
count_item_in_pockets(Count):-	
	aggregate_all(count, holding(_), Count).
	
/* ========== shared helpers (all top level predicates defined in main file) =========== */

/* life check: when the game is over you won't be allowed to use the main predicates */
alive(Alive):-
	life_points(Points),! ,
	alive(Points, Alive), !.
alive(_):-
	nl, format("Please, type the start command to begin the game"), nl, fail, !.	
alive(Points, Alive):-
	Points =< 0,
	format("~sGame Over, thanks for playing <aMazeInMonkey>.~sStats >>> ", ["\n", "\n\n"]),
	named(Name),
	format("Name: ~w, Life: ~w\n", [Name, Points]), !, 
	nl, write("Type 'start.' and hit enter to play again."),
	nl, write("Type 'instructions.' and hit enter to see the available commands."), nl,
	Alive = false, fail. 
alive(Points, Alive):-
	Points > 0,
	Alive = true.

/* print a message when you win */	
win :- 
	i_am_at(jungle),
	named(Name),
	format("\nGreat ~w! You made it out of the maze!!!", [Name]), nl,
	write("Thanks for playing <aMazeInMonkey>.~s").
