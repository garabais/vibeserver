const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "zig-demo",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    // Use default target/optimize; override via `zig build -Dtarget=... -Doptimize=...` if desired.

    // Include path to the C library headers
    exe.addIncludePath(b.path("../../lib/webserver/include"));

    // Link the prebuilt static library (ensure `make` ran at repo root)
    exe.addObjectFile(b.path("../../build/lib/libwebserver.a"));

    // Link libc and pthread
    exe.linkLibC();
    exe.linkSystemLibrary("pthread");

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    const run_step = b.step("run", "Run the zig demo");
    run_step.dependOn(&run_cmd.step);
}
