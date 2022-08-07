const micro = @import("microzig");

const status_led_pin = micro.Pin("PA14");

pub fn main() void {
    const status_led = micro.Gpio(status_led_pin, .{
        .mode = .output,
        .initial_state = .low,
    });
    status_led.init();

    while (true) {
        busyloop();
        status_led.toggle();
    }
}

fn busyloop() void {
    const limit = 500_000_0;

    var i: u32 = 0;
    while (i < limit) : (i += 1) {
        @import("std").mem.doNotOptimizeAway(i);
    }
}
