/* <aMazeInMonkey>, by <Angelo Oparah>. */

%set_prolog_flag(answer_write_options,[max_depth(0)]).

/* dynamic predicates */
:- dynamic(i_am_at/1).
:- dynamic(at/2).
:- dynamic(at_area/3).
:- dynamic(named/1).
:- dynamic(locked/2).
:- dynamic(helpers:holding/1).
:- dynamic(life_points/1).
:- dynamic(moving:moved/1).
:- dynamic(enemy_holds/2).
:- dynamic(health/1).


/* ========================== Importing files and modules ============================= */

/* this describes how rooms are conneted between them */
:- include('rooms.pl').

/* these allow the user to move around the maze */ 
:- use_module(moving, [n/0, s/0, w/0, e/0, moved/1]).

/* this allows the user to hit enemies */
:- use_module(fight, [punch/0]).

/* ...... */
:- use_module(utils, [shortest/3]).

/* importing helpers predicte that should not be invoked directly by the user */
:- use_module(helpers, [there_is_something/1, item_is_near_me/2, can_pick/0, 
	count_item_in_pockets/1, still_space_in_pockets/1, max_reached/1, edible/1, 
	does_damage/2, i_hold_anything/0, list_enemy_items/2, pick_from_safe/2, holding/1,
	is_there_even_a_safe/0, item_is_actually_there/3, alive/1, can_be_picked/1]).

/* ================================== Game reset ====================================== */

/* this section will reset the game ot the initital state when the game is reloaded */
init:- retractall(at(_, _)), retractall(i_am_at(_)), retractall(at_area(_, _, _)),  
	retractall(life_points(_)), retractall(holding(_)), retractall(named(_)),  
	retractall(moved(_)), retractall(locked(_)), retractall(enemy_holds(_, _)).

/* =================================== Game misc  ===================================== */

win :- i_am_at(jungle).		
reset :- [gm], [moving], [fight], [helpers], [utils], init.

/* ================================ Player predicates  ================================ */
	
me:-
	named(Name),
	life_points(Life),
	format("Name: ~w, Life: ~w\n", [Name, Life]).
life :- 
	life_points(X), 
	write(X).

where :-
	i_am_at(Place),
	moved(Area),
	Area == just_arrived,
	format("Current location: ~w, ~w", [Place, Area]), !.
where :-
	i_am_at(Place),
	moved(Area),
	Area == nowhere,
	format("Current location: ~w, ~w...", [Place, Area]), !.
where :-
	i_am_at(Place),
	moved(Area),
	Area \= just_arrived,
	format("Current location: ~w, ~w side", [Place, Area]), !.

select_name :-
	write("Type your name (lower-case, please): "),
	read(Value),
	process_name(Value, Name),
	retractall(named(_)),
	assert(named(Name)),
	format(`Hi ~w! Welcome to aMazeInMonkey.`, [Name]).
	
process_name(Value, Name):-
	Value = anything_really, /* checking if the value is bound the actual 
								value is not important */
	Name = "monkey lover", !.
process_name(Value, Name):-	Name = Value.

/* ================================== START FACTS ===================================== */

:- init, select_name.

i_am_at(grey_area). moving:moved(nowhere). life_points(50). health(healthy).

/* locations */
locked(room8, north). locked(room1, north). /* to be removed.... */

/* items' location and status-description */	
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
at(grey_area, food(banana, rotten)).
at(grey_area, drink(elisir, _)).
at(grey_area, food(banana, infected)).
at(grey_area, food(apple, healthy)).
at(grey_area, object(key_to_safe, _)).
at(grey_area, safe(magic_glasses, locked)).
at(room1, safe(key_to_jungle, locked)).
at(grey_area, object(specs, unequipped)).
at(grey_area, object(lens, _)).
at_area(grey_area, north, enemy(evil_bat, b1, 2, aggressive)).
at_area(grey_area, north, enemy(gorilla, g1, 20, aggressive)).
at_area(grey_area, north, enemy(zoo_keeper, z1, 7, aggressive)).


enemy(gorilla, g1, 26, aggressive).
enemy(gorilla, g2, 23, aggressive).
enemy(gorilla, g3, 26, aggressive).
enemy(gorilla, g4, 22, aggressive).

enemy(evil_bat, b1, 8, aggressive).
enemy(evil_bat, b2, 9, aggressive).
enemy(evil_bat, b3, 7, aggressive).
enemy(evil_bat, b4, 12, aggressive).

enemy(zoo_keeper, z1, 14, aggressive).
enemy(zoo_keeper, z2, 22, aggressive).
enemy(zoo_keeper, z3, 16, aggressive).
enemy(zoo_keeper, z4, 15, aggressive).


place_enemies(Enemies):-
	Enemies = [H|T].
	shortest(grey_area, jungle, Path), /* or before the jungle... */
	length(Path, Count),
	Path = [F,S|R], /* first, second, rest */
	H = enemy(Type, Id, Life, _).

enemy_holds(b1, object(lens, _)).
enemy_holds(b1, object(shield, _)).
enemy_holds(g1, object(lens, _)).
enemy_holds(z1, drink(elisir, _)).

/* defining items as containers */
contains(Item, Content) :- 
	Item = food(Content, _).
contains(Item, Content) :- 
	Item = drink(Content, _).
contains(object(specs, lens), Content) :-
	name(" (equipped)", Suffix),
	name(specs, Prefix),
	append(Prefix, Suffix, ContentToList),
	name(Content, ContentToList), !.
contains(Item, Content) :- 
	Item = object(Content, _).
	
/* describing safe in terms of their content and locked(unlocked) status */
contains(safe(_, locked), Content) :-
	name(" (locked)", Suffix),
	name("safe", Prefix),
	append(Prefix, Suffix, ContentToList),
	name(Content, ContentToList), !.
contains(safe(empty, unlocked), Content) :-
	name(" (empty)", Suffix),
	name("safe", Prefix),
	append(Prefix, Suffix, ContentToList),
	name(Content, ContentToList), !.
contains(Item, Content) :-
	Item = safe(X, unlocked),
	X \= empty,
	name("safe", Prefix),
	name(" (unlocked, containing: 1 x ", Left_part),
	name(X, Middle_part),
	append(Left_part, Middle_part, Left_and_middle),
	name(")", Right_part),
	append(Left_and_middle, Right_part, Item_description),
	append(Prefix, Item_description, ContentToList),
	name(Content, ContentToList).
	
/* =================================== LOOKING AROUND ================================= */

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

/* =============================== INSPECTING ENEMIES ================================= */

/* inspecting an area looking for enemies TO BE FIXED... too many branches */
inspect:- 
	alive(Alive),
	Alive = true, inspect(_).
inspect:-
	moved(Area),
	connected(_, Area, _),! ,
	not(holding(object(specs, lens))),
	write("You need to pair specs and lens to be able to see more!"), fail, !.
inspect(_):-
	i_am_at(Here), moved(Area),
	holding(object(specs, lens)),
	write("Inspecting enemies...:"), nl,
	at_area(Here, Area, enemy(Type, Id, _, _)),
	list_enemy_items(Id, Item),
	format("1 x ~w, (held by ~w)\n", [Item, Type]), fail.
inspect(_):-
	i_am_at(Here), moved(Area),
	holding(object(specs, lens)),
	not(at_area(Here, Area, enemy(_, _, _, _))),
	write("Seems like there's no one here..."), fail, !.

/* ================================= PICKING objects ================================== */

/* picking individual items */
pick(Item):-
	alive(Alive),
	Alive = true, pick(Item, _).
pick(Item, _):-
	Item \= safe,
	can_pick,
	i_am_at(Place),
	item_is_actually_there(Place, Container, Item), !,
	can_be_picked(Container), !,
	contains(Container, Item), /* not needed... */
	assertz(holding(Container)),
	format("Picked: ~w~s", [Item, "\n"]),
	retract(at(Place, Container)), !.
/* trying to pick up safes */
pick(safe, _):-
	i_am_at(Place),
	at(Place, safe(_, locked)), !,
	format("You can't pick up a safe...~s", ["\n"]), fail, !.
pick(safe, _):-
	i_am_at(Place),
	at(Place, safe(Item, unlocked)), !,
	format("Safes are to heavy...Hint: try grabbing the ~w...~s", [Item, "\n"]), fail, !.

/* picking one item and showing pockets content */	
pick_and_show(Item):-
	alive(Alive),
	Alive = true, pick_and_show(Item, _).
pick_and_show(Item, _):- pick(Item, _), !, nl, pockets, !.
	
/* picking everything around */
pick_all:-
	alive(Alive),
	Alive = true, pick_all(_).
pick_all(_):-
	can_pick, !,
	i_am_at(Place),
	item_is_near_me(Place, Container),
	can_be_picked(Container), !,
	assertz(holding(Container)),
	contains(Container, Item),
	format("Picked: ~w~s", [Item, "\n"]),
	retract(at(Place, Container)), pick_all(_), !.

/* picking everything and showing pockets content */
pick_all_and_show:-
	alive(Alive),
	Alive = true, pick_all_and_show(_).	
pick_all_and_show(_):- pick_all(_), !; nl, pockets, !.
	
/* ================================= DROPPING objects ================================= */

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
	
/* ================================ EATING objects ==================================== */

/* eating items TODO allow only food to be eaten */
eat(Item):-
	alive(Alive),
	Alive = true, eat(Item, _).
eat(Item, _):-
	contains(Container, Item),
	holding(Container), !,
	retract(holding(Container)), !,
	edible(Container), !.
eat(Item, _):-
	contains(_, Item), !,
	format("You have no ~w, try and find it first!", [Item]), fail, !.

/* alias for the elisir */	
drink(elisir):- !, eat(elisir), !.
drink(_):- write("You can't drink that..."), fail.

/* ============================= LISTING OUT HELD objects ============================= */

/* listing all items currently held */
pockets:-
	alive(Alive),
	Alive = true, pockets(_).	
pockets(_):-
	i_hold_anything, !, /* stop checking if I have nothing */
	write("Checking pockets..."), nl,
	holding(Container),
	contains(Container, Item),
	format("1 x ~w~s", [Item, "\n"]), fail.

/* ================================= PAIRING objects ================================== */
	
/* pairing specs and lens */
pair:-
	alive(Alive),
	Alive = true, pair(_).	
pair(_):-
	holding(object(specs, _)),
	holding(object(lens, _)),
	retract(holding(object(specs, _))),
	retract(holding(object(lens, _))),
	assertz(holding(object(specs, lens))),
	write("Well done! Now you can see enemies and what they hold!"), !.
pair(_):-
	holding(object(specs, lens)),
	write("Discovery specs and lens are already paired"), nl,
	write("Use your equipped specs to see even more"), fail, !.
pair(_):-
	not(holding(object(specs, lens))),
	write("You need both specs and lens...\n"), fail, !.

	
/* ================================ UNLOCKING SAFES =================================== */

/* unlocking safes */
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
	holding(object(key_to_safe, _)), /* you hold the key container...*/
	retract(at(Place, Item)),
	assert(at(Place, safe(Precious, unlocked))),
	format("You have unlocked the safe!! Grab the ~w inside it!!~s", [Content,"\n"]), !.

/* ====================== GRABBING objects from OPEN SAFES ============================ */
	
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




