const std = @import("std");
const micro = @import("microzig");
const cbor = @import("zbor");

const status_led_pin = micro.Pin("PA14");
const user_switch_pin = micro.Pin("PA15");

pub fn main() !void {
    micro.chip.nvmctrlInit();
    micro.chip.enableTrng();
    micro.chip.crypto.public_key.init();

    const status_led = micro.Gpio(status_led_pin, .{
        .mode = .output,
        .initial_state = .low,
    });
    status_led.init();

    var uart = micro.Uart(5, .{ .tx = null, .rx = null }).init(.{
        .baud_rate = 115200,
        .stop_bits = .one,
        .parity = null,
        .data_bits = .eight,
    }) catch |err| {
        blinkError(status_led, err);

        micro.hang();
    };

    var out = uart.writer();

    micro.chip.gpio.setInputPullUp(user_switch_pin.source_pin);

    while (true) {
        // Fixed buffer allocator won't reuse freed memory
        // so no point in keeping it around.
        var buffer: [512]u8 = undefined;
        var fba = std.heap.FixedBufferAllocator.init(&buffer);
        const allocator = fba.allocator();

        busyloop();
        status_led.toggle();

        const r: u32 = micro.chip.crypto.random.getWord();

        var di = try cbor.DataItem.map(allocator, &.{
            cbor.Pair.new(try cbor.DataItem.text(allocator, "random"), cbor.DataItem.int(r)),
        });
        defer di.deinit(allocator);

        //try cbor.encode(out, &di);
        try out.print("random: {d}", .{r});
        try out.writeAll("\n\r");
    }
}

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
