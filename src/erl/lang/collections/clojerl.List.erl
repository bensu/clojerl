-module('clojerl.List').

-include("clojerl.hrl").

-behavior('clojerl.Counted').
-behavior('clojerl.IColl').
-behavior('clojerl.IEquiv').
-behavior('clojerl.IHash').
-behavior('clojerl.IMeta').
-behavior('clojerl.IReduce').
-behavior('clojerl.ISeq').
-behavior('clojerl.ISequential').
-behavior('clojerl.IStack').
-behavior('clojerl.Seqable').
-behavior('clojerl.Stringable').

-export([?CONSTRUCTOR/1]).

-export([count/1]).
-export([ cons/2
        , empty/1
        ]).
-export([equiv/2]).
-export([hash/1]).
-export([ meta/1
        , with_meta/2
        ]).
-export([ reduce/2
        , reduce/3
        ]).
-export([ first/1
        , next/1
        , more/1
        ]).
-export(['_'/1]).
-export([ peek/1
        , pop/1
        ]).
-export([ seq/1
        , to_list/1
        ]).
-export([str/1]).

-type type() :: #?TYPE{}.

-spec ?CONSTRUCTOR(list()) -> type().
?CONSTRUCTOR(Items) when is_list(Items) ->
  #?TYPE{data = Items};
?CONSTRUCTOR(?NIL) ->
  #?TYPE{data = []};
?CONSTRUCTOR(Items) ->
  #?TYPE{data = clj_rt:to_list(Items)}.

%%------------------------------------------------------------------------------
%% Protocols
%%------------------------------------------------------------------------------

count(#?TYPE{name = ?M, data = Items}) -> length(Items).

cons(#?TYPE{name = ?M, data = []} = List, X) ->
  List#?TYPE{data = [X]};
cons(#?TYPE{name = ?M, data = Items} = List, X) ->
  List#?TYPE{data = [X | Items]}.

empty(_) -> ?CONSTRUCTOR([]).

equiv( #?TYPE{name = ?M, data = X}
     , #?TYPE{name = ?M, data = Y}
     ) ->
  clj_rt:equiv(X, Y);
equiv(#?TYPE{name = ?M, data = X}, Y) ->
  case clj_rt:'sequential?'(Y) of
    true  -> clj_rt:equiv(X, Y);
    false -> false
  end.

hash(#?TYPE{name = ?M, data = X}) ->
  clj_murmur3:ordered(X).

meta(#?TYPE{name = ?M, info = Info}) ->
  maps:get(meta, Info, ?NIL).

with_meta(#?TYPE{name = ?M, info = Info} = List, Metadata) ->
  List#?TYPE{info = Info#{meta => Metadata}}.

reduce(#?TYPE{name = ?M, data = []}, F) ->
  clj_rt:apply(F, []);
reduce(#?TYPE{name = ?M, data = [First | Rest]}, F) ->
  do_reduce(F, First, Rest).

reduce(#?TYPE{name = ?M, data = List}, F, Init) ->
  do_reduce(F, Init, List).

do_reduce(F, Acc, [First | Items]) ->
  Val = clj_rt:apply(F, [Acc, First]),
  case 'clojerl.Reduced':is_reduced(Val) of
    true  -> Val;
    false -> do_reduce(F, Val, Items)
  end;
do_reduce(_F, Acc, []) ->
  Acc.

first(#?TYPE{name = ?M, data = []}) -> ?NIL;
first(#?TYPE{name = ?M, data = [First | _]}) -> First.

next(#?TYPE{name = ?M, data = []}) -> ?NIL;
next(#?TYPE{name = ?M, data = [_ | []]}) -> ?NIL;
next(#?TYPE{name = ?M, data = [_ | Rest]} = List) ->
  List#?TYPE{name = ?M, data = Rest}.

more(#?TYPE{name = ?M, data = []}) -> ?NIL;
more(#?TYPE{name = ?M, data = [_ | Rest]} = List) ->
  List#?TYPE{data = Rest}.

'_'(_) -> ?NIL.

peek(#?TYPE{name = ?M, data = List}) ->
  clj_rt:peek(List).

pop(#?TYPE{name = ?M, data = []} = List) ->
  List;
pop(#?TYPE{name = ?M, data = [_ | Rest]} = List) ->
  List#?TYPE{data = Rest}.

seq(#?TYPE{name = ?M, data = []}) -> ?NIL;
seq(#?TYPE{name = ?M, data = Seq}) -> Seq.

to_list(#?TYPE{name = ?M, data = List}) -> List.

str(#?TYPE{name = ?M, data = []}) ->
  <<"()">>;
str(#?TYPE{name = ?M} = List) ->
  clj_rt:print(List).
