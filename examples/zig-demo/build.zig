const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "zig-demo",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    // Include path to the C library headers
    exe.addIncludePath(.{ .path = "../../lib/webserver/include" });

    // Link the prebuilt static library (ensure `make` ran at repo root)
    exe.addObjectFile(.{ .path = "../../build/libwebserver.a" });

    // Link libc and pthread
    exe.linkLibC();
    exe.linkSystemLibrary("pthread");

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    const run_step = b.step("run", "Run the zig demo");
    run_step.dependOn(&run_cmd.step);
}
