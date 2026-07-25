#import <AppKit/AppKit.h>
#import <ApplicationServices/ApplicationServices.h>
#import <CoreGraphics/CoreGraphics.h>
#import <sys/wait.h>
#import <unistd.h>

static NSScreen *preferred_external_screen(void)
{
    NSScreen *fallback = nil;

    for (NSScreen *screen in NSScreen.screens) {
        NSNumber *screenNumber = screen.deviceDescription[@"NSScreenNumber"];
        if (!screenNumber || CGDisplayIsBuiltin(screenNumber.unsignedIntValue)) {
            continue;
        }

        if (!fallback) fallback = screen;
        if ([screen.localizedName isEqualToString:@"VX2779 Series"]) {
            return screen;
        }
    }

    return fallback;
}

static NSArray<NSRunningApplication *> *running_re7_apps(void)
{
    NSMutableArray<NSRunningApplication *> *matches = [NSMutableArray array];

    for (NSRunningApplication *app in NSWorkspace.sharedWorkspace.runningApplications) {
        if ([app.localizedName.lowercaseString isEqualToString:@"re7.exe"]) {
            [matches addObject:app];
        }
    }

    return matches;
}

static void move_ax_window(AXUIElementRef window, CGRect displayBounds)
{
    CFTypeRef sizeValue = NULL;
    CGSize size = CGSizeZero;

    if (AXUIElementCopyAttributeValue(
            window,
            kAXSizeAttribute,
            &sizeValue
        ) != kAXErrorSuccess ||
        !sizeValue ||
        CFGetTypeID(sizeValue) != AXValueGetTypeID() ||
        !AXValueGetValue((AXValueRef)sizeValue, kAXValueCGSizeType, &size)) {
        if (sizeValue) CFRelease(sizeValue);
        return;
    }
    CFRelease(sizeValue);

    if (size.width < 320 || size.height < 200) return;

    CGPoint position = CGPointMake(
        CGRectGetMidX(displayBounds) - size.width / 2.0,
        CGRectGetMidY(displayBounds) - size.height / 2.0
    );
    AXValueRef positionValue = AXValueCreate(kAXValueCGPointType, &position);
    if (!positionValue) return;

    AXUIElementSetAttributeValue(window, kAXPositionAttribute, positionValue);
    CFRelease(positionValue);
}

static BOOL move_re7_windows(void)
{
    NSScreen *target = preferred_external_screen();
    if (!target || !AXIsProcessTrusted()) return NO;

    NSNumber *screenNumber = target.deviceDescription[@"NSScreenNumber"];
    if (!screenNumber) return NO;

    CGRect displayBounds = CGDisplayBounds(screenNumber.unsignedIntValue);
    NSArray<NSRunningApplication *> *apps = running_re7_apps();

    for (NSRunningApplication *app in apps) {
        AXUIElementRef axApp = AXUIElementCreateApplication(app.processIdentifier);
        CFTypeRef windowsValue = NULL;

        if (AXUIElementCopyAttributeValue(
                axApp,
                kAXWindowsAttribute,
                &windowsValue
            ) == kAXErrorSuccess &&
            windowsValue &&
            CFGetTypeID(windowsValue) == CFArrayGetTypeID()) {
            CFArrayRef windows = (CFArrayRef)windowsValue;
            for (CFIndex index = 0; index < CFArrayGetCount(windows); index++) {
                move_ax_window(
                    (AXUIElementRef)CFArrayGetValueAtIndex(windows, index),
                    displayBounds
                );
            }
        }

        if (windowsValue) CFRelease(windowsValue);
        CFRelease(axApp);
    }

    return apps.count > 0;
}

static NSString *original_executable_path(void)
{
    NSString *contents = NSBundle.mainBundle.bundlePath;
    NSString *record = [contents stringByAppendingPathComponent:
        @"Contents/Resources/re7-mac-controller-fix/external-display-original-executable"];
    NSString *name = [[NSString stringWithContentsOfFile:
        record
        encoding:NSUTF8StringEncoding
        error:nil] stringByTrimmingCharactersInSet:
        NSCharacterSet.whitespaceAndNewlineCharacterSet];

    if (!name.length || [name containsString:@"/"]) return nil;
    return [contents stringByAppendingPathComponent:
        [@"Contents/MacOS" stringByAppendingPathComponent:name]];
}

int main(int argc, char **argv)
{
    @autoreleasepool {
        NSString *target = original_executable_path();
        if (!target.length) return 1;

        NSDictionary *options = @{
            (__bridge NSString *)kAXTrustedCheckOptionPrompt: @YES
        };
        AXIsProcessTrustedWithOptions((__bridge CFDictionaryRef)options);

        NSTask *task = [[NSTask alloc] init];
        task.executableURL = [NSURL fileURLWithPath:target];

        NSMutableArray<NSString *> *arguments = [NSMutableArray array];
        for (int index = 1; index < argc; index++) {
            [arguments addObject:[NSString stringWithUTF8String:argv[index]]];
        }
        task.arguments = arguments;
        task.currentDirectoryURL = [NSURL fileURLWithPath:
            [target stringByDeletingLastPathComponent]];

        NSError *launchError = nil;
        if (![task launchAndReturnError:&launchError]) return 1;

        BOOL sawRE7 = NO;
        NSUInteger missingTicks = 0;

        while (task.running || !sawRE7 || missingTicks < 40) {
            BOOL foundRE7 = move_re7_windows();
            if (foundRE7) {
                sawRE7 = YES;
                missingTicks = 0;
            } else if (sawRE7) {
                missingTicks++;
            }

            if (!task.running && !sawRE7) missingTicks++;
            if (!task.running && !sawRE7 && missingTicks >= 120) break;

            [NSRunLoop.currentRunLoop runUntilDate:
                [NSDate dateWithTimeIntervalSinceNow:0.25]];
        }

        return task.terminationStatus;
    }
}
