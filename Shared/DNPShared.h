#ifndef DNPShared_h
#define DNPShared_h

#include <stdint.h>

enum DNPExternalMethod : uint32_t {
    kDNPExternalMethodWrite = 0,
    kDNPExternalMethodTransact = 1,
    kDNPExternalMethodCount
};

enum {
    kDNPMaximumWriteChunk = 256 * 1024,
    kDNPMaximumResponse = 4096
};

#endif /* DNPShared_h */

