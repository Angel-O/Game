/* ================================================================================== */
/* this section describes which locations are connected between them and in what 
direction */

/*fix r4 r8...east..*/

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
connected(room4, east, room8).

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
connected(room8, east, room4).

/* connected(room9, south, room1). */
connected(room9, west, room5).
connected(room9, north, room10).
connected(room9, east, room8).

connected(room10, south, room9).
connected(room10, west, room7).
connected(room10, east, key_room).

connected(jungle, north, sroom).