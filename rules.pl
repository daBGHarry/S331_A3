%% =============================================================================
%%                                Rules
%% =============================================================================

%% 1. is_loop(Event, Guard) succeeds by finding a loop edge. We assume that an edge can be represented by a non-null event-guard pair.
is_loop(Event,Guard):- transition(X, X, Event, Guard,_).

%% 2. all_loops(Set) succeeds by returning a set of all loop edges.
all_loops(Set):- findall([Event, Guard], is_loop(Event, Guard), List), list_to_set(List, Set).

%% 3. is_edge(Event, Guard) succeeds by finding an edge.
is_edge(Event, Guard):- transition(_, _, Event, Guard,_).

%% 4. size(Length) succeeds by returning the size of the entire EFSM (given by the number of its edges).
size(Length) :- findall([Event, Guard], is_edge(Event, Guard), List), length(List,Length).

%% 5. is_link(Event, Guard) succeeds by finding a link edge.
is_link(Event, Guard) :- transition(_, _, Event, Guard, _).

%% 6. Rule all superstates(Set) succeeds by ﬁnding all superstates in the EFSM.
all_superstates(Set) :- findall(States, (state(States), superstate(States, _)), List), list_to_set(List, Set).

%% 7. ancestor(Ancestor,Descendant) is a utility rule that succeeds by returning an ancestor to a given state.
%% returns the ancestor to the state Descendant
ancestor(Ancestor, Descendant) :- superstate(Ancestor, Descendant). 
%% returns null if descendant has no ancestor
ancestor(Ancestor, Descendant) :- Ancestor is null. 

%% 8. inherits_transitions(State, List) succeeds by returning all transitions inherited by a given state.
inherits_transitions(State,List) :- superstate(X,State),
									superstate(_,X),
									inherits_transitions(X,L2),
									findall(transition(State1,State2,Event,Guard,Action),(superstate(State1,State),transition(State1,State2,Event,Guard,Action)),L1),
									append(L1,L2,List).
inherits_transitions(State,List) :- findall(transition(State1,State2,Event,Guard,Action),(superstate(State1,State),transition(State1,State2,Event,Guard,Action)),List).


%% ## inherits_transitions(State, List) :- findall(transition(State, Anothersuperstate, _, _, _), superstate(Superstate, State), List).

%% 9. all_states(L) succeeds by returning a list of all states.
%% returns a list of all states in EFSM
all_states(L) :- findall(X,state(X),L). 

%% 10. all_init_states(L) succeeds by returning a list of all starting states.
all_init_states(L) :- findall(State, initial_state(State, _), L).

%% 11. get_starting_state(State) succeeds by returning the top-level starting state.
get_starting_state(State) :- initial_state(State, null).

%% ## get_starting_state(State) :- initial_state(State,null).	
%% ## get_starting_state(State) :- superstate(X,State), get_starting_state(X). 
%% ## get_starting_state(State) :- transition(X,State,_,_,_), get_starting_state(X). 

%% 12. state_is_reflexive(State) succeeds if State is reﬂexive. 
state_is_reflexive(State) :- transition(State, State, _, _, _).

%% 13. graph_is_reflexive succeeds if the entire EFSM is reflexive.
%% graph_is_reflexive succeeds if every state is reflexive
graph_is_reflexive :- graph_is_reflexive(all_states(L)).
%% base case
graph_is_reflexive([H]) :- is_loop(H).	
%% iterates through list of all states and checks if they are all reflexive
graph_is_reflexive([H|T]) :- is_loop(H), graph_is_reflexive(T). 

%% ## graph_is_reflexive :- all_states(States), findall(ReflexiveState, (state(ReflexiveState), state_is_reflexive(ReflexiveState)), ReflexiveStates), length(States) == length(ReflexiveStates).

%% 14. get_guards(Ret) succeeds by returning a set of all guards.
get_guards(Ret) :- findall(Guard, transition(_, _, _, Guard, _), List), list_to_set(List, Ret).

%% 15. get_events(Ret) succeeds by returning a set of all events.
%% finds all events from the transitions and adds them to a set
get_events(Ret) :- findall(Event, transition(_, _, Event, _, _),L), list_to_set(L,Ret).

%% 16 get_actions(Ret) succeeds by returning a set of all actions.
get_actions(Ret) :- findall(Action, transition(_, _, _, _, Action), List), list_to_set(List, Ret).

%% 17. get_only_guarded(Ret) succeeds by returning state pairs that are associated by guards only.
%% finds all the state pairs associated with guards only and inserts them by pairs in a nested list
get_only_guarded(Ret) :- findall([Ancestor,Descendant|[]],transition(Ancestor,Descendant,_,null,null),Ret).

%% 18. legal_events_of(State, L) succeeds by returning all legal event-guard pairs.
legal_events_of(State, L) :- findall([Event, Guard], transition(State, _, Event, Guard, _), L).
