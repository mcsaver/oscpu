# V8X compile-success RTL mutation results

- RTL SHA-256 before: `6d3bed55ae4b00fe28400877ff85246cb40681a965b05c938687565849232174`
- RTL SHA-256 after: `6d3bed55ae4b00fe28400877ff85246cb40681a965b05c938687565849232174`
- source restored: `True`
- testbench SHA-256: `c52f2a9257d6306e470a2bd5cb991e40fc6b4f1f58536de6dd72e15e6fbd6940`
- adapter SHA-256: `fb0c164e7373b427cf602bc89cd96858836362ccd8f4e620c983f2ef1711d008`
- compile-success: 2/2
- rejected: 2/2

- PASS `mask-active-recovery-while-station-valid`: compile_rc=0, sim_rc=1, witness=`V8X active A exact selective authority`
- PASS `block-killed-station-promotion`: compile_rc=0, sim_rc=1, witness=`V8X station B promotes to active B`
