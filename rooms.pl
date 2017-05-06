/*
 This imported file defines what locations are in the game and how they are connected.
 It also defines helper predicates to get a list of all the locations, 
 or a trimmed version of it, depending on the use case.
*/

/* all rooms in the maze */
locations(Locations):-
	Locations = [grey_area, room1, room2, room3, room4, room5, room6, room7, room8,
	room9, room10, room11, jungle].
	
locations_no_goal(Locations):-
	locations(All_locations), 
	reverse(All_locations, [_|Reversed]),
	reverse(Reversed, Locations). 

locations_no_start(Locations):-
	locations([_|Locations]).

locations_no_ends(Locations):-
	locations([_|No_start]),
	reverse(Rev_no_start, No_start),
	Rev_no_start = [_|Rev_no_ends],
	reverse(Locations, Rev_no_ends), !.

/* directions from one room to the other */
connected(grey_area, south, room1).
connected(grey_area, west, room1).
connected(grey_area, north, room1).
connected(grey_area, east, room1).

connected(room1, south, grey_area).
connected(room1, west, room3).
connected(room1, north, room2).
connected(room1, east, room4).

connected(room2, south, room1).
connected(room2, west, room6).
connected(room2, north, room9).
connected(room2, east, room4).

connected(room3, south, room1).
connected(room3, north, room6).
 
connected(room4, south, room1).
connected(room4, west, room2).
connected(room4, east, room11).

connected(room5, south, room9).
connected(room5, west, room7).
connected(room5, north, room8).

connected(room6, south, room3).
connected(room6, north, room7).
connected(room6, east, room2).

connected(room7, south, room6).
connected(room7, west, grey_area).
connected(room7, north, room10).
/* connected(room7, east, room5). */

connected(room8, south, room9).
/* connected(room8, west, room6). */
connected(room8, north, jungle).
connected(room8, east, room11).

connected(room11, north, room8).
connected(room11, south, room4).

/* connected(room9, south, room1). */
connected(room9, west, room5).
connected(room9, north, room10).
connected(room9, east, room8).

connected(room10, south, room9).
connected(room10, west, room7).