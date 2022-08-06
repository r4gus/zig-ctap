pub const cpu = @import("cpu");
pub const micro = @import("microzig");
pub const chip = @import("registers.zig");

const regs = chip.registers;
pub usingnamespace chip;

pub const chip_name = "ATSAME51J20A";

pub const clock_frequencies = . {
    .cpu = 120_000_000, // Arm Cortex-M4 runs at 120 MHz
};

/// Get access to the pin specified by `spec`.
///
/// - `spec`: P{port}{pin}
///     - `port`: A, B
///     - `pin`: 0..31
pub fn parsePin(comptime spec: []const u8) type {
    const invalid_format_msg = "The given pin '" ++ spec ++ "' has an invalid format. Pins must follow the format \"P{Port}{Pin}\" scheme.";

    if (spec[0] != 'P')
        @compileError(invalid_format_msg);
    if (spec[1] < 'A' or spec[1] > 'B') // J = 64 Pins; 2 Ports
        @compileError("Unknown port '" ++ spec[1..2] ++ "'. Supported ports: A, B.");

    return struct {
        // Try to parse the given pin number as u6, i.e. a value in '0'..'31'.
        const pin_number: u5 = @import("std").fmt.parseInt(u5, spec[2..], 10) catch @compileError(invalid_format_msg);
        const pin_mask: u32 = (1 << pin_number);
        // Port is either 'A' or 'B'.
        const port_number: usize = if (spec[1] == 'A') 0 else 1;
        const gpio_port = @field(regs.PORT, "GROUP");
    };
}

pub const gpio = struct {
    pub fn setOutput(comptime pin: type) void {
        pin.gpio_port[pin.port_number].DIRSET |= pin.pin_mask;
    }

    pub fn setInput(comptime pin: type) void {
        pin.gpio_port[pin.port_number].DIRCLR |= pin.pin_mask;
    }

    pub fn read(comptime pin: type) micro.gpio.State {
        _ = pin;
        return micro.gpio.State.low;
    }

    pub fn write(comptime pin: type, state: micro.gpio.State) void {
        switch (state) {
            .high => pin.gpio_port[pin.port_number].OUTSET |= pin.pin_mask,
            .low => pin.gpio_port[pin.port_number].OUTCLR |= pin.pin_mask,
        }
    }
};