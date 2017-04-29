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


