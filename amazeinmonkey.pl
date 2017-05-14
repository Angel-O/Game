/* <aMazeInMonkey>, by <Angelo Oparah>. */

/*
 This is the main file.
*/


/* will prevent the solutions from being truncated */
:-set_prolog_flag(answer_write_options,[max_depth(0)]).

/* dynamic predicates */
:- dynamic(i_am_at/1).
:- dynamic(at/2).
:- dynamic(at_area/3).
:- dynamic(named/1).
:- dynamic(locked/2).
:- dynamic(helpers:holding/1).
:- dynamic(life_points/1).
:- dynamic(moving:moved/1).
:- dynamic(enemy:enemy_holds/2).
:- dynamic(health/1).
:- dynamic(game_is_finished/0).

%TODO add describe predicate to combine lots of useful stuff in one go

/* ========================== Importing files and modules ============================= */

/* this describes how rooms are conneted between them */
:- include('rooms.pl').

/* contains all items in the game */
:- include('items.pl').

/* these allow the user to move around the maze */ 
:- use_module(moving, [n/0, s/0, w/0, e/0, moved/1]).

/* this allows the user to hit enemies */
:- use_module(fight, [punch/0]).

/* shortest path (it's used by the enemy module, but it's useful to have it here
to have access to it without loading the file each time) */
:- use_module(utils, [shortest/3, all_paths_dir/3, shortest_dir/3, longest_dir/3]).

/* places the enemy, adds item to them */
:- use_module(enemy, [place_enemy/0, equip_enemy/0, enemy_holds/2]).

/* debugging */
:- use_module(debugging, [place_items_debug/0]).

/* importing helpers predicte that should not be invoked directly by the user */
:- use_module(helpers, [there_is_something/1, item_is_near_me/2, can_pick/0, 
	count_item_in_pockets/1, edible/1, drinkable/1, does_damage/2, i_hold_anything/0, 
	list_enemy_items/2, pick_from_safe/2, holding/1, is_there_even_a_safe/0, 
	item_is_actually_there/3, alive/1, can_be_picked/1, item_is_inside_open_safe/2, 
	process_name/2, does_damage/2, game_is_still_on/0]).

/* defining pseudo constants */
max_life(35).
max_items_in_pockets(3).

/* ================================== Game misc ======================================= */

/* this section will reset the game ot the initital state */
init:- retractall(at(_, _)), retractall(i_am_at(_)), retractall(at_area(_, _, _)),  
	retractall(life_points(_)), retractall(holding(_)), retractall(named(_)),  
	retractall(moved(_)), retractall(locked(_, _)), retractall(enemy_holds(_, _)),
	retractall(game_is_finished), retractall(health(_)), initialize.

/* setting up the initial conditions */	
initialize:- assert(i_am_at(grey_area)), 
			 assert(moving:moved(nowhere)),
			 max_life(Max),
			 assert(life_points(Max)), 
			 assert(health(healthy)),
			 lock_doors,
			 equip_enemy,
			 place_enemy,
			 place_items,
			 %place_items_debug, /* disabled */
			 select_name.

/* reloads all files and restart the game */
reset :- [gm], [enemy], [moving], [fight], [helpers], [utils], [debugging] , init.

/* start the game */
start :- init.

/* sets an invalid value for life points then tries moving north... */
lose :- game_is_still_on, retractall(life_points(_)), assert(life_points(-1)), n.

/* abandoning the game */
quit :- nl, write("See you soon!"), nl, nl, halt.

/* selecting the placyer's name */	
select_name :-
	game_is_still_on, select_name(_).
select_name(_) :-
	write("Type your name (lower-case, please): "),
	read(Value),
	process_name(Value, Name),
	retractall(named(_)),
	assert(named(Name)),
	life_points(X),
	format(`Hi ~w! Available life points: ~w.`, [Name, X]).
			 
/* ============================ Player queries predicates ============================= */

/* print name and life points */
me :-
	game_is_still_on, me(_), !.
me(_) :- 
	life_points(Life),
	named(Name),
	format("Name: ~w, Life: ~w\n", [Name, Life]), !.
		
/* info on current location and area */	
where :-
	game_is_still_on, where(_), !.
where(_) :-
	i_am_at(Place),
	room_name(Place, Place_name),
	moved(Area),
	Area == just_arrived,
	format("Current location: ~w, ~w", [Place_name, Area]), !.
where(_) :-
	i_am_at(Place),
	room_name(Place, Place_name),
	moved(Area),
	Area == nowhere,
	format("Current location: ~w, ~w...", [Place_name, Area]), !.
where(_) :-
	i_am_at(Place),
	room_name(Place, Place_name),
	moved(Area),
	Area \= just_arrived,
	format("Current location: ~w, ~w side", [Place_name, Area]), !.

/* listing available directions and destinations */		
to :- 
	game_is_still_on, 
	write("Available directions: "), nl, nl, to(_);
	life_points(Life),
	Life > 0,
	i_am_at(Place), 
	connected(Place, _, _),
	not(game_is_finished), !.	
to(_):-	
	i_am_at(Place),
	connected(Place, Area, _),
	locked(Place, Area),
	format("~w ==> ~w ~s", [Area, "???", "\n"]), fail.
to(_):-
	i_am_at(Place),
	connected(Place, Area, Destination),
	not(locked(Place, Area)),
	room_name(Destination, Room_name),
	format("~w ==> ~w ~s", [Area, Room_name, "\n"]), fail.

/* ============================= START FACTS - placing items ========================== */

/* placing items randomly */	
place_items:-
	/* freebies */	
	assertz(at(grey_area, food(banana, healthy))), 
	assertz(at(grey_area, food(banana, healthy))), 
	assertz(at(grey_area, food(apple, healthy))), 	
	assertz(at(room1, food(banana, rotten))), 
	assertz(at(room1, food(apple, healthy))), 
	/* all locations excluding goal */
	locations_no_goal(All_locations_no_goal), 
	random_permutation(All_locations_no_goal, Locations),	
	/* all items */
	all_items(All_items),
	random_permutation(All_items, Items),		
	place_them(Items, Locations, All_locations_no_goal), !.

/* safe check in case of too restrictive constraints */	
place_items.

/******** constraints *******/
place_them([], _, _). /* done */
place_them(Items, [], All_loc):- /* scrumble the original location list and try again */
	Items = [_|_],
	random_permutation(All_loc, Random_loc),
	place_them(Items, Random_loc, All_loc). 
place_them(Items, Locations, All_loc):-
	Items = [IH|_],
	Locations = [LH|LT],
	IH = object(key, safe), /* key to safe cannot be in room with safe */
	at(LH, safe(_, _)),
	place_them(Items, LT, All_loc).
place_them(Items, Locations, All_loc):-
	Items = [IH|_],
	Locations = [LH|LT],
	IH = safe(_, _), /* and vice-versa */
	at(LH, object(key, safe)),
	place_them(Items, LT, All_loc).
place_them(Items, Locations, All_loc):-
	Items = [IH|_],
	Locations = [LH|LT],
	IH = object(key, door), /* key to room cannot be in room with locked door */
	locked(LH, _),
	place_them(Items, LT, All_loc).
place_them(Items, Locations, All_loc):-
	Items = [IH|_],
	Locations = [LH|LT],
	IH = safe(_, _), /* no more than one safe per room */
	at(LH, safe(_, _)),
	place_them(Items, LT, All_loc).
place_them(Items, Locations, All_loc):-
	Items = [IH|_],
	Locations = [LH|LT],
	IH = object(shield, _), /* no more than one shield per room */
	at(LH, object(shield, _)),
	place_them(Items, LT, All_loc).
place_them(Items, Locations, All_loc):-
	Items = [IH|_],
	Locations = [LH|LT],
	IH = liquid(elisir, _), /* no more than one elisir per room */
	at(LH, liquid(elisir, _)),
	place_them(Items, LT, All_loc).
place_them(Items, Locations, All_loc):-
	Items = [IH|_],
	Locations = [LH|LT],
	IH = liquid(elisir, _), /* no elisir where infected food is */
	at(LH, food(_, infected)),
	place_them(Items, LT, All_loc).
place_them(Items, Locations, All_loc):-
	Items = [IH|_],
	Locations = [LH|LT],
	IH = food(_, infected), /* and vice-versa */
	at(LH, liquid(elisir, _)),
	place_them(Items, LT, All_loc).
place_them(Items, Locations, All_loc):-
	Items = [IH|IT],
	IH \= object(key, door),
	Locations = [LH|LT],	
	assertz(at(LH, IH)), /* place the item */
	place_them(IT, LT, All_loc).
place_them(Items, Locations, All_loc):-
	Items = [IH|IT],
	IH = object(key, door),
	Locations = [LH|LT],
	all_paths_dir(grey_area, LH, Path),
	path_is_clear(Path), /* keys are accessible from start area: no locks on the way */
	length(Path, Count),
	Count > 2, /* path longer than 2...let's not give away the keys easily */	
	assertz(at(LH, IH)), 
	place_them(IT, LT, All_loc).
place_them(_, _).

/* helper predicate: path does not contain a locked location */
path_is_clear([]).	
path_is_clear([_|[]]).
path_is_clear(Path):-
	Path = [Location, Direction|T],
	not(locked(Location, Direction)),
	path_is_clear(T).		

/* ============================= START FACTS - locking doors ========================== */

/* locking at least one door in the shortest path from each location connected to room1 */
lock_doors:-
	place_locks_on_shortest_paths; /* disjuction as this will fail to backtrack */
	locked(_, _), /* at least one lock is placed... */
	fully_lock_goal. /* just in case */
lock_doors:-
	not(locked(_, _)), fully_lock_goal.

/* fully locking out the jungle */
fully_lock_goal:-
	connected(Place, Locked_dir, jungle), 
	not(locked(Place, Locked_dir)),
	assert(locked(Place, Locked_dir)).	
fully_lock_goal.

/* randomly locking doors on the 3 main shortest paths from room1 to the jungle */	
place_locks_on_shortest_paths:-
	connected(room1, _, Next_Room), /* room2, room3, room4 */
	Next_Room \= grey_area, /* not going backwards */
	shortest_dir(Next_Room, jungle, Path_dir), /* shortest path with directions */
	shortest(Next_Room, jungle, Path), /* shortest path without directions */
	reverse(Path_dir, [_|T_dir]), reverse(T_dir, Path_dir_without_jungle),
	reverse(Path, [_|T]), reverse(T, Path_without_jungle),
	not_locked_already(Location, Path_without_jungle),
	get_direction_to_jungle(Path_dir_without_jungle, Location, Direction),
	assert(locked(Location, Direction)), fail. /* backtracking to lock more doors */

/* get the direction towards the jungle (which is the adjacent member in the list) */
get_direction_to_jungle([Location, Direction|_], Location, Direction).
get_direction_to_jungle(Path, Location, Direction):-
	Path = [_, _|T],
	get_direction_to_jungle(T, Location, Direction).

/* finding a location not already locked and not equal to start area */	
not_locked_already(Location, Path):-
	get_random_Location(Location, Path, _),
	Location \= grey_area, /* no locks in the start location */
	not(locked(Location, _)). /* max allowed: 1 lock per location */

/* encapsulate random_member predicate to try again recursively until it succeeds */	
get_random_Location(Location, Path, _):-
	random_member(Location, Path);
	get_random_Location(Location, Path, _), !.
	
/* =================================== LOOKING AROUND ================================= */

/* inspecting a place looking for object */
look:-
	game_is_still_on, not(look(_)), !. /* negating as it will always fail to leverage 
										  backtracking and list all items at once. 
										  The command will always succeed no matter what, 
										  unless the pre-check (game_is_still_on) fails */
look(_) :-
	write("Looking around...:"), nl,
	i_am_at(Here),
	there_is_something(Here), !, /* stop checking if there is nothing around */
	at(Here, Stuff),
	contains(Stuff, Content),
	format("1 x ~w~s", [Content, "\n"]), fail.

/* =============================== INSPECTING ENEMIES ================================= */

/* entry point */
inspect:-
	game_is_still_on, try_inspect, !.	
try_inspect:-
	holding(object(specs, lens)), 
	write("Inspecting enemies..."), nl, nl, inspect(_), !.
try_inspect:-
 	not(holding(object(specs, lens))), 
 	write("You need to pair specs and lens to be able to inspect!"), fail, !.
	
/* inspecting an area looking for enemies and see wa=hat they hold */
inspect(_):-
	i_am_at(Here), moved(Area),
	holding(object(specs, lens)),
	at_area(Here, Area, enemy(Type, Id, _, _)),
	list_enemy_items(Id, Item),
	write("Item found:"), nl,
	format("1 x ~w, (held by: ~w)\n", [Item, Type]), fail, !.
inspect(_):-
 	i_am_at(Here), moved(Area),
 	holding(object(specs, lens)),
 	at_area(Here, Area, enemy(Type, Id, _, _)),
 	not(enemy_holds(Id, _)),
 	nl, write("This guy here has nothing..."), nl,
 	format("1 x ~w\n", [Type]), fail, !.
inspect(_):-
	i_am_at(Here), moved(Area),
	holding(object(specs, lens)),
	not(at_area(Here, Area, enemy(_, _, _, _))),
	write("Seems like there's no one here..."), fail, !.

/* ================================= PICKING objects ================================== */

/* picking individual items, whichever is first */
pick:-
	game_is_still_on, can_pick, try_pick, !.
	
try_pick:- i_am_at(Place), at(Place, _), pick(_), !.

try_pick:- 
	i_am_at(Place), not(at(Place, _)), 
	write("...there is nothing here to pick!!"), fail, !.

/* when a safe is on top of the list and the pick predicate is invoked with arity = 0,
having this clause allows to display the proper message */
try_pick:- i_am_at(Place), !, 
	at(Place, safe(_, _)), !,
	at(Place, Thing), can_be_picked(Thing),
	contains(Thing, Item),
	pick(Item, _); /* pick a pickable item first, then try with picking a safe if there
					is one */
	i_am_at(Place),
	at(Place, safe(_, _)),
	pick(safe, _), !.

/* picking individual items */
pick(Item):-
	game_is_still_on, can_pick, try_pick_item(Item), !.
try_pick_item(Item):-
	i_am_at(Place), at(Place, Thing), Thing \= safe(_, _),! , pick(Item, _), !.
try_pick_item(_):-
	i_am_at(Place), at(Place, safe(_, locked)),! , pick(safe, _), !.
try_pick_item(_):-
	i_am_at(Place), at(Place, safe(_, unlocked)),! , grab, !.
try_pick_item(_):-
	i_am_at(Place), not(at(Place, _)),
	write("...there is nothing here you can pick!"), fail, !.
pick(Item, _):-
	i_am_at(Place),
	not(item_is_inside_open_safe(Place, Item)),
	item_is_actually_there(Place, Container, Item), !,
	can_be_picked(Container), !,
	assertz(holding(Container)),
	format("Picked: ~w~s", [Item, "\n"]),
	retract(at(Place, Container)).
/* picking item from an open safe*/	
pick(Item, _):-
	i_am_at(Place),
	item_is_inside_open_safe(Place, Item),
	grab, !.
/* default */
pick(Item, _):-
	Item \= safe,
	i_am_at(Place),
	not(item_is_actually_there(Place, _, Item)),
	write("...And where the heck have you seen that?!"), nl, fail, !.
/* trying to pick up safes */
pick(safe, _):-
	i_am_at(Place),
	at(Place, safe(_, locked)), !,
	format("You can't pick up a safe...~s", ["\n"]), !, fail, !.
pick(safe, _):-
	i_am_at(Place),
	at(Place, safe(Item, unlocked)),
	Item \= empty,
	format("Safes are too heavy...try grabbing the ~w inside...~s", [Item, "\n"]),! ,fail.
pick(safe, _):-
	i_am_at(Place),
	at(Place, safe(empty, unlocked)), !,
	named(Name),
	write("You can't pick up a safe..."),
	format("and by the way this one is empty, can't you see that, ~w ?", [Name]), fail, !.
pick(safe, _):-
	i_am_at(Place),
	not(at(Place, safe(_, _))), !,
	write("You can't pick up a safe...and there isn't one here, anyway..."), fail, !.
	
/* picking one item and showing pockets content */	
pick_and_show(Item):-
	game_is_still_on, pick_and_show(Item, _), !.
pick_and_show(Item, _):- pick(Item), fail; nl, pockets, !.
	
/* picking everything around */
pick_all:-
	game_is_still_on, try_pick_all, !.
try_pick_all:-
	can_pick, !, /* checking here as this willl be called recursively */
	i_am_at(Place),
	item_is_near_me(Place, Container),
	can_be_picked(Container), !,
	assertz(holding(Container)),
	contains(Container, Item),
	format("Picked: ~w~s", [Item, "\n"]),
	retract(at(Place, Container)), !, try_pick_all, !.

/* picking everything and showing pockets content */
pick_all_and_show:-
	game_is_still_on, try_pick_all_and_show, !.	
try_pick_all_and_show:- try_pick_all, !; pockets, !.

	
/* ================================= DROPPING objects ================================= */

/* entry point: dropping individual items, whichever is first */
drop:-
	game_is_still_on, try_drop, !.
try_drop:- /* dropping only if in posses of anything */
	holding(_),! , drop(_).
try_drop:- /* print friendly message otherwise */
	write("You don't have anything on you at the moment..."), fail.
	
/* entry point: dropping a specific item */
drop(Item):-
	game_is_still_on, drop(Item, _), !.
/* 2 branches (using a placeholder) */	
drop(Item, _):-
	holding(_), !, drop_aux(Item).
drop(Item, _):-
	contains(Container, Item), !,
	not(holding(Container)),
	write("You can't drop what you don't have..."), fail.	
/* helpers */	
drop_aux(Item):-
	i_am_at(Place),
	holding(Container),
	contains(Container, Item),
	retract(holding(Container)),
	assertz(at(Place, Container)),
	format("Dropped: ~w~s", [Item, "\n"]),
	holding(_), nl, pockets, !. /* show the pocket content only if anything is left */
drop_aux(_):-
	nl, write("Your pockets are empty now."), nl, !.
	
/* dropping everything: entry point */
drop_all:-
	game_is_still_on, !, try_drop_all(_).
/* 2 secondary branches */	
try_drop_all(_):-
	holding(_), !, 
	not(drop_all_aux), /* negate the predicate as it will eventually fail */
	nl, write("Your pockets are empty now.\n"), nl, !.
try_drop_all(_):-
	write("You don't have anything on you at the moment..."), fail.
/* recursive helper */	
drop_all_aux:-
	i_am_at(Place),
	holding(Container), !,
	contains(Container, Item),
	retract(holding(Container)),
	assertz(at(Place, Container)),
	format("Dropped: ~w~s", [Item, "\n"]),
	not(holding(Container)),
	drop_all_aux.
	
/* ================================== EATING objects ================================== */

/* entry point 1: eating the first item currently held: Note: by-passing entry point 2
by adding a placeholder */
eat:-
	game_is_still_on, try_eat, !.
try_eat:-
	holding(Item), edible(Item), !,
	contains(Item, Content), eat(Content, _), !.
try_eat:-
	write("You have nothing to eat, go and get something!"), fail, !.

/* entry point 2: eating a specific item: checks if alive then delegates to the version
of the predicate that takes a placeholder */
eat(Item):-
	game_is_still_on, !, eat(Item, _), !.

/* eaing individual items */		
eat(Item, _):-
	contains(Container, Item),
	holding(Container),
	edible(Container),
	Container = food(Item, Status),
	does_damage(Item, Status),
	retract(holding(Container)), !.
eat(Item,  _):-
	contains(Container, Item),
	holding(Container),
	write("You can't eat that..."), !, fail, !.
eat(Item, _):-
	contains(Container, Item),
	not(holding(Container)), !,
	write("Do you have that in your pockets ??..."), fail, !.
	
/* =================================== DRINKING objects =============================== */

/* entry point 1: drinking the first item currently held, Note: by-passing entry point 2
by adding a placeholder */
drink:-
	game_is_still_on, try_drink, !.
try_drink:-
	holding(Item), drinkable(Item), !, 
	contains(Item, Content), drink(Content, _), !.
try_drink:-
	write("You have nothing to drink, go and get something!"), fail, !.
	
/* entry point 2: drinking a specific item: checks if alive then delegates to the version
of the predicate that takes a placeholder */		
drink(Item):-
	game_is_still_on, !, drink(Item, _), !.

/* drinking individual items */	
drink(Item, _):-	
	holding(Container), /*order matters...*/
	contains(Container, Item),	/*order matters...*/
	drinkable(Container),
	Container = liquid(Item, Status),
	does_damage(Item, Status),
	retract(holding(Container)), !.
drink(Item, _):-
	contains(Container, Item),
	holding(Container),
	write("You can't drink that..."), !, fail, !.
drink(Item, _):-
	contains(Container, Item),
	not(holding(Container)), !,
	write("Do you have that in your pockets ??..."), fail, !.

/* ============================= LISTING OUT HELD objects ============================= */

/* listing all items currently held */
pockets:-
	game_is_still_on, pockets(_); 
	count_item_in_pockets(Count),
	Count > 0, life_points(X), X > 0, /* succeed only if we have something in our 
										pockets. The additional life point check 
										is not necessary, but it prevents prolog 
										from reporting a success value when the game
										is over */
	not(game_is_finished).
		
pockets(_):-
	i_hold_anything, !, /* stop checking if I have nothing */
	write("Checking pockets..."), nl,
	holding(Container),
	contains(Container, Item),
	format("1 x ~w~s", [Item, "\n"]), fail. /* letting it fail to backtrack and list all
												items held at once */

/* ================================= PAIRING objects ================================== */
	
/* pairing specs and lens */
pair:-
	game_is_still_on, pair(_), !.	
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
	game_is_still_on, unlock(_), !.
unlock(_):-
	is_there_even_a_safe.
unlock(_):-
	i_am_at(Place),
	at(Place, safe(_, locked)),
	not(holding(object(key, safe))),
	write("You can't unlock a safe without a key"), nl, fail.
unlock(_):-
	i_am_at(Place),
	at(Place, Item),
	Item = safe(Content, locked),
	Precious = Content,
	holding(object(key, safe)), /* you hold the key container...*/
	retract(at(Place, Item)),
	assert(at(Place, safe(Precious, unlocked))),
	format("You have unlocked the safe!! Grab the ~w inside it!!~s", [Content,"\n"]), !.
unlock(_):-
	i_am_at(Place),
	at(Place, safe(_, unlocked)),
	holding(object(key, safe)),
	write("The safe is already open..."), nl, fail.

/* ====================== GRABBING objects from OPEN SAFES ============================ */
	
/* grabbing an object from an open safe */
grab:- 
	game_is_still_on, grab(_), !.
grab(_):-
	is_there_even_a_safe.
grab(_):-
	i_am_at(Place),
	at(Place, safe(_, locked)),
	write("You can't grab anything until you unlock the safe"), nl, fail.
grab(_):-
	i_am_at(Place),
	at(Place, safe(Content, unlocked)),! ,
	can_pick,
	pick_from_safe(Content, Place), !.
	
	
/* ================================ UNLOCKING DOORS =================================== */

/* unlocking doors: entry point */
unlock_door:- 
	game_is_still_on, try_unlock_door, !.
/* 2 branches */
try_unlock_door:- 
	holding(object(key, door)), unlock_door(_), !.
try_unlock_door:-
	not(holding(object(key, door))),	
	write("You need a key to to unlock doors."), !, fail.
unlock_door(_):-	
	i_am_at(Place),
	moved(Area),
	locked(Place, Area),
	retract(locked(Place, Area)),
	format("Nice! You unlocked the door! Keep moving ~w !", [Area]), nl, !.
unlock_door(_):-	
	write("The way is clear...don't procrastinate!!"), nl, !, fail.


/* ================================= INSTRUCTIONS ===================================== */

/* list of available commands */	

instructions:-	
	write("Commands available to you:"), nl, nl,
	format("00. instructions. [~s]", ["show this menu"]), nl,
	format("01. start. [~s]", ["start the game"]), nl,
	format("02. reset. [~s]", ["restart the game, reloading all the files, useful when debugging"]), nl,
	format("03. n. [~s]", ["move north"]), nl,
	format("04. s. [~s]", ["move south"]), nl,
	format("05. w. [~s]", ["move west"]), nl,
	format("06. e. [~s]", ["move east"]), nl,
	format("07. look. [~s]", ["look around the location you are in and list all objects"]), nl,
	format("08. inspect. [~s]", ["allows to view who holds what: only available after pairing specs and lens"]), nl,
	format("09. pick. [~s]", ["try to pick the first item found"]), nl,
	format("10. pick(item). [~s]", ["pick the item specified, if there is enough space in your pockets"]), nl,
	format("11. pick_all. [~s]", ["pick all the items around"]), nl,
	format("12. pockets. [~s]", ["show what is currently held"]), nl,
	format("13. eat. [~s]", ["eat the first item found in the pockets, if edible"]), nl,
	format("14. eat(item). [~s]", ["eat the specified item, if edible"]), nl,
	format("15. drink. [~s]", ["drink the first item found in the pockets, if drinkable"]), nl,
	format("16. drink(item). [~s]", ["drink the specified item, if drinkable"]), nl,
	format("17. pick_and_show(item). [~s]", ["pick an item and show the pockets content"]), nl,
	format("18. pick_all_and_show. [~s]", ["pick all the items around and show the pockets content"]), nl,
	format("19. drop. [~s]", ["drops the first item in the pockets, if any are held"]), nl,
	format("20. drop(item). [~s]", ["drops the specified item, if currently held"]), nl,
	format("21. drop_all. [~s]", ["drop all the items currently held"]), nl,
	format("22. pair. [~s]", ["pair specs and lens to be able to use the inspect command"]), nl,
	format("23. punch. [~s]", ["hit the enemy!"]), nl,
	format("24. unlock. [~s]", ["unlock an open safe"]), nl,
	format("25. grab. [~s]", ["grab an item from an open safe. You can also use the pick command if you wish"]), nl,
	format("26. unlock_door. [~s]", ["unlock a door allowing to proceed in that direction"]), nl,
	format("27. me. [~s]", ["print info about the player, name and life points"]), nl,
	format("28. where. [~s]", ["show current location and area"]), nl,
	format("29. select_name. [~s]", ["pick a name"]), nl,
	format("30. to. [~s]", ["show available directions and destinations from the current location"]), nl,
	format("31. lose. [~s]", ["ends the game"]), nl,
	format("32. quit. [~s]", ["abandon the game (equivalent of Prolog halt command)"]), nl, nl.

/* ================================ LAUNCH THE GAME =================================== */

/* provide the instructions at game start */

:- write("Welcome to aMazeInMonkey!! Use the start command to begin the adventure!"), nl,
   write("Once started, use any of the commands listed below (followed by a dot), hit enter and see what happens"),
   write(" (all lower-case please)!"), nl, nl, instructions.	