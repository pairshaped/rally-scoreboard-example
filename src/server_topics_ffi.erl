-module(server_topics_ffi).
-export([start/0, join/1, broadcast/2]).

start() ->
    case pg:start_link(scoreboard_topics) of
        {ok, _Pid} -> nil;
        {error, {already_started, _Pid}} -> nil
    end.

join(Topic) ->
    pg:join(scoreboard_topics, Topic, self()),
    nil.

broadcast(Topic, Frame) ->
    Members = pg:get_members(scoreboard_topics, Topic),
    Self = self(),
    lists:foreach(fun(Pid) ->
        case Pid of
            Self -> ok;
            _ -> Pid ! {scoreboard_frame, Frame}
        end
    end, Members),
    nil.
