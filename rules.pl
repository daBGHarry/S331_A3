%% =============================================================================
%%                                Rules
%% =============================================================================

%% 1. is_loop(Event, Guard) succeeds by finding a loop edge. We assume that an edge can be represented by a non-null event-guard pair.
%% returns true if a transitions goes from a state X to that same state X
is_loop(Event,Guard):- transition(X, X, Event, Guard,_).

%% 2. all_loops(Set) succeeds by returning a set of all loop edges.
%% returns all loops within the efsm in a set
all_loops(Set):- findall([Event, Guard], is_loop(Event, Guard), List), list_to_set(List, Set).

%% 3. is_edge(Event, Guard) succeeds by finding an edge.
%% returns true if a transition is found with the corresponding event and guard
is_edge(Event, Guard):- transition(_,_, Event, Guard,_).

%% 4. size(Length) succeeds by returning the size of the entire EFSM (given by the number of its edges).
%% returns the number of edges of the entire efsm
size(Length) :- findall([Event, Guard], is_edge(Event, Guard), List), length(List,Length).

%% 5. is_link(Event, Guard) succeeds by finding a link edge.
%% returns true if an edge is not a loop
is_link(Event, Guard) :- transition(Y, X, Event, Guard, _), not(Y==X).

%% 6. Rule all superstates(Set) succeeds by ﬁnding all superstates in the EFSM.
%% returns a set of all superstates within the efsm
all_superstates(Set) :- findall(States, (state(States), superstate(States, _)), List), list_to_set(List, Set).

%% 7. ancestor(Ancestor,Descendant) is a utility rule that succeeds by returning an ancestor to a given state.
%% returns the ancestor to the state Descendant
ancestor(Ancestor, Descendant) :- superstate(Ancestor, Descendant). 
%% returns null if descendant has no ancestor
ancestor(Ancestor, Descendant) :- Ancestor is null. 

%% 8. inherits_transitions(State, List) succeeds by returning all transitions inherited by a given state.
%% returns a list of all transitons inherited from the superstate, and of the superstate's superstate and so on.
inherits_transitions(State,List) :- superstate(X,State),
									superstate(_,X),
									inherits_transitions(X,L2),
									findall(transition(State1,State2,Event,Guard,Action),(superstate(State1,State),transition(State1,State2,Event,Guard,Action)),L1),
									append(L1,L2,List).
%% returns a list of all transitons inherited from the superstate
inherits_transitions(State,List) :- findall(transition(State1,State2,Event,Guard,Action),(superstate(State1,State),transition(State1,State2,Event,Guard,Action)),List).

%% 9. all_states(L) succeeds by returning a list of all states.
%% returns a list of all states in EFSM
all_states(L) :- findall(X,state(X),L). 

%% 10. all_init_states(L) succeeds by returning a list of all starting states.
%% returns a list of all the initial states
all_init_states(L) :- findall(State, initial_state(State, _), L).

%% 11. get_starting_state(State) succeeds by returning the top-level starting state.
%% returns a State that is the initial top-level starting state
get_starting_state(State) :- initial_state(State, null).

%% 12. state_is_reflexive(State) succeeds if State is reﬂexive.
%% returns true if a state is reflexive (loop edge) 
state_is_reflexive(State) :- transition(State, State, _, _, _).

%% 13. graph_is_reflexive succeeds if the entire EFSM is reflexive.
%% returns true if every state of the efsm is reflexive
graph_is_reflexive :- graph_is_reflexive(all_states(L)).
%% base case: if last element of the list of states
graph_is_reflexive([H]) :- is_loop(H).	
%% iterates through list of all states and checks if they are all reflexive
graph_is_reflexive([H|T]) :- is_loop(H), graph_is_reflexive(T). 

%% 14. get_guards(Ret) succeeds by returning a set of all guards.
%% retuns a set of all guards of the efsm
get_guards(Ret) :- findall(Guard,(transition(_, _, _, Guard, _),not(Guard==null)), List), list_to_set(List, Ret).

%% 15. get_events(Ret) succeeds by returning a set of all events.
%% retuns a set of all events of the efsm
get_events(Ret) :- findall(Event,(transition(_, _, Event, _, _),not(Event==null)),L), list_to_set(L,Ret).

%% 16 get_actions(Ret) succeeds by returning a set of all actions.
%% retuns a set of all actions of the efsm
get_actions(Ret) :- findall(Action,(transition(_, _, _, _, Action),not(Action==null)), List), list_to_set(List, Ret).

%% 17. get_only_guarded(Ret) succeeds by returning state pairs that are associated by guards only.
%% finds all the state pairs associated with guards only and inserts them by pairs in a nested list
get_only_guarded(Ret) :- findall([State1,State2],(transition(State1,State2,null,Guard,null),not(Guard==null)),Ret).

%% 18. legal_events_of(State, L) succeeds by returning all legal event-guard pairs.
%% retuns a list of event, guard pair of all outgoing edges of State
legal_events_of(State, L) :- findall([Event, Guard], transition(State, _, Event, Guard, _), L).
