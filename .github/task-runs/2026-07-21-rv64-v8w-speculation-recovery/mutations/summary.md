# V8W OOO-4 compile-success RTL mutation results

- RTL SHA-256: `6d3bed55ae4b00fe28400877ff85246cb40681a965b05c938687565849232174`
- testbench SHA-256: `7800e4b45906278f823ee07a3c4faf0b3e427b74c422c5689decd557f2d6b988`
- backend RTL SHA-256: `772960e9e14622ab8e551e9b9fb28d7ee26c0e1e65120fcba6cc89cbf81c0cee`
- backend testbench SHA-256: `b63104890bb17edb11aab6e64db32482913d68496c514272a644e80a50a9153f`
- compile-success: 18/18
- rejected: 18/18

- PASS `remove-selective-recovery-domain`: target=bridge, case=9, compile_rc=0, sim_rc=1, witness=`V8W exact killed SQ query is masked`
- PASS `drop-terminal-global-only`: target=bridge, case=9, compile_rc=0, sim_rc=1, witness=`V8W exact killed SQ query emits one terminal`
- PASS `fsm-recovery-global-only`: target=bridge, case=10, compile_rc=0, sim_rc=1, witness=`V8W recovered PTW does not present next PTE AR`
- PASS `raw-effective-killed-authority`: target=bridge, case=12, compile_rc=0, sim_rc=1, witness=`V8W MIQ identity mismatch blocks selective recovery`
- PASS `omit-tracker-identity-guard`: target=bridge, case=12, compile_rc=0, sim_rc=1, witness=`V8W tracker identity mismatch blocks selective recovery`
- PASS `omit-sticky-identity-guard`: target=bridge, case=12, compile_rc=0, sim_rc=1, witness=`V8W sticky identity mismatch blocks selective recovery`
- PASS `omit-sticky-delayed-r-drain`: target=bridge, case=13, compile_rc=0, sim_rc=1, witness=`V8W delayed PTW emits exact late terminal`
- PASS `ad-maintenance-authority-global-only`: target=bridge, case=14, compile_rc=0, sim_rc=1, witness=`V8W selective A/D captures maintenance authority`
- PASS `disconnect-bank0-drop-from-miq-pop`: target=backend, case=V8W_MEMORY_RECOVERY_FOCUSED, compile_rc=0, sim_rc=1, witness=`V8W bank0 exact drop selects MIQ pop`
- PASS `disconnect-bank1-drop-from-miq-pop`: target=backend, case=V8W_MEMORY_RECOVERY_FOCUSED, compile_rc=0, sim_rc=1, witness=`V8W bank1 exact drop selects MIQ pop`
- PASS `disconnect-bank0-drop-from-terminal-collector`: target=backend, case=V8W_MEMORY_RECOVERY_FOCUSED, compile_rc=0, sim_rc=1, witness=`[V8W-DROP0-TERMINAL]`
- PASS `disconnect-bank1-drop-from-terminal-collector`: target=backend, case=V8W_MEMORY_RECOVERY_FOCUSED, compile_rc=0, sim_rc=1, witness=`[V8W-DROP0-TERMINAL]`
- PASS `omit-bank0-drop-tuple-guard`: target=backend, case=V8W_MEMORY_RECOVERY_FOCUSED, compile_rc=0, sim_rc=1, witness=`V8W bank0 killed head blocks wrong-tuple drop pop`
- PASS `omit-bank0-drop-effective-kill-guard`: target=backend, case=V8W_MEMORY_RECOVERY_FOCUSED, compile_rc=0, sim_rc=1, witness=`V8W bank0 live head blocks raw exact drop pop`
- PASS `omit-bank0-drop-tracker-guard`: target=backend, case=V8W_MEMORY_RECOVERY_FOCUSED, compile_rc=0, sim_rc=1, witness=`V8W bank0 killed head blocks tracker-mismatch drop pop`
- PASS `omit-bank1-drop-tuple-guard`: target=backend, case=V8W_MEMORY_RECOVERY_FOCUSED, compile_rc=0, sim_rc=1, witness=`V8W bank1 killed head blocks wrong-tuple drop pop`
- PASS `omit-bank1-drop-effective-kill-guard`: target=backend, case=V8W_MEMORY_RECOVERY_FOCUSED, compile_rc=0, sim_rc=1, witness=`V8W bank1 live head blocks raw exact drop pop`
- PASS `omit-bank1-drop-tracker-guard`: target=backend, case=V8W_MEMORY_RECOVERY_FOCUSED, compile_rc=0, sim_rc=1, witness=`V8W bank1 killed head blocks tracker-mismatch drop pop`
