-module(concolic).
-export([concolic/1]).

concolic(Call) ->
	Explored = lists:reverse(explore_all(parse_expr(Call),[],[])),
	[lists:flatten(erl_pp:exprs([Call_])) || Call_ <- Explored].

explore_all(Call,Stack,Explored) ->
	io:format("pasa: ~p\n~p\n",[Call,Stack]),
	% io:get_line(""),
	Trace = case_tracer:trace(Call),
	NStack = 
		case Explored of 
			[] ->
				lists:reverse(build_stack(Trace));
			_ -> 
				io:format("Trace: ~p\n",[Trace]),
				NTrace = remove_from_trace(Stack,Trace),
				remove_done(lists:reverse(build_stack(NTrace)) ++ Stack)
		end,
	io:format("NStack: ~p\n",[NStack]),
	case NStack of 
		[] -> 
			[Call | Explored];
		_ -> 
			% io:format("NStack: ~p\n",[NStack]),
			{NCall, NNStack} = create_new_call(Call,NStack),
			% io:format("NTrace: ~p\n",[NTrace]),
			explore_all(NCall,NNStack ,[Call|Explored])
	end.
	% LastExplored = evaluate_trace(Trace),
	% NStack = 
	% 	case Stack of 
	% 		[] ->
	% 			[{CaseLine,[]}|| {CaseLine,PatternNumber} <- LastExplored];
	% 	end,
	% NExplored = [LastExplored|Explored],
	% {LastCase,LastPattern} = lists:last(LastExplored),
	% {ok,TokensExpr,_} = erl_scan:string(Expr),
	% {ok,Expr} = erl_parse:parse_term(TokensExpr).

remove_from_trace([],Trace) ->
	Trace;
remove_from_trace(_,[]) ->
	[];
remove_from_trace([_|Stack], [_|Trace]) ->
	remove_from_trace(Stack,Trace).

remove_done([]) ->
	[];
remove_done([{_, _, _, []} | TailStack]) ->
	remove_done(TailStack);
remove_done(Stack) ->
	Stack.

build_stack([]) ->
	[];	
build_stack([{_,{case_trace,{CaseLine, PatternNumber, ExprS, PatternS, PatternsClausesS}}} | Trace]) -> 
	PatternsClauses = parse_expr(PatternsClausesS),
	Pattern = parse_expr(PatternS),
	Expr = parse_expr(ExprS),
	% io:format("ps: ~p\np: ~p\n",[PatternsClauses,Pattern]),
	[{CaseLine, Expr, PatternsClauses, PatternsClauses -- [Pattern]} | build_stack(Trace)].

create_new_call(AECall, [{CaseLine, Expr, AllPatterns, [Pattern | TailPatterns]}|TailStack]) ->
	%io:format("~p\n",[OldCall]),
	VarsParameter = get_vars_parameters(AECall),
	NPars = find_new_args(Expr, VarsParameter, Pattern, AllPatterns),
	{erlang:setelement(4, AECall, NPars),[{CaseLine, Expr, AllPatterns, TailPatterns} | TailStack]}.
	%{Expr, VarsParameter, Pattern}.

find_new_args({op,_,Op,OpA,OpB}, VarsParameter, [{atom,_,Pattern}], _) ->
	{{var,_,Var}, {integer,_,Int},Op1} = 
		case OpA of 
			{var,_,_} -> 
				{OpA,OpB,Op};
			_ ->
				{OpB,OpA,inverse_operator(Op)}
		end,
	NValue = {integer,1,value_arg(Op1,Int,Pattern)},
	[case Var_ of 
		Var -> NValue;
		_ -> Value_
	 end || Item = {Var_,Value_} <- VarsParameter];
find_new_args({var,_,Var}, VarsParameter, [{Type,_,Pattern}], AllPatterns) ->
	NValue = 
		case Type of
			var ->
				different_pattern(0,[ Pattern_ || {_,_,Pattern_} <- AllPatterns]);
			_ ->
				value_arg('=:=',Pattern,true)
		end,
	[case Var_ of 
		Var -> {integer,1,NValue};
		_ -> Value_
	 end || Item = {Var_,Value_} <- VarsParameter].

inverse_operator('>') -> '<';
inverse_operator('<') -> '>';
inverse_operator('=<') -> '>=';
inverse_operator('>=') -> '=<';
inverse_operator(Op) -> Op.

value_arg('<',Int,true) -> Int - 1;
value_arg('<',Int,false) -> Int;
value_arg('=<',Int,true) -> Int;
value_arg('=<',Int,false) -> Int + 1;
value_arg('>',Int,true) -> Int + 1;
value_arg('>',Int,false) -> Int;
value_arg('>=',Int,true) -> Int;
value_arg('>=',Int,false) -> Int - 1;
value_arg('=:=',Int,true) -> Int;
value_arg('=:=',Int,false) -> Int + 1;
value_arg('=/=',Int,true) -> Int + 1;
value_arg('=/=',Int,false) -> Int.

different_pattern(Current,AllPatterns) ->
	case lists:member(Current,AllPatterns) of 
		true -> 
			different_pattern(Current + 1,AllPatterns);
		false ->
			Current
	end.

get_vars_parameters(Call) ->
	{call,_,{remote,_,{atom,_,ModName},{atom,_,FunName}},Args} = Call,
	{ok, Forms} = 
		epp:parse_file(atom_to_list(ModName) ++ ".erl", [], []),
	Params = 
		hd([Params_ || {function,_,FunName_,_,[{clause,_,Params_,_,_}]} <- Forms, FunName_ =:= FunName]),
	Vars = [VarName || {var,_,VarName} <- Params],
	lists:zip(Vars, Args).

parse_expr(ExprString) ->
    case erl_scan:string(ExprString ++ ".") of
		{ok, Toks, _} ->
		    case erl_parse:parse_term(Toks) of
				{ok, Term} ->
				    Term;
				_Err ->
					case erl_parse:parse_exprs(Toks) of
						{ok, [Term]} ->
							Term;
						_Err ->
					    	{error, parse_error}
				    end
		    end;
		_Err ->
		    {error, parse_error}
    end.

% evaluate_trace([]) -> 
% 	[];
% evaluate_trace([{_,{case_trace,{CaseLine,PatternNumber,_,_}}}|TailTrace]) ->
% 	[{CaseLine,PatternNumber} | evaluate_trace(TailTrace)].

