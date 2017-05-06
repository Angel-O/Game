/*
 This imported file all Things (aka objects or items, anything the user can interact with, 
 except for enemies) in the game and a predicate to extract information reltive to
 a particular Thing. Things are composite objects that can have very different properties 
 (or functionalities): its definition together with the predicate allows to 
 use a unique way to interact with any object in the game.
*/


/* all items in the game */
all_items(Items):-
	Items = [safe(lens, locked), food(banana, healthy), food(banana, healthy),
			food(banana, healthy), food(banana, healthy), food(apple, rotten),
			object(key, door), object(specs, unpaired),
			food(apple, healthy), safe(lens, locked), food(banana, rotten),
			food(banana, healthy), food(banana, healthy), food(apple, infected),
			food(banana, rotten), food(banana, healthy), liquid(elisir, _),
			food(banana, healthy), food(banana, healthy), food(apple, infected),
			food(banana, infected), food(banana, healthy), food(banana, rotten),
			liquid(elisir, _), liquid(elisir, _), object(lens, _), 
			object(specs, unpaired), food(banana, healthy), food(banana, infected), 
			food(apple, infected), food(banana, rotten), liquid(elisir, _), 
			food(banana, rotten), object(shield, 10), object(shield, 6), 
			object(shield, 7), object(key, safe), safe(lens, locked), liquid(elisir, _), 
			liquid(elisir, _)].
			
			
/* =============================== OBJECT DEFINITIONS ================================= */

/* defining food and drinks as containers */
contains(Item, Content) :- 
	Item = food(Content, _), !.
contains(Item, Content) :- 
	Item = liquid(Content, _), !.
/* defining a container object made of specs and lens */
contains(object(specs, lens), Content) :-
	name(" (paired)", Suffix),
	name(specs, Prefix),
	append(Prefix, Suffix, ContentToList),
	name(Content, ContentToList), !.
/* defining a container object made of unpaired specs */
contains(object(specs, _), Content) :-
	name(" (unpaired)", Suffix),
	name(specs, Prefix),
	append(Prefix, Suffix, ContentToList),
	name(Content, ContentToList), !.
/* defining a container object made of key and what the key can unlock */
contains(Item, Content) :-
	Item = object(key, To_what),
	name(To_what, Prefix),
	name("_", Middle),
	name(key, Suffix),
	append(Prefix, Middle, Left_and_middle),
	append(Left_and_middle, Suffix, ContentToList),
	name(Content, ContentToList), !.	
/* defining a locked safe container */
contains(safe(_, locked), Content) :-
	name(" (locked)", Suffix),
	name("safe", Prefix),
	append(Prefix, Suffix, ContentToList),
	name(Content, ContentToList), !.
/* defining an unlocked and empty safe container */
contains(safe(empty, unlocked), Content) :-
	name(" (empty)", Suffix),
	name("safe", Prefix),
	append(Prefix, Suffix, ContentToList),
	name(Content, ContentToList), !.
/* defining an unlocked and non-empty safe container */
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
	name(Content, ContentToList), !.
/* defining any other type of object */
contains(Item, Content) :- 
	Item = object(Content, _),
	Content \= key, !.