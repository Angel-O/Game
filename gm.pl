/* <aMazeInMonkey>, by <Angelo Oparah>. */

%set_prolog_flag(answer_write_options,[max_depth(0)]).

/* dynamic predicates */
:- dynamic(i_am_at/2).
:- dynamic(at/2).
:- dynamic(named/1). 
:- dynamic(locked/2).
:- dynamic(holding/1).
:- dynamic(life_points/1).

/* ========================== Importing files and modules ============================= */
/* this describes how rooms are conneted between them */
:- include('rooms.pl').
:- use_module(moving, [n/0, s/0, w/0, e/0]).

/* ================================== Game reset ====================================== */
/* this section will reset the game ot the initital state when the game is reloaded */
:- retractall(at(_, _)), retractall(i_am_at(_)), retractall(life_points(_)), retractall(holding(_)).
:- assert(life_points(20)).

/* ================================== Game misc  ===================================== */
/* more to come... */
win :- i_am_at(jungle).
game_over :-
	life_points(X),
	X < 0;
	write("Game Over"), fail.
	
life :- 
	life_points(X),
	write(X).
	
/* user interaction... */
first_name :-
	write("type your name (\"in double qoutes\"): "),
	read(X),
	retract(named(me, _)),
	assert(named(me, X)),
	format(`welcome to aMazeInMonkey, ~w`, [X]).

/* ================================== Start facts ===================================== */
/* player */
i_am_at(grey_area). named(player).

/* locations */
locked(room8, north). locked(room1, north). /* to be removed.... */

/* items' location and status */	
at(room10, object(key_to_jungle, _)).
at(room5, safe(magic_wand, locked)).
at(room7, food(banana, healthy)).
at(room1, food(banana, healthy)).
at(room2, food(banana, healthy)).
at(room4, food(banana, healthy)).
at(room8, food(banana, rotten)). 
at(room3, food(banana, infected)). 
at(room5, object(rotten_banana_detector)).
at(room6, object(key_to_safe, _)).
at(room9, safe(magic_wand, locked)).

/* debug */
at(grey_area, food(banana, infected)).
at(grey_area, food(apple, healthy)).
at(grey_area, object(key_to_safe, _)).
at(grey_area, safe(magic_wand, locked)).
at(room1, safe(key_to_jungle, locked)).


/* defining items as containers */
contains(Item, Content) :- 
	Item = food(Content, _);
	Item = object(Content, Content).
contains(Item, Content) :-
	Item = safe(_, locked),
	Content = locked_safe.
contains(Item, Content) :-
	Item = safe(empty, unlocked),
	Content = "empty safe".
contains(Item, Content) :-
	Item = safe(X, unlocked),
	X \= empty,
	name(" (inside an open safe)", Suffix),
	name(X, Prefix),
	append(Prefix, Suffix, ContentToList),
	name(Content, ContentToList).
	
/* defining what items can be picked */
can_be_picked(Item):-
	Item = food(_, _);
	Item = object(_, _).
	
can_be_picked(Item):-
	Item = safe(_, locked),
	format("There is a safe here, but you can't lift it...~s", ["\n"]),
	fail.
can_be_picked(Item):-
	Item = safe(_, unlocked),
	format("You can't pick it...but you can grab it!...~s", ["\n"]),
	fail.
	

/* ===================================  Actions  ===================================== */
/* inspecting a place */
look :-
	write("Looking around...:"), nl,
	i_am_at(Here),
	there_is_something(Here), !, /* stop checking if there is nothing around */
	at(Here, Stuff),
	contains(Stuff, Content),
	format("1 x ~w~s", [Content, "\n"]).
there_is_something(Place) :-
	at(Place, _); 
	write("nothing in the area"), fail.
/* picking individual items */
pick(Item):-
	Item == safe,
	can_be_picked(safe(_,_)), !,
	fail.	
pick(Item):-
	Item \= safe,
	i_am_at(Place),
	item_is_actually_there(Place, Container, Item),
	can_be_picked(Container),
	contains(Container, Item),
	can_pick,
	assertz(holding(Container)),
	format("Picked: ~w~s", [Item, "\n"]),
	retract(at(Place, Container)), !.
/* picking everything */
pick:-
	i_am_at(Place),
	item_is_near_me(Place, Container), !, /* stop backtracking if the item is not there!!! */
	can_be_picked(Container), !, /* stop backtracking if the item is cannot be picked up */
	contains(Container, Item),
	can_pick,
	assertz(holding(Container)),
	format("Picked: ~w~s", [Item, "\n"]),
	retract(at(Place, Container)),
	pick.
/* helper */	
item_is_near_me(Place, Item):-
	at(Place, Item);
	format("nothing else to pick here...~s", ["\n"]),
	fail.
/* helper */	
item_is_actually_there(Place, Item, Content):-
	at(Place, Item);
	format("~w? ...are you dreaming??!", [Content]),
	fail.
/* dropping items */	
drop(Item):-
	i_am_at(Place),
	contains(Container, Item),
	holding(Container),
	retract(holding(Container)),
	assertz(at(Place, Container)), !.
/* dropping everything */
drop:-
	i_am_at(Place),
	holding(Container),
	contains(Container, Item),
	retract(holding(Container)),
	assertz(at(Place, Container)),
	format("Dropped: ~w~s", [Item, "\n"]),
	drop.
/* TODO: listing items held */
can_pick:-
	count_item_in_pockets(Count), 
	still_space_in_pockets(Count), !,
	not(max_reached(Count)),
	Count < 3.
/* less than 3 items */
count_item_in_pockets(Count):-	
	aggregate_all(count, holding(_), Count).
/* allow less than 2 items and stop */
still_space_in_pockets(Count):- Count =< 3.
max_reached(Count):-
	Count == 3,
	write("Your pockets are full! Drop something or eat it!!"),
	fail, !.
/* nothing held */	
empty_pockets:-
	aggregate_all(count, holding(_), Count),
	Count == 0.	
holding(nothing):- fail.

/* interactions with items -- food */
eat(Item):-
	contains(Container, Item),
	holding(Container),
	retract(holding(Container)), !,
	edible(Container), !.
/* is the item edible */
edible(Item):-
	contains(Item, Content),
	Item = food(Content, Status),
	does_damage(Content, Status).	
/* calculate damage or bonus */
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

/* listing all items held */	
pockets:-
	i_hold_anything, !, /* stop checking if I have nothing */
	write("checking pockets..."), nl,
	holding(Container),
	contains(Container, Item),
	format("1 x ~w~s", [Item, "\n"]).
i_hold_anything:-
	holding(_);
	write("You have nothing, mate...keep looking."), fail.

/* interactions with items -- safe. TODO: prevent safe from being picked */
unlock:-
	i_am_at(Place),
	at(Place, Item),
	Item = safe(Content, locked),
	Precious = Content,
	holding(object(key_to_safe, _)), /*you hold the key container...*/
	%assertz(at(Place, Precious, Precious)),
	retract(at(Place, Item)),
	assert(at(Place, safe(Precious, unlocked))), /*add (empty)*/
	format("You have unlocked the safe!! Grab the ~w inside it!!~s", [Content,"\n"]), !.
/* picking up an object from a safe */	
grab:-
	i_am_at(Place),
	at(Place, safe(Content, unlocked)),
	can_pick,
	pick_from_safe(Content, Place) , !.
grab:-
	i_am_at(Place),
	at(Place, safe(_, locked)),
	write("You can grab anything until you unlock the safe"), nl, fail.
/* helper */	
pick_from_safe(Item, Place):-
	can_pick, /* make predicate private and remove this...*/
	Stuff = object(Item, Item),
	assertz(holding(Stuff)),
	retract(at(Place, safe(Item, unlocked))),
	assertz(at(Place, safe(empty, unlocked))),
	format("Picked: ~w~s", [Item, "\n"]), !.
	

/* enemy types */
/* enemys' locations */
/* interaction with enemies */


