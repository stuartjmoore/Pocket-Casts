#include <Cocoa/Cocoa.h>
#import <IOKit/hidsystem/ev_keymap.h>
#import <Carbon/Carbon.h>

// http://overooped.com/post/2593597587/mediakeys

#define SPSystemDefinedEventMediaKeys 8

@interface SPMediaKeyTap : NSObject {
	EventHandlerRef _app_switching_ref;
	EventHandlerRef _app_terminating_ref;
	CFMachPortRef _eventPort;
	CFRunLoopSourceRef _eventPortSource;
	CFRunLoopRef _tapThreadRL;
	BOOL _shouldInterceptMediaKeyEvents;
	id _delegate;
	// The app that is frontmost in this list owns media keys
	NSMutableArray *_mediaKeyAppList;
}
+ (nonnull NSArray*)defaultMediaKeyUserBundleIdentifiers;

-(nonnull id)initWithDelegate:(nonnull id)delegate;

+(BOOL)usesGlobalMediaKeyTap;
-(void)startWatchingMediaKeys;
-(void)stopWatchingMediaKeys;
-(void)handleAndReleaseMediaKeyEvent:(nonnull NSEvent *)event;
@end

@interface NSObject (SPMediaKeyTapDelegate)
-(void)mediaKeyTap:(nullable SPMediaKeyTap*)keyTap receivedMediaKeyEvent:(nonnull NSEvent*)event;
@end

#ifdef __cplusplus
extern "C" {
#endif

extern NSString* _Nonnull kMediaKeyUsingBundleIdentifiersDefaultsKey;
extern NSString* _Nonnull kIgnoreMediaKeysDefaultsKey;

#ifdef __cplusplus
}
#endif
