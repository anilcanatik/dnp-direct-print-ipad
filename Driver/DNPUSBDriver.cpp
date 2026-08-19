#include <os/log.h>
#include <DriverKit/IOLib.h>
#include <DriverKit/IOBufferMemoryDescriptor.h>
#include <USBDriverKit/USBDriverKit.h>

#include "DNPUSBDriver.h"

#define DNPLog(fmt, ...) os_log(OS_LOG_DEFAULT, "DNPUSBDriver - " fmt, ##__VA_ARGS__)

struct DNPUSBDriver_IVars {
    IOUSBHostInterface *interface = nullptr;
    IOUSBHostPipe *pipeOut = nullptr;
    IOUSBHostPipe *pipeIn = nullptr;
    bool interfaceOpen = false;
};

static kern_return_t DNPReadExact(DNPUSBDriver_IVars *state,
                                  uint8_t *destination,
                                  uint32_t required,
                                  uint32_t timeoutMilliseconds)
{
    uint32_t offset = 0;
    while (offset < required) {
        IOBufferMemoryDescriptor *buffer = nullptr;
        kern_return_t result = state->interface->CreateIOBuffer(
            kIOMemoryDirectionIn, required - offset, &buffer);
        if (result != kIOReturnSuccess || buffer == nullptr) {
            OSSafeReleaseNULL(buffer);
            return result == kIOReturnSuccess ? kIOReturnNoMemory : result;
        }

        uint32_t received = 0;
        result = state->pipeIn->IO(buffer, required - offset, &received, timeoutMilliseconds);
        if (result == kIOReturnSuccess && received > 0) {
            IOAddressSegment segment;
            buffer->GetAddressRange(&segment);
            memcpy(destination + offset, reinterpret_cast<void *>(segment.address), received);
            offset += received;
        }
        OSSafeReleaseNULL(buffer);
        if (result != kIOReturnSuccess) return result;
        if (received == 0) return kIOReturnUnderrun;
    }
    return kIOReturnSuccess;
}

bool DNPUSBDriver::init()
{
    if (!super::init()) return false;
    ivars = IONewZero(DNPUSBDriver_IVars, 1);
    return ivars != nullptr;
}

void DNPUSBDriver::free()
{
    if (ivars != nullptr) {
        OSSafeReleaseNULL(ivars->pipeOut);
        OSSafeReleaseNULL(ivars->pipeIn);
        IOSafeDeleteNULL(ivars, DNPUSBDriver_IVars, 1);
    }
    super::free();
}

kern_return_t IMPL(DNPUSBDriver, Start)
{
    kern_return_t result = Start(provider, SUPERDISPATCH);
    if (result != kIOReturnSuccess) return result;

    ivars->interface = OSDynamicCast(IOUSBHostInterface, provider);
    if (ivars->interface == nullptr) {
        result = kIOReturnNoDevice;
        goto fail;
    }

    result = ivars->interface->Open(this, 0, nullptr);
    if (result != kIOReturnSuccess) goto fail;
    ivars->interfaceOpen = true;

    // DNP models expose one bulk OUT and one bulk IN endpoint. Probe endpoint
    // addresses rather than hard-code them, because firmware revisions may
    // assign different endpoint numbers.
    for (uint8_t endpoint = 1; endpoint < 16 && ivars->pipeOut == nullptr; ++endpoint) {
        IOUSBHostPipe *candidate = nullptr;
        if (ivars->interface->CopyPipe(endpoint, &candidate) == kIOReturnSuccess) {
            ivars->pipeOut = candidate;
        }
    }
    for (uint8_t endpoint = 0x81; endpoint < 0x90 && ivars->pipeIn == nullptr; ++endpoint) {
        IOUSBHostPipe *candidate = nullptr;
        if (ivars->interface->CopyPipe(endpoint, &candidate) == kIOReturnSuccess) {
            ivars->pipeIn = candidate;
        }
    }
    if (ivars->pipeOut == nullptr || ivars->pipeIn == nullptr) {
        result = kIOReturnNoDevice;
        goto fail;
    }

    result = RegisterService();
    if (result != kIOReturnSuccess) goto fail;
    DNPLog("ready");
    return kIOReturnSuccess;

fail:
    OSSafeReleaseNULL(ivars->pipeOut);
    OSSafeReleaseNULL(ivars->pipeIn);
    if (ivars->interfaceOpen) {
        ivars->interface->Close(this, 0);
        ivars->interfaceOpen = false;
    }
    Stop(provider, SUPERDISPATCH);
    DNPLog("start failed: 0x%x", result);
    return result;
}

kern_return_t IMPL(DNPUSBDriver, Stop)
{
    OSSafeReleaseNULL(ivars->pipeOut);
    OSSafeReleaseNULL(ivars->pipeIn);
    if (ivars->interface != nullptr && ivars->interfaceOpen) {
        ivars->interface->Close(this, 0);
        ivars->interfaceOpen = false;
    }
    ivars->interface = nullptr;
    return Stop(provider, SUPERDISPATCH);
}

kern_return_t IMPL(DNPUSBDriver, NewUserClient)
{
    IOService *service = nullptr;
    kern_return_t result = Create(this, "UserClientProperties", &service);
    if (result != kIOReturnSuccess || service == nullptr) {
        return result == kIOReturnSuccess ? kIOReturnError : result;
    }
    *userClient = OSDynamicCast(IOUserClient, service);
    if (*userClient == nullptr) {
        service->release();
        return kIOReturnError;
    }
    return kIOReturnSuccess;
}

kern_return_t DNPUSBDriver::WriteBytes(const uint8_t *bytes, uint32_t length)
{
    if (bytes == nullptr || length == 0) return kIOReturnBadArgument;
    if (ivars->interface == nullptr || ivars->pipeOut == nullptr) return kIOReturnNotReady;

    IOBufferMemoryDescriptor *buffer = nullptr;
    kern_return_t result = ivars->interface->CreateIOBuffer(kIOMemoryDirectionOut, length, &buffer);
    if (result != kIOReturnSuccess || buffer == nullptr) {
        OSSafeReleaseNULL(buffer);
        return result == kIOReturnSuccess ? kIOReturnNoMemory : result;
    }

    IOAddressSegment segment;
    buffer->GetAddressRange(&segment);
    memcpy(reinterpret_cast<void *>(segment.address), bytes, length);
    buffer->SetLength(length);

    uint32_t transferred = 0;
    result = ivars->pipeOut->IO(buffer, length, &transferred, 30'000);
    OSSafeReleaseNULL(buffer);
    if (result == kIOReturnSuccess && transferred != length) return kIOReturnUnderrun;
    return result;
}

kern_return_t DNPUSBDriver::Transact(const uint8_t *request,
                                     uint32_t requestLength,
                                     uint8_t *response,
                                     uint32_t responseCapacity,
                                     uint32_t *responseLength)
{
    if (request == nullptr || requestLength == 0 || response == nullptr || responseLength == nullptr) {
        return kIOReturnBadArgument;
    }
    *responseLength = 0;
    kern_return_t result = WriteBytes(request, requestLength);
    if (result != kIOReturnSuccess) return result;

    uint8_t lengthHeader[8] = {};
    result = DNPReadExact(ivars, lengthHeader, sizeof(lengthHeader), 5'000);
    if (result != kIOReturnSuccess) return result;

    uint32_t payloadLength = 0;
    for (uint32_t index = 0; index < sizeof(lengthHeader); ++index) {
        if (lengthHeader[index] < '0' || lengthHeader[index] > '9') return kIOReturnBadMessageID;
        payloadLength = payloadLength * 10 + static_cast<uint32_t>(lengthHeader[index] - '0');
    }
    if (payloadLength > responseCapacity) return kIOReturnNoSpace;
    if (payloadLength == 0) return kIOReturnSuccess;

    result = DNPReadExact(ivars, response, payloadLength, 5'000);
    if (result == kIOReturnSuccess) *responseLength = payloadLength;
    return result;
}

