echo "Running unit tests:"
#!/usr/bin/env bash
# Use a portable strict mode; Makefile may invoke this via /bin/sh, so avoid 'pipefail'
set -eu

echo "Running unit tests:"

LOGFILE=tests/tests.log
rm -f "$LOGFILE" || true

for i in tests/*_tests
do
    if test -f "$i"
    then
        if ${VALGRIND:-} ./"$i" 2>> "$LOGFILE"
        then
            echo "$i PASS"
        else
            echo "ERROR in test $i: here's $LOGFILE"
            echo "------"
            if test -f "$LOGFILE"; then
                tail "$LOGFILE"
            else
                echo "(no log file)"
            fi
            exit 1
        fi
    fi
done

echo ""