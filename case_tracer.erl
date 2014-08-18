-module(case_tracer).

-export([trace/1]).

trace(InitialCall) ->
	AExpr = 
		case is_list(InitialCall) of 
		 	true ->
		 		hd(parse_expr(InitialCall++"."));
		 	false ->
		 		InitialCall
		end,
	{call,_,{remote,_,{atom,_,ModName},_},_} = AExpr,
	%io:format("~p\n~p\n",[AExpr,ModName]),
	compile:file(atom_to_list(ModName) ++ ".erl" ,[{parse_transform,case_clause_sender_pt}]),
	register(case_tracer,self()),
	try
		erlang:purge_module(ModName)
	catch 
		_:_ -> ok
	end,
	code:load_abs(atom_to_list(ModName)),
	spawn(fun() -> erl_eval:expr(AExpr,[]),case_tracer!stop end),
	Trace = lists:reverse(receive_loop(0,[])),
	unregister(case_tracer),
	%io:format("~p\n",[Trace]),
	Trace.

receive_loop(Current,Trace) ->
	receive 
		stop ->
			Trace;
		TraceItem = {case_trace, _} ->
			% io:format("entra ~p\n",[TraceItem]),
			receive_loop(Current + 1, [{Current,TraceItem}|Trace])
		% ;
		% Other ->
		% 	io:format("entra ~p\n",[Other])
	end.


parse_expr(Func) ->
    case erl_scan:string(Func) of
		{ok, Toks, _} ->
		    case erl_parse:parse_exprs(Toks) of
				{ok, _Term} = Res ->
				    Res;
				_Err ->
				    {error, parse_error}
		    end;
		_Err ->
		    {error, parse_error}
    end.