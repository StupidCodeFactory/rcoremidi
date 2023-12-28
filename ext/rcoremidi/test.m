#include <CoreMIDI/CoreMIDI.h>
#include <Foundation/Foundation.h>


const char * NSSTringToCString(void * name) {
    NSString *tmp = (__bridge NSString *)(name);
    const char * property = [tmp cStringUsingEncoding:[NSString defaultCStringEncoding]];
    return property;
}
