const std = @import("std");
const micro = @import("microzig");
const cbor = @import("zbor");

const status_led_pin = micro.Pin("PA14");
const user_switch_pin = micro.Pin("PA15");

//pub fn main() !void {
//    micro.chip.nvmctrlInit();
//    micro.chip.enableTrng();
//
//    const status_led = micro.Gpio(status_led_pin, .{
//        .mode = .output,
//        .initial_state = .low,
//    });
//    status_led.init();
//
//    var uart = micro.Uart(5, .{ .tx = null, .rx = null }).init(.{
//        .baud_rate = 115200,
//        .stop_bits = .one,
//        .parity = null,
//        .data_bits = .eight,
//    }) catch |err| {
//        blinkError(status_led, err);
//
//        micro.hang();
//    };
//
//    var out = uart.writer();
//
//    micro.chip.gpio.setInputPullUp(user_switch_pin.source_pin);
//
//    while (true) {
//        // Fixed buffer allocator won't reuse freed memory
//        // so no point in keeping it around.
//        var buffer: [512]u8 = undefined;
//        var fba = std.heap.FixedBufferAllocator.init(&buffer);
//        const allocator = fba.allocator();
//
//        busyloop();
//        status_led.toggle();
//
//        const r: u32 = micro.chip.crypto.random.getWord();
//
//        var x: [12]u8 = undefined;
//        micro.chip.crypto.random.getBlock(&x);
//
//        var di = try cbor.DataItem.map(allocator, &.{
//            cbor.Pair.new(try cbor.DataItem.text(allocator, "random"), cbor.DataItem.int(r)),
//        });
//        defer di.deinit(allocator);
//
//        //try cbor.encode(out, &di);
//        //try out.print("random: {d}", .{r});
//        for (x) |value| {
//            try out.print("{x}", .{value});
//        }
//        try out.writeAll("\n\r");
//    }
//}

fn blinkError(led: anytype, err: micro.uart.InitError) void {
    var blinks: u3 =
        switch (err) {
        error.UnsupportedBaudRate => 1,
        error.UnsupportedParity => 2,
        error.UnsupportedStopBitCount => 3,
        error.UnsupportedWordSize => 4,
    };

    while (blinks > 0) : (blinks -= 1) {
        led.toggle();
        micro.debug.busySleep(1_000_000);
        led.toggle();
        micro.debug.busySleep(1_000_000);
    }
}

fn busyloop() void {
    const limit = 6_000_000;

    var i: u32 = 0;
    while (i < limit) : (i += 1) {
        @import("std").mem.doNotOptimizeAway(i);
    }
}

//--------------------------------------------------------------------+
// Extern
//--------------------------------------------------------------------+

// defined in tinyusb/src/class/hid/hid_device.h
extern fn tud_hid_n_report(instance: u8, report_id: u8, report: [*]const u8, len: u16) bool;
extern fn board_millis() u32;
extern fn board_led_write(state: bool) void;
extern fn board_init() void;
extern fn tud_init(rhport: u8) bool;
/// Task function should be called in main/rtos loop, extended version of tudTask.
/// - timeout_ms: milliseconds to wait, zero = no wait, 0xffffffff = wait forever
/// - in_isr: if function is called in ISR
extern fn tud_task_ext(timeout_ms: u32, in_isr: bool) void;

const HidReportType = enum(c_int) {
    // defined in tinyusb/src/class/hid/hid.h
    invalid = 0,
    input,
    output,
    feature,
};

//--------------------------------------------------------------------+
// Wrapper
//--------------------------------------------------------------------+

fn tudHidReport(report_id: u8, report: []const u8) bool {
    if (report.len > 65535) {
        return false;
    }

    // Note: the narrowing int cast is safe because of the check above.
    return tud_hid_n_report(0, report_id, report.ptr, @intCast(u16, report.len));
}

// Task function should be called in main loop.
fn tudTask() void {
    // UINT32_MAX
    tud_task_ext(0xffffffff, false);
}

//--------------------------------------------------------------------+
// Main
//--------------------------------------------------------------------+

pub fn main() void {
    board_init();

    // init device stack on configured roothub port.
    _ = tud_init(0);

    while (true) {
        tudTask(); // tinyusb device task
        led_blinking_task();
    }
}

//--------------------------------------------------------------------+
// MACRO CONSTANT TYPEDEF PROTYPES
//--------------------------------------------------------------------+

/// Blink pattern
/// - 250 ms    : device not mounted
/// - 1000 ms   : device mounted
/// - 2500 ms   : device is suspended
const Blink = enum(u32) {
    not_mounted = 250,
    mounted = 1000,
    suspended = 2500,
};

var blink_interval_ms: u32 = @enumToInt(Blink.not_mounted);

//--------------------------------------------------------------------+
// Device callbacks
//--------------------------------------------------------------------+

/// Invoked when device is mounted.
export fn tud_mount_cb() void {
    blink_interval_ms = @enumToInt(Blink.mounted);
}

// Invoked when device is unmounted.
export fn tud_umount_cb() void {
    blink_interval_ms = @enumToInt(Blink.not_mounted);
}

/// Invoked when usb bus is suspended
/// remote_wakeup_en : if host allow us  to perform remote wakeup
/// Within 7ms, device must draw an average of current less than 2.5 mA from bus
export fn tud_suspend_cb(remote_wakeup_en: bool) void {
    _ = remote_wakeup_en;
    blink_interval_ms = @enumToInt(Blink.suspended);
}

// Invoked when usb bus is resumed.
export fn tud_resume_cb() void {
    blink_interval_ms = @enumToInt(Blink.mounted);
}

//--------------------------------------------------------------------+
// USB HID
//--------------------------------------------------------------------+

/// Invoked when received SET_REPORT control request or
/// received data on OUT endpoint ( Report ID = 0, Type = 0 ).
export fn tud_hid_set_report_cb(itf: u8, report_id: u8, report_type: HidReportType, buffer: [*]u8, bufsize: u16) void {
    _ = itf;
    _ = report_id;
    _ = report_type;

    _ = tudHidReport(0, buffer[0..bufsize]);
}

// Invoked when received GET_REPORT control request.
// Application must fill buffer report's content and return its length.
// Return zero will cause the stack to STALL request.
export fn tud_hid_get_report_cb(itf: u8, report_id: u8, report_type: HidReportType, buffer: [*]u8, reqlen: u16) u16 {
    _ = itf;
    _ = report_id;
    _ = report_type;
    _ = buffer;
    _ = reqlen;

    return 0;
}

//--------------------------------------------------------------------+
// BLINKING TASK
//--------------------------------------------------------------------+

export fn led_blinking_task() void {
    const S = struct {
        var start_ms: u32 = 0;
        var led_state: bool = false;
    };

    if (board_millis() - S.start_ms < blink_interval_ms) return;
    S.start_ms += blink_interval_ms;

    board_led_write(S.led_state);
    S.led_state = !S.led_state;
}
