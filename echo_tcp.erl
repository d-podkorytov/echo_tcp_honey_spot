-module(echo_tcp).
-autor("Dmitry Porkorytov").

-compile(export_all).

% server specific code
start() -> 
   io:format("~p:~p ~n",[?MODULE,?LINE]),
   echo_tcp_server:start(?MODULE, 2323, {?MODULE, loop}).

start(Port) when is_integer(Port)-> 
   io:format("~p:~p start at tcp port=~p ~n",[?MODULE,?LINE,Port]),
   echo_tcp_server:start(?MODULE, Port, {?MODULE, loop});

start({silent,Port}) when is_integer(Port)-> 
   echo_tcp_server:start(?MODULE, Port, {?MODULE, loop});

start({fast,Port}) when is_integer(Port)-> 
   spawn(fun()->echo_tcp_server:start(?MODULE, Port, {?MODULE, loop}) end);
   
start([])->ok;   
start([Port|Tail]) when is_integer(Port)-> 
    start({fast,Port}),
    start(Tail).   

start(From,To)->
 start(lists:seq(From,To)).
     
loop(Socket) ->
 case gen_tcp:recv(Socket, 0) of
   {ok,Data}->
                 spawn(fun()->
                        gen_tcp:send(Socket,list_to_binary(atom_to_list(?MODULE)++":" ++
                                                           integer_to_list(?LINE)++" "++
                                                           "ECHO:"++binary_to_list(Data))),
                        io:format("~p:~p get data: ~p ~n",[?MODULE,?LINE,Data]) 
                      end),
                 loop(Socket);
   {error, closed} -> ok
 end.