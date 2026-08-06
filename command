921-
922-static int64_t current_work_ms(const FlowMeta *meta, int64_t now_ms) {
923-    int64_t active_pause = 0;
924-    if (meta->pause_started_ms > 0 && now_ms > meta->pause_started_ms) {
925-        active_pause = now_ms - meta->pause_started_ms;
926-    }
927-    int64_t work = meta->initial_work_ms + (now_ms - meta->started_ms) -
928-                   meta->gate_ms - meta->paused_ms - active_pause;
929-    return work > 0 ? work : 0;
930-}
931-
932-static int gate_pass_for_generation(const char *state_dir, const char *gate_id,
933-                                    int generation, GateResult *result) {
934-    char path[PATH_MAX];
935-    char line[MAX_LINE];
936:    if (path_join(path, sizeof(path), state_dir, "gate-status.tsv") != 0) {
937-        return 0;
938-    }
939-    FILE *stream = fopen(path, "r");
940-    if (stream == NULL) {
941-        return 0;
942-    }
943-    int found = 0;
944-    while (fgets(line, sizeof(line), stream) != NULL) {
945-        char *save = NULL;
946-        char *raw_generation = strtok_r(line, "\t", &save);
947-        char *raw_id = strtok_r(NULL, "\t", &save);
948-        char *raw_status = strtok_r(NULL, "\t", &save);
949-        char *raw_elapsed = strtok_r(NULL, "\t", &save);
950-        char *raw_log = strtok_r(NULL, "\t\r\n", &save);
951-        if (raw_generation == NULL || raw_id == NULL || raw_status == NULL ||
--
957-            snprintf(result->id, sizeof(result->id), "%s", raw_id);
958-            snprintf(result->status, sizeof(result->status), "%s", raw_status);
959-            result->elapsed_ms = strtoll(raw_elapsed, NULL, 10);
960-            snprintf(result->log_path, sizeof(result->log_path), "%s", raw_log);
961-            result->reused = 1;
962-            found = 1;
963-        }
964-    }
965-    fclose(stream);
966-    return found;
967-}
968-
969-static int append_gate_status(const char *state_dir, int generation,
970-                              const GateResult *result) {
971-    char path[PATH_MAX];
972:    if (path_join(path, sizeof(path), state_dir, "gate-status.tsv") != 0) {
973-        return -1;
974-    }
975-    FILE *stream = fopen(path, "a");
976-    if (stream == NULL) {
977-        return -1;
978-    }
979-    fprintf(stream, "%d\t%s\t%s\t%lld\t%s\n", generation, result->id,
980-            result->status, (long long)result->elapsed_ms, result->log_path);
981-    return fclose(stream);
982-}
983-
984-static int run_gate(const char *repo_root, const char *state_dir, const GateDef *gate,
985-                    int64_t timeout_ms, GateResult *result) {
986-    char logs_dir[PATH_MAX];
987-    char absolute_log[PATH_MAX];
988-    char relative_log[PATH_MAX];
989-    if (path_join(logs_dir, sizeof(logs_dir), state_dir, "gates") != 0 ||
990-        mkdir_p(logs_dir) != 0) {
991-        return -1;
992-    }
993:    int written = snprintf(absolute_log, sizeof(absolute_log), "%s/%s.log", logs_dir, gate->id);
994-    if (written < 0 || (size_t)written >= sizeof(absolute_log)) {
995-        return -1;
996-    }
997-    const char *relative = strstr(absolute_log, "/.github/");
998-    snprintf(relative_log, sizeof(relative_log), "%s",
999-             relative != NULL ? relative + 1 : absolute_log);
1000-
1001-    int descriptor = open(absolute_log, O_CREAT | O_WRONLY | O_TRUNC, 0664);
1002-    if (descriptor < 0) {
1003-        return -1;
1004-    }
1005-    int64_t started = monotonic_ms();
1006-    pid_t child = fork();
1007-    if (child < 0) {
1008-        close(descriptor);
1009-        return -1;
1010-    }
1011-    if (child == 0) {
1012-        setpgid(0, 0);
1013:        if (chdir(repo_root) != 0 || dup2(descriptor, STDOUT_FILENO) < 0 ||
1014-            dup2(descriptor, STDERR_FILENO) < 0) {
1015-            _exit(126);
1016-        }
1017-        close(descriptor);
1018:        execl("/bin/sh", "sh", "-c", gate->command, (char *)NULL);
1019-        _exit(127);
1020-    }
1021-    close(descriptor);
1022-    setpgid(child, child);
1023-
1024-    int status = 0;
1025-    int timed_out = 0;
1026-    for (;;) {
1027-        pid_t waited = waitpid(child, &status, WNOHANG);
1028-        if (waited == child) {
1029-            break;
1030-        }
1031-        if (waited < 0) {
1032-            return -1;
1033-        }
--
1036-            timed_out = 1;
1037-            kill(-child, SIGTERM);
1038-            struct timespec grace = {.tv_sec = 0, .tv_nsec = 200000000L};
1039-            nanosleep(&grace, NULL);
1040-            if (waitpid(child, &status, WNOHANG) == 0) {
1041-                kill(-child, SIGKILL);
1042-            }
1043-            waitpid(child, &status, 0);
1044-            break;
1045-        }
1046-        struct timespec interval = {.tv_sec = 0, .tv_nsec = 50000000L};
1047-        nanosleep(&interval, NULL);
1048-    }
1049-    int64_t ended = monotonic_ms();
1050-    memset(result, 0, sizeof(*result));
1051:    snprintf(result->id, sizeof(result->id), "%s", gate->id);
1052-    snprintf(result->log_path, sizeof(result->log_path), "%s", relative_log);
1053-    result->elapsed_ms = ended >= started ? ended - started : 0;
1054-    if (timed_out) {
1055-        snprintf(result->status, sizeof(result->status), "TIMEOUT");
1056-        return 1;
1057-    }
1058-    if (WIFEXITED(status) && WEXITSTATUS(status) == 0) {
1059-        snprintf(result->status, sizeof(result->status), "PASS");
1060-        return 0;
1061-    }
1062-    snprintf(result->status, sizeof(result->status), "FAIL");
1063-    return 1;
1064-}
1065-
1066-static int write_summary(const char *state_dir, const FlowMeta *meta,
--
1274-        return -1;
1275-    }
1276-    char archive_dir[PATH_MAX];
1277-    char logs_dir[PATH_MAX];
1278-    if (path_join(archive_dir, sizeof(archive_dir), repo_root, archive_rel) != 0 ||
1279-        path_join(logs_dir, sizeof(logs_dir), archive_dir, "agent-flow-logs") != 0 ||
1280-        mkdir_p(logs_dir) != 0) {
1281-        return -1;
1282-    }
1283-
1284-    static const char *sources[] = {
1285-        "paths.log",
1286-        "directories.log",
1287-        "evidence.tsv",
1288-        "decisions.tsv",
1289:        "gate-status.tsv",
1290-    };
1291-    static const char *destinations[] = {
1292-        "agent-flow-changed-paths.tsv",
1293-        "agent-flow-changed-directories.tsv",
1294-        "agent-flow-evidence.tsv",
1295-        "agent-flow-decision-trace.tsv",
1296-        "agent-flow-gates.tsv",
1297-    };
1298-    for (size_t i = 0; i < sizeof(sources) / sizeof(sources[0]); ++i) {
1299-        char source[PATH_MAX];
1300-        char destination[PATH_MAX];
1301-        if (path_join(source, sizeof(source), state_dir, sources[i]) != 0 ||
1302-            path_join(destination, sizeof(destination), archive_dir, destinations[i]) != 0 ||
1303-            copy_file_if_present(source, destination) != 0) {
1304-            return -1;
--
1950-        print_summary(state_dir);
1951-        return 1;
1952-    }
1953-
1954-    GateResult results[MAX_ITEMS];
1955-    size_t result_count = 0;
1956-    int blocked = 0;
1957-    snprintf(reason, sizeof(reason), "all selected gates passed");
1958-    for (size_t i = 0; i < gates.count; ++i) {
1959-        const GateDef *gate = find_gate(gates.values[i]);
1960-        if (gate == NULL || result_count >= MAX_ITEMS) {
1961-            return 2;
1962-        }
1963-        GateResult *result = &results[result_count++];
1964-        memset(result, 0, sizeof(*result));
1965:        if (gate_pass_for_generation(state_dir, gate->id, meta.generation, result)) {
1966-            continue;
1967-        }
1968:        int64_t gate_limit_ms = (int64_t)gate->timeout_seconds * 1000;
1969-        int gate_rc = run_gate(repo_root, state_dir, gate, gate_limit_ms, result);
1970-        meta.gate_ms += result->elapsed_ms;
1971-        if (write_meta(state_dir, &meta) != 0 ||
1972-            append_gate_status(state_dir, meta.generation, result) != 0) {
1973-            return 2;
1974-        }
1975-        char detail[MAX_LINE];
1976-        snprintf(detail, sizeof(detail), "%s:%s:%lld", result->id, result->status,
1977-                 (long long)result->elapsed_ms);
1978-        append_event(state_dir, "GATE", detail);
1979-        if (gate_rc != 0) {
1980:            snprintf(reason, sizeof(reason), "gate=%s status=%s", gate->id, result->status);
1981-            blocked = 1;
1982-            break;
1983-        }
1984-    }
1985-
1986-    if (!blocked && candidate_only) {
1987-        snprintf(meta.status, sizeof(meta.status), "CANDIDATE");
1988-        snprintf(reason, sizeof(reason),
1989-                 "all selected gates passed; awaiting pre-delivery review");
1990-        if (write_meta(state_dir, &meta) != 0 ||
1991-            append_event(state_dir, "CANDIDATE", reason) != 0 ||
1992-            write_summary(state_dir, &meta, &paths, &directories, &gates,
1993-                          results, result_count, "CANDIDATE_PASS", reason) != 0 ||
1994-            print_summary(state_dir) != 0) {
1995-            return 2;
