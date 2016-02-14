#!/bin/bash

# Like a mythical touch -p
function touchp() {
    install -Dm644 /dev/null "$1"
}

# Creates a simple file+directory structure for tests
function make_basic() {
    touchp "$1/a"
    touchp "$1/b"
    touchp "$1/c/d"
    touchp "$1/e/f"
    mkdir -p "$1/g/h"
    mkdir -p "$1/i"
    touchp "$1/j/foo"
    touchp "$1/k/foo/bar"
    touchp "$1/l/foo/bar/baz"
}

basic="$(mktemp -d "${TMPDIR:-/tmp}"/bfs.basic.XXXXXXXXXX)"
make_basic "$basic"

# Creates a file+directory structure with various permissions for tests
function make_perms() {
    install -Dm444 /dev/null "$1/r"
    install -Dm222 /dev/null "$1/w"
    install -Dm644 /dev/null "$1/rw"
    install -Dm555 /dev/null "$1/rx"
    install -Dm311 /dev/null "$1/wx"
    install -Dm755 /dev/null "$1/rwx"
}

perms="$(mktemp -d "${TMPDIR:-/tmp}"/bfs.perms.XXXXXXXXXX)"
make_perms "$perms"

# Creates a file+directory structure with various symbolic and hard links
function make_links() {
    touchp "$1/a"
    ln -s a "$1/b"
    ln "$1/a" "$1/c"
    mkdir -p "$1/d/e/f"
    ln -s ../../d "$1/d/e/g"
    ln -s d/e "$1/h"
    ln -s q "$1/d/e/i"
}

links="$(mktemp -d "${TMPDIR:-/tmp}"/bfs.links.XXXXXXXXXX)"
make_links "$links"

# Clean up temporary directories on exit
function cleanup() {
    rm -rf "$links"
    rm -rf "$perms"
    rm -rf "$basic"
}
trap cleanup EXIT

# Checks for any (order-independent) differences between bfs and find
function find_diff() {
    diff -u <(./bfs "$@" | sort) <(find "$@" | sort)
}

# Test cases

function test_0001() {
    find_diff "$basic"
}

function test_0002() {
    find_diff "$basic" -type d
}

function test_0003() {
    find_diff "$basic" -type f
}

function test_0004() {
    find_diff "$basic" -mindepth 1
}

function test_0005() {
    find_diff "$basic" -maxdepth 1
}

function test_0006() {
    find_diff "$basic" -mindepth 1 -depth
}

function test_0007() {
    find_diff "$basic" -mindepth 2 -depth
}

function test_0008() {
    find_diff "$basic" -maxdepth 1 -depth
}

function test_0009() {
    find_diff "$basic" -maxdepth 2 -depth
}

function test_0010() {
    find_diff "$basic" -name '*f*'
}

function test_0011() {
    find_diff "$basic" -path "$basic/*f*"
}

function test_0012() {
    find_diff "$perms" -executable
}

function test_0013() {
    find_diff "$perms" -readable
}

function test_0014() {
    find_diff "$perms" -writable
}

function test_0015() {
    find_diff "$basic" -empty
}

function test_0016() {
    find_diff "$basic" -gid "$(id -g)" && \
        find_diff "$basic" -gid +0 && \
        find_diff "$basic" -gid -10000
}

function test_0017() {
    find_diff "$basic" -uid "$(id -u)" && \
        find_diff "$basic" -uid +0 && \
        find_diff "$basic" -uid -10000
}

function test_0018() {
    find_diff "$basic" -newer "$basic/e/f"
}

function test_0019() {
    find_diff "$basic" -cnewer "$basic/e/f"
}

function test_0020() {
    find_diff "$links" -links 2 && \
        find_diff "$links" -links -2 && \
        find_diff "$links" -links +1
}

function test_0021() {
    find_diff -P "$links/d/e/f" && \
        find_diff -P "$links/d/e/f/"
}

function test_0022() {
    find_diff -H "$links/d/e/f" && \
        find_diff -H "$links/d/e/f/"
}

function test_0023() {
    find_diff -H "$links" -newer "$links/d/e/f"
}

function test_0024() {
    find_diff -H "$links/d/e/i"
}

function test_0025() {
    find_diff -L "$links" 2>/dev/null
}

function test_0026() {
    find_diff "$links" -follow 2>/dev/null
}

function test_0027() {
    find_diff -L "$links" -depth 2>/dev/null
}

function test_0028() {
    find_diff "$links" -samefile "$links/a"
}

function test_0029() {
    find_diff "$links" -xtype l
}

function test_0030() {
    find_diff "$links" -xtype f
}

function test_0031() {
    find_diff -L "$links" -xtype l 2>/dev/null
}

function test_0032() {
    find_diff -L "$links" -xtype f 2>/dev/null
}

function test_0033() {
    find_diff "$basic/a" -name 'a'
}

function test_0034() {
    find_diff "$basic/g/" -name 'g'
}

function test_0035() {
    find_diff "/" -maxdepth 0 -name '/' 2>/dev/null
}

function test_0036() {
    find_diff "//" -maxdepth 0 -name '/' 2>/dev/null
}

function test_0037() {
    find_diff "$basic" -iname '*F*'
}

function test_0038() {
    find_diff "$basic" -ipath "$basic/*F*"
}

for i in {1..38}; do
    test="test_$(printf '%04d' $i)"
    "$test" "$dir"
    status=$?
    if [ $status -ne 0 ]; then
        echo "$test failed!" >&2
        exit $status
    fi
done