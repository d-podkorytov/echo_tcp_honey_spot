-module(echo_tcp_server).
-autor("Dmitry Porkorytov").

-behavior(gen_server).

-export([init/1, code_change/3, handle_call/3, handle_cast/2, handle_info/2, terminate/2]).
-export([accept_loop/1]).
-export([start/3]).

-define(T(),io:format("~p:~p ~n",[?MODULE,?LINE])).
-define(T1(Msg),io:format("~p:~p ~p ~n",[?MODULE,?LINE,Msg])).

-define(TCP_OPTIONS, [binary, {packet, 0}, {active, false}, {reuseaddr, true}]).

-record(server_state, {port,loop,ip=any,lsocket=null}).

start(Name, Port, Loop) ->
 ?T1({Name, Port, Loop}),
 State = #server_state{port = Port, loop = Loop},
 gen_server:start_link({local, Name}, ?MODULE, State, []).

init(State = #server_state{port=Port}) ->
 ?T1(State),
 case gen_tcp:listen(Port, ?TCP_OPTIONS) of
 {ok, LSocket} ->  NewState = State#server_state{lsocket = LSocket},
                   {ok, accept(NewState)};
 {error, Reason} -> {stop, Reason}
 end.
 
handle_cast({accepted, _Pid}, State=#server_state{}) ->
 ?T1({_Pid,State}),
 {noreply, accept(State)}.
 
accept_loop({Server, LSocket, {M, F}}) ->
    ?T1({Server, LSocket, {M, F}}),
    {ok, Socket} = gen_tcp:accept(LSocket),
% Let the server spawn a new process and replace this loop
% with the echo loop, to avoid blocking 
    R1=gen_server:cast(Server, {accepted, self()}),
    ?T1(R1),
    R2=M:F(Socket),
    ?T1(R2).
 
% To be more robust we should be using spawn_link and trapping exits
accept(State = #server_state{lsocket=LSocket, loop = Loop}) ->
 proc_lib:spawn(?MODULE, accept_loop, [{self(), LSocket, Loop}]),
 ?T1(State),
 State.
 
% These are just here to suppress warnings.
handle_call(_Msg, _Caller, State) ->  ?T1({_Msg, _Caller, State}),
                                      {noreply, State}.

handle_info(_Msg, Library) ->   ?T1({_Msg, Library}),
                                {noreply, Library}.

terminate(_Reason, _Library) ->   ?T1({_Reason, _Library}),ok.

code_change(_OldVersion, Library, _Extra) ->   ?T(),{ok, Library}.
 