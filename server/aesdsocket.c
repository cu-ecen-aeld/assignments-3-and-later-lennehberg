#include <netdb.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/syslog.h>
#include <sys/types.h>
#include <sys/un.h>
#include <syslog.h>

#define MY_SOCK_PATH "/var/tmp/"
#define LISTEN_BACKLOG 50

#define FAILED -1
#define SUCCESS 0

int create_socket() {
  // socket creation
  int sfd;

  sfd = socket(AF_INET, SOCK_STREAM, 0);
  // return -1 if socket allocation failed
  if (sfd == FAILED) {
    return FAILED;
  }

  return sfd;
}

int bind_socket(int fd, const char *port_num) {
  // get a socket address using getaddrinfo
  struct addrinfo hints, *res;
  // intiate sock_addr to be 0's of struct size
  memset(&hints, 0, sizeof(hints));

  // set the AI_PASSIVE flag so that address is bindable
  hints.ai_flags = AI_PASSIVE;

  // get address for socket to bind to
  if (getaddrinfo(NULL, port_num, &hints, &res) == FAILED) {
    freeaddrinfo(res);
    return FAILED;
  }

  // bind socket to address
  if (bind(fd, res->ai_addr, sizeof(*res->ai_addr)) == FAILED) {
    freeaddrinfo(res);
    return FAILED;
  }

  freeaddrinfo(res);
  return SUCCESS;
}

int accept_connection(int sfd) {
  // declare peer address variables
  int cfd;
  struct sockaddr_in peer_addr;
  socklen_t peer_addr_size = sizeof(peer_addr);

  // try to accept connection from client, save socket in cfd
  cfd = accept(sfd, (struct sockaddr *)&peer_addr, &peer_addr_size);
  if (cfd == FAILED) {
    return FAILED;
  }

  // log peer address using syslog
  syslog(LOG_DEBUG, "Accepted connection from: %ud", peer_addr.sin_addr.s_addr);
  return cfd;
}

int open_stream(const char *port_num) {
  // open a new socket in stream mode
  int cfd;
  int sfd = create_socket();
  struct sockaddr_in peer_addr;
  socklen_t peer_addr_size;

  // bind socket to address and listen for connections...
  if (sfd == -1) {
    return FAILED;
  }

  if (bind_socket(sfd, port_num) == FAILED) {
    return FAILED;
  }

  if (listen(sfd, LISTEN_BACKLOG) == FAILED) {
    return FAILED;
  }

  // accept incoming connectin, store info in peer_addr
  cfd = accept_connection(sfd);
  if (cfd == FAILED) {
    return FAILED;
  }

  return SUCCESS;
}
