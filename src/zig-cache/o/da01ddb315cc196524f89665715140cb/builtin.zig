usingnamespace @import("std").builtin;
/// Deprecated
pub const arch = Target.current.cpu.arch;
/// Deprecated
pub const endian = Target.current.cpu.arch.endian();
pub const output_mode = OutputMode.Exe;
pub const link_mode = LinkMode.Dynamic;
pub const is_test = true;
pub const single_threaded = false;
pub const abi = Abi.gnu;
pub const cpu: Cpu = Cpu{
    .arch = .x86_64,
    .model = &Target.x86.cpu.skylake,
    .features = Target.x86.featureSet(&[_]Target.x86.Feature{
        .@"64bit",
        .@"adx",
        .@"aes",
        .@"avx",
        .@"avx2",
        .@"bmi",
        .@"bmi2",
        .@"clflushopt",
        .@"cmov",
        .@"cx16",
        .@"cx8",
        .@"ermsb",
        .@"f16c",
        .@"false_deps_popcnt",
        .@"fast_gather",
        .@"fast_scalar_fsqrt",
        .@"fast_shld_rotate",
        .@"fast_variable_shuffle",
        .@"fast_vector_fsqrt",
        .@"fma",
        .@"fsgsbase",
        .@"fxsr",
        .@"idivq_to_divl",
        .@"invpcid",
        .@"lzcnt",
        .@"macrofusion",
        .@"merge_to_threeway_branch",
        .@"mmx",
        .@"movbe",
        .@"nopl",
        .@"pclmul",
        .@"popcnt",
        .@"prfchw",
        .@"rdrnd",
        .@"rdseed",
        .@"rtm",
        .@"sahf",
        .@"sgx",
        .@"slow_3ops_lea",
        .@"sse",
        .@"sse2",
        .@"sse3",
        .@"sse4_1",
        .@"sse4_2",
        .@"ssse3",
        .@"vzeroupper",
        .@"x87",
        .@"xsave",
        .@"xsavec",
        .@"xsaveopt",
        .@"xsaves",
    }),
};
pub const os = Os{
    .tag = .macosx,
    .version_range = .{ .semver = .{
        .min = .{
            .major = 10,
            .minor = 15,
            .patch = 7,
        },
        .max = .{
            .major = 10,
            .minor = 15,
            .patch = 7,
        },
    }},
};
pub const object_format = ObjectFormat.macho;
pub const mode = Mode.Debug;
pub const link_libc = true;
pub const link_libcpp = false;
pub const have_error_return_tracing = true;
pub const valgrind_support = true;
pub const position_independent_code = true;
pub const strip_debug_info = false;
pub const code_model = CodeModel.default;
pub var test_functions: []TestFn = undefined; // overwritten later
pub const test_io_mode = .blocking;
