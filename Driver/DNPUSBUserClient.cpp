#include <DriverKit/IOLib.h>
#include <DriverKit/IOMemoryMap.h>
#include <DriverKit/IOUserClient.h>
#include <DriverKit/OSData.h>

#include "DNPUSBDriver.h"
#include "DNPUSBUserClient.h"
#include "DNPShared.h"

struct DNPUSBUserClient_IVars {
    DNPUSBDriver *driver = nullptr;
};

static kern_return_t DNPMapInput(IOUserClientMethodArguments *arguments,
                                 const uint8_t **bytes,
                                 uint64_t *length,
                                 IOMemoryMap **mapping)
{
    *bytes = nullptr;
    *length = 0;
    *mapping = nullptr;
    if (arguments->structureInput != nullptr) {
        *bytes = static_cast<const uint8_t *>(arguments->structureInput->getBytesNoCopy());
        *length = arguments->structureInput->getLength();
        return *bytes == nullptr ? kIOReturnBadArgument : kIOReturnSuccess;
    }
    if (arguments->structureInputDescriptor != nullptr) {
        kern_return_t result = arguments->structureInputDescriptor->CreateMapping(0, 0, 0, 0, 0, mapping);
        if (result != kIOReturnSuccess || *mapping == nullptr) return result;
        *bytes = reinterpret_cast<const uint8_t *>((*mapping)->GetAddress());
        uint64_t descriptorLength = 0;
        result = arguments->structureInputDescriptor->GetLength(&descriptorLength);
        if (result != kIOReturnSuccess) return result;
        *length = descriptorLength;
        return *bytes == nullptr ? kIOReturnBadArgument : kIOReturnSuccess;
    }
    return kIOReturnBadArgument;
}

bool DNPUSBUserClient::init()
{
    if (!super::init()) return false;
    ivars = IONewZero(DNPUSBUserClient_IVars, 1);
    return ivars != nullptr;
}

void DNPUSBUserClient::free()
{
    if (ivars != nullptr) {
        OSSafeReleaseNULL(ivars->driver);
        IOSafeDeleteNULL(ivars, DNPUSBUserClient_IVars, 1);
    }
    super::free();
}

kern_return_t IMPL(DNPUSBUserClient, Start)
{
    kern_return_t result = Start(provider, SUPERDISPATCH);
    if (result != kIOReturnSuccess) return result;
    ivars->driver = OSDynamicCast(DNPUSBDriver, provider);
    if (ivars->driver == nullptr) {
        Stop(provider, SUPERDISPATCH);
        return kIOReturnNoDevice;
    }
    ivars->driver->retain();
    return kIOReturnSuccess;
}

kern_return_t IMPL(DNPUSBUserClient, Stop)
{
    OSSafeReleaseNULL(ivars->driver);
    return Stop(provider, SUPERDISPATCH);
}

kern_return_t DNPUSBUserClient::ExternalMethod(uint64_t selector,
                                               IOUserClientMethodArguments *arguments,
                                               const IOUserClientMethodDispatch *dispatch,
                                               OSObject *target,
                                               void *reference)
{
    (void)dispatch;
    (void)target;
    (void)reference;
    if (arguments == nullptr || ivars->driver == nullptr) return kIOReturnNotReady;
    if (selector >= kDNPExternalMethodCount) return kIOReturnUnsupported;

    const uint8_t *input = nullptr;
    uint64_t inputLength = 0;
    IOMemoryMap *inputMapping = nullptr;
    kern_return_t result = DNPMapInput(arguments, &input, &inputLength, &inputMapping);
    if (result != kIOReturnSuccess) goto exit;

    if (selector == kDNPExternalMethodWrite) {
        if (inputLength == 0 || inputLength > kDNPMaximumWriteChunk) {
            result = kIOReturnBadArgument;
            goto exit;
        }
        result = ivars->driver->WriteBytes(input, static_cast<uint32_t>(inputLength));
    } else if (selector == kDNPExternalMethodTransact) {
        if (inputLength == 0 || inputLength > 4096) {
            result = kIOReturnBadArgument;
            goto exit;
        }
        uint8_t response[kDNPMaximumResponse] = {};
        uint32_t responseLength = 0;
        result = ivars->driver->Transact(input,
                                         static_cast<uint32_t>(inputLength),
                                         response,
                                         sizeof(response),
                                         &responseLength);
        if (result == kIOReturnSuccess) {
            arguments->structureOutput = OSData::withBytes(response, responseLength);
            if (arguments->structureOutput == nullptr) result = kIOReturnNoMemory;
        }
    }

exit:
    OSSafeReleaseNULL(inputMapping);
    return result;
}
