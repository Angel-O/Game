/* <aMazeInMonkey>, by <Angelo Oparah>. */

%set_prolog_flag(answer_write_options,[max_depth(0)]).

/* dynamic predicates */
:- dynamic(i_am_at/2).
:- dynamic(at/2).
:- dynamic(named/1). 
:- dynamic(locked/2).
:- dynamic(helpers:holding/1).
:- dynamic(life_points/1).

/* ========================== Importing files and modules ============================= */
/* this describes how rooms are conneted between them */
:- include('rooms.pl').
:- use_module(moving, [n/0, s/0, w/0, e/0, punch/0]).
:- use_module(helpers, [there_is_something/1, item_is_near_me/2, can_pick/0, count_item_in_pockets/1, 
 still_space_in_pockets/1, max_reached/1, edible/1, does_damage/2, i_hold_anything/0,
 pick_from_safe/2, holding/1, is_there_even_a_safe/0 ]).

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
	
where :-
	i_am_at(Place),
	format("Current location: ~w", [Place]).
	
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
at(grey_area, enemy(evil_bat, 2)).
at(grey_area, enemy(gorilla, 20)).


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
	

/* ============================= INTERACTION WITH OBJECTS ============================= */

/* inspecting a place */
look :-
	write("Looking around...:"), nl,
	i_am_at(Here),
	there_is_something(Here), !, /* stop checking if there is nothing around */
	at(Here, Stuff),
	contains(Stuff, Content),
	format("1 x ~w~s", [Content, "\n"]).
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
/* picking everything around */
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
/* dropping individual items */	
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
/* eating items */
eat(Item):-
	contains(Container, Item),
	holding(Container),
	retract(holding(Container)), !,
	edible(Container), !.
/* listing all items held */	
pockets:-
	i_hold_anything, !, /* stop checking if I have nothing */
	write("checking pockets..."), nl,
	holding(Container),
	contains(Container, Item),
	format("1 x ~w~s", [Item, "\n"]).
	
/* ====================== safes ======================= */
/* unlock safes */
unlock:- is_there_even_a_safe.
unlock:-
	i_am_at(Place),
	at(Place, safe(_, locked)),
	not(holding(object(key_to_safe, _))),
	write("You can't unlock a safe without a key"), nl, fail.
unlock:-
	i_am_at(Place),
	at(Place, Item),
	Item = safe(Content, locked),
	Precious = Content,
	holding(object(key_to_safe, _)), /*you hold the key container...*/
	retract(at(Place, Item)),
	assert(at(Place, safe(Precious, unlocked))),
	format("You have unlocked the safe!! Grab the ~w inside it!!~s", [Content,"\n"]), !.
/* grabbing an object from an open safe */
grab:- is_there_even_a_safe.
grab:-
	i_am_at(Place),
	at(Place, safe(_, locked)),
	write("You can't grab anything until you unlock the safe"), nl, fail.
grab:-
	i_am_at(Place),
	at(Place, safe(Content, unlocked)),
	can_pick,
	pick_from_safe(Content, Place) , !.


/* ============================= INTERACTION WITH ENEMIES ============================= */

/* enemy types */

enemy(zoo_keeper, 7).
enemy(evil_bat, 5).
enemy(gorilla, 12).


/* enemys' locations */
/* interaction with enemies */


	


