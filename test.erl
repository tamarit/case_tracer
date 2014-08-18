-module(test).

-export([f/3 ]).

f(X,Y,Z) ->
	% N = 3,
	NX = 
		case X of 
			1 -> 
				0;
			2 -> 
				1;
			N ->
				N - 1
			% ;
			% _ -> 
			% 	N - 2
		end,
	case Y > 0 of
	%case 0 < Y of
		true -> Y - NX;
		false -> 
			case Z of 
				1 -> NX - Y;
				_ -> NX + Y
			end
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