-module('clojerl.protocol').

-export([ resolve/3
        , 'extends?'/2
        , impl_module/2
        ]).

-spec resolve(atom(), atom(), list()) -> any().
resolve(Protocol, Function, Args = [Head | _]) ->
  Type = clj_core:type(Head),
  case resolve_impl_cache(Protocol, Function, Type, length(Args)) of
    {M, F}    -> apply(M, F, Args);
    undefined -> throw({unimplemented, Type, Protocol})
  end.

-spec resolve_impl_cache(atom(), atom(), atom(), integer()) ->
  {module(), atom()} | undefined.
resolve_impl_cache(Protocol, Function, Type, Arity) ->
  Key = {resolve_impl, Protocol, Function, Type, Arity},
  case clj_cache:get(Key) of
    undefined ->
      Value = resolve_impl(Protocol, Function, Type, Arity),
      clj_cache:put(Key, Value),
      Value;
    {ok, Value} -> Value
  end.

-spec resolve_impl(atom(), atom(), atom(), integer()) ->
  {module(), atom()} | undefined.
resolve_impl(Protocol, Function, Type, Arity) ->
  case erlang:function_exported(Type, Function, Arity) of
    true  -> {Type, Function};
    false ->
      ImplModule = impl_module(Protocol, Type),
      case erlang:function_exported(ImplModule, Function, Arity) of
        true  -> {ImplModule, Function};
        false -> undefined
      end
  end.

-spec impl_module(atom(), atom()) -> atom().
impl_module(Protocol, Type)
  when is_atom(Protocol),
       is_atom(Type) ->
  TypeBin     = atom_to_binary(Type, utf8),
  ProtocolBin = atom_to_binary(Protocol, utf8),
  impl_module(ProtocolBin, TypeBin);
impl_module(ProtocolBin, TypeBin)
  when is_binary(ProtocolBin),
       is_binary(TypeBin) ->
  binary_to_atom(<<ProtocolBin/binary, "__", TypeBin/binary>>, utf8).

-spec 'extends?'(atom(), atom()) -> boolean().
'extends?'(Protocol, Type) ->
  Key = {extends, Protocol, Type},
  case clj_cache:get(Key) of
    undefined ->
      Value = ( erlang:function_exported(Type, module_info, 1) andalso
                lists:keymember([Protocol], 2, Type:module_info(attributes))
              ),
      clj_cache:put(Key, Value),
      Value;
    {ok, Value} -> Value
  end.
