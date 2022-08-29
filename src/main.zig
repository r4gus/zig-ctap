const micro = @import("microzig");

const status_led_pin = micro.Pin("PA14");
const user_switch_pin = micro.Pin("PA15");

pub fn main() void {
    micro.chip.nvmctrlInit();

    const status_led = micro.Gpio(status_led_pin, .{
        .mode = .output,
        .initial_state = .low,
    });
    status_led.init();

    var uart = micro.Uart(5, .{ .tx = null, .rx = null }).init(.{
        //.baud_rate = 63019, // 65536 * ( 1 - 16 * (115200 / 48_000_000)), p. 830
        .baud_rate = 65326, // 65536 * ( 1 - 16 * (115200 / 48_000_000)), p. 830
        .stop_bits = .one,
        .parity = null,
        .data_bits = .eight,
    }) catch |err| {
        blinkError(status_led, err);

        micro.hang();
    };

    var out = uart.writer();
    _ = out;

    //const user_switch = micro.Gpio(user_switch_pin, .{.mode = .input});
    //user_switch.init();
    micro.chip.gpio.setInputPullUp(user_switch_pin.source_pin);

    while (true) {
        busyloop();
        status_led.toggle();
        uart.internal.tx('X');

        //if (micro.chip.gpio.read(user_switch_pin.source_pin) == .low) {
        //    status_led.write(.low);
        //
        //    uart.internal.tx('A');
        //} else {
        //    status_led.write(.high);
        //}
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
    const limit = 5_000_000;

    var i: u32 = 0;
    while (i < limit) : (i += 1) {
        @import("std").mem.doNotOptimizeAway(i);
    }
}
