"""Specialize generated CXXRTL for the adapter's native assertion path."""
import re

def specialize_native_checks(code):
    # The adapter never supplies a performer. Reject other callers explicitly.
    # Keep every original RTL check and CXXRTL_ASSERT; only unreachable callback
    # formatting/metadata construction can be removed by the C++ compiler.
    pattern = r"(bool p_\w+::eval\(performer \*performer\) \{)"
    result, count = re.subn(pattern,
        r"\1\n\tCXXRTL_ASSERT(performer == nullptr);\n\tperformer = nullptr;", code)
    if count == 0:
        raise ValueError("unrecognized CXXRTL eval signature")
    return result.replace("if (performer) {", "if constexpr (false) {")
