#include "threading.h"
#include <pthread.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>

// Optional: use these functions to add debug or error prints to your
// application
// #define DEBUG_LOG(msg, ...)
#define DEBUG_LOG(msg, ...) printf("threading: " msg "\n", ##__VA_ARGS__);
#define ERROR_LOG(msg, ...) printf("threading ERROR: " msg "\n", ##__VA_ARGS__);

int wait_millisecs(int millisecs) { return usleep(millisecs * 1000); }

void *threadfunc(void *thread_param) {

  // TODO: wait, obtain mutex, wait, release mutex as described by thread_data
  // structure hint: use a cast like the one below to obtain thread arguments
  // from your parameter
  // struct thread_data* thread_func_args = (struct thread_data *) thread_param;

  // DEBUG_LOG("started thread func")
  // fflush(stdin);
  struct thread_data *data_ptr = (struct thread_data *)thread_param;
  int wait_to_obtain_ms = data_ptr->wait_to_obtain_ms;
  int wait_to_release_ms = data_ptr->wait_to_release_ms;

  // DEBUG_LOG("acquired data and starting wait sequence %d %d",
  // wait_to_obtain_ms,
  //          wait_to_release_ms);
  // wait before obtaining mutex in data pointer
  if (wait_millisecs(wait_to_obtain_ms) != 0) {
    ERROR_LOG("wait error");
    data_ptr->thread_complete_success = false;
    return thread_param;
  }
  // lock mutex after wait
  if (pthread_mutex_lock(data_ptr->wait_mutex) != 0) {
    ERROR_LOG("mutex error");
    data_ptr->thread_complete_success = false;
    return thread_param;
  }

  // DEBUG_LOG("MUTEX ATTAINED!");
  // fflush(stdin);

  // wait before releasing mutex
  if (wait_millisecs(wait_to_release_ms) != 0) {
    ERROR_LOG("wait error");
    data_ptr->thread_complete_success = false;
    return thread_param;
  }
  // unlock mutex after wait
  if (pthread_mutex_unlock(data_ptr->wait_mutex) != 0) {
    ERROR_LOG("mutex error");
    data_ptr->thread_complete_success = false;
    return thread_param;
  }

  // set complete flag to true
  data_ptr->thread_complete_success = true;

  return thread_param;
}

bool start_thread_obtaining_mutex(pthread_t *thread, pthread_mutex_t *mutex,
                                  int wait_to_obtain_ms,
                                  int wait_to_release_ms) {
  /**
   * TODO: allocate memory for thread_data, setup mutex and wait arguments, pass
   * thread_data to created thread using threadfunc() as entry point.
   *
   * return true if successful.
   *
   * See implementation details in threading.h file comment block
   */
  struct thread_data *t_data =
      (struct thread_data *)malloc(sizeof(struct thread_data));

  if (!t_data) {
    return false;
  }

  t_data->wait_mutex = mutex;
  t_data->wait_to_obtain_ms = wait_to_obtain_ms;
  t_data->wait_to_release_ms = wait_to_release_ms;
  t_data->thread_complete_success = true;
  // start new thread with threadfunc and t_data
  if (pthread_create(thread, NULL, threadfunc, t_data) != 0) {
    ERROR_LOG("pthread_create error");
    free(t_data);
    return false;
  }

  t_data->thread = *thread;

  // no need to block for the thread
  return t_data->thread_complete_success;
}
