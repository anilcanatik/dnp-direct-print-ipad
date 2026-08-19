#include "DNPHostBridge.h"
#include "DNPShared.h"

#include <IOKit/IOKitLib.h>
#include <mach/mach.h>

uint32_t dnp_host_open(void)
{
    io_iterator_t iterator = IO_OBJECT_NULL;
    kern_return_t result = IOServiceGetMatchingServices(
        0, IOServiceNameMatching("DNPUSBDriver"), &iterator);
    if (result != KERN_SUCCESS) return 0;

    io_connect_t connection = IO_OBJECT_NULL;
    io_service_t service = IO_OBJECT_NULL;
    while ((service = IOIteratorNext(iterator)) != IO_OBJECT_NULL) {
        result = IOServiceOpen(service, mach_task_self_, 0, &connection);
        IOObjectRelease(service);
        if (result == KERN_SUCCESS) break;
        connection = IO_OBJECT_NULL;
    }
    IOObjectRelease(iterator);
    return (uint32_t)connection;
}

void dnp_host_close(uint32_t connection)
{
    if (connection != IO_OBJECT_NULL) IOServiceClose((io_connect_t)connection);
}

int32_t dnp_host_write(uint32_t connection, const void *bytes, size_t length)
{
    if (connection == IO_OBJECT_NULL || bytes == NULL || length == 0 || length > kDNPMaximumWriteChunk) {
        return KERN_INVALID_ARGUMENT;
    }
    return IOConnectCallStructMethod(
        (io_connect_t)connection,
        kDNPExternalMethodWrite,
        bytes,
        length,
        NULL,
        NULL);
}

int32_t dnp_host_transact(uint32_t connection,
                          const void *request,
                          size_t requestLength,
                          void *response,
                          size_t *responseLength)
{
    if (connection == IO_OBJECT_NULL || request == NULL || requestLength == 0 ||
        response == NULL || responseLength == NULL || *responseLength > kDNPMaximumResponse) {
        return KERN_INVALID_ARGUMENT;
    }
    return IOConnectCallStructMethod(
        (io_connect_t)connection,
        kDNPExternalMethodTransact,
        request,
        requestLength,
        response,
        responseLength);
}

