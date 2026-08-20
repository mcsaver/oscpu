#define _POSIX_C_SOURCE 200809L

#include <ctype.h>
#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <signal.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <time.h>
#include <unistd.h>

#ifndef PATH_MAX
#define PATH_MAX 4096
#endif

#define FLOW_SCHEMA 1
#define MAX_ITEMS 256
#define MAX_ENTRY 2048
#define MAX_ID 96
#define MAX_CLASS 32
#define MAX_STATUS 32
#define MAX_LINE 8192

typedef struct {
    char task_id[MAX_ID];
    char task_class[MAX_CLASS];
    char archive_mode[16];
    char status[MAX_STATUS];
    int overhead_target_percent;
    int64_t started_ms;
    int64_t initial_work_ms;
    int64_t gate_ms;
    int64_t paused_ms;
    int64_t pause_started_ms;
    int generation;
} FlowMeta;

typedef struct {
    const char *id;
    const char *command;
    int timeout_seconds;
} GateDef;

typedef struct {
    char values[MAX_ITEMS][MAX_ENTRY];
    size_t count;
} StringList;

typedef struct {
    char id[64];
    char status[24];
    int64_t elapsed_ms;
    char log_path[PATH_MAX];
    int reused;
} GateResult;

static const GateDef GATES[] = {
    {
        "flow-self-test",
        "scripts/tests/test-agent-flow.sh",
        60,
    },
    {
        "flow-observation-smoke",
        "test -r scripts/agent-flow.c",
        5,
    },
    {
        "source-artifact-hygiene",
        "scripts/tests/test-source-tree-artifact-hygiene.sh && "
        "scripts/check-source-tree-artifact-hygiene.sh",
        30,
    },
    {
        "rv64-soc-delivery-gates",
        "scripts/tests/test-rv64-soc-delivery-gates.sh",
        60,
    },
    {
        "rv64-architecture-registry",
        "/usr/bin/python3 -B -m unittest "
        "npc.rv64.eval.ppa.tests.test_architecture_registry -v && "
        "/usr/bin/python3 -B "
        "npc/rv64/eval/ppa/tools/architecture_registry.py check",
        60,
    },
    {
        "rv64-terminal-collector-lane-contract",
        "/usr/bin/python3 -B -m unittest "
        "npc.rv64.eval.ppa.tests.test_terminal_collector_lane_contract -v",
        60,
    },
    {
        "rv64-historical-defect-ledger-audit",
        "/usr/bin/python3 -B -m unittest "
        "npc.rv64.eval.ppa.tests.test_historical_defect_backfill -v && "
        "/usr/bin/python3 -B "
        "npc/rv64/eval/ppa/tools/historical_defect_backfill.py",
        60,
    },
    {
        "rv64-historical-defect-current-contract",
        "/usr/bin/python3 -B -m unittest "
        "npc.rv64.eval.ppa.tests.test_historical_defect_current -v",
        60,
    },
    {
        "rv64-full-core-runner-contract",
        "/usr/bin/python3 -B -m unittest "
        "npc.rv64.eval.ppa.tests.test_full_core_current_evidence "
        "npc.rv64.eval.ppa.tests.test_full_core_functional_evidence "
        "npc.rv64.eval.ppa.tests.test_full_core_runner_entry "
        "npc.rv64.eval.ppa.tests.test_full_core_functional_replay "
        "npc.rv64.eval.ppa.tests.test_functional_aggregate -v && "
        "/usr/bin/python3 -B "
        "npc/rv64/eval/ppa/tools/full_core_functional_evidence.py "
        "--isolation-smoke && "
        "scripts/tests/test-task-run-status.sh",
        300,
    },
    {
        "rv64-system-recertification-runner-contract",
        "npc/rv64/eval/ppa/run-system-recertification-current.sh "
        "--validate-only",
        300,
    },
    {
        "rv64-current-simulator-cache-contract",
        "npc/rv64/eval/ppa/build-current-simulator-cache.sh --validate-only",
        60,
    },
    {
        "rv64-mini-system-runner-contract",
        "npc/rv64/eval/ppa/run-mini-system-current.sh --validate-only",
        300,
    },
    {
        "rv64-lightweight-linux-runner-contract",
        "npc/rv64/eval/ppa/run-lightweight-linux-current.sh "
        "--validate-only",
        300,
    },
    {
        "rv64-layered-system-signoff-current",
        "/usr/bin/python3 -B -m unittest "
        "npc.rv64.eval.ppa.tests.test_layered_system_signoff "
        "npc.rv64.eval.ppa.tests.test_system_recertification_current -v && "
        "/usr/bin/python3 -B "
        "npc/rv64/eval/ppa/tools/layered_system_signoff.py verify "
        "--receipt "
        "npc/rv64/eval/ppa/evidence/layered-system-signoff-current.json && "
        "/usr/bin/python3 -B "
        "npc/rv64/eval/ppa/tools/system_recertification_current.py "
        "--root . verify --input "
        "npc/rv64/eval/ppa/evidence/system-recertification-current.json",
        300,
    },
    {
        "rv64-architecture-debt-current",
        "/usr/bin/env -u MAKEFLAGS -u MFLAGS -u MAKELEVEL -u GNUMAKEFLAGS "
        "-u MAKEFILES /usr/bin/make -rR --no-print-directory -C npc/rv64 "
        "-f eval/ppa/architecture-debt-current-evidence.mk "
        "check-architecture-debt-current",
        180,
    },
    {
        "rv64-historical-defect-current",
        "/usr/bin/env -u MAKEFLAGS -u MFLAGS -u MAKELEVEL -u GNUMAKEFLAGS "
        "-u MAKEFILES /usr/bin/make -rR --no-print-directory -C npc/rv64 "
        "-f eval/ppa/historical-defect-current-evidence.mk "
        "check-historical-defect-current",
        180,
    },
    {
        "rv64-arch-stable-checker-contract",
        "/usr/bin/python3 -B -m unittest "
        "npc.rv64.eval.ppa.tests.test_arch_stable_freeze "
        "npc.rv64.eval.ppa.tests.test_arch_stable_current_candidate "
        "npc.rv64.eval.ppa.tests.test_functional_archive_rehydrate -v",
        300,
    },
    {
        "rv64-arch-stable-current",
        "/usr/bin/python3 -B npc/rv64/eval/ppa/tools/arch_stable_freeze.py verify "
        "npc/rv64/eval/ppa/evidence/arch-stable-current.json --require-stable",
        300,
    },
    {
        "rv64-owner-timing-fast",
        "npc/rv64/eval/ppa/instrumentation/check-owner-timing.sh --tier fast",
        120,
    },
    {
        "rv64-owner-timing-link",
        "npc/rv64/eval/ppa/instrumentation/check-owner-timing.sh --tier link",
        600,
    },
    {
        "rv64-optimization-slice-selector",
        "npc/rv64/eval/ppa/run-optimization-slice-selector.sh --validate-only",
        120,
    },
    {
        "rv64-memory-request-hold-fast",
        "npc/rv64/testbench/scripts/check_v14r_memory_request_hold.sh --tier fast",
        120,
    },
    {
        "rv64-memory-request-hold-link",
        "npc/rv64/testbench/scripts/check_v14r_memory_request_hold.sh --tier link",
        300,
    },
    {
        "profile-bindings",
        "scripts/agent-e2e.sh --validate-all-profiles",
        180,
    },
    {
        "policy-audit",
        "python3 scripts/github_index_db.py policy-audit",
        180,
    },
    {
        "schema-audit",
        "python3 scripts/github_index_db.py schema-audit",
        180,
    },
    {
        "artifact-audit",
        "python3 scripts/github_index_db.py artifact-audit",
        180,
    },
    {
        "delivery-audit",
        "scripts/package-ai-dev-env.sh && python3 scripts/github_index_db.py delivery-audit",
        300,
    },
    {
        "trace-audit",
        "python3 scripts/github_index_db.py trace-audit",
        180,
    },
    {
        "state-audit",
        "python3 scripts/github_index_db.py state-audit",
        180,
    },
    {
        "skill-audit",
        "python3 scripts/github_index_db.py skill-audit",
        180,
    },
    {
        "rtl-task-contract",
        "python3 .github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py audit && "
        "python3 .github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py self-test && "
        "python3 .github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py cli-self-test",
        240,
    },
    {
        "task-run-status-test",
        "scripts/tests/test-task-run-status.sh",
        90,
    },
    {
        "maintain-final",
        "scripts/agent-maintain.sh --mode final",
        900,
    },
    {
        "maintain-release",
        "scripts/agent-maintain.sh --mode release",
        1800,
    },
};

static const char *VALID_CLASSES[] = {
    "review",
    "analysis",
    "docs",
    "development",
    "verification",
    "environment",
    "longrun",
    "cleanup",
    "release",
};

static int64_t realtime_ms(void) {
    struct timespec ts;
    if (clock_gettime(CLOCK_REALTIME, &ts) != 0) {
        return -1;
    }
    return (int64_t)ts.tv_sec * 1000 + ts.tv_nsec / 1000000;
}

static int64_t monotonic_ms(void) {
    struct timespec ts;
    if (clock_gettime(CLOCK_MONOTONIC, &ts) != 0) {
        return -1;
    }
    return (int64_t)ts.tv_sec * 1000 + ts.tv_nsec / 1000000;
}

static void iso8601_now(char *buffer, size_t size) {
    time_t now = time(NULL);
    struct tm utc;
    if (gmtime_r(&now, &utc) == NULL) {
        snprintf(buffer, size, "unknown-time");
        return;
    }
    strftime(buffer, size, "%Y-%m-%dT%H:%M:%SZ", &utc);
}

static int path_join(char *out, size_t size, const char *left, const char *right) {
    int written = snprintf(out, size, "%s/%s", left, right);
    if (written < 0 || (size_t)written >= size) {
        fprintf(stderr, "[agent-flow] path too long: %s/%s\n", left, right);
        return -1;
    }
    return 0;
}

static int mkdir_p(const char *path) {
    char copy[PATH_MAX];
    size_t length = strlen(path);
    if (length == 0 || length >= sizeof(copy)) {
        return -1;
    }
    memcpy(copy, path, length + 1);
    for (char *cursor = copy + 1; *cursor != '\0'; ++cursor) {
        if (*cursor != '/') {
            continue;
        }
        *cursor = '\0';
        if (mkdir(copy, 0775) != 0 && errno != EEXIST) {
            return -1;
        }
        *cursor = '/';
    }
    if (mkdir(copy, 0775) != 0 && errno != EEXIST) {
        return -1;
    }
    return 0;
}

static int valid_token(const char *value, size_t max_length) {
    size_t length = strlen(value);
    if (length == 0 || length >= max_length) {
        return 0;
    }
    for (size_t i = 0; i < length; ++i) {
        unsigned char ch = (unsigned char)value[i];
        if (!(isalnum(ch) || ch == '.' || ch == '_' || ch == '-')) {
            return 0;
        }
    }
    return 1;
}

static int valid_class(const char *value) {
    size_t count = sizeof(VALID_CLASSES) / sizeof(VALID_CLASSES[0]);
    for (size_t i = 0; i < count; ++i) {
        if (strcmp(value, VALID_CLASSES[i]) == 0) {
            return 1;
        }
    }
    return 0;
}

static int normalize_repo_path(const char *raw, char *out, size_t size) {
    while (raw[0] == '.' && raw[1] == '/') {
        raw += 2;
    }
    if (*raw == '\0' || *raw == '/' || strlen(raw) >= size) {
        return -1;
    }
    size_t segment_length = 0;
    const char *segment = raw;
    for (const char *cursor = raw;; ++cursor) {
        unsigned char ch = (unsigned char)*cursor;
        if (ch == '\t' || ch == '\r' || ch == '\n' || (ch != '\0' && ch < 32)) {
            return -1;
        }
        if (ch == '/' || ch == '\0') {
            if (segment_length == 0 ||
                (segment_length == 1 && segment[0] == '.') ||
                (segment_length == 2 && segment[0] == '.' && segment[1] == '.')) {
                return -1;
            }
            if (ch == '\0') {
                break;
            }
            segment = cursor + 1;
            segment_length = 0;
        } else {
            ++segment_length;
        }
    }
    snprintf(out, size, "%s", raw);
    return 0;
}

static int write_meta(const char *state_dir, const FlowMeta *meta) {
    char path[PATH_MAX];
    char temporary[PATH_MAX];
    if (path_join(path, sizeof(path), state_dir, "meta") != 0) {
        return -1;
    }
    int written = snprintf(temporary, sizeof(temporary), "%s.tmp.%ld", path, (long)getpid());
    if (written < 0 || (size_t)written >= sizeof(temporary)) {
        return -1;
    }
    FILE *stream = fopen(temporary, "w");
    if (stream == NULL) {
        perror("fopen meta");
        return -1;
    }
    fprintf(stream, "schema=%d\n", FLOW_SCHEMA);
    fprintf(stream, "task_id=%s\n", meta->task_id);
    fprintf(stream, "task_class=%s\n", meta->task_class);
    fprintf(stream, "archive_mode=%s\n", meta->archive_mode);
    fprintf(stream, "status=%s\n", meta->status);
    fprintf(stream, "overhead_target_percent=%d\n", meta->overhead_target_percent);
    fprintf(stream, "started_ms=%lld\n", (long long)meta->started_ms);
    fprintf(stream, "initial_work_ms=%lld\n", (long long)meta->initial_work_ms);
    fprintf(stream, "gate_ms=%lld\n", (long long)meta->gate_ms);
    fprintf(stream, "paused_ms=%lld\n", (long long)meta->paused_ms);
    fprintf(stream, "pause_started_ms=%lld\n", (long long)meta->pause_started_ms);
    fprintf(stream, "generation=%d\n", meta->generation);
    int write_error = 0;
    if (fflush(stream) != 0) {
        write_error = -1;
    }
    if (fsync(fileno(stream)) != 0) {
        write_error = -1;
    }
    if (fclose(stream) != 0) {
        write_error = -1;
    }
    if (write_error != 0) {
        unlink(temporary);
        return -1;
    }
    if (rename(temporary, path) != 0) {
        unlink(temporary);
        return -1;
    }
    return 0;
}

static int read_meta(const char *state_dir, FlowMeta *meta) {
    char path[PATH_MAX];
    char line[MAX_LINE];
    int schema = 0;
    memset(meta, 0, sizeof(*meta));
    if (path_join(path, sizeof(path), state_dir, "meta") != 0) {
        return -1;
    }
    FILE *stream = fopen(path, "r");
    if (stream == NULL) {
        return -1;
    }
    while (fgets(line, sizeof(line), stream) != NULL) {
        char *newline = strchr(line, '\n');
        if (newline != NULL) {
            *newline = '\0';
        }
        char *equals = strchr(line, '=');
        if (equals == NULL) {
            continue;
        }
        *equals = '\0';
        const char *key = line;
        const char *value = equals + 1;
        if (strcmp(key, "schema") == 0) {
            schema = atoi(value);
        } else if (strcmp(key, "task_id") == 0) {
            snprintf(meta->task_id, sizeof(meta->task_id), "%s", value);
        } else if (strcmp(key, "task_class") == 0) {
            snprintf(meta->task_class, sizeof(meta->task_class), "%s", value);
        } else if (strcmp(key, "archive_mode") == 0) {
            snprintf(meta->archive_mode, sizeof(meta->archive_mode), "%s", value);
        } else if (strcmp(key, "status") == 0) {
            snprintf(meta->status, sizeof(meta->status), "%s", value);
        } else if (strcmp(key, "overhead_target_percent") == 0 ||
                   strcmp(key, "budget_percent") == 0) {
            meta->overhead_target_percent = atoi(value);
        } else if (strcmp(key, "started_ms") == 0) {
            meta->started_ms = strtoll(value, NULL, 10);
        } else if (strcmp(key, "initial_work_ms") == 0) {
            meta->initial_work_ms = strtoll(value, NULL, 10);
        } else if (strcmp(key, "gate_ms") == 0) {
            meta->gate_ms = strtoll(value, NULL, 10);
        } else if (strcmp(key, "paused_ms") == 0) {
            meta->paused_ms = strtoll(value, NULL, 10);
        } else if (strcmp(key, "pause_started_ms") == 0) {
            meta->pause_started_ms = strtoll(value, NULL, 10);
        } else if (strcmp(key, "generation") == 0) {
            meta->generation = atoi(value);
        }
    }
    fclose(stream);
    if (schema != FLOW_SCHEMA || !valid_token(meta->task_id, sizeof(meta->task_id)) ||
        !valid_class(meta->task_class) || meta->overhead_target_percent < 1 ||
        meta->overhead_target_percent > 100 || meta->started_ms <= 0 ||
        meta->initial_work_ms < 0 || meta->gate_ms < 0 ||
        meta->paused_ms < 0 || meta->generation < 1 ||
        !(strcmp(meta->archive_mode, "none") == 0 ||
          strcmp(meta->archive_mode, "compact") == 0 ||
          strcmp(meta->archive_mode, "durable") == 0)) {
        return -1;
    }
    return 0;
}

static int append_event(const char *state_dir, const char *kind, const char *detail) {
    char path[PATH_MAX];
    char timestamp[32];
    if (strchr(detail, '\n') != NULL || strchr(detail, '\r') != NULL) {
        return -1;
    }
    if (path_join(path, sizeof(path), state_dir, "events.log") != 0) {
        return -1;
    }
    FILE *stream = fopen(path, "a");
    if (stream == NULL) {
        return -1;
    }
    iso8601_now(timestamp, sizeof(timestamp));
    fprintf(stream, "%s\t%s\t%s\n", timestamp, kind, detail);
    return fclose(stream);
}

static int load_lines(const char *path, StringList *list) {
    char line[MAX_ENTRY];
    memset(list, 0, sizeof(*list));
    FILE *stream = fopen(path, "r");
    if (stream == NULL) {
        return errno == ENOENT ? 0 : -1;
    }
    while (fgets(line, sizeof(line), stream) != NULL) {
        char *end = line + strlen(line);
        while (end > line && (end[-1] == '\n' || end[-1] == '\r')) {
            *--end = '\0';
        }
        if (*line == '\0') {
            continue;
        }
        if (list->count >= MAX_ITEMS) {
            fclose(stream);
            return -1;
        }
        snprintf(list->values[list->count], MAX_ENTRY, "%s", line);
        ++list->count;
    }
    return fclose(stream);
}

static int list_contains(const StringList *list, const char *value) {
    for (size_t i = 0; i < list->count; ++i) {
        if (strcmp(list->values[i], value) == 0) {
            return 1;
        }
    }
    return 0;
}

static int list_add(StringList *list, const char *value) {
    if (list_contains(list, value)) {
        return 0;
    }
    if (list->count >= MAX_ITEMS || strlen(value) >= MAX_ENTRY) {
        return -1;
    }
    snprintf(list->values[list->count], MAX_ENTRY, "%s", value);
    ++list->count;
    return 1;
}

static int append_unique_line(const char *path, const char *value) {
    StringList list;
    if (load_lines(path, &list) != 0) {
        return -1;
    }
    if (list_contains(&list, value)) {
        return 0;
    }
    FILE *stream = fopen(path, "a");
    if (stream == NULL) {
        return -1;
    }
    fprintf(stream, "%s\n", value);
    if (fclose(stream) != 0) {
        return -1;
    }
    return 1;
}

static void directory_for_path(const char *path, char *directory, size_t size) {
    snprintf(directory, size, "%s", path);
    char *slash = strrchr(directory, '/');
    if (slash == NULL) {
        snprintf(directory, size, ".");
    } else {
        *slash = '\0';
    }
}

static const GateDef *find_gate(const char *id) {
    size_t count = sizeof(GATES) / sizeof(GATES[0]);
    for (size_t i = 0; i < count; ++i) {
        if (strcmp(GATES[i].id, id) == 0) {
            return &GATES[i];
        }
    }
    return NULL;
}

static int starts_with(const char *value, const char *prefix) {
    return strncmp(value, prefix, strlen(prefix)) == 0;
}

static int ends_with(const char *value, const char *suffix) {
    size_t value_length = strlen(value);
    size_t suffix_length = strlen(suffix);
    return value_length >= suffix_length &&
           strcmp(value + value_length - suffix_length, suffix) == 0;
}

static int is_allowed_build_description(const char *path) {
    return strcmp(path,
                  "tool/softfloat/build/Linux-x86_64-GCC/.gitignore") == 0 ||
           strcmp(path,
                  "tool/softfloat/build/Linux-x86_64-GCC/Makefile") == 0 ||
           strcmp(path,
                  "tool/softfloat/build/Linux-x86_64-GCC/platform.h") == 0 ||
           starts_with(
               path,
               "ysyxSoC/rocket-chip/dependencies/chisel/.github/workflows/"
               "build-scala-cli-template/");
}

static int has_generated_directory_component(const char *path) {
    const char *component = path;
    while (*component != '\0') {
        const char *slash = strchr(component, '/');
        size_t length = slash == NULL ? strlen(component)
                                      : (size_t)(slash - component);
        if ((length == strlen("build") &&
             strncmp(component, "build", length) == 0) ||
            (length == strlen("obj_dir") &&
             strncmp(component, "obj_dir", length) == 0) ||
            (length == strlen("CMakeFiles") &&
             strncmp(component, "CMakeFiles", length) == 0) ||
            (length == strlen("__pycache__") &&
             strncmp(component, "__pycache__", length) == 0)) {
            return 1;
        }
        /* build-*.py/build_helper.c 等源码文件不是目录；只有后续仍有
         * path component 时才把 build-/build_ 前缀视作二级产物目录。 */
        if (slash != NULL && length > strlen("build-") &&
            (strncmp(component, "build-", strlen("build-")) == 0 ||
             strncmp(component, "build_", strlen("build_")) == 0)) {
            return 1;
        }
        if (slash == NULL) {
            break;
        }
        component = slash + 1;
    }
    return 0;
}

static int is_regenerable_source_artifact(const char *path) {
    if (is_allowed_build_description(path)) {
        return 0;
    }
    return has_generated_directory_component(path) ||
           ends_with(path, ".pyc") || ends_with(path, ".pyo") ||
           ends_with(path, ".pyd") ||
           ends_with(path, ".o") || ends_with(path, ".vvp") ||
           ends_with(path, ".vcd") || ends_with(path, ".fst") ||
           ends_with(path, ".fsdb") || ends_with(path, ".wlf") ||
           ends_with(path, ".vpd") || ends_with(path, ".ghw");
}

static int is_environment_surface(const char *path) {
    return strcmp(path, "AGENTS.md") == 0 ||
           strcmp(path, "AI_ENVIRONMENT.md") == 0 ||
           strcmp(path, ".github/AGENTS.md") == 0 ||
           strcmp(path, ".github/copilot-instructions.md") == 0 ||
           starts_with(path, ".github/ai-env/") ||
           starts_with(path, ".github/agents/") ||
           starts_with(path, ".github/e2e/") ||
           starts_with(path, ".github/skills/") ||
           starts_with(path, ".github/instructions/agent-") ||
           strcmp(path,
                  ".github/instructions/rv64-ppa-optimization-workflow.instructions.md") == 0 ||
           starts_with(path, ".github/workflows/agent-") ||
           strcmp(path,
                  "npc/rv64/design/arch/rv64-soc-delivery-gates.tsv") == 0 ||
           strcmp(path,
                  "npc/rv64/design/arch/rv64-soc-maturity-stages.tsv") == 0 ||
           starts_with(path, "scripts/agent-") ||
           strcmp(path, "scripts/check-rv64-soc-delivery-gates.sh") == 0 ||
           strcmp(path, "scripts/tests/test-rv64-soc-delivery-gates.sh") == 0 ||
           starts_with(path, "scripts/e2e/") ||
           starts_with(path, "scripts/dev_memory/") ||
           strcmp(path, "scripts/github_index_db.py") == 0;
}

static int is_ordinary_documentation_path(const char *path) {
    int documentation_suffix = ends_with(path, ".md") ||
                               ends_with(path, ".rst") ||
                               ends_with(path, ".adoc") ||
                               ends_with(path, ".txt");
    if (!documentation_suffix || is_environment_surface(path)) {
        return 0;
    }
    /* ROADMAP mirrors machine authorities; editing its narration is not a
       request to rebuild a stale current-design receipt. */
    if (strcmp(path, "npc/rv64/design/arch/ROADMAP.md") == 0) {
        return 1;
    }
    /* Architecture contracts remain evidence-bearing even when Markdown. */
    if (starts_with(path, "npc/rv64/design/arch/") ||
        starts_with(path, ".github/runtime-artifacts/")) {
        return 0;
    }
    if (starts_with(path, ".github/task-runs/")) {
        return ends_with(path, "/delivery-summary.md") ||
               ends_with(path, "/dispatch-log.md");
    }
    return 1;
}

static int add_gate(StringList *gates, const char *id) {
    if (find_gate(id) == NULL) {
        fprintf(stderr, "[agent-flow] unknown gate pointer: %s\n", id);
        return -1;
    }
    return list_add(gates, id) < 0 ? -1 : 0;
}

static int normalize_gate_dependencies(StringList *gates) {
    StringList normalized;
    int owner_timing_link = list_contains(gates, "rv64-owner-timing-link");
    int memory_request_hold_link =
        list_contains(gates, "rv64-memory-request-hold-link");
    memset(&normalized, 0, sizeof(normalized));
    for (size_t i = 0; i < gates->count; ++i) {
        const char *id = gates->values[i];
        if (owner_timing_link && strcmp(id, "rv64-owner-timing-fast") == 0) {
            continue;
        }
        if (memory_request_hold_link &&
            strcmp(id, "rv64-memory-request-hold-fast") == 0) {
            continue;
        }
        if (add_gate(&normalized, id) != 0) {
            return -1;
        }
    }
    *gates = normalized;
    return 0;
}

static int derive_gates(const FlowMeta *meta, const StringList *paths,
                        const StringList *explicit_gates, StringList *gates) {
    memset(gates, 0, sizeof(*gates));
    if (strcmp(meta->task_class, "review") == 0 ||
        strcmp(meta->task_class, "analysis") == 0) {
        return 0;
    }
    if (strcmp(meta->task_class, "release") == 0) {
        return add_gate(gates, "maintain-release");
    }
    for (size_t i = 0; i < explicit_gates->count; ++i) {
        if (add_gate(gates, explicit_gates->values[i]) != 0) {
            return -1;
        }
    }
    for (size_t i = 0; i < paths->count; ++i) {
        const char *path = paths->values[i];
        /* 可再生编译物只属于源码树清洁面。先短路能避免历史 task-run
         * 目录名把 __pycache__/build/ 清理误路由到架构 current receipt。 */
        if (is_regenerable_source_artifact(path)) {
            if (add_gate(gates, "source-artifact-hygiene") != 0) {
                return -1;
            }
            continue;
        }
        if (strcmp(meta->task_class, "docs") == 0 &&
            is_ordinary_documentation_path(path)) {
            continue;
        }
        if (strcmp(path, ".gitignore") == 0 ||
            strcmp(path, "scripts/check-source-tree-artifact-hygiene.sh") == 0 ||
            strcmp(path,
                   "scripts/tests/test-source-tree-artifact-hygiene.sh") == 0) {
            if (add_gate(gates, "source-artifact-hygiene") != 0) {
                return -1;
            }
        }
        if (strcmp(path, "scripts/agent-flow.c") == 0 ||
            strcmp(path, "scripts/agent-flow.sh") == 0 ||
            strcmp(path, "scripts/tests/test-agent-flow.sh") == 0 ||
            strcmp(path,
                   ".github/instructions/agent-lightweight-workflow.instructions.md") == 0) {
            if (add_gate(gates, "flow-self-test") != 0) {
                return -1;
            }
        }
        if (strcmp(path,
                   ".github/instructions/rv64-ppa-optimization-workflow.instructions.md") == 0 ||
            strcmp(path,
                   "npc/rv64/design/arch/rv64-soc-delivery-gates.tsv") == 0 ||
            strcmp(path,
                   "npc/rv64/design/arch/rv64-soc-maturity-stages.tsv") == 0 ||
            strcmp(path, "scripts/check-rv64-soc-delivery-gates.sh") == 0 ||
            strcmp(path, "scripts/tests/test-rv64-soc-delivery-gates.sh") == 0) {
            if (add_gate(gates, "rv64-soc-delivery-gates") != 0) {
                return -1;
            }
        }
        if (strcmp(path, "npc/rv64/ARCHITECTURE.md") == 0 ||
            strcmp(path,
                   "npc/rv64/design/arch/rv64-architecture-registry-v1.json") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/schemas/rv64-architecture-registry-v1.schema.json") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/tools/architecture_registry.py") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/tests/test_architecture_registry.py") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/evidence/architecture-registry-elaboration-current.json") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/run-traceable-mapped-current.sh") == 0) {
            if (add_gate(gates, "rv64-architecture-registry") != 0) {
                return -1;
            }
        }
        if (strcmp(path,
                   "npc/rv64/design/arch/full-core-functional-run-policy-v1.json") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/run-full-core-current.sh") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/tools/full_core_current_evidence.py") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/tools/full_core_functional_evidence.py") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/tools/functional_aggregate.py") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/tools/arch_stable_freeze.py") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/schemas/functional-aggregate-v2.schema.json") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/schemas/functional-aggregate-result-v1.schema.json") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/schemas/difftest-reference-profile-v1.schema.json") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/tools/architecture_hard_gates.py") == 0 ||
            strcmp(path,
                   "npc/rv64/testsuites/scripts/npc-rv64-core-regress.sh") == 0 ||
            strcmp(path,
                   "am-kernels/tests/cpu-tests/scripts/check_results.py") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/tests/test_full_core_current_evidence.py") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/tests/test_full_core_functional_evidence.py") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/tests/test_full_core_runner_entry.py") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/replay-full-core-functional-current.sh") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/tools/full_core_functional_replay.py") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/tests/test_full_core_functional_replay.py") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/tests/test_functional_aggregate.py") == 0 ||
            strcmp(path,
                   ".github/task-runs/2026-07-22-rv64-v9l-functional-aggregate-current-design/run-functional-aggregate.py") == 0 ||
            strcmp(path,
                   ".github/task-runs/2026-07-22-rv64-v9l-functional-aggregate-current-design/run-focused.sh") == 0 ||
            strcmp(path, "abstract-machine/Makefile") == 0 ||
            strcmp(path, "abstract-machine/am/Makefile") == 0 ||
            strcmp(path, "abstract-machine/klib/Makefile") == 0 ||
            strcmp(path, "am-kernels/benchmarks/coremark/Makefile") == 0 ||
            strcmp(path, "am-kernels/benchmarks/dhrystone/Makefile") == 0 ||
            strcmp(path, "am-kernels/tests/cpu-tests/Makefile") == 0 ||
            strcmp(path, "nemu/Makefile") == 0 ||
            strcmp(path, "abstract-machine/scripts/riscv64-npc.mk") == 0 ||
            strcmp(path, "abstract-machine/scripts/platform/npc.mk") == 0 ||
            strcmp(path, "npc/rv64/Makefile") == 0) {
            if (add_gate(gates, "rv64-full-core-runner-contract") != 0) {
                return -1;
            }
        }
        if (strcmp(path,
                   "npc/rv64/design/arch/system-recertification-run-policy-v1.json") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/run-system-recertification-current.sh") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/tools/system_recertification_run.py") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/tools/architecture_hard_gates.py") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/tests/test_system_recertification_runner.py") == 0 ||
            strcmp(path, "Linux/scripts/check-ubuntu-rootfs.sh") == 0 ||
            strcmp(path, "Linux/scripts/check-npc-systemd-guest.sh") == 0 ||
            strcmp(path, "Linux/scripts/npc-systemd-strict-check.sh") == 0 ||
            strcmp(path,
                   "Linux/scripts/npc_systemd_transaction_evidence.py") == 0 ||
            strcmp(path,
                   "Linux/scripts/prepare-npc-rootfs-run-image.sh") == 0 ||
            strcmp(path,
                   "Linux/scripts/tests/test_npc_systemd_strict_check.py") == 0 ||
            strcmp(path,
                   "Linux/scripts/tests/test_check_npc_systemd_guest_contract.py") == 0 ||
            strcmp(path,
                   "Linux/scripts/tests/test_npc_systemd_transaction_evidence.py") == 0 ||
            strcmp(path,
                   "npc/rv64/testbench/scripts/test_debug_ooo_flags_contract.py") == 0 ||
            strcmp(path, "npc/rv64/configs/default_defconfig") == 0 ||
            strcmp(path, "npc/rv64/configs/product-rtl-defaults.mk") == 0) {
            if (add_gate(gates,
                         "rv64-system-recertification-runner-contract") != 0) {
                return -1;
            }
        }
        if (strcmp(path,
                   "npc/rv64/eval/ppa/build-current-simulator-cache.sh") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/rv64-simulator-source-id.sh") == 0 ||
            strcmp(path, "npc/rv64/vsrc/sim/NpcSimTop.sv") == 0 ||
            strcmp(path, "npc/rv64/csrc/dpi.c") == 0) {
            if (add_gate(gates,
                         "rv64-current-simulator-cache-contract") != 0) {
                return -1;
            }
        }
        if (strcmp(path,
                   "npc/rv64/design/arch/layered-system-signoff-policy-v1.json") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/run-mini-system-current.sh") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/build-current-simulator-cache.sh") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/rv64-simulator-source-id.sh") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/rv64-layer-source-id.sh") == 0 ||
            strcmp(path, "npc/rv64/vsrc/sim/NpcSimTop.sv") == 0 ||
            strcmp(path, "npc/rv64/csrc/dpi.c") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/replay-layer-checker-current.sh") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/tools/mini_system_run.py") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/tests/test_mini_system_run.py") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/tools/architecture_hard_gates.py") == 0 ||
            strcmp(path,
                   "Linux/mini-system/rv64-l2-payload.S") == 0 ||
            strcmp(path,
                   "Linux/mini-system/rv64-l2-payload.ld") == 0 ||
            strcmp(path,
                   "Linux/scripts/build-rv64-mini-system.sh") == 0 ||
            strcmp(path, "Linux/scripts/build-opensbi.sh") == 0 ||
            strcmp(path, "Linux/platform/gen_dts.py") == 0 ||
            strcmp(path, "Linux/platform/common-rv64.yml") == 0 ||
            strcmp(path, "Linux/platform/npc-rv64.yml") == 0) {
            if (add_gate(gates,
                         "rv64-mini-system-runner-contract") != 0) {
                return -1;
            }
        }
        if (strcmp(path,
                   "npc/rv64/design/arch/layered-system-signoff-policy-v1.json") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/run-lightweight-linux-current.sh") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/build-current-simulator-cache.sh") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/rv64-simulator-source-id.sh") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/rv64-layer-source-id.sh") == 0 ||
            strcmp(path, "npc/rv64/vsrc/sim/NpcSimTop.sv") == 0 ||
            strcmp(path, "npc/rv64/csrc/dpi.c") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/replay-layer-checker-current.sh") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/tools/lightweight_linux_run.py") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/tests/test_lightweight_linux_run.py") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/tools/architecture_hard_gates.py") == 0 ||
            strcmp(path,
                   "Linux/lightweight/rv64-l3-kernel.config") == 0 ||
            strcmp(path,
                   "Linux/lightweight/rv64-l3-init.c") == 0 ||
            strcmp(path,
                   "Linux/scripts/build-rv64-lightweight-linux.sh") == 0 ||
            strcmp(path,
                   "Linux/scripts/check-rv64-lightweight-linux-config.sh") == 0 ||
            strcmp(path, "Linux/scripts/build-opensbi.sh") == 0 ||
            strcmp(path, "Linux/platform/gen_dts.py") == 0 ||
            strcmp(path, "Linux/platform/common-rv64.yml") == 0 ||
            strcmp(path, "Linux/platform/npc-rv64.yml") == 0) {
            if (add_gate(gates,
                         "rv64-lightweight-linux-runner-contract") != 0) {
                return -1;
            }
        }
        if (strcmp(path,
                   "npc/rv64/design/arch/layered-system-signoff-policy-v1.json") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/tools/layered_system_signoff.py") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/tools/system_recertification_current.py") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/tests/test_layered_system_signoff.py") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/tests/test_system_recertification_current.py") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/schemas/layered-system-signoff-current-v1.schema.json") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/evidence/layered-system-signoff-current.json") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/evidence/system-recertification-current.json") == 0) {
            if (add_gate(gates,
                         "rv64-layered-system-signoff-current") != 0) {
                return -1;
            }
        }
        if (strcmp(path, "npc/rv64/vsrc/execute/OooIntBackend.v") == 0 ||
            strcmp(path,
                   "npc/rv64/vsrc/memory/OooMemOwnerTerminalCollector.v") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/tools/terminal_collector_lane_contract.py") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/tests/test_terminal_collector_lane_contract.py") == 0) {
            if (add_gate(gates,
                         "rv64-terminal-collector-lane-contract") != 0) {
                return -1;
            }
        }
        if (strcmp(path,
                   "npc/rv64/design/arch/historical-defect-backfill-ledger.json") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/schemas/historical-defect-backfill-ledger-v1.schema.json") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/tests/test_historical_defect_backfill.py") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/tools/historical_defect_backfill.py") == 0) {
            if (add_gate(gates,
                         "rv64-historical-defect-ledger-audit") != 0) {
                return -1;
            }
        }
        if (strcmp(path,
                   "npc/rv64/eval/ppa/schemas/historical-defect-current-v1.schema.json") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/tests/test_historical_defect_current.py") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/tools/historical_defect_current.py") == 0) {
            if (add_gate(gates,
                         "rv64-historical-defect-current-contract") != 0) {
                return -1;
            }
        }
        if (strcmp(path, "npc/rv64/design/arch/architecture-debt-ledger.json") == 0 ||
            strcmp(path,
                   "npc/rv64/design/arch/full-core-cohort-scope-v1.md") == 0 ||
            strcmp(path,
                   "npc/rv64/design/arch/producer-holder-semantic-coverage.json") == 0 ||
            starts_with(path, "npc/rv64/design/arch/cohort/") ||
            starts_with(path,
                        ".github/task-runs/2026-08-02-rv64-v14c-p0-transitive-current-rebind-v1/") ||
            starts_with(path,
                        ".github/task-runs/2026-08-02-rv64-v14d-p1-direct-current-rebind-v1/") ||
            starts_with(path,
                        ".github/task-runs/2026-08-02-rv64-v14e-p1-remaining-current-rebind-v1/") ||
            strcmp(path,
                   "npc/rv64/eval/ppa/architecture-debt-current-evidence.mk") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/evidence/architecture-debt-current.json") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/evidence/architecture-debt-delta-rebind-current.json") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/evidence/global-producer-no-live-reuse-current.json") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/evidence/system-recertification-checker-replay-current.json") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/evidence/system-recertification-checker-tests.log") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/schemas/architecture-debt-current-v1.schema.json") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/schemas/architecture-debt-current-v2.schema.json") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/tests/test_architecture_debt_current.py") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/tests/test_architecture_debt_delta_rebind.py") == 0 ||
            strcmp(path,
                   "npc/rv64/testbench/scripts/run_architecture_delta_mutations.py") == 0 ||
            strcmp(path,
                   "npc/rv64/testbench/scripts/test_run_architecture_delta_mutations.py") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/tools/architecture_debt_current.py") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/tools/architecture_debt_delta_rebind.py") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/tools/architecture_hard_gates.py") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/tools/global_producer_no_live_reuse.py") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/tools/control_event_sq_retry_evidence.py") == 0 ||
            strcmp(path,
                   "npc/rv64/testbench/scripts/test_debug_ooo_flags_contract.py") == 0) {
            if (add_gate(gates, "rv64-architecture-debt-current") != 0) {
                return -1;
            }
        }
        if (starts_with(path,
                        ".github/task-runs/2026-07-20-rv64-v8l-global-producer-no-live-reuse/") ||
            starts_with(path,
                        ".github/task-runs/2026-07-27-rv64-v10e-current-design-system-recert/") ||
            starts_with(path,
                        ".github/task-runs/2026-07-28-rv64-v10f-a3-checker-replay-v2/") ||
            starts_with(path,
                        ".github/task-runs/2026-07-29-rv64-hist-ser-qh-stop-hold-drop/") ||
            starts_with(path,
                        ".github/task-runs/2026-07-29-rv64-hist-ser-qh-younger-store-cycle/") ||
            starts_with(path,
                        ".github/task-runs/2026-08-02-rv64-v14e-p1-remaining-current-rebind-v1/") ||
            starts_with(path,
                        ".github/task-runs/2026-08-04-rv64-v14k-arch-stable-current-baseline-v1/") ||
            starts_with(path,
                        ".github/runtime-artifacts/agent-flow/rv64-v14g-producer-owner-global-gate/") ||
            strcmp(path,
                   "npc/rv64/eval/ppa/historical-defect-current-evidence.mk") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/evidence/historical-defect-current.json") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/evidence/global-producer-no-live-reuse-current.json") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/tools/architecture_hard_gates.py") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/tools/global_producer_no_live_reuse.py") == 0 ||
            strcmp(path,
                   "npc/rv64/testbench/scripts/run_historical_exit_current.py") == 0) {
            if (add_gate(gates, "rv64-historical-defect-current") != 0) {
                return -1;
            }
        }
        if (strcmp(path, "scripts/agent-e2e.sh") == 0 ||
            starts_with(path, "scripts/e2e/") ||
            starts_with(path, ".github/e2e/")) {
            if (add_gate(gates, "profile-bindings") != 0) {
                return -1;
            }
        }
        if (strcmp(path, ".github/ai-env/contracts/agent-env-policy.json") == 0 ||
            strcmp(path, ".github/workflows/agent-maintain.yml") == 0) {
            if (add_gate(gates, "policy-audit") != 0) {
                return -1;
            }
        }
        if (strcmp(path, ".github/ai-env/contracts/agent-env-schema-contract.json") == 0 ||
            starts_with(path, "scripts/dev_memory/") ||
            strcmp(path, "scripts/github_index_db.py") == 0) {
            if (add_gate(gates, "schema-audit") != 0) {
                return -1;
            }
        }
        if (strcmp(path, ".github/ai-env/contracts/agent-env-runtime-artifacts.json") == 0 ||
            strcmp(path, "scripts/e2e/lib/report.sh") == 0) {
            if (add_gate(gates, "artifact-audit") != 0) {
                return -1;
            }
        }
        if (strcmp(path, ".github/ai-env/contracts/agent-env-delivery.json") == 0 ||
            strcmp(path, "scripts/package-ai-dev-env.sh") == 0) {
            if (add_gate(gates, "delivery-audit") != 0) {
                return -1;
            }
        }
        if (strcmp(path, ".github/ai-env/contracts/agent-env-observability.json") == 0) {
            if (add_gate(gates, "trace-audit") != 0) {
                return -1;
            }
        }
        if (strcmp(path, ".github/ai-env/contracts/agent-env-state-traceability.json") == 0 ||
            strcmp(path, ".github/instructions/agent-env-state-machine.instructions.md") == 0) {
            if (add_gate(gates, "state-audit") != 0) {
                return -1;
            }
        }
        if (starts_with(path, ".github/skills/")) {
            if (add_gate(gates, "skill-audit") != 0) {
                return -1;
            }
        }
        if (starts_with(path, ".github/skills/prepare-rtl-task-contract/") ||
            strcmp(path, ".github/ai-env/contracts/agent-env-rtl-task-contract.json") == 0 ||
            strcmp(path, ".github/instructions/rtl-agent-task-contract.instructions.md") == 0) {
            if (add_gate(gates, "rtl-task-contract") != 0) {
                return -1;
            }
        }
        if (strcmp(path, "scripts/task-run-status.sh") == 0 ||
            strcmp(path, "scripts/tests/test-task-run-status.sh") == 0) {
            /* 该 helper 是全核 runner 的 fail-closed 状态承重件；修改时同时
             * 复核入口接线，不能只测 helper 的孤立状态机。 */
            if (add_gate(gates, "rv64-full-core-runner-contract") != 0) {
                return -1;
            }
            if (add_gate(gates,
                         "rv64-system-recertification-runner-contract") != 0) {
                return -1;
            }
            if (add_gate(gates,
                         "rv64-mini-system-runner-contract") != 0) {
                return -1;
            }
            if (add_gate(gates,
                         "rv64-lightweight-linux-runner-contract") != 0) {
                return -1;
            }
            if (add_gate(gates, "task-run-status-test") != 0) {
                return -1;
            }
        }
        if (strcmp(path,
                   "npc/rv64/eval/ppa/tools/arch_stable_freeze.py") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/tools/arch_stable_current_candidate.py") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/tools/functional_archive_rehydrate.py") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/tests/test_arch_stable_freeze.py") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/tests/test_arch_stable_current_candidate.py") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/tests/test_functional_archive_rehydrate.py") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/schemas/arch-stable-independent-review-v1.schema.json") == 0) {
            if (add_gate(gates, "rv64-arch-stable-checker-contract") != 0) {
                return -1;
            }
        }
        if (strcmp(path,
                   "npc/rv64/eval/ppa/run-arch-stable-audit.sh") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/arch-stable/full-core-current.json") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/evidence/arch-stable-independent-review-current.json") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/evidence/arch-stable-current.json") == 0) {
            if (add_gate(gates, "rv64-arch-stable-current") != 0) {
                return -1;
            }
        }
        if (starts_with(path,
                        "npc/rv64/eval/ppa/instrumentation/owner-timing") ||
            starts_with(path,
                        "npc/rv64/eval/ppa/instrumentation/owner_timing") ||
            strcmp(path,
                   "npc/rv64/eval/ppa/instrumentation/NpcOooOwnerTimingProbe.sv") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/instrumentation/check-owner-timing.sh") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/run-owner-timing-diagnostics.sh") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/run-owner-timing-workload-ab.sh") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/replay-owner-timing-link.sh") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/replay-owner-timing-invalid-probe.sh") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/tools/owner_timing_workload_ab.py") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/tests/test_owner_timing_workload_ab.py") == 0) {
            if (add_gate(gates, "rv64-owner-timing-fast") != 0) {
                return -1;
            }
        }
        if (strcmp(path,
                   "npc/rv64/design/arch/optimization-slice-selector-policy-v1.json") == 0 ||
            strcmp(path,
                   "npc/rv64/design/arch/rv64-architecture-ppa-contract.md") == 0 ||
            strcmp(path,
                   "npc/rv64/design/arch/rv64-soc-maturity-stages.tsv") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/optimization-slices-current.json") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/policies/proxy-200mhz-v1.json") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/baselines/index.json") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/evidence/architecture-debt-current.json") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/evidence/historical-defect-current.json") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/evidence/arch-stable-current.json") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/evidence/layered-system-signoff-current.json") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/evidence/performance-baseline-current.json") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/evidence/cpi-bottleneck-census-current.json") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/evidence/optimization-slice-current.json") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/schemas/optimization-slice-decision-v1.schema.json") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/tools/performance_baseline_current.py") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/tools/performance_bottleneck_census.py") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/tools/owner_timing_workload_ab.py") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/tools/check.py") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/tools/optimization_slice_selector.py") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/tests/test_performance_bottleneck_census.py") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/tests/test_optimization_slice_selector.py") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/run-performance-bottleneck-census.sh") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/run-optimization-slice-selector.sh") == 0 ||
            strcmp(path,
                   "npc/rv64/eval/ppa/README.md") == 0 ||
            strcmp(path,
                   ".github/instructions/rv64-ppa-optimization-workflow.instructions.md") == 0 ||
            strcmp(path, ".github/agentic-hardware-blueprint.md") == 0) {
            if (add_gate(gates, "rv64-optimization-slice-selector") != 0) {
                return -1;
            }
        }
        if (strcmp(path, "npc/rv64/vsrc/execute/OooIntBackend.v") == 0 ||
            strcmp(path,
                   "npc/rv64/testbench/tests/tb_ooo_int_backend.sv") == 0 ||
            strcmp(path, "npc/rv64/testbench/Makefile") == 0 ||
            strcmp(path,
                   "npc/rv64/design/specs/ooo-memory-request-admission-hold.md") == 0 ||
            strcmp(path,
                   "npc/rv64/testbench/scripts/run_v14r_memory_request_hold_mutation.sh") == 0 ||
            strcmp(path,
                   "npc/rv64/testbench/scripts/check_v14r_memory_request_hold.sh") == 0) {
            if (add_gate(gates, "rv64-memory-request-hold-fast") != 0) {
                return -1;
            }
        }
    }
    return normalize_gate_dependencies(gates);
}

static int count_pass_evidence(const char *state_dir, const char *required_name) {
    char path[PATH_MAX];
    char line[MAX_LINE];
    int count = 0;
    if (path_join(path, sizeof(path), state_dir, "evidence.tsv") != 0) {
        return 0;
    }
    FILE *stream = fopen(path, "r");
    if (stream == NULL) {
        return 0;
    }
    while (fgets(line, sizeof(line), stream) != NULL) {
        char *save = NULL;
        char *timestamp = strtok_r(line, "\t", &save);
        char *name = strtok_r(NULL, "\t", &save);
        char *status = strtok_r(NULL, "\t", &save);
        (void)timestamp;
        if (name != NULL && status != NULL && strcmp(status, "PASS") == 0 &&
            (required_name == NULL || strcmp(name, required_name) == 0)) {
            ++count;
        }
    }
    fclose(stream);
    return count;
}

static int validate_completion_inputs(const FlowMeta *meta, const StringList *paths,
                                      const char *state_dir, char *reason, size_t reason_size) {
    if ((strcmp(meta->task_class, "review") == 0 ||
         strcmp(meta->task_class, "analysis") == 0 ||
         strcmp(meta->task_class, "verification") == 0) &&
        paths->count != 0) {
        snprintf(reason, reason_size, "class=%s forbids source modifications", meta->task_class);
        return -1;
    }
    if (strcmp(meta->task_class, "environment") != 0 &&
        strcmp(meta->task_class, "release") != 0) {
        for (size_t i = 0; i < paths->count; ++i) {
            if (is_environment_surface(paths->values[i])) {
                snprintf(reason, reason_size,
                         "path=%s requires class=environment or release", paths->values[i]);
                return -1;
            }
        }
    }
    if (strcmp(meta->task_class, "development") == 0 && paths->count > 0 &&
        count_pass_evidence(state_dir, NULL) == 0) {
        snprintf(reason, reason_size, "development modifications require one PASS evidence record");
        return -1;
    }
    if (strcmp(meta->task_class, "verification") == 0 &&
        count_pass_evidence(state_dir, NULL) == 0) {
        snprintf(reason, reason_size, "verification requires one PASS evidence record");
        return -1;
    }
    if (strcmp(meta->task_class, "longrun") == 0 &&
        count_pass_evidence(state_dir, "task-run-status") == 0) {
        snprintf(reason, reason_size, "longrun requires task-run-status PASS evidence");
        return -1;
    }
    if (strcmp(meta->task_class, "cleanup") == 0 &&
        (count_pass_evidence(state_dir, "cleanup-preview") == 0 ||
         count_pass_evidence(state_dir, "cleanup-result") == 0)) {
        snprintf(reason, reason_size,
                 "cleanup requires cleanup-preview and cleanup-result PASS evidence");
        return -1;
    }
    snprintf(reason, reason_size, "ok");
    return 0;
}

static int64_t current_work_ms(const FlowMeta *meta, int64_t now_ms) {
    int64_t active_pause = 0;
    if (meta->pause_started_ms > 0 && now_ms > meta->pause_started_ms) {
        active_pause = now_ms - meta->pause_started_ms;
    }
    int64_t work = meta->initial_work_ms + (now_ms - meta->started_ms) -
                   meta->gate_ms - meta->paused_ms - active_pause;
    return work > 0 ? work : 0;
}

static int gate_pass_for_generation(const char *state_dir, const char *gate_id,
                                    int generation, GateResult *result) {
    char path[PATH_MAX];
    char line[MAX_LINE];
    if (path_join(path, sizeof(path), state_dir, "gate-status.tsv") != 0) {
        return 0;
    }
    FILE *stream = fopen(path, "r");
    if (stream == NULL) {
        return 0;
    }
    int found = 0;
    while (fgets(line, sizeof(line), stream) != NULL) {
        char *save = NULL;
        char *raw_generation = strtok_r(line, "\t", &save);
        char *raw_id = strtok_r(NULL, "\t", &save);
        char *raw_status = strtok_r(NULL, "\t", &save);
        char *raw_elapsed = strtok_r(NULL, "\t", &save);
        char *raw_log = strtok_r(NULL, "\t\r\n", &save);
        if (raw_generation == NULL || raw_id == NULL || raw_status == NULL ||
            raw_elapsed == NULL || raw_log == NULL) {
            continue;
        }
        if (atoi(raw_generation) == generation && strcmp(raw_id, gate_id) == 0 &&
            strcmp(raw_status, "PASS") == 0) {
            snprintf(result->id, sizeof(result->id), "%s", raw_id);
            snprintf(result->status, sizeof(result->status), "%s", raw_status);
            result->elapsed_ms = strtoll(raw_elapsed, NULL, 10);
            snprintf(result->log_path, sizeof(result->log_path), "%s", raw_log);
            result->reused = 1;
            found = 1;
        }
    }
    fclose(stream);
    return found;
}

static int append_gate_status(const char *state_dir, int generation,
                              const GateResult *result) {
    char path[PATH_MAX];
    if (path_join(path, sizeof(path), state_dir, "gate-status.tsv") != 0) {
        return -1;
    }
    FILE *stream = fopen(path, "a");
    if (stream == NULL) {
        return -1;
    }
    fprintf(stream, "%d\t%s\t%s\t%lld\t%s\n", generation, result->id,
            result->status, (long long)result->elapsed_ms, result->log_path);
    return fclose(stream);
}

static int run_gate(const char *repo_root, const char *state_dir, const GateDef *gate,
                    int64_t timeout_ms, GateResult *result) {
    char logs_dir[PATH_MAX];
    char absolute_log[PATH_MAX];
    char relative_log[PATH_MAX];
    if (path_join(logs_dir, sizeof(logs_dir), state_dir, "gates") != 0 ||
        mkdir_p(logs_dir) != 0) {
        return -1;
    }
    int written = snprintf(absolute_log, sizeof(absolute_log), "%s/%s.log", logs_dir, gate->id);
    if (written < 0 || (size_t)written >= sizeof(absolute_log)) {
        return -1;
    }
    const char *relative = strstr(absolute_log, "/.github/");
    snprintf(relative_log, sizeof(relative_log), "%s",
             relative != NULL ? relative + 1 : absolute_log);

    int descriptor = open(absolute_log, O_CREAT | O_WRONLY | O_TRUNC, 0664);
    if (descriptor < 0) {
        return -1;
    }
    int64_t started = monotonic_ms();
    pid_t child = fork();
    if (child < 0) {
        close(descriptor);
        return -1;
    }
    if (child == 0) {
        setpgid(0, 0);
        if (chdir(repo_root) != 0 || dup2(descriptor, STDOUT_FILENO) < 0 ||
            dup2(descriptor, STDERR_FILENO) < 0) {
            _exit(126);
        }
        close(descriptor);
        execl("/bin/sh", "sh", "-c", gate->command, (char *)NULL);
        _exit(127);
    }
    close(descriptor);
    setpgid(child, child);

    int status = 0;
    int timed_out = 0;
    for (;;) {
        pid_t waited = waitpid(child, &status, WNOHANG);
        if (waited == child) {
            break;
        }
        if (waited < 0) {
            return -1;
        }
        int64_t now = monotonic_ms();
        if (now < 0 || now - started >= timeout_ms) {
            timed_out = 1;
            kill(-child, SIGTERM);
            struct timespec grace = {.tv_sec = 0, .tv_nsec = 200000000L};
            nanosleep(&grace, NULL);
            if (waitpid(child, &status, WNOHANG) == 0) {
                kill(-child, SIGKILL);
            }
            waitpid(child, &status, 0);
            break;
        }
        struct timespec interval = {.tv_sec = 0, .tv_nsec = 50000000L};
        nanosleep(&interval, NULL);
    }
    int64_t ended = monotonic_ms();
    memset(result, 0, sizeof(*result));
    snprintf(result->id, sizeof(result->id), "%s", gate->id);
    snprintf(result->log_path, sizeof(result->log_path), "%s", relative_log);
    result->elapsed_ms = ended >= started ? ended - started : 0;
    if (timed_out) {
        snprintf(result->status, sizeof(result->status), "TIMEOUT");
        return 1;
    }
    if (WIFEXITED(status) && WEXITSTATUS(status) == 0) {
        snprintf(result->status, sizeof(result->status), "PASS");
        return 0;
    }
    snprintf(result->status, sizeof(result->status), "FAIL");
    return 1;
}

static int write_summary(const char *state_dir, const FlowMeta *meta,
                         const StringList *paths, const StringList *directories,
                         const StringList *gates, const GateResult *results,
                         size_t result_count, const char *result,
                         const char *reason) {
    char path[PATH_MAX];
    char temporary[PATH_MAX];
    int64_t now = realtime_ms();
    int64_t work_ms = current_work_ms(meta, now);
    double overhead = work_ms > 0 ? (100.0 * (double)meta->gate_ms / (double)work_ms) : 0.0;
    if (path_join(path, sizeof(path), state_dir, "summary.txt") != 0) {
        return -1;
    }
    int written = snprintf(temporary, sizeof(temporary), "%s.tmp.%ld", path, (long)getpid());
    if (written < 0 || (size_t)written >= sizeof(temporary)) {
        return -1;
    }
    FILE *stream = fopen(temporary, "w");
    if (stream == NULL) {
        return -1;
    }
    fprintf(stream, "AGENT_FLOW_V1\n");
    fprintf(stream, "RESULT=%s\n", result);
    fprintf(stream, "REASON=%s\n", reason);
    fprintf(stream, "TASK_ID=%s\n", meta->task_id);
    fprintf(stream, "TASK_CLASS=%s\n", meta->task_class);
    fprintf(stream, "ARCHIVE_MODE=%s\n", meta->archive_mode);
    fprintf(stream, "GENERATION=%d\n", meta->generation);
    fprintf(stream, "WORK_MS=%lld\n", (long long)work_ms);
    fprintf(stream, "GATE_MS=%lld\n", (long long)meta->gate_ms);
    fprintf(stream, "OVERHEAD_PERCENT=%.2f\n", overhead);
    fprintf(stream, "OVERHEAD_TARGET_PERCENT=%d\n",
            meta->overhead_target_percent);
    fprintf(stream, "PATH_COUNT=%zu\n", paths->count);
    fprintf(stream, "DIRECTORY_COUNT=%zu\n", directories->count);
    fprintf(stream, "GATE_COUNT=%zu\n", gates->count);
    for (size_t i = 0; i < directories->count; ++i) {
        fprintf(stream, "DIRECTORY_%zu=%s\n", i, directories->values[i]);
    }
    for (size_t i = 0; i < gates->count; ++i) {
        fprintf(stream, "PLANNED_GATE_%zu=%s\n", i, gates->values[i]);
    }
    for (size_t i = 0; i < result_count; ++i) {
        fprintf(stream, "GATE_%zu=%s:%s:%lld:%s%s\n", i, results[i].id,
                results[i].status, (long long)results[i].elapsed_ms,
                results[i].log_path, results[i].reused ? ":reused" : "");
    }
    fprintf(stream, "PATH_LOG=%s/paths.log\n", state_dir);
    fprintf(stream, "DIRECTORY_LOG=%s/directories.log\n", state_dir);
    fprintf(stream, "EVENT_LOG=%s/events.log\n", state_dir);
    char archive_path_file[PATH_MAX];
    char archive_path_value[PATH_MAX] = "pending";
    if (strcmp(meta->archive_mode, "none") == 0) {
        snprintf(archive_path_value, sizeof(archive_path_value), "none");
    } else if (path_join(archive_path_file, sizeof(archive_path_file),
                         state_dir, "archive.path") == 0) {
        FILE *archive_stream = fopen(archive_path_file, "r");
        if (archive_stream != NULL) {
            if (fgets(archive_path_value, sizeof(archive_path_value), archive_stream) != NULL) {
                archive_path_value[strcspn(archive_path_value, "\r\n")] = '\0';
            }
            fclose(archive_stream);
        }
    }
    fprintf(stream, "TASK_RUN=%s\n", archive_path_value);
    int write_error = 0;
    if (fflush(stream) != 0) {
        write_error = -1;
    }
    if (fsync(fileno(stream)) != 0) {
        write_error = -1;
    }
    if (fclose(stream) != 0) {
        write_error = -1;
    }
    if (write_error != 0) {
        unlink(temporary);
        return -1;
    }
    return rename(temporary, path);
}

static const char *default_archive_mode(const char *task_class) {
    if (strcmp(task_class, "development") == 0 ||
        strcmp(task_class, "environment") == 0 ||
        strcmp(task_class, "cleanup") == 0) {
        return "compact";
    }
    if (strcmp(task_class, "longrun") == 0 ||
        strcmp(task_class, "release") == 0) {
        return "durable";
    }
    return "none";
}

static int valid_archive_mode(const char *mode) {
    return strcmp(mode, "none") == 0 ||
           strcmp(mode, "compact") == 0 ||
           strcmp(mode, "durable") == 0;
}

static int copy_file_if_present(const char *source, const char *destination) {
    FILE *input = fopen(source, "rb");
    if (input == NULL) {
        return errno == ENOENT ? 0 : -1;
    }
    FILE *output = fopen(destination, "wb");
    if (output == NULL) {
        fclose(input);
        return -1;
    }
    char buffer[16384];
    size_t count;
    int rc = 0;
    while ((count = fread(buffer, 1, sizeof(buffer), input)) > 0) {
        if (fwrite(buffer, 1, count, output) != count) {
            rc = -1;
            break;
        }
    }
    int input_error = ferror(input);
    int input_close_error = fclose(input);
    int output_close_error = fclose(output);
    if (input_error || input_close_error != 0 || output_close_error != 0) {
        rc = -1;
    }
    return rc;
}

static int copy_bounded_log(const char *source, const char *destination, int64_t limit) {
    FILE *input = fopen(source, "rb");
    if (input == NULL) {
        return errno == ENOENT ? 0 : -1;
    }
    if (fseek(input, 0, SEEK_END) != 0) {
        fclose(input);
        return -1;
    }
    long size = ftell(input);
    if (size < 0 || fseek(input, 0, SEEK_SET) != 0) {
        fclose(input);
        return -1;
    }
    FILE *output = fopen(destination, "wb");
    if (output == NULL) {
        fclose(input);
        return -1;
    }
    char buffer[16384];
    int64_t head_limit = size > limit ? limit / 2 : size;
    int64_t copied = 0;
    int rc = 0;
    while (copied < head_limit) {
        size_t wanted = (size_t)((head_limit - copied) < (int64_t)sizeof(buffer)
                                     ? (head_limit - copied)
                                     : (int64_t)sizeof(buffer));
        size_t count = fread(buffer, 1, wanted, input);
        if (count == 0 || fwrite(buffer, 1, count, output) != count) {
            rc = -1;
            break;
        }
        copied += (int64_t)count;
    }
    if (rc == 0 && size > limit) {
        const char marker[] = "\n[agent-flow] ... bounded log middle omitted ...\n";
        int64_t tail_limit = limit - head_limit;
        if (fwrite(marker, 1, sizeof(marker) - 1, output) != sizeof(marker) - 1 ||
            fseek(input, size - (long)tail_limit, SEEK_SET) != 0) {
            rc = -1;
        }
        while (rc == 0 && tail_limit > 0) {
            size_t wanted = (size_t)(tail_limit < (int64_t)sizeof(buffer)
                                         ? tail_limit
                                         : (int64_t)sizeof(buffer));
            size_t count = fread(buffer, 1, wanted, input);
            if (count == 0 || fwrite(buffer, 1, count, output) != count) {
                rc = -1;
                break;
            }
            tail_limit -= (int64_t)count;
        }
    }
    int input_close_error = fclose(input);
    int output_close_error = fclose(output);
    if (input_close_error != 0 || output_close_error != 0) {
        rc = -1;
    }
    return rc;
}

static int create_task_run_archive(const char *repo_root, const char *state_dir,
                                   const FlowMeta *meta,
                                   const StringList *directories,
                                   const GateResult *results, size_t result_count) {
    if (strcmp(meta->archive_mode, "none") == 0) {
        return 0;
    }
    time_t now = time(NULL);
    struct tm utc;
    char date[16];
    char archive_rel[PATH_MAX];
    if (gmtime_r(&now, &utc) == NULL ||
        strftime(date, sizeof(date), "%Y-%m-%d", &utc) == 0) {
        return -1;
    }
    int written = snprintf(archive_rel, sizeof(archive_rel),
                           ".github/task-runs/%s-%s", date, meta->task_id);
    if (written < 0 || (size_t)written >= sizeof(archive_rel)) {
        return -1;
    }
    char archive_dir[PATH_MAX];
    char logs_dir[PATH_MAX];
    if (path_join(archive_dir, sizeof(archive_dir), repo_root, archive_rel) != 0 ||
        path_join(logs_dir, sizeof(logs_dir), archive_dir, "agent-flow-logs") != 0 ||
        mkdir_p(logs_dir) != 0) {
        return -1;
    }

    static const char *sources[] = {
        "paths.log",
        "directories.log",
        "evidence.tsv",
        "decisions.tsv",
        "gate-status.tsv",
    };
    static const char *destinations[] = {
        "agent-flow-changed-paths.tsv",
        "agent-flow-changed-directories.tsv",
        "agent-flow-evidence.tsv",
        "agent-flow-decision-trace.tsv",
        "agent-flow-gates.tsv",
    };
    for (size_t i = 0; i < sizeof(sources) / sizeof(sources[0]); ++i) {
        char source[PATH_MAX];
        char destination[PATH_MAX];
        if (path_join(source, sizeof(source), state_dir, sources[i]) != 0 ||
            path_join(destination, sizeof(destination), archive_dir, destinations[i]) != 0 ||
            copy_file_if_present(source, destination) != 0) {
            return -1;
        }
    }

    int64_t log_limit = strcmp(meta->archive_mode, "durable") == 0
                            ? 256 * 1024
                            : 64 * 1024;
    for (size_t i = 0; i < result_count; ++i) {
        if (strcmp(results[i].log_path, "-") == 0) {
            continue;
        }
        char source[PATH_MAX];
        char destination[PATH_MAX];
        if (path_join(source, sizeof(source), repo_root, results[i].log_path) != 0) {
            return -1;
        }
        written = snprintf(destination, sizeof(destination), "%s/%s.txt",
                           logs_dir, results[i].id);
        if (written < 0 || (size_t)written >= sizeof(destination) ||
            copy_bounded_log(source, destination, log_limit) != 0) {
            return -1;
        }
    }

    char report_path[PATH_MAX];
    if (path_join(report_path, sizeof(report_path), archive_dir,
                  "agent-flow-result.md") != 0) {
        return -1;
    }
    FILE *report = fopen(report_path, "w");
    if (report == NULL) {
        return -1;
    }
    char timestamp[32];
    iso8601_now(timestamp, sizeof(timestamp));
    int64_t work_ms = current_work_ms(meta, realtime_ms());
    double overhead = work_ms > 0
                          ? (100.0 * (double)meta->gate_ms / (double)work_ms)
                          : 0.0;
    fprintf(report, "# Agent Flow Result\n\n");
    fprintf(report, "- `schema`: agent-flow-v1\n");
    fprintf(report, "- `task_id`: %s\n", meta->task_id);
    fprintf(report, "- `task_class`: %s\n", meta->task_class);
    fprintf(report, "- `archive_mode`: %s\n", meta->archive_mode);
    fprintf(report, "- `status`: PASS\n");
    fprintf(report, "- `completed_at`: %s\n", timestamp);
    fprintf(report, "- `work_ms`: %lld\n", (long long)work_ms);
    fprintf(report, "- `gate_ms`: %lld\n", (long long)meta->gate_ms);
    fprintf(report, "- `workflow_overhead_percent`: %.2f\n", overhead);
    fprintf(report, "- `workflow_overhead_target_percent`: %d\n",
            meta->overhead_target_percent);
    fprintf(report, "- `workflow_overhead_policy`: advisory; never blocks delivery\n");
    fprintf(report, "- `path_source`: explicit-agent-flow-log; no Git enumeration\n\n");
    fprintf(report, "## Modified directories\n\n");
    if (directories->count == 0) {
        fprintf(report, "- none\n");
    } else {
        for (size_t i = 0; i < directories->count; ++i) {
            fprintf(report, "- `%s`\n", directories->values[i]);
        }
    }
    fprintf(report, "\n## Retained result surface\n\n");
    fprintf(report, "- changed paths/directories\n");
    fprintf(report, "- verification evidence pointers\n");
    fprintf(report, "- engineering decision trace\n");
    fprintf(report, "- gate results and bounded selected logs\n\n");
    fprintf(report,
            "Full startup context, Git worktree enumeration, duplicated raw payload, "
            "and private token-by-token reasoning are not archived.\n");
    if (fclose(report) != 0) {
        return -1;
    }

    char archive_path_file[PATH_MAX];
    if (path_join(archive_path_file, sizeof(archive_path_file),
                  state_dir, "archive.path") != 0) {
        return -1;
    }
    FILE *archive_marker = fopen(archive_path_file, "w");
    if (archive_marker == NULL) {
        return -1;
    }
    fprintf(archive_marker, "%s\n", archive_rel);
    return fclose(archive_marker);
}

static int print_summary(const char *state_dir) {
    char path[PATH_MAX];
    char line[MAX_LINE];
    if (path_join(path, sizeof(path), state_dir, "summary.txt") != 0) {
        return -1;
    }
    FILE *stream = fopen(path, "r");
    if (stream == NULL) {
        return -1;
    }
    while (fgets(line, sizeof(line), stream) != NULL) {
        fputs(line, stdout);
    }
    return fclose(stream);
}

static void usage(FILE *stream) {
    fprintf(stream,
            "usage:\n"
            "  scripts/agent-flow.sh begin --task ID --class CLASS "
            "[--overhead-target 1..100] "
            "[--archive none|compact|durable] [--initial-work-seconds N]\n"
            "  scripts/agent-flow.sh record --task ID [--path PATH ...] [--gate GATE ...]\n"
            "  scripts/agent-flow.sh evidence --task ID --name NAME --status PASS|FAIL|GAP "
            "[--artifact PATH|-]\n"
            "  scripts/agent-flow.sh decision --task ID "
            "--kind hypothesis|evidence|decision|counterexample|rollback|note --text TEXT "
            "[--artifact PATH|-]\n"
            "  scripts/agent-flow.sh reclassify --task ID --class CLASS --reason TEXT\n"
            "  scripts/agent-flow.sh pause|resume|status --task ID\n"
            "  scripts/agent-flow.sh finish --task ID [--plan|--candidate]\n"
            "  scripts/agent-flow.sh classify\n"
            "  scripts/agent-flow.sh list-gates\n");
}

static const char *option_value(int argc, char **argv, const char *option) {
    for (int i = 0; i + 1 < argc; ++i) {
        if (strcmp(argv[i], option) == 0) {
            return argv[i + 1];
        }
    }
    return NULL;
}

static int collect_option_values(int argc, char **argv, const char *option, StringList *values) {
    memset(values, 0, sizeof(*values));
    for (int i = 0; i < argc; ++i) {
        if (strcmp(argv[i], option) != 0) {
            continue;
        }
        if (i + 1 >= argc || list_add(values, argv[i + 1]) < 0) {
            return -1;
        }
        ++i;
    }
    return 0;
}

static int has_option(int argc, char **argv, const char *option) {
    for (int i = 0; i < argc; ++i) {
        if (strcmp(argv[i], option) == 0) {
            return 1;
        }
    }
    return 0;
}

static int state_dir_for_task(const char *state_root, const char *task_id,
                              char *state_dir, size_t size) {
    if (!valid_token(task_id, MAX_ID)) {
        fprintf(stderr, "[agent-flow] invalid task id: %s\n", task_id);
        return -1;
    }
    return path_join(state_dir, size, state_root, task_id);
}

static int command_begin(const char *state_root, int argc, char **argv) {
    const char *task_id = option_value(argc, argv, "--task");
    const char *task_class = option_value(argc, argv, "--class");
    const char *raw_target = option_value(argc, argv, "--overhead-target");
    const char *raw_budget = option_value(argc, argv, "--budget");
    const char *raw_archive = option_value(argc, argv, "--archive");
    const char *raw_initial = option_value(argc, argv, "--initial-work-seconds");
    if (task_id == NULL || task_class == NULL || !valid_token(task_id, MAX_ID) ||
        !valid_class(task_class)) {
        usage(stderr);
        return 2;
    }
    int overhead_target =
        raw_target != NULL ? atoi(raw_target) :
        (raw_budget != NULL ? atoi(raw_budget) : 40);
    const char *archive_mode = raw_archive != NULL
                                   ? raw_archive
                                   : default_archive_mode(task_class);
    long long initial_seconds = raw_initial != NULL ? strtoll(raw_initial, NULL, 10) : 0;
    if (overhead_target < 1 || overhead_target > 100 ||
        !valid_archive_mode(archive_mode) ||
        initial_seconds < 0 ||
        initial_seconds > 365LL * 24 * 3600) {
        fprintf(stderr, "[agent-flow] invalid overhead target or initial work credit\n");
        return 2;
    }
    char state_dir[PATH_MAX];
    char meta_path[PATH_MAX];
    if (state_dir_for_task(state_root, task_id, state_dir, sizeof(state_dir)) != 0 ||
        path_join(meta_path, sizeof(meta_path), state_dir, "meta") != 0) {
        return 2;
    }
    if (access(meta_path, F_OK) == 0) {
        fprintf(stderr, "[agent-flow] task already exists: %s\n", task_id);
        return 2;
    }
    if (mkdir_p(state_dir) != 0) {
        perror("mkdir state");
        return 2;
    }
    FlowMeta meta;
    memset(&meta, 0, sizeof(meta));
    snprintf(meta.task_id, sizeof(meta.task_id), "%s", task_id);
    snprintf(meta.task_class, sizeof(meta.task_class), "%s", task_class);
    snprintf(meta.archive_mode, sizeof(meta.archive_mode), "%s", archive_mode);
    snprintf(meta.status, sizeof(meta.status), "ACTIVE");
    meta.overhead_target_percent = overhead_target;
    meta.started_ms = realtime_ms();
    meta.initial_work_ms = initial_seconds * 1000;
    meta.generation = 1;
    if (meta.started_ms <= 0 || write_meta(state_dir, &meta) != 0 ||
        append_event(state_dir, "BEGIN", task_class) != 0) {
        return 2;
    }
    printf("[agent-flow] BEGIN task=%s class=%s archive=%s overhead_target~%d%% "
           "state=%s\n",
           task_id, task_class, archive_mode, overhead_target, state_dir);
    return 0;
}

static int command_record(const char *state_root, int argc, char **argv) {
    const char *task_id = option_value(argc, argv, "--task");
    if (task_id == NULL) {
        return 2;
    }
    char state_dir[PATH_MAX];
    if (state_dir_for_task(state_root, task_id, state_dir, sizeof(state_dir)) != 0) {
        return 2;
    }
    FlowMeta meta;
    if (read_meta(state_dir, &meta) != 0 || strcmp(meta.status, "PASS") == 0) {
        fprintf(stderr, "[agent-flow] task is missing or already complete: %s\n", task_id);
        return 2;
    }
    StringList raw_paths;
    StringList raw_gates;
    if (collect_option_values(argc, argv, "--path", &raw_paths) != 0 ||
        collect_option_values(argc, argv, "--gate", &raw_gates) != 0 ||
        (raw_paths.count == 0 && raw_gates.count == 0)) {
        return 2;
    }
    if ((strcmp(meta.task_class, "review") == 0 ||
         strcmp(meta.task_class, "analysis") == 0) &&
        raw_gates.count != 0) {
        fprintf(stderr, "[agent-flow] class=%s forbids gate pointers\n",
                meta.task_class);
        return 2;
    }
    char paths_file[PATH_MAX];
    char directories_file[PATH_MAX];
    char gates_file[PATH_MAX];
    if (path_join(paths_file, sizeof(paths_file), state_dir, "paths.log") != 0 ||
        path_join(directories_file, sizeof(directories_file), state_dir, "directories.log") != 0 ||
        path_join(gates_file, sizeof(gates_file), state_dir, "gates.log") != 0) {
        return 2;
    }
    int touched = 0;
    for (size_t i = 0; i < raw_paths.count; ++i) {
        char normalized[PATH_MAX];
        char directory[PATH_MAX];
        if (normalize_repo_path(raw_paths.values[i], normalized, sizeof(normalized)) != 0) {
            fprintf(stderr, "[agent-flow] invalid repository path: %s\n", raw_paths.values[i]);
            return 2;
        }
        int added = append_unique_line(paths_file, normalized);
        if (added < 0) {
            return 2;
        }
        if (added > 0) {
            directory_for_path(normalized, directory, sizeof(directory));
            if (append_unique_line(directories_file, directory) < 0 ||
                append_event(state_dir, "PATH", normalized) != 0) {
                return 2;
            }
        } else if (append_event(state_dir, "PATH_TOUCH", normalized) != 0) {
            return 2;
        }
        touched = 1;
    }
    for (size_t i = 0; i < raw_gates.count; ++i) {
        if (find_gate(raw_gates.values[i]) == NULL) {
            fprintf(stderr, "[agent-flow] unknown gate pointer: %s\n", raw_gates.values[i]);
            return 2;
        }
        int added = append_unique_line(gates_file, raw_gates.values[i]);
        if (added < 0) {
            return 2;
        }
        if (added > 0) {
            if (append_event(state_dir, "GATE_POINTER", raw_gates.values[i]) != 0) {
                return 2;
            }
        } else if (append_event(state_dir, "GATE_POINTER_TOUCH",
                                raw_gates.values[i]) != 0) {
            return 2;
        }
        touched = 1;
    }
    if (touched) {
        ++meta.generation;
        snprintf(meta.status, sizeof(meta.status), "ACTIVE");
        if (write_meta(state_dir, &meta) != 0) {
            return 2;
        }
    }
    printf("[agent-flow] RECORD task=%s paths=%zu gates=%zu generation=%d\n",
           task_id, raw_paths.count, raw_gates.count, meta.generation);
    return 0;
}

static int command_evidence(const char *repo_root, const char *state_root,
                            int argc, char **argv) {
    const char *task_id = option_value(argc, argv, "--task");
    const char *name = option_value(argc, argv, "--name");
    const char *status = option_value(argc, argv, "--status");
    const char *artifact = option_value(argc, argv, "--artifact");
    if (task_id == NULL || name == NULL || status == NULL ||
        !valid_token(name, 96) ||
        !(strcmp(status, "PASS") == 0 || strcmp(status, "FAIL") == 0 ||
          strcmp(status, "GAP") == 0)) {
        return 2;
    }
    if (artifact == NULL) {
        artifact = "-";
    }
    char normalized[PATH_MAX];
    if (strcmp(artifact, "-") != 0) {
        if (normalize_repo_path(artifact, normalized, sizeof(normalized)) != 0) {
            return 2;
        }
        char absolute[PATH_MAX];
        if (path_join(absolute, sizeof(absolute), repo_root, normalized) != 0 ||
            access(absolute, F_OK) != 0) {
            fprintf(stderr, "[agent-flow] evidence artifact is missing: %s\n", normalized);
            return 2;
        }
        artifact = normalized;
    }
    char state_dir[PATH_MAX];
    if (state_dir_for_task(state_root, task_id, state_dir, sizeof(state_dir)) != 0) {
        return 2;
    }
    FlowMeta meta;
    if (read_meta(state_dir, &meta) != 0 || strcmp(meta.status, "PASS") == 0) {
        return 2;
    }
    char evidence_path[PATH_MAX];
    char timestamp[32];
    if (path_join(evidence_path, sizeof(evidence_path), state_dir, "evidence.tsv") != 0) {
        return 2;
    }
    FILE *stream = fopen(evidence_path, "a");
    if (stream == NULL) {
        return 2;
    }
    iso8601_now(timestamp, sizeof(timestamp));
    fprintf(stream, "%s\t%s\t%s\t%s\n", timestamp, name, status, artifact);
    if (fclose(stream) != 0) {
        return 2;
    }
    char detail[MAX_LINE];
    snprintf(detail, sizeof(detail), "%s:%s:%s", name, status, artifact);
    if (append_event(state_dir, "EVIDENCE", detail) != 0) {
        return 2;
    }
    snprintf(meta.status, sizeof(meta.status), "ACTIVE");
    if (write_meta(state_dir, &meta) != 0) {
        return 2;
    }
    printf("[agent-flow] EVIDENCE task=%s name=%s status=%s artifact=%s\n",
           task_id, name, status, artifact);
    return 0;
}

static int valid_decision_kind(const char *kind) {
    static const char *kinds[] = {
        "hypothesis",
        "evidence",
        "decision",
        "counterexample",
        "rollback",
        "note",
    };
    for (size_t i = 0; i < sizeof(kinds) / sizeof(kinds[0]); ++i) {
        if (strcmp(kind, kinds[i]) == 0) {
            return 1;
        }
    }
    return 0;
}

static int valid_trace_text(const char *text) {
    size_t length = strlen(text);
    if (length == 0 || length > 2048) {
        return 0;
    }
    for (size_t i = 0; i < length; ++i) {
        unsigned char ch = (unsigned char)text[i];
        if (ch == '\t' || ch == '\r' || ch == '\n' || ch < 32) {
            return 0;
        }
    }
    return 1;
}

static int append_decision_trace(const char *state_dir, const char *kind,
                                 const char *text, const char *artifact) {
    char decisions_path[PATH_MAX];
    char timestamp[32];
    if (path_join(decisions_path, sizeof(decisions_path), state_dir,
                  "decisions.tsv") != 0) {
        return -1;
    }
    FILE *stream = fopen(decisions_path, "a");
    if (stream == NULL) {
        return -1;
    }
    iso8601_now(timestamp, sizeof(timestamp));
    fprintf(stream, "%s\t%s\t%s\t%s\n", timestamp, kind, text, artifact);
    if (fclose(stream) != 0) {
        return -1;
    }
    char detail[MAX_LINE];
    snprintf(detail, sizeof(detail), "%s:%s", kind, artifact);
    return append_event(state_dir, "DECISION_TRACE", detail);
}

static int command_decision(const char *repo_root, const char *state_root,
                            int argc, char **argv) {
    const char *task_id = option_value(argc, argv, "--task");
    const char *kind = option_value(argc, argv, "--kind");
    const char *text = option_value(argc, argv, "--text");
    const char *artifact = option_value(argc, argv, "--artifact");
    if (task_id == NULL || kind == NULL || text == NULL ||
        !valid_decision_kind(kind) || !valid_trace_text(text)) {
        return 2;
    }
    if (artifact == NULL) {
        artifact = "-";
    }
    char normalized[PATH_MAX];
    if (strcmp(artifact, "-") != 0) {
        if (normalize_repo_path(artifact, normalized, sizeof(normalized)) != 0) {
            return 2;
        }
        char absolute[PATH_MAX];
        if (path_join(absolute, sizeof(absolute), repo_root, normalized) != 0 ||
            access(absolute, F_OK) != 0) {
            fprintf(stderr, "[agent-flow] decision artifact is missing: %s\n", normalized);
            return 2;
        }
        artifact = normalized;
    }
    char state_dir[PATH_MAX];
    if (state_dir_for_task(state_root, task_id, state_dir, sizeof(state_dir)) != 0) {
        return 2;
    }
    FlowMeta meta;
    if (read_meta(state_dir, &meta) != 0 || strcmp(meta.status, "PASS") == 0) {
        return 2;
    }
    if (append_decision_trace(state_dir, kind, text, artifact) != 0) {
        return 2;
    }
    snprintf(meta.status, sizeof(meta.status), "ACTIVE");
    if (write_meta(state_dir, &meta) != 0) {
        return 2;
    }
    printf("[agent-flow] DECISION task=%s kind=%s artifact=%s\n",
           task_id, kind, artifact);
    return 0;
}

static int command_reclassify(const char *state_root, int argc, char **argv) {
    const char *task_id = option_value(argc, argv, "--task");
    const char *task_class = option_value(argc, argv, "--class");
    const char *reason = option_value(argc, argv, "--reason");
    if (task_id == NULL || task_class == NULL || reason == NULL ||
        !valid_class(task_class) || !valid_trace_text(reason)) {
        return 2;
    }
    char state_dir[PATH_MAX];
    if (state_dir_for_task(state_root, task_id, state_dir,
                           sizeof(state_dir)) != 0) {
        return 2;
    }
    FlowMeta meta;
    if (read_meta(state_dir, &meta) != 0 ||
        strcmp(meta.status, "PASS") == 0) {
        fprintf(stderr,
                "[agent-flow] task is missing or already complete: %s\n",
                task_id);
        return 2;
    }
    if (strcmp(meta.task_class, task_class) == 0) {
        fprintf(stderr, "[agent-flow] task already has class=%s\n", task_class);
        return 2;
    }
    char old_class[MAX_CLASS];
    char trace_text[MAX_LINE];
    char event_detail[MAX_LINE];
    snprintf(old_class, sizeof(old_class), "%s", meta.task_class);
    snprintf(trace_text, sizeof(trace_text),
             "task class changed %s -> %s: %s",
             old_class, task_class, reason);
    snprintf(event_detail, sizeof(event_detail), "%s->%s:%s",
             old_class, task_class, reason);
    if (!valid_trace_text(trace_text) ||
        append_decision_trace(state_dir, "decision", trace_text, "-") != 0 ||
        append_event(state_dir, "RECLASSIFY", event_detail) != 0) {
        return 2;
    }
    snprintf(meta.task_class, sizeof(meta.task_class), "%s", task_class);
    snprintf(meta.status, sizeof(meta.status), "ACTIVE");
    ++meta.generation;
    if (write_meta(state_dir, &meta) != 0) {
        return 2;
    }
    printf("[agent-flow] RECLASSIFY task=%s class=%s->%s generation=%d\n",
           task_id, old_class, task_class, meta.generation);
    return 0;
}

static int command_pause_resume(const char *state_root, int argc, char **argv, int resume) {
    const char *task_id = option_value(argc, argv, "--task");
    if (task_id == NULL) {
        return 2;
    }
    char state_dir[PATH_MAX];
    if (state_dir_for_task(state_root, task_id, state_dir, sizeof(state_dir)) != 0) {
        return 2;
    }
    FlowMeta meta;
    if (read_meta(state_dir, &meta) != 0 || strcmp(meta.status, "PASS") == 0) {
        return 2;
    }
    int64_t now = realtime_ms();
    if (!resume) {
        if (meta.pause_started_ms != 0) {
            return 2;
        }
        meta.pause_started_ms = now;
        append_event(state_dir, "PAUSE", "-");
    } else {
        if (meta.pause_started_ms <= 0 || now < meta.pause_started_ms) {
            return 2;
        }
        meta.paused_ms += now - meta.pause_started_ms;
        meta.pause_started_ms = 0;
        append_event(state_dir, "RESUME", "-");
    }
    if (write_meta(state_dir, &meta) != 0) {
        return 2;
    }
    printf("[agent-flow] %s task=%s\n", resume ? "RESUME" : "PAUSE", task_id);
    return 0;
}

static int load_task_lists(const char *state_dir, StringList *paths,
                           StringList *directories, StringList *explicit_gates) {
    char path[PATH_MAX];
    if (path_join(path, sizeof(path), state_dir, "paths.log") != 0 ||
        load_lines(path, paths) != 0 ||
        path_join(path, sizeof(path), state_dir, "directories.log") != 0 ||
        load_lines(path, directories) != 0 ||
        path_join(path, sizeof(path), state_dir, "gates.log") != 0 ||
        load_lines(path, explicit_gates) != 0) {
        return -1;
    }
    return 0;
}

static int command_status(const char *state_root, int argc, char **argv) {
    const char *task_id = option_value(argc, argv, "--task");
    if (task_id == NULL) {
        return 2;
    }
    char state_dir[PATH_MAX];
    if (state_dir_for_task(state_root, task_id, state_dir, sizeof(state_dir)) != 0) {
        return 2;
    }
    FlowMeta meta;
    StringList paths;
    StringList directories;
    StringList explicit_gates;
    StringList gates;
    if (read_meta(state_dir, &meta) != 0 ||
        load_task_lists(state_dir, &paths, &directories, &explicit_gates) != 0 ||
        derive_gates(&meta, &paths, &explicit_gates, &gates) != 0) {
        return 2;
    }
    const char *result = strcmp(meta.status, "PASS") == 0 ? "PASS" : "ACTIVE";
    if (write_summary(state_dir, &meta, &paths, &directories, &gates,
                      NULL, 0, result, meta.status) != 0 ||
        print_summary(state_dir) != 0) {
        return 2;
    }
    return 0;
}

static int command_finish(const char *repo_root, const char *state_root,
                          int argc, char **argv) {
    const char *task_id = option_value(argc, argv, "--task");
    int plan_only = has_option(argc, argv, "--plan");
    int candidate_only = has_option(argc, argv, "--candidate");
    if (task_id == NULL || (plan_only && candidate_only)) {
        return 2;
    }
    char state_dir[PATH_MAX];
    if (state_dir_for_task(state_root, task_id, state_dir, sizeof(state_dir)) != 0) {
        return 2;
    }
    FlowMeta meta;
    StringList paths;
    StringList directories;
    StringList explicit_gates;
    StringList gates;
    if (read_meta(state_dir, &meta) != 0 ||
        load_task_lists(state_dir, &paths, &directories, &explicit_gates) != 0 ||
        derive_gates(&meta, &paths, &explicit_gates, &gates) != 0) {
        return 2;
    }
    if (strcmp(meta.status, "PASS") == 0) {
        return print_summary(state_dir) == 0 ? 0 : 2;
    }
    if (plan_only) {
        if (write_summary(state_dir, &meta, &paths, &directories, &gates,
                          NULL, 0, "PLAN", "no gates executed") != 0 ||
            print_summary(state_dir) != 0) {
            return 2;
        }
        return 0;
    }
    if (meta.pause_started_ms != 0) {
        fprintf(stderr, "[agent-flow] resume task before finish\n");
        return 2;
    }
    char reason[MAX_LINE];
    if (validate_completion_inputs(&meta, &paths, state_dir, reason, sizeof(reason)) != 0) {
        snprintf(meta.status, sizeof(meta.status), "BLOCKED");
        write_meta(state_dir, &meta);
        append_event(state_dir, "BLOCKED", reason);
        write_summary(state_dir, &meta, &paths, &directories, &gates,
                      NULL, 0, "BLOCKED", reason);
        print_summary(state_dir);
        return 1;
    }

    GateResult results[MAX_ITEMS];
    size_t result_count = 0;
    int blocked = 0;
    snprintf(reason, sizeof(reason), "all selected gates passed");
    for (size_t i = 0; i < gates.count; ++i) {
        const GateDef *gate = find_gate(gates.values[i]);
        if (gate == NULL || result_count >= MAX_ITEMS) {
            return 2;
        }
        GateResult *result = &results[result_count++];
        memset(result, 0, sizeof(*result));
        if (gate_pass_for_generation(state_dir, gate->id, meta.generation, result)) {
            continue;
        }
        int64_t gate_limit_ms = (int64_t)gate->timeout_seconds * 1000;
        int gate_rc = run_gate(repo_root, state_dir, gate, gate_limit_ms, result);
        meta.gate_ms += result->elapsed_ms;
        if (write_meta(state_dir, &meta) != 0 ||
            append_gate_status(state_dir, meta.generation, result) != 0) {
            return 2;
        }
        char detail[MAX_LINE];
        snprintf(detail, sizeof(detail), "%s:%s:%lld", result->id, result->status,
                 (long long)result->elapsed_ms);
        append_event(state_dir, "GATE", detail);
        if (gate_rc != 0) {
            snprintf(reason, sizeof(reason), "gate=%s status=%s", gate->id, result->status);
            blocked = 1;
            break;
        }
    }

    if (!blocked && candidate_only) {
        snprintf(meta.status, sizeof(meta.status), "CANDIDATE");
        snprintf(reason, sizeof(reason),
                 "all selected gates passed; awaiting pre-delivery review");
        if (write_meta(state_dir, &meta) != 0 ||
            append_event(state_dir, "CANDIDATE", reason) != 0 ||
            write_summary(state_dir, &meta, &paths, &directories, &gates,
                          results, result_count, "CANDIDATE_PASS", reason) != 0 ||
            print_summary(state_dir) != 0) {
            return 2;
        }
        return 0;
    }
    if (!blocked &&
        create_task_run_archive(repo_root, state_dir, &meta, &directories,
                                results, result_count) != 0) {
        snprintf(reason, sizeof(reason), "task-run result archive failed");
        blocked = 1;
    }
    snprintf(meta.status, sizeof(meta.status), "%s", blocked ? "BLOCKED" : "PASS");
    if (write_meta(state_dir, &meta) != 0 ||
        append_event(state_dir, blocked ? "BLOCKED" : "FINISH", reason) != 0 ||
        write_summary(state_dir, &meta, &paths, &directories, &gates,
                      results, result_count, blocked ? "BLOCKED" : "PASS", reason) != 0 ||
        print_summary(state_dir) != 0) {
        return 2;
    }
    return blocked ? 1 : 0;
}

int main(int argc, char **argv) {
    const char *repo_root = getenv("AGENT_FLOW_REPO_ROOT");
    const char *state_root = getenv("AGENT_FLOW_STATE_ROOT");
    int index = 1;
    if (index + 1 < argc && strcmp(argv[index], "--repo") == 0) {
        repo_root = argv[index + 1];
        index += 2;
    }
    if (repo_root == NULL || *repo_root == '\0') {
        fprintf(stderr, "[agent-flow] AGENT_FLOW_REPO_ROOT or --repo is required\n");
        return 2;
    }
    char default_state_root[PATH_MAX];
    if (state_root == NULL || *state_root == '\0') {
        if (path_join(default_state_root, sizeof(default_state_root), repo_root,
                      ".github/runtime-artifacts/agent-flow") != 0) {
            return 2;
        }
        state_root = default_state_root;
    }
    if (index >= argc) {
        usage(stderr);
        return 2;
    }
    const char *command = argv[index++];
    int sub_argc = argc - index;
    char **sub_argv = argv + index;

    if (strcmp(command, "begin") == 0) {
        return command_begin(state_root, sub_argc, sub_argv);
    }
    if (strcmp(command, "record") == 0) {
        return command_record(state_root, sub_argc, sub_argv);
    }
    if (strcmp(command, "evidence") == 0) {
        return command_evidence(repo_root, state_root, sub_argc, sub_argv);
    }
    if (strcmp(command, "decision") == 0) {
        return command_decision(repo_root, state_root, sub_argc, sub_argv);
    }
    if (strcmp(command, "reclassify") == 0) {
        return command_reclassify(state_root, sub_argc, sub_argv);
    }
    if (strcmp(command, "pause") == 0) {
        return command_pause_resume(state_root, sub_argc, sub_argv, 0);
    }
    if (strcmp(command, "resume") == 0) {
        return command_pause_resume(state_root, sub_argc, sub_argv, 1);
    }
    if (strcmp(command, "status") == 0) {
        return command_status(state_root, sub_argc, sub_argv);
    }
    if (strcmp(command, "finish") == 0) {
        return command_finish(repo_root, state_root, sub_argc, sub_argv);
    }
    if (strcmp(command, "classify") == 0) {
        puts("review       read-only code review; no guard");
        puts("analysis     read-only explanation/research; no guard");
        puts("docs         ordinary documentation change; no heavy guard");
        puts("development  RTL/software implementation; domain evidence only");
        puts("verification existing tests or evidence replay; no source modification");
        puts("environment  AI workflow/rule/script change; selected pointer gates at finish");
        puts("longrun      simulation/synthesis/STA/system replay; explicit status evidence");
        puts("cleanup      deletion/retention work; preview and result evidence");
        puts("release      CI/package/external delivery; release gates at finish");
        return 0;
    }
    if (strcmp(command, "list-gates") == 0) {
        size_t count = sizeof(GATES) / sizeof(GATES[0]);
        for (size_t i = 0; i < count; ++i) {
            printf("%s\t%d\t%s\n", GATES[i].id, GATES[i].timeout_seconds,
                   GATES[i].command);
        }
        return 0;
    }
    usage(stderr);
    return 2;
}
