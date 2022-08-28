const std = @import("std");
const microzig = @import("libs/microzig/src/main.zig");

pub fn build(b: *std.build.Builder) void {
    const backing = .{
        .chip = microzig.chips.atsame51j20a,
    };

    const exe = microzig.addEmbeddedExecutable(b, "zig-ctap", "src/main.zig", backing, .{
        // optional slice of packages that can be imported into your app:b
        // .packages = &my_packages,
    });

    exe.inner.setBuildMode(.ReleaseSmall);
    exe.inner.strip = true;
    exe.inner.install();

    const bin = b.addInstallRaw(
        exe.inner,
        "zig-ctap.bin",
        .{},
    );

    const edbg = b.addSystemCommand(&[_][]const u8{
        "sudo", "edbg", "-b", "-t", "same51", "-pv", "-f", "zig-out/bin/zig-ctap.bin",
    });
    edbg.step.dependOn(&bin.step);

    const program_step = b.step("edbg", "Program the chip using edbg");
    program_step.dependOn(&edbg.step);
}
