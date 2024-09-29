// simple application which creates a new file with name and path
// with content writestr, overwriting any existing file
// and assuming the path is valid.

#include <stdio.h>
#include <stdlib.h>
#include <sys/syslog.h>
#include <syslog.h>

#define PATHERR "No such file or directory\n"
#define ARGCERR "writer [writefile] [writestr]\n"
#define DEBUGMSG(str, file) "Writing %s to %s\n", str, file
// arg 1 - full path to file (writefile)
// arg 2 - text string which will be written to file (writestr)
// exit 0 for success, exit 1 for failure

int main(int argc, char *argv[]) {
  // open syslog connection for debugging and error logging
  openlog(NULL, LOG_CONS, LOG_USER);

  // if argc less than 3, not enough arguments
  if (argc < 3) {
    // printf("Usage: " ARGCERR);
    syslog(LOG_ERR, "Usage: " ARGCERR);
    exit(1);
  }

  const char *writefile = argv[1];
  char *writestr = argv[2];
  // try to open file
  FILE *writefile_p = fopen(writefile, "w");
  if (!writefile_p) {
    // log error no file exists and exit 1
    // printf("Error: " PATHERR);
    syslog(LOG_ERR, "Error: " PATHERR);
    exit(1);
  }

  // TODO log writing to file
  syslog(LOG_DEBUG, DEBUGMSG(writestr, writefile));
  // write writestr to writefile
  fprintf(writefile_p, "%s\n", writestr);
  fclose(writefile_p);
  exit(0);
}
