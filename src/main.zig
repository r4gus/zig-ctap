const micro = @import("microzig");

const status_led_pin = micro.Pin("PA14");

pub fn main() !void {
    const status_led = micro.Gpio(status_led_pin, .{
        .mode = .output,
        .initial_state = .low,
    });
    status_led.init();
}

test "simple test" {

}
