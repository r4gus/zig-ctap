const std = @import("std");
const microzig = @import("libs/microzig/src/main.zig");

fn compileTinyUsb(self: *std.build.Step) !void {
    _ = self;
}

pub fn build(b: *std.build.Builder) void {
    const backing = .{
        .chip = microzig.chips.atsame51j20a,
    };

    // ########################################################################
    // tinyusb
    // ########################################################################

    const tinyusb_path = "libs/tinyusb/";
    const flags = [_][]const u8{
        "-ggdb",
        "-fdata-sections",
        "-ffunction-sections",
        //"-fsingle-precision-constant",
        "-fno-strict-aliasing",
        "-Wall",
        "-Wextra",
        "-Werror",
        "-Wfatal-errors",
        "-Wdouble-promotion",
        "-Wstrict-prototypes",
        "-Wstrict-overflow",
        "-Werror-implicit-function-declaration",
        "-Wfloat-equal",
        "-Wundef",
        "-Wshadow",
        "-Wwrite-strings",
        "-Wsign-compare",
        "-Wmissing-format-attribute",
        "-Wunreachable-code",
        "-Wcast-align",
        "-Wcast-function-type",
        //"-Wcast-qual",
        "-Wnull-dereference",
        "-Wuninitialized",
        "-Wunused",
        "-Wredundant-decls",
        // chip
        "-mabi=aapcs",
        "-mlong-calls",
        "-mfloat-abi=hard",
    };
    const obj = [_][]const u8{
        // tinyusb core
        tinyusb_path ++ "src/tusb.c",
        tinyusb_path ++ "src/common/tusb_fifo.c",
        tinyusb_path ++ "src/device/usbd.c",
        tinyusb_path ++ "src/device/usbd_control.c",
        tinyusb_path ++ "src/class/audio/audio_device.c",
        tinyusb_path ++ "src/class/cdc/cdc_device.c",
        tinyusb_path ++ "src/class/dfu/dfu_device.c",
        tinyusb_path ++ "src/class/dfu/dfu_rt_device.c",
        tinyusb_path ++ "src/class/hid/hid_device.c",
        tinyusb_path ++ "src/class/midi/midi_device.c",
        tinyusb_path ++ "src/class/msc/msc_device.c",
        tinyusb_path ++ "src/class/net/ecm_rndis_device.c",
        tinyusb_path ++ "src/class/net/ncm_device.c",
        tinyusb_path ++ "src/class/usbtmc/usbtmc_device.c",
        tinyusb_path ++ "src/class/video/video_device.c",
        tinyusb_path ++ "src/class/vendor/vendor_device.c",
        // app
        "c_src/usb_descriptors.c",
        "c_src/same51curiositynano.c",
        // chip specific
        tinyusb_path ++ "src/portable/microchip/samd/dcd_samd.c",
        tinyusb_path ++ "hw/mcu/microchip/same51/gcc/gcc/startup_same51.c",
        tinyusb_path ++ "hw/mcu/microchip/same51/gcc/system_same51.c",
        tinyusb_path ++ "hw/mcu/microchip/same51/hal/utils/src/utils_syscalls.c",
        // board specific
    };

    var tinyusb = b.addStaticLibrary("tinyusb", null);
    tinyusb.addCSourceFiles(&obj, &flags);
    tinyusb.addIncludePath(tinyusb_path ++ "hw");
    tinyusb.addIncludePath(tinyusb_path ++ "src");
    tinyusb.addIncludePath(tinyusb_path ++ "src/class/audio");
    tinyusb.addIncludePath(tinyusb_path ++ "src/class/bth");
    tinyusb.addIncludePath(tinyusb_path ++ "src/class/cdc");
    tinyusb.addIncludePath(tinyusb_path ++ "src/class/dfu");
    tinyusb.addIncludePath(tinyusb_path ++ "src/class/hid");
    tinyusb.addIncludePath(tinyusb_path ++ "src/class/midi");
    tinyusb.addIncludePath(tinyusb_path ++ "src/class/msc");
    tinyusb.addIncludePath(tinyusb_path ++ "src/class/net");
    tinyusb.addIncludePath(tinyusb_path ++ "src/class/usbtmc");
    tinyusb.addIncludePath(tinyusb_path ++ "src/class/vendor");
    tinyusb.addIncludePath(tinyusb_path ++ "src/class/video");
    tinyusb.addIncludePath(tinyusb_path ++ "src/common");
    tinyusb.addIncludePath(tinyusb_path ++ "src/device");
    tinyusb.addIncludePath(tinyusb_path ++ "src/host");
    tinyusb.addIncludePath(tinyusb_path ++ "src/osal");
    tinyusb.addIncludePath(tinyusb_path ++ "src/portable/chipidea/ci_hs");
    tinyusb.addIncludePath(tinyusb_path ++ "src/portable/ehci");
    tinyusb.addIncludePath(tinyusb_path ++ "src/portable/mentor/musb");
    tinyusb.addIncludePath(tinyusb_path ++ "src/portable/microchip/samx7x");
    // main
    tinyusb.addIncludePath("c_src");
    // system
    tinyusb.addIncludePath("/usr/include");
    tinyusb.addIncludePath("/usr/local/include");
    // chip specific
    tinyusb.addIncludePath(tinyusb_path ++ "hw/mcu/microchip/same51");
    tinyusb.addIncludePath(tinyusb_path ++ "hw/mcu/microchip/same51/config");
    tinyusb.addIncludePath(tinyusb_path ++ "hw/mcu/microchip/same51/include");
    tinyusb.addIncludePath(tinyusb_path ++ "hw/mcu/microchip/same51/hal/include");
    tinyusb.addIncludePath(tinyusb_path ++ "hw/mcu/microchip/same51/hal/utils/include");
    tinyusb.addIncludePath(tinyusb_path ++ "hw/mcu/microchip/same51/hpl/port");
    tinyusb.addIncludePath(tinyusb_path ++ "hw/mcu/microchip/same51/hri");
    tinyusb.addIncludePath(tinyusb_path ++ "hw/mcu/microchip/same51/CMSIS/Include");
    // board specific
    tinyusb.addIncludePath(tinyusb_path ++ "bsp");
    tinyusb.defineCMacro("__SAME51J20A__", "1");
    tinyusb.defineCMacro("CONF_CPU_FREQUENCY", "48000000");
    tinyusb.defineCMacro("CFG_TUSB_MCU", "OPT_MCU_SAME5X");
    tinyusb.defineCMacro("BOARD_NAME", "\"Microchip SAM E51 Curiosity Nano\"");
    tinyusb.setTarget(std.zig.CrossTarget{
        .cpu_arch = .thumb,
        .cpu_model = .{ .explicit = &std.Target.arm.cpu.cortex_m4 },
        .os_tag = .freestanding,
        .abi = .eabihf,
    });
    tinyusb.install();

    // ########################################################################
    // main
    // ########################################################################

    var exe = microzig.addEmbeddedExecutable(b, "zig-ctap", "src/main.zig", backing, .{
        // optional slice of packages that can be imported into your app:b
        // .packages = &my_packages,
    });
    exe.inner.step.dependOn(&tinyusb.step);

    exe.setBuildMode(.ReleaseSmall);
    exe.inner.strip = true;
    exe.addPackagePath("zbor", "libs/zbor/src/main.zig");
    //exe.inner.addLibraryPath("zig-out/lib/libtinyusb.a");
    exe.inner.linkLibrary(tinyusb);
    //exe.inner.linkSystemLibrary("m");
    //exe.inner.linkSystemLibrary("nosys");
    //exe.inner.linkSystemLibrary("gcc");
    exe.inner.addObjectFile("/usr/arm-none-eabi/lib/thumb/v7e-m+fp/hard/libc.a");
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
