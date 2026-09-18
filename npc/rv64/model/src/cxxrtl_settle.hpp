#pragma once
namespace r64model {
// The harness samples combinational CSR/platform outputs after each edge.
// CXXRTL::step() can commit a register and return before updating outputs
// that depend on it. Continue through the post-commit evaluation as well.
template<class Engine>
void settle(Engine& engine) {
    do {
        engine.eval();
    } while (engine.commit());
}
}
