%% Top level states
state(exit).
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

%% Superstates
superstate(init, ).
superstate(init, ).
superstate(init, ).
superstate(init, ).
superstate(init, ).
superstate(monitor, ).
superstate(monitor, ).
superstate(monitor, ).
superstate(error_diagnosis, ).
superstate(error_diagnosis, ).
superstate(error_diagnosis, ).
superstate(lockdown, ).
superstate(lockdown, ).
superstate(lockdown, ).
superstate(lockdown, ).
superstate(lockdown, ).

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
transition(error_diagnosis, monitoring, null, null, null).
