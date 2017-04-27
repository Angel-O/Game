/* <aMazeInMonkey>, by <Angelo Oparah>. */

%set_prolog_flag(answer_write_options,[max_depth(0)]).

/* dynamic predicates */
:- dynamic(i_am_at/2).
:- dynamic(at/2).
:- dynamic(at_area/3).
:- dynamic(named/1).
:- dynamic(locked/2).
:- dynamic(helpers:holding/1).
:- dynamic(life_points/1).
:- dynamic(moved/1).
:- dynamic(enemy_holds/2).

/* ========================== Importing files and modules ============================= */
/* this describes how rooms are conneted between them */
:- include('rooms.pl').
:- use_module(moving, [n/0, s/0, w/0, e/0, punch/0]).
:- use_module(helpers, [there_is_something/1, item_is_near_me/2, can_pick/0, count_item_in_pockets/1, 
 still_space_in_pockets/1, max_reached/1, edible/1, does_damage/2, i_hold_anything/0,
 pick_from_safe/2, holding/1, is_there_even_a_safe/0, item_is_actually_there/3, pair/0 ]).

/* ================================== Game reset ====================================== */
/* this section will reset the game ot the initital state when the game is reloaded */
:- retractall(at(_, _)), retractall(i_am_at(_)), 
	retractall(life_points(_)), retractall(holding(_)), 
	retractall(at_area(_, _, _)), retractall(moved(_)),
	retractall(enemy_holds(_, _)).


/* ================================== Game misc  ===================================== */
/* more to come... */
win :- i_am_at(jungle).
%game_over :-
%	life_points(X),
%	X < 0;
%	write("Game Over"), fail.

life_points(20).

moved(nowhere).
	
life :- 
	life_points(X),
	write(X).
	
where :-
	i_am_at(Place),
	moved(Area),
	format("Current location: ~w, ~w side", [Place, Area]).
	
me:-
	named(Name),
	life_points(Life),
	format("Name: ~w, Life: ~w\n", [Name, Life]).
	
alive(Alive):-
	life_points(Points),
	alive(Points, Alive).
alive(Points, Alive):-
	Points =< 0,
	format("~sGame Over, thanks for playing <aMazeInMonkey>.~sStats >>> ", ["\n", "\n\n"]),
	me, /* print stats */
	Alive = false, fail. 
alive(Points, Alive):-
	Points > 0,
	Alive = true.	
	
/* user interaction... */
select_name :-
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
at(room5, object(rotten_banana_detector, _)).
at(room6, object(key_to_safe, _)).
at(room9, safe(magic_wand, locked)).

/* debug */
at(grey_area, food(banana, infected)).
at(grey_area, food(apple, healthy)).
at(grey_area, object(key_to_safe, _)).
at(grey_area, safe(magic_glasses, locked)).
at(room1, safe(key_to_jungle, locked)).

at(grey_area, object(discovery_specs, unequipped)).
at(grey_area, object(lens, _)).

at_area(grey_area, north, enemy(evil_bat, b1, 2, aggressive)).
at_area(grey_area, north, enemy(gorilla, g1, 20, aggressive)).
at_area(grey_area, north, enemy(zoo_keeper, z1, 7, aggressive)).

enemy_holds(b1, object(lens, _)).
enemy_holds(b1, object(shield, _)).
enemy_holds(g1, object(lens, _)).
enemy_holds(z1, object(elisir, _)).


/* defining items as containers */
contains(Item, Content) :- 
	Item = food(Content, _).
contains(object(discovery_specs, lens), Content) :-
	name(" (equipped)", Suffix),
	name(discovery_specs, Prefix),
	append(Prefix, Suffix, ContentToList),
	name(Content, ContentToList), !.
contains(Item, Content) :- 
	Item = object(Content, _).
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

/* inspecting a place looking for object */
look:-
	alive(Alive),
	Alive = true, look(_).
look(_) :-
	write("Looking around...:"), nl,
	i_am_at(Here),
	there_is_something(Here), !, /* stop checking if there is nothing around */
	at(Here, Stuff),
	contains(Stuff, Content),
	format("1 x ~w~s", [Content, "\n"]), fail.
	
/* inspecting an area looking for enemies */
inspect:- 
	alive(Alive),
	Alive = true, inspect(_).
inspect(_):-
	write("Inspecting enemies...:"), nl,
	i_am_at(Here), moved(Area),
	holding(object(discovery_specs, lens)),
	at_area(Here, Area, enemy(Type, Id, _, _)),
	list_enemy_items(Id, Item),
	format("1 x ~w, (held by ~w)\n", [Item, Type]), fail.
list_enemy_items(Id, Item):-
	enemy_holds(Id, Stuff),
	contains(Stuff, Item).
/* picking individual items */
pick(Item):-
	alive(Alive),
	Alive = true, pick(Item, _).
pick(Item, _):-
	can_pick,
	i_am_at(Place),
	item_is_actually_there(Place, Container, Item),
	Container \= safe(_, _),
	can_be_picked(Container),
	contains(Container, Item),
	assertz(holding(Container)),
	format("Picked: ~w~s", [Item, "\n"]),
	retract(at(Place, Container)), !.
/* picking everything around */
pick_all:-
	alive(Alive),
	Alive = true, pick_all(_).
pick_all(_):-
	can_pick, !,
	i_am_at(Place),
	item_is_near_me(Place, Container),
	Container \= safe(_, _),
	can_be_picked(Container), !,
	assertz(holding(Container)),
	contains(Container, Item),
	format("Picked: ~w~s", [Item, "\n"]),
	retract(at(Place, Container)), pick_all(_), !.
/* dropping individual items */	
drop(Item):-
	alive(Alive),
	Alive = true, drop(Item, _).
drop(Item, _):-
	i_am_at(Place),
	contains(Container, Item),
	holding(Container),
	retract(holding(Container)),
	assertz(at(Place, Container)), !.
/* dropping everything */
drop_all:-
	alive(Alive),
	Alive = true, drop_all(_).
drop_all(_):-
	i_am_at(Place),
	holding(Container),
	contains(Container, Item),
	retract(holding(Container)),
	assertz(at(Place, Container)),
	format("Dropped: ~w~s", [Item, "\n"]),
	drop_all(_).
/* eating items */
eat(Item):-
	alive(Alive),
	Alive = true, eat(Item, _).
eat(Item, _):-
	contains(Container, Item),
	holding(Container),
	retract(holding(Container)), !,
	edible(Container), !.
/* listing all items held */
pockets:-
	alive(Alive),
	Alive = true, pockets(_).	
pockets(_):-
	i_hold_anything, !, /* stop checking if I have nothing */
	write("Checking pockets..."), nl,
	holding(Container),
	contains(Container, Item),
	format("1 x ~w~s", [Item, "\n"]), fail.
	
/* ====================== safes ======================= */
/* unlock safes */
unlock:- 
	alive(Alive),
	Alive = true, unlock(_).
unlock(_):-
	is_there_even_a_safe.
unlock(_):-
	i_am_at(Place),
	at(Place, safe(_, locked)),
	not(holding(object(key_to_safe, _))),
	write("You can't unlock a safe without a key"), nl, fail.
unlock(_):-
	i_am_at(Place),
	at(Place, Item),
	Item = safe(Content, locked),
	Precious = Content,
	holding(object(key_to_safe, _)), /*you hold the key container...*/
	retract(at(Place, Item)),
	assert(at(Place, safe(Precious, unlocked))),
	format("You have unlocked the safe!! Grab the ~w inside it!!~s", [Content,"\n"]), !.
/* grabbing an object from an open safe */
grab:- 
	alive(Alive),
	Alive = true, grab(_).
grab(_):-
	is_there_even_a_safe.
grab(_):-
	i_am_at(Place),
	at(Place, safe(_, locked)),
	write("You can't grab anything until you unlock the safe"), nl, fail.
grab(_):-
	i_am_at(Place),
	at(Place, safe(Content, unlocked)),
	can_pick,
	pick_from_safe(Content, Place) , !.


/* ============================= INTERACTION WITH ENEMIES ============================= */

/* enemy types */
/* enemys' locations */
/* interaction with enemies */

/* defined here to avoid ambiguity... */

enemy_drops(Place, Id):-
	enemy_holds(Id, Item),
	assertz(at(Place, Item)),
	retract(enemy_holds(Id, Item)),
	enemy_drops(Place, Id).
enemy_drops(_, _). /* the predicate will always be true */


steal(Type, Id):-
	holding(Item),
	contains(Item, Content),
	retract(holding(Item)),
	assertz(enemy_holds(Id, Item)),
	format("The ~w just robbed you!~sSay goodbye to your ~w", [Type, "\n", Content]), !.
steal(_,_).


