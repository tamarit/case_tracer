-module(case_clause_sender_pt).

-export([parse_transform/2,ref_append/1]).


ref_append(File) ->
	{ok, Forms} = epp:parse_file(File, [], []),
    Comments = erl_comment_scan:file(File),
    NForms = parse_transform(Forms,[]),
    lists:map(fun(Form) -> io:format("~p\n",[Form]) end, NForms),
    FinalForms = erl_recomment:recomment_forms(NForms,Comments),
    io:format("~s\n",[erl_prettypr:format(FinalForms)]).

parse_transform(Forms,_) ->
	[erl_syntax_lib:map(
		fun case_clause_sender_fun/1,
		Form) || Form <- Forms].

case_clause_sender_fun(T) ->
	case_clause_sender_expr(erl_syntax:revert(T)).


case_clause_sender_expr({'case',LINE,E,Clauses}) ->
	PatternsClauses = 
		[Pattern || {clause,_,Pattern,_,_} <- Clauses],
	{'case',LINE,E,change_clauses(Clauses,1,E,PatternsClauses,LINE)};
case_clause_sender_expr(Other) ->
	Other.


change_clauses([],_,_,_,_) ->
	[];
change_clauses([{clause,LINE,Pattern,Guards,Body}|Clauses],Num,E,PatternsClauses,CaseLine) ->
	NClauses = change_clauses(Clauses,Num + 1,E,PatternsClauses,CaseLine),
	NBody = 
		[{op,LINE,'!',
			{atom,LINE,'case_tracer'},
			 {tuple,LINE,[
			 	{atom,LINE,'case_trace'},
			 	{tuple,LINE,[
				 	{integer,LINE,CaseLine},
				 	{integer,LINE,Num},
				 	% {integer,LINE,0},
				 	% {integer,LINE,1}
				 	{string,LINE,lists:flatten(io_lib:format("~p",[E]))},
				 	{string,LINE,lists:flatten(io_lib:format("~p",[Pattern]))},
				 	{string,LINE,lists:flatten(io_lib:format("~p",[PatternsClauses]))}
			 	]}
			 ]} }
		 | Body],
	[{clause,LINE,Pattern,Guards,NBody}|NClauses].



