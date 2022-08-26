#import "PrinterControllerPlugin.h"
#if __has_include(<printer_controller/printer_controller-Swift.h>)
#import <printer_controller/printer_controller-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "printer_controller-Swift.h"
#endif

@implementation PrinterControllerPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftPrinterControllerPlugin registerWithRegistrar:registrar];
}
@end
