# v8v LQ topology review

- reviewer contract SHA-256: `5824ab836008a5b59756919f960dbfba1175e34027eea72f4dc12f8e7756cd56`
- execution mode: `self-contained-no-tools`
- wording profile: `rv64-hardware-professional`
- candidate A: `GAP`; would expand into a dual-bank scheduler/transport rewrite.
- candidate B: `PASS` after protocol freeze; shared retire-resident LQ plus two bank-local MIQs.

The review required LQ behavior on capacity, exact final-PA ordering, issue authorization, completion, recovery drain
and exact retirement.  It rejected ROB-index-only identity, terminal-time release, flush-time removal of fired loads,
single-port loss of dual-bank terminals and a fixed four-entry design that would break sustained dual-load issue.

The reviewer intentionally did not access the repository.  The main agent subsequently resolved the listed source
unknowns by tracing `OooIntBackend`, `OooMemInflightQueue`, `OooStoreQueue`, `OooRob` and the existing DI-5 evidence.
The resulting frozen decisions are recorded in `contract.md` and `rtl-derivation.md`; this note is review provenance,
not standalone proof of RTL behavior.
