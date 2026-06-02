-module(app_config_ffi).
-export([getenv/1]).

getenv(Name) ->
    case os:getenv(binary_to_list(Name)) of
        false -> getenv_from_file(Name);
        Value -> {ok, unicode:characters_to_binary(Value)}
    end.

getenv_from_file(Name) ->
    case file:read_file(".env") of
        {ok, Contents} -> find_env_line(Name, binary:split(Contents, <<"\n">>, [global]));
        {error, _} -> {error, nil}
    end.

find_env_line(_Name, []) ->
    {error, nil};
find_env_line(Name, [Line | Rest]) ->
    Trimmed = trim(Line),
    case Trimmed of
        <<>> -> find_env_line(Name, Rest);
        <<"#", _/binary>> -> find_env_line(Name, Rest);
        _ ->
            case binary:split(Trimmed, <<"=">>) of
                [Name, Value] -> {ok, trim(Value)};
                _ -> find_env_line(Name, Rest)
            end
    end.

trim(Value) ->
    unicode:characters_to_binary(string:trim(unicode:characters_to_list(Value))).
