likes(wallace, cheese).
likes(grommit, cheese).
likes(wendolene, sheep).

% order is important: if the last goal is at the start it won’t work
friends(X, Y) :- likes(X, Z), likes(Y, Z), \+(X = Y).

parent(kyle, bob).
parent(patricia, bob).

parent(dan, lucy).
parent(karl, lucy).

parent(bob, john).
parent(sarah, john).

parent(will, lucy).
parent(mary, lucy).

parent(will, frank).
parent(mary, frank).

% note the backticks to enclose string literals
grandparent(X, Y) :- 
	parent(Z, Y),
	parent(X, Z), 
	format(`~w ~s ~w’s grandpa ~n`, [X, `is`, Y]). 
	
%need both to work...not really recursion...	
related(X, Y) :-
	parent(X, Y).
		
% same as grandparent basically...	NO!!
related(X, Y) :-
	parent(X, Z),
	related(Z, Y).
	

sum_all(0, []).
sum_all(Sum, [Head|Tail]) :-
	sum_all(TailSum, Tail),
	Sum is Head + TailSum.
	
find_max(Value, [Value]).
find_max(Max, [Head|Tail]) :-
	find_max(TailMax, Tail),
	Max is max(TailMax, Head).
	

make_listw([0], 0).
make_listw([0, 1], 1).
make_listw([0, 1, 2], 2).
make_listw(List, Value) :-
	Y is Value - 1, %1
	Y >= 0,	% true
	%append([Y],[Value], [Y|List]), %[1,2]
	make_listw([Y|List], Y).

mli([0], 0).
mli(List, Value):-
	[Head|Tail] = List,
	%append(List, [Value], Z),
	%Y is Value - 1,
	%mli(Z, Y).
	Tail.
	
ml([Head|Tail], X) :-
	Tail = [H|T],
	X = H.

gggg(X, 0) :- X = [0].
gggg(List, Value) :-
	Value > 0,
	App = [List|Value],		
	Next is Value - 1,
	gggg(App, Next).
	
mm(X, 0) :- X = [0].
mm(List, Value) :-
	append(List, [Value], NewList),
	List = [H|[]],
	H = 0,
	Next is H + 1,
	Next < Value,
	mm(NewList, Value).

%% given an integer it returns an ordered list containing
%% all the precendent elements up to the integer given
make_list(X, 0) :- X = [0].
make_list(List, Value) :-
	Next is Value - 1, Next >= 0,
	make_list(NextList, Next),
	append(NextList, [Value], List).

%% multiply all elemnts in the given list	
mult_list([H|[]], H).	
mult_list([H|T], R) :-
	mult_list(T, P),
	R is H * P. 

%% calculate the factorial of the given value
%% using a list internally	
factorial(0, 0).
factorial(Fact, Value):-
	make_list([_|Tail], Value),
	mult_list(Tail, Fact).

%% calculate the factorial of the given value
%% without using a list internally	
factorial_no_list(1, 1).	
factorial_no_list(Fact, Value) :-
	Next is Value - 1, Value > 0,
	factorial_no_list(NextFact, Next), 
	Fact is Value * NextFact.
	


