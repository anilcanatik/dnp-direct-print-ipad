#ifndef DNPHostBridge_h
#define DNPHostBridge_h

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

uint32_t dnp_host_open(void);
void dnp_host_close(uint32_t connection);
int32_t dnp_host_write(uint32_t connection, const void *bytes, size_t length);
int32_t dnp_host_transact(uint32_t connection,
                          const void *request,
                          size_t requestLength,
                          void *response,
                          size_t *responseLength);

#ifdef __cplusplus
}
#endif

#endif /* DNPHostBridge_h */

