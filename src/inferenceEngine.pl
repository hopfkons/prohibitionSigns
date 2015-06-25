
%	beschreiben, welchen Eigenschaften ein Objekt mitbringen muss,
%	um fuer ein Verbotsschild zu taugen.

% annoy <=> social_interaction



affordances(no_smoking, [area, social_interaction]).
affordances(no_smoking, [indoors]).
affordances(no_smoking, [ignite]).

affordances(no_bike_leaning, [enclosure]).
affordances(no_fire, [area, walk, outdoors,ignit]).
affordances(no_food, [food_handling,walk]).
affordances(no_food, [stain,walk]).

affordances(no_alk, [area, social_interaction]).

affordances(no_camping, [area,outdoors]).
affordances(no_littering, [area,outdoors]).

affordances(no_access, [area, danger]).
affordances(no_access, [indoors]).

affordances(no_mobile, [area, walk, ignite]).
affordances(no_mobile, [area, walk, social_interaction]).

affordances(no_alc, [area,social_interaction]).

affordances(dogs_on_leash, [area, outdoors, walk, hunt_prey]).
%affordances(dogs_on_leash, [indoors]).
affordances(no_dogs, [walk, food_handling]).  % area,
affordances(no_dogs, [walk, stain]).
affordances(no_riding, [area]).

affordances(no_driving, [area]).
affordances(no_skate, [area,social_interaction]).

affordances(no_blocking, [area, emergency_access]).

affordances(no_bike_leaning, [outdoors,area,walk]).

affordances(no_fishing, [water_area, outdoors]).
affordances(no_stepping_on_ice, [water_area]).

affordances(no_swimming, [water_area]).

affordances(no_entering, [area, walk]).


union([X|Y],Z,W) :- member(X,Z),  union(Y,Z,W).
union([X|Y],Z,[X|W]) :- \+ member(X,Z), union(Y,Z,W).
union([],Z,Z).

signAffordances([], []).
signAffordances([S|Ss], A) :-
	affordances(S, A1),
	signAffordances(Ss, A2),
	union(A1,A2,A).


%%	Bewertungsfunktion, wie gut eine affordance zu einem Objekt
%	passt


meetsAffordance(Id, outdoors, -2) :- has(Id,building,_).
meetsAffordance(Id, outdoors, 2) :- has(Id,landuse,grass).
meetsAffordance(Id, outdoors, 2) :- has(Id,leisure,park).

meetsAffordance(Id, food_handling, 2) :- has(Id,shop,Sell), member(Sell, [bakery, butcher, cheese, chocolate, coffee, confectionery, convenience, deli, dairy, farm, greengrocer, pasta, pastry, seafood, supermarket]).
meetsAffordance(Id, food_handling, 1) :- has(Id,shop,_).
meetsAffordance(Id, food_handling, 2) :- has(Id,amenity, A), member(A, [cafe,bar,biergarten,fast_food,food_cout,ice_cream,pub,restaurant]).

meetsAffordance(Id, stain, 2) :- has(Id, buildingxuse, retail).
meetsAffordance(Id, stain, 2) :- has(Id, leisure, playground).
meetsAffordance(Id, stain, 2) :- has(Id, leisure, _).
meetsAffordance(Id, stain, 2) :- has(Id, shop, _).

meetsAffordance(Id, walk, 2) :- has(Id,building,_).
meetsAffordance(Id, walk, 2) :- has(Id,leisure,_).
meetsAffordance(Id, walk, 2) :- has(Id,man_made, dyke).
meetsAffordance(Id, walk, 2) :- has(Id,landuse,grass).

meetsAffordance(Id, indoors, 2) :- has(Id, building, _).

meetsAffordance(Id, area, 2) :- has(Id, building, _).
meetsAffordance(Id, area, 2) :- has(Id, leisure,_).
meetsAffordance(Id, area, 2) :- has(Id, landuse,_).
meetsAffordance(Id, area, 2) :- has(Id, amenity,_).

meetsAffordance(Id, hunt_prey, 2) :- has(Id,landuse,grass).
meetsAffordance(Id, hunt_prey, 2) :- has(Id,landuse,forest).
meetsAffordance(Id, hunt_prey, 2) :- has(Id,man_made, dyke).



meetsAffordance(Id, social_interaction, 2) :- has(Id, amenity, _).
meetsAffordance(Id, social_interaction, 1) :- has(Id,building,_).

meetsAffordance(Id, emergency_access, 2) :- has(Id, emergency, _).

meetsAffordance(Id, ignite, 1) :- has(Id, _, industrial).

meetsAffordance(Id, danger, 2) :- has(Id, _, industrial).

%%	 Water area
meetsAffordance(Id, water_area, 2) :- has(Id,landuse,basin).
meetsAffordance(Id, water_area, 2) :- has(Id,natural,water). % maybe requires restriction to local area
meetsAffordance(Id, water_area, 2) :- has(Id,waterway,_).
meetsAffordance(Id, water_area, 2) :- has(Id,natural,coastline).

%%	Leaning
meetsAffordance(Id, enclosure, 2) :- has(Id,building,_).
meetsAffordance(Id, enclosure, 1) :- has(Id,highway,_), obj_distance(Id,Id2,touch), meetsAffordance(Id2, water_area, 2).
meetsAffordance(Id, enclosure, 1) :- has(Id,highway,_), obj_distance(Id,Id2,near), meetsAffordance(Id2, water_area, 2).


meetsAffordance(_, _, -2).

%%	Bewertung eines Objektes bzgl. des Schildes

affordanceSum(_, [],0).
affordanceSum(Id, [A], S) :- meetsAffordance(Id, A, S).
affordanceSum(Id, [A|As],S) :-
	meetsAffordance(Id, A, S1),
	affordanceSum(Id, As, S2),
	S is S1+S2.

applicability(Sign, Id, Score) :-
	signAffordances(Sign, A),
	affordanceSum(Id, A, Score2),
	length(A,Len), % normalize by length of requirements
	Score is Score2/Len.

bestApplicability(Sign, Id, Score) :-
	findall(S,applicability(Sign,Id,S), Scores),
	max_list(Scores,Score).

doInterpretation(_,[], []).
doInterpretation(R, [Id|Rest], [[Id,Val]|Scores]) :-
	bestApplicability(R, Id, Val),
	write([R,Id,Val]),
	doInterpretation(R, Rest, Scores).


%%	Sortieren der Ergebnisliste (mergesort)


merge([], Xs, Xs).
merge(Xs, [], Xs).
% Other cases: the @=< predicate compares terms by the "standard order"
merge(Xs, Ys, S) :-
    Xs = [[IX,XSc]|Xs0],
    Ys = [[IY,YSc]|Ys0],
    %% nach Bewertung sortieren, bei gleicher Bewertung nach Abstand
%    %(((distance(IY,DY), distance(IX,DX), (DY + 20*YSc) > (20*XSc +
%    DX))) ->
      (((YSc @< XSc); (YSc = XSc, distance(IY,DY), distance(IX,DX), DY>DX)) ->
        S = [[IX,XSc]|S0],
        merge(Xs0, Ys, S0)
    ;
        S = [[IY,YSc]|S0],
        merge(Xs, Ys0, S0)
    ).

split_at(Xs, N, Ys, Zs) :-
    length(Ys, N),
    append(Ys, Zs, Xs).

split_in_half(Xs, Ys, Zs) :-
	length(Xs, Len),
	Half is Len // 2,
	split_at(Xs, Half, Ys, Zs).

sortResults([], []).
sortResults([X], [X]).
sortResults([X|Xs], S) :-
	split_in_half([X|Xs], Ys, Zs),
	sortResults(Ys, SY),
	sortResults(Zs, SZ),
	merge(SY, SZ, S).


printLispPair(Stream, [X,Y]) :- swritef(S,'(%w %w)', [X, Y]), print(Stream,S).

printLispStyle(_, []).
printLispStyle(Stream, [P|Ps]) :-
	printLispPair(Stream, P),
	printLispStyle(Stream, Ps).

interpret :-
	restriction(R), % Bezeichnung(en) des Schildes
	entities(Ids), % alle Objekte in der Szene
	write(R), % Debug...
	doInterpretation(R, Ids, ScoreObjPairs),
	sortResults([[here,0]|[[popup,0.1]|ScoreObjPairs]], SortedObjPairs),
	open('/tmp/prolog-out.txt', write, Stream),
	print(Stream,'('),
	print('\n--- beste Kandidaten ---\n'),
	write(SortedObjPairs),
	printLispStyle(Stream, SortedObjPairs),
	print(Stream,')\n'),
	close(Stream).

remove_duplicates([],[]).
remove_duplicates([X|Ys], Xs) :-
	remove_duplicates(Ys,Xs),
	member(X,Xs).

remove_duplicates([X|Xs], [X|Ys]) :-
	remove_duplicates(Xs,Ys),
	not(member(X,Ys)).

all_Signs(Signs) :-
	findall(S,affordances(S,_),Signs2),
	remove_duplicates(Signs2,Signs).



