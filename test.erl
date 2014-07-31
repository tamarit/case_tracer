-module(test).

-export([main/2 ]).

main(X,Y) ->
	NX = 
		case X of 
			1 -> 
				0;
			2 -> 
				1;
			N ->
				N - 1
		end,
	case Y > 0 of
		true -> Y - NX;
		false -> NX - Y
	end.



% -module(test).

% -export([main/1]).

% main(X) ->
% 	NX = 
% 		case X of 
% 			1 -> 
% 				case X of 
% 					1 -> 0
% 				end;
% 			2 -> 1;
% 			N ->
% 				N - 1
% 		end,
% 	case NX > 0 of
% 		true -> main(NX);
% 		false -> ok
% 	end.