#ifndef YourAppName_Bridging_Header_h
#define YourAppName_Bridging_Header_h

#import "MediaRemote.h"
#import <dlfcn.h>

// workaround for not managing to link the private framework
typedef void (*MRMediaRemoteSendCommandFunction)(unsigned int command, void* userInfo);
static MRMediaRemoteSendCommandFunction getMRMediaRemoteSendCommand() {
    void* handle = dlopen("/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote", RTLD_LAZY);
    if (!handle) return NULL;
    return (MRMediaRemoteSendCommandFunction)dlsym(handle, "MRMediaRemoteSendCommand");
}

#endif /* YourAppName_Bridging_Header_h */
