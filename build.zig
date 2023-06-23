//! Requires zig version: 0.11 or higher
//! build: zig build -Doptimize=ReleaseFast -DShared (or -DShared=true/false)

const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Options
    const shared = b.option(bool, "Shared", "Build the Shared Library [default: false]") orelse false;
    const tests = b.option(bool, "Tests", "Build tests [default: false]") orelse false;

    const libcppcoro = if (!shared) b.addStaticLibrary(.{
        .name = "cppcoro",
        .target = target,
        .optimize = optimize,
    }) else b.addSharedLibrary(.{
        .name = "cppcoro",
        .target = target,
        .optimize = optimize,
    });

    // allow use anothers C e/or C++ compiler with cppcoro static-lib
    if (optimize == .Debug or optimize == .ReleaseSafe)
        libcppcoro.bundle_compiler_rt = true // zig compiler-rt
    else
        libcppcoro.strip = true;

    libcppcoro.addIncludePath("include");
    libcppcoro.addIncludePath("lib");
    libcppcoro.addCSourceFiles(src, cxxFlags);

    if (target.isWindows()) {
        libcppcoro.defineCMacro("SCOPEID_UNSPECIFIED_INIT", "{0}");
        libcppcoro.addCSourceFiles(win_src, cxxFlags);
        libcppcoro.linkSystemLibrary("ws2_32");
        libcppcoro.linkSystemLibrary("mswsock");
        libcppcoro.linkSystemLibrary("kernel32");
        libcppcoro.want_lto = false;
    }
    // TODO: MSVC no has libcxx support (need: ucrt/vcruntime)
    // https://github.com/ziglang/zig/issues/5312
    if (target.getAbi() == .msvc) {
        libcppcoro.linkLibC();
    } else {
        libcppcoro.linkLibCpp(); // LLVM libc++ (builtin)
    }
    libcppcoro.installHeadersDirectory("include", "");

    b.installArtifact(libcppcoro);

    if (tests) {
        buildTest(b, .{
            .lib = libcppcoro,
            .path = "test/async_auto_reset_event_tests.cpp",
        });
        buildTest(b, .{
            .lib = libcppcoro,
            .path = "test/async_manual_reset_event_tests.cpp",
        });
        buildTest(b, .{
            .lib = libcppcoro,
            .path = "test/single_consumer_async_auto_reset_event_tests.cpp",
        });
        buildTest(b, .{
            .lib = libcppcoro,
            .path = "test/async_latch_tests.cpp",
        });
        buildTest(b, .{
            .lib = libcppcoro,
            .path = "test/async_generator_tests.cpp",
        });
        buildTest(b, .{
            .lib = libcppcoro,
            .path = "test/async_mutex_tests.cpp",
        });
        buildTest(b, .{
            .lib = libcppcoro,
            .path = "test/generator_tests.cpp",
        });
        buildTest(b, .{
            .lib = libcppcoro,
            .path = "test/cancellation_token_tests.cpp",
        });
        buildTest(b, .{
            .lib = libcppcoro,
            .path = "test/recursive_generator_tests.cpp",
        });
        buildTest(b, .{
            .lib = libcppcoro,
            .path = "test/shared_task_tests.cpp",
        });
        buildTest(b, .{
            .lib = libcppcoro,
            .path = "test/single_producer_sequencer_tests.cpp",
        });
        buildTest(b, .{
            .lib = libcppcoro,
            .path = "test/multi_producer_sequencer_tests.cpp",
        });
        buildTest(b, .{
            .lib = libcppcoro,
            .path = "test/sequence_barrier_tests.cpp",
        });
        buildTest(b, .{
            .lib = libcppcoro,
            .path = "test/task_tests.cpp",
        });
        buildTest(b, .{
            .lib = libcppcoro,
            .path = "test/sync_wait_tests.cpp",
        });
        buildTest(b, .{
            .lib = libcppcoro,
            .path = "test/when_all_tests.cpp",
        });
        buildTest(b, .{
            .lib = libcppcoro,
            .path = "test/when_all_ready_tests.cpp",
        });
        buildTest(b, .{
            .lib = libcppcoro,
            .path = "test/static_thread_pool_tests.cpp",
        });
        buildTest(b, .{
            .lib = libcppcoro,
            .path = "test/ip_address_tests.cpp",
        });
        buildTest(b, .{
            .lib = libcppcoro,
            .path = "test/ip_endpoint_tests.cpp",
        });

        buildTest(b, .{
            .lib = libcppcoro,
            .path = "test/ipv4_address_tests.cpp",
        });
        buildTest(b, .{
            .lib = libcppcoro,
            .path = "test/ipv4_endpoint_tests.cpp",
        });
        buildTest(b, .{
            .lib = libcppcoro,
            .path = "test/ipv6_address_tests.cpp",
        });
        buildTest(b, .{
            .lib = libcppcoro,
            .path = "test/ipv6_endpoint_tests.cpp",
        });
        if (target.isWindows()) {
            buildTest(b, .{
                .lib = libcppcoro,
                .path = "test/socket_tests.cpp",
            });
            buildTest(b, .{
                .lib = libcppcoro,
                .path = "test/io_service_tests.cpp",
            });
            buildTest(b, .{
                .lib = libcppcoro,
                .path = "test/scheduling_operator_tests.cpp",
            });
            buildTest(b, .{
                .lib = libcppcoro,
                .path = "test/file_tests.cpp",
            });
        }
    }
}

fn buildTest(b: *std.Build, info: BuildInfo) void {
    const test_exe = b.addExecutable(.{
        .name = info.filename(),
        .optimize = info.lib.optimize,
        .target = info.lib.target,
    });
    test_exe.linkLibrary(info.lib);
    test_exe.addIncludePath("include");
    test_exe.addIncludePath("lib");
    test_exe.addIncludePath("test");
    test_exe.addIncludePath("test/doctest");
    test_exe.addCSourceFile(info.path, cxxFlags);
    test_exe.addCSourceFiles(&[_][]const u8{
        "test/main.cpp",
        "test/counted.cpp",
    }, cxxFlags);
    if (test_exe.target.isWindows()) {
        test_exe.linkSystemLibrary("ws2_32");
        test_exe.linkSystemLibrary("mswsock");
        test_exe.want_lto = false;
    }
    if (test_exe.target.getAbi() == .msvc) {
        test_exe.linkLibC();
    } else {
        test_exe.linkLibCpp(); // LLVM libc++ (builtin)
    }
    b.installArtifact(test_exe);

    const run_cmd = b.addRunArtifact(test_exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step(
        b.fmt("{s}", .{info.filename()}),
        b.fmt("Run the {s} test", .{info.filename()}),
    );
    run_step.dependOn(&run_cmd.step);
}

const cxxFlags: []const []const u8 = &.{
    "-std=c++20",
    "-Wall",
    "-Wextra",
    "-fexperimental-library",
};

const src = &.{
    "lib/async_auto_reset_event.cpp",
    "lib/async_manual_reset_event.cpp",
    "lib/async_mutex.cpp",
    "lib/auto_reset_event.cpp",
    "lib/cancellation_registration.cpp",
    "lib/cancellation_source.cpp",
    "lib/cancellation_state.cpp",
    "lib/cancellation_token.cpp",
    "lib/ip_address.cpp",
    "lib/ip_endpoint.cpp",
    "lib/ipv4_address.cpp",
    "lib/ipv4_endpoint.cpp",
    "lib/ipv6_address.cpp",
    "lib/ipv6_endpoint.cpp",
    "lib/lightweight_manual_reset_event.cpp",
    "lib/spin_mutex.cpp",
    "lib/spin_wait.cpp",
    "lib/static_thread_pool.cpp",
};

const win_src = &.{
    "lib/win32.cpp",                    "lib/file.cpp",
    "lib/io_service.cpp",               "lib/read_write_file.cpp",
    "lib/readable_file.cpp",            "lib/socket.cpp",
    "lib/read_only_file.cpp",           "lib/socket_accept_operation.cpp",
    "lib/socket_connect_operation.cpp", "lib/socket_disconnect_operation.cpp",
    "lib/socket_helpers.cpp",           "lib/socket_recv_from_operation.cpp",
    "lib/socket_recv_operation.cpp",    "lib/socket_send_operation.cpp",
    "lib/socket_send_to_operation.cpp", "lib/file_read_operation.cpp",
    "lib/file_write_operation.cpp",     "lib/writable_file.cpp",
    "lib/write_only_file.cpp",
};

const BuildInfo = struct {
    lib: *std.Build.CompileStep,
    path: []const u8,

    fn filename(self: BuildInfo) []const u8 {
        var split = std.mem.split(u8, std.fs.path.basename(self.path), ".");
        return split.first();
    }
};
