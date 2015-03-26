%% ** MUST SEPERATE THIS FILE INTO FACTS AND RULES FILES

%% Top level states

state(init).
state(idle).
state(monitoring).
state(error_diagnosis).
state(safe_shutdown).

%% States under init state
state(boot_hw).
state(senchk).
state(tchk).
state(psichk).
state(ready).

%% States under monitor state
state(monidle).
state(regulate_environment).
state(lockdown).

%% States under error_diagnosis state
state(error_rcv).
state(applicable_rescue).
state(reset_module_data).

%% States under lockdown state
state(prep_vpurge).
state(alt_temp).
state(alt_psi).
state(risk_assess).
state(safe_status).

%% Initial states
initial_state(dormant, null).
initial_state(boot_hw, init).
initial_state(monidle, monitor).
initial_state(error_rcv, error_diagnosis).
initial_state(prep_vpurge, lockdown).

%% Final states
final(exit, null).
final(lock_exit, lockdown).
final(err_exit, error_diagnosis).

%% Superstates
superstate(init, boot_hw).
superstate(init, senchk).
superstate(init, tchk).
superstate(init, psichk).
superstate(init, ready).
superstate(monitor, monidle).
superstate(monitor, regulate_environment).
superstate(monitor, lockdown).
superstate(error_diagnosis, error_rcv).
superstate(error_diagnosis, applicable_rescue).
superstate(error_diagnosis, reset_module_data).
superstate(lockdown, prep_vpurge).
superstate(lockdown, alt_temp).
superstate(lockdown, alt_psi).
superstate(lockdown, risk_assess).
superstate(lockdown, safe_status).

%% transition(source, destination, event, guard, action).

%% Transitions within top level
transition(dormant, exit, kill, null, null).
transition(dormant, init, start, null, 'system boot and load drivers').
transition(init, idle, init_ok, null, null).
transition(init, error_diagnosis, init_crash, null, 'broadcast init_err_msg').
transition(idle, monitoring, begin_monitoring, null, null).
transition(idle, error_diagnosis, idle_crash, null, 'broadcast idle_err_msg').
transition(monitoring, error_diagnosis, monitor_crash, not(inlockdown), 'broadcast idle_err_msg').
transition(error_diagnosis, init, retry_init, 'retry < 3', 'retry++').
transition(error_diagnosis, idle, idle_rescue, null, null).
transition(error_diagnosis, monitoring, moni_rescue, null, null).
transition(error_diagnosis, safe_shutdown, shutdown, 'retry >= 3', 'system clean up').
transition(safe_shutdown,dormant,sleep,null,null).

%% Transitions within init state
transition(boot_hw, senchk, hw_ok, null, null).
transition(senchk, tchk, senok, null, null).
transition(tchk, psichk, t_ok, null, null).
transition(psichk, ready, psi_ok, null, null).

%% Transitons within monitor
transition(monidle, monidle, null, is_contagion, null).								%% still need to check if this transition is necessary
transition(monidle, regulate_environment, no_contagion, null, null).
transition(monidle, lockdown, contagion_alert, null, 'broadcast FACILITY_CRIT_MESG and lockdown = true').
transition(regulate_environment, monidle, after_100ms, null, null).
transition(lockdown, monidle, purge_succ, null, 'lockdown = false').

%% Transitions within lockdown
transition(prep_vpurge, alt_temp, initiate_purge, null, 'lock doors').
transition(prep_vpurge, alt_psi, initiate_purge, null, 'lock doors').
transition(alt_temp, risk_assess, tcyc_comp, null, null).
transition(alt_psi, risk_assess, psicyc_comp, null, null).
transition(risk_assess, safe_status, null, 'risk < 1%', unlock_doors). 
transition(risk_assess, prep_vpurge, null, 'risk >= 1%', null).
transition(safe_status, exit, null, null, null).

%% Transitions within error_diagnosis
transition(error_rcv, applicable_rescue, null, err_protocol_def, null).
transition(error_rcv, reset_module_data, null, no err_protocol_def, null).
transition(applicable_rescue, exit, apply_protocol_rescues, null, null).
transition(reset_module_data, exit, reset_to_stable, null, null).

%% =============================================================================
%%                                Rules
%% =============================================================================

%% 1. is_loop(Event, Guard) succeeds by finding a loop edge. We assume that an edge can be represented by a non-null event-guard pair.
is_loop(Event,Guard):- transition(X,X,Event,Guard,_).

%% 2. all_loops(Set) succeeds by returning a set of all loop edges.
all_loops(Set):- findall([Event, Guard], is_loop(Event, Guard), List), list_to_set(List,Set).

%% 3. is_edge(Event, Guard) succeeds by finding an edge.
is_edge(Event,Guard):- transition(_,_,Event,Guard,_).

%% 4. size(Length) succeeds by returning the size of the entire EFSM (given by the number of its edges).
size(Length) :- findall([Event, Guard], is_edge(Event, Guard), List), length(List).

%% 5. is_link(Event, Guard) succeeds by finding a link edge.
is_link(Event,Guard) :- 															%% ** WTF is a link edge????????

%% 6. Rule all superstates(Set) succeeds by ﬁnding all superstates in the EFSM.
all_superstates(Set) :- findall(States, (state(States), superstate(States, _)), List), list_to_set(List, Set).

%% 7. ancestor(Ancestor,Descendant) is a utility rule that succeeds by returning an ancestor to a given state. 	%% ** are we trying to prove that descendant has ancestor? or find ancestor to descendant?????
%% returns the ancestor to the state Descendant
ancestor(Ancestor, Descendant) :- superstate(Ancestor, Descendant). 
%% returns null if descendant has no ancestor
ancestor(Ancestor, Descendant) :- Ancestor is null. 

%% 8. inherits_transitions(State, List) succeeds by returning all transitions inherited by a given state.
inherits_transitions(State, List) :- findall(transition(State, Anothersuperstate, _, _, _), superstate(Superstate, State), List).

%% 9. all states(L) succeeds by returning a list of all states.
%% returns a list of all states in EFSM
states(L) :- findall(X,state(X),L). 

%% 10. all_init_states(L) succeeds by returning a list of all starting states.
all_init_states(L) :- findall(State, initial_state(State, _), L).

%% 11. get starting state(State) succeeds by returning the top-level starting state.
%% if state is initial state
get_starting_state(State) :- initial_state(State,null).	
%% if state is in lower level states, find the intial state of its superstate
get_starting_state(State) :- superstate(X,State), get_starting_state(X). 
%% if state has ancestor, see if the ancestor is the initial state
get_starting_state(State) :- get_starting_state(ancestor(Ancestor, State)). 

%% 12. state_is_reflexive(State) succeeds if State is reﬂexive. %% ** What the hell is reflexive?
state_is_reflexive(State) :- transition(State, State, _, _, _).

%% 13. graph_is_reflexive succeeds if the entire EFSM is reflexive.	%% ** Every state is reflexive???
%% graph_is_reflexive succeeds if every state is reflexive

%% Get all the states in a list. Get all reflexive states in a list. Compare length of lists. If they're the same, then the graph is reflexive. 
graph_is_reflexive :- all_states(States), findall(ReflexiveState, state_is_reflexive(ReflexiveState), ReflexiveStates), length(States) == length(ReflexiveStates).

%% base case
%% graph_is_reflexive([H]) :- transition(H,H,_,_,_).	
%% iterates through list of all states and checks if they are all reflexive
%% graph_is_reflexive([H|T]) :- transition(H,H,_,_,_), graph_is_reflexive(T). 

%% 14. get_guards(Ret) succeeds by returning a set of all guards.
get_guards(Ret) :- findall(Guard, transition(_, _, _, Guard, _), List), list_to_set(List, Ret).

%% 15. get_events(Ret) succeeds by returning a set of all events.
%% finds all events from the transitions and adds them to a set
get_events(Ret) :- findall(Event, transition(_,_,Event,_,_),L),list_to_set(L,Ret).

%% 16 get_actions(Ret) succeeds by returning a set of all actions.
get_actions(Ret) :- findall(Action, transition(_, _, _, _, Action), List), list_to_set(List, Ret).

%% 17. get_only_guarded(Ret) succeeds by returning state pairs that are associated by guards only.
%% finds all the state pairs associated with guards only and inserts them by pairs in a nested list
get_only_guarded(Ret) :- findall([Ancestor,Descendant|[]],transition(Ancestor,Descendant,_,null,null),Ret).

%% 18. legal_events_of(State, L) succeeds by returning all legal event-guard pairs.
legal_events_of(State, L) :- findall([Event, Guard], transition(State, _, Event, Guard, _), L).
legal_events_of(State, L) :- findall([Event, Guard], transition(_, State, Event, Guard, _), L).




