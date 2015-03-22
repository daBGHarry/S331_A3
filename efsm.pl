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
transition(dormant, init, start, null, 'load drivers').
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
transition(monidle, monidle, null, null, 'check contagion').
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

%% 1. is loop(Event, Guard) succeeds by finding a loop edge. We assume that an edge can be represented by a non-null event-guard pair.
is_loop(Event,Guard):- transition(X,X,Event,Guard,_).

%% 2. 
all_loops(Set):- findall(Edge,

%% 3. is edge(Event, Guard) succeeds by finding an edge.
is_edge(Event,Guard):- transition(_,_,Event,Guard,_).

%% 5. is link(Event, Guard) succeeds by finding a link edge.
is_link(Event,Guard) :- 															%% ** WTF is a link edge????????

%% 7. ancestor(Ancestor,Descendant) is a utility rule that succeeds by returning an ancestor to a given state. 	%% ** are we trying to prove that descendant has ancestor? or find ancestor to descendant?????
ancestor(Ancestor, Descendant) :- transition(Ancestor, Descendant,_,_,_). %% returns the ancestor to the state Descendant
%% ** ancestor(Ancestor, Descendant) :- transition(Ancestor,Descendant,_,_,_).
%% ** ancestor(Ancestor, Descendant) :- transition(Ancestor,X,_,_,_), ancestor(X, Descendant).

%% 9. all states(L) succeeds by returning a list of all states.
states(L) :- findall(X,state(X),L). %% returns a list of all states in EFSM

%% 11. get starting state(State) succeeds by returning the top-level starting state.
get_starting_state(State) :- initial_state(State,null).	%% if state is initial state
get_starting_state(State) :- superstate(X,State), get_starting_state(X). %% if state is in lower level states, find the intial state of its superstate
get_starting_state(State) :- get_starting_state(ancestor(Ancestor, State)). %% if state has ancestor, see if the ancestor is the initial state

%% 13. graph is reflexive succeeds if the entire EFSM is reflexive.	%% ** Every state is reflexive???
graph_is_reflexive :- list_is_reflexive(states(L)).
list_is_reflexive([H]) :- transition(H,H,_,_,_).	%% base case
list_is_reflexive([H|T]) :- transition(H,H,_,_,_), list_is_reflexive(T). %% iterates through list of all states and checks if they are all reflexive

%% 15. get events(Ret) succeeds by returning a set of all events.
get_events(Ret) :- findall(Event, transition(_,_,Event,_,_),L),list_to_set(L,Ret).

%% 17. get only guarded(Ret) succeeds by returning state pairs that are associated by guards only.
get_only_guarded(Ret) :- findall([Ancestor,Descendant|[]],transition(Ancestor,Descendant,_,null,null),Ret).










