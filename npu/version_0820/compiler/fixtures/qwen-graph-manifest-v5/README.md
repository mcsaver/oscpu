# Legacy Qwen graph input (v5)

`dispatch.manifest.json` preserves the earlier 1711-node Qwen graph as a
historical compiler fixture. It contains graph and tensor metadata, not model
weights, and has no sampler node (`sampler_count=0`).

The current backend defaults use
[the strict manifest pair](../qwen-strict-manifests/README.md).
The strict dispatch graph retains these 1711 nodes and appends a logits VIEW,
RESHAPE, and greedy ARGMAX, bringing the total to 1714 nodes and
`sampler_count=1`. Use the strict pair for the current backend workflow;
this file is retained for historical graph comparisons.

The legacy file passes the existing manifest envelope and graph IR validation.
It is not a replacement for the strict bootstrap/steady bundle.
