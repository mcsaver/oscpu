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
        # Skip ex29_tests if the optional shared lib isn't built
        if [ "${i}" = "tests/ex29_tests" ] && [ ! -f build/libex29.so ]; then
            echo "Skipping $i (missing build/libex29.so)"
            continue
        fi
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