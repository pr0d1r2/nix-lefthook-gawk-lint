#!/usr/bin/env bats

setup() {
    load "$BATS_LIB_PATH/bats-support/load"
    load "$BATS_LIB_PATH/bats-assert/load"
    load "$BATS_LIB_PATH/bats-file/load"

    TEST_TEMP="$(mktemp -d)"
}

teardown() {
    rm -rf "$TEST_TEMP"
}

@test "exits 0 with no arguments" {
    run lefthook-gawk-lint
    assert_success
}

@test "exits 0 when no .awk files in arguments" {
    touch "$TEST_TEMP/file.txt"
    run lefthook-gawk-lint "$TEST_TEMP/file.txt"
    assert_success
}

@test "skips missing files silently" {
    run lefthook-gawk-lint "/nonexistent/file.awk"
    assert_success
}

@test "accepts valid awk program" {
    cat > "$TEST_TEMP/good.awk" << 'EOF'
BEGIN { print "hello" }
EOF
    run lefthook-gawk-lint "$TEST_TEMP/good.awk"
    assert_success
}

@test "detects invalid awk syntax" {
    cat > "$TEST_TEMP/bad.awk" << 'EOF'
BEGIN { print "hello
EOF
    run lefthook-gawk-lint "$TEST_TEMP/bad.awk"
    assert_failure
}

@test "filters non-.awk files from mixed input" {
    cat > "$TEST_TEMP/good.awk" << 'EOF'
BEGIN { print "hello" }
EOF
    touch "$TEST_TEMP/file.txt"
    run lefthook-gawk-lint "$TEST_TEMP/good.awk" "$TEST_TEMP/file.txt"
    assert_success
}

@test "reports failure for any bad file in batch" {
    cat > "$TEST_TEMP/good.awk" << 'EOF'
BEGIN { print "hello" }
EOF
    cat > "$TEST_TEMP/bad.awk" << 'EOF'
BEGIN { print "hello
EOF
    run lefthook-gawk-lint "$TEST_TEMP/good.awk" "$TEST_TEMP/bad.awk"
    assert_failure
}
