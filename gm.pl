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
at(grey_area, food(banana, infected)).
at(grey_area, food(apple, healthy)).

/* defining items as containers */
contains(Item, Content) :- 
	Item = food(Content, _);
	Item = safe(Content, _);
	Item = object(Content).

/* ===================================  Actions  ===================================== */
/* inspecting a place */
look :-
	write("Looking around...found:"), nl,
	inspect.	
inspect :-
	i_am_at(Here),
	at(Here, Stuff),
	contains(Stuff, Content),
	format("~w~s", [Content, "\n"]). /*helper not needed atm*/
/* picking items */
pick(Item):-
	i_am_at(Place),
	contains(Container, Item),
	at(Place, Container),
	can_pick,
	assertz(holding(Container)),
	retract(at(Place, Container)), !.
/* dropping items */	
drop(Item):-
	i_am_at(Place),
	contains(Container, Item),
	holding(Container),
	retract(holding(Container)),
	assertz(at(Place, Container)), !. /* TODO: dbl check */
/* TODO: listing items held */
%pockets:-.
can_pick:-
	still_space_in_pockets;
	write("Your pockets are full! Drop something or eat it!!"),
	fail.
/* less than 3 items */
still_space_in_pockets:-	
	aggregate_all(count, holding(_), Count),
	Count < 3.
/* nothing held*/	
empty_pockets:-
	aggregate_all(count, holding(_), Count),
	Count == 0.	
holding(nothing):- fail.

/* interactions with items -- food */
eat(Item):-
	contains(Container, Item),
	holding(Container),
	retract(holding(Container)), !,
	edible(Container).
/* is the item edible */
edible(Item):-
	contains(Item, Content),
	Item = food(Content, Status),
	does_damage(Content, Status).	
/* calculate damage or bonus */
does_damage(Content, infected):-
	life_points(Life),
	NewLife is Life - 3,
	assert(life_points(NewLife)),
	format("You ate ~s ~w. New life: ~w", [infected, Content, NewLife]), !.
does_damage(Content, rotten):- 
	life_points(Life),
	NewLife is Life - 2,
	assert(life_points(NewLife)),
	format("You ate ~s ~W. New life: ~w", [rotten, Content, NewLife]), !.
does_damage(_, healthy):- 
	life_points(Life),
	NewLife is Life + 1,
	assert(life_points(NewLife)),
	format("Yummy! New life: ~w", [Life]), !.
does_damage(_, _):-
	write("You can't eat that!"), fail. /*random damage...todo*/
	
	
/* interactions with items -- safe. TODO: prevent safe from being picked */
%unlock(Safe):-.
	
unlock(Item):-
	Item == safe.

/* enemy types */
/* enemys' locations */
/* interaction with enemies */


