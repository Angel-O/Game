/* <aMazeInMonkey>, by <Angelo Oparah>. */

/* certain stuff will move around... */
:- dynamic(at/2).
:- dynamic(named/2). 

/* this section will reset the game ot the initital state when the game is reloaded */
:- retractall(at(_, _)), retractall(i_am_at(_)), retractall(alive(_)).

/* start facts */
at(me, grey_area). /* you start the game in a neboulous place called grey_area... */
named(me, player).
first_name :-
	write("type your name (\"in double qoutes\"): "),
	read(X),
	retract(named(me, _)),
	assert(named(me, X)),
	format(`welcome to aMazeInMonkey, ~w`, [X]).

/* this section defines the start area */




