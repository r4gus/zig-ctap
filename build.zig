const std = @import("std");
const microzig = @import("libs/microzig/src/main.zig");

pub fn build(b: *std.build.Builder) void {
    const backing = .{
        .chip = microzig.chips.atsame51j20a,
    };

    var exe = microzig.addEmbeddedExecutable(b, "zig-ctap", "src/main.zig", backing, .{
        // optional slice of packages that can be imported into your app:b
        // .packages = &my_packages,
    });

    exe.setBuildMode(.ReleaseSmall);
    exe.inner.strip = true;
    exe.addPackagePath("zbor", "libs/zbor/src/main.zig");
    exe.install();

    // ########################################################################
    // Use `zig build edbg` to:
    //   1. build the raw binary
    //   2. program the device using edbg (Microchip SAM)
    // ########################################################################

    const bin = exe.installRaw("zig-ctap.bin", .{});

    const edbg = b.addSystemCommand(&[_][]const u8{
        "sudo", "edbg", "-b", "-t", "same51", "-pv", "-f", "zig-out/bin/zig-ctap.bin",
    });
    edbg.step.dependOn(&bin.step);

    const program_step = b.step("edbg", "Program the chip using edbg");
    program_step.dependOn(&edbg.step);
}
