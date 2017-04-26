:- module(helpers, [there_is_something/1, item_is_near_me/2, can_pick/0, count_item_in_pockets/1, 
 still_space_in_pockets/1, max_reached/1, edible/1, does_damage/2, i_hold_anything/0,
 pick_from_safe/2, holding/1, is_there_even_a_safe/0, item_is_actually_there/3 ]).

:- dynamic(holding/1).

/* ======================================== HELPERS =================================== */
/* look helper */
there_is_something(Place) :-
	at(Place, _); 
	write("nothing in the area"), fail.

/* pick helper */	
item_is_near_me(Place, Item):-
	at(Place, Item);
	format("nothing else to pick here...~s", ["\n"]),
	fail.
item_is_actually_there(Place, Container, Content):-
	at(Place, Container);
	format("~w? ...are you dreaming??!", [Content]),
	fail.
can_pick:-
	count_item_in_pockets(Count), 
	still_space_in_pockets(Count), !,
	not(max_reached(Count)),
	Count < 3.
count_item_in_pockets(Count):-	
	aggregate_all(count, holding(_), Count).
still_space_in_pockets(Count):- Count =< 3.
max_reached(Count):-
	Count == 3,
	write("Your pockets are full! Drop something or eat it!!\n"),
	fail, !.
	
/*  eat helper */
edible(Item):-
	contains(Item, Content),
	Item = food(Content, Status),
	does_damage(Content, Status).	
does_damage(Content, infected):-
	life_points(Life),
	NewLife is Life - 3,
	retract(life_points(_)),
	assert(life_points(NewLife)),
	format("You ate: ~s ~w. New life: ~w", [infected, Content, NewLife]), !.
does_damage(Content, rotten):- 
	life_points(Life),
	NewLife is Life - 2,
	retract(life_points(_)),
	assert(life_points(NewLife)),
	format("You ate: ~s ~W. New life: ~w", [rotten, Content, NewLife]), !.
does_damage(_, healthy):- 
	life_points(Life),
	NewLife is Life + 1,
	retract(life_points(_)),
	assert(life_points(NewLife)),
	format("Yummy! New life: ~w", [NewLife]), !.
does_damage(_, _):-
	write("You can't eat that!"), fail. /*random damage...todo*/

/* pockets helper */	
i_hold_anything:-
	holding(_);
	write("You have nothing, mate...keep looking."), fail.

/* grab helper */	
pick_from_safe(Item, Place):-
	can_pick, /* make predicate private and remove this...*/
	Stuff = object(Item, Item),
	assertz(holding(Stuff)),
	retract(at(Place, safe(Item, unlocked))),
	assertz(at(Place, safe(empty, unlocked))),
	format("Picked: ~w~s", [Item, "\n"]), !.

/* unlock and grab helpers */	
is_there_even_a_safe:-
	i_am_at(Place),
	safe_is_not_there(Place).
safe_is_not_there(Place):-
	not(at(Place, safe(_, _))),
	write("There isn't even a safe here..., try another place"), nl, fail, !.