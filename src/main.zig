const std = @import("std");
const tallocator = std.testing.allocator;
const warn = std.debug.warn;
const assertEqual = std.testing.expectEqual;

pub fn reduce(
    comptime func: anytype, 
    iterable: []@typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?,
    comptime init: @typeInfo(@TypeOf(func)).Fn.return_type.? 
) @typeInfo(@TypeOf(func)).Fn.return_type.? {
    var ans = init;
    for (iterable) | item | {
        ans = func(ans, item);
    }
    return ans;
}

fn add8(a: u8, b: u8) u8 { 
    return a + b; 
}
fn mul8(a: u8, b: u8) u8 { 
    return a * b; 
}

pub fn Iterator(comptime T: type) type {
    return struct {
        allocator: *std.mem.Allocator,
        items: []const T,
        index: usize = 0,
        len: usize,

        const Self = @This();

        fn incr(it: *Self) void {
            it.index += 1;
        }

        pub fn next(it: *Self) ?*const T {
            if(it.index < it.len) {
                defer it.incr();
                return &it.items[it.index];
            }
            return null;
        }

        pub fn init(alloc: *std.mem.Allocator, iter: []const T) Self {
            const temp: []T = alloc.dupe(T, iter) catch unreachable;
            return Self{
                .allocator = alloc,
                .items = temp,
                .len = iter.len
            };
        }

        pub fn deinit(it: *Self) void {
            it.allocator.free(it.items);
        }
    };
}

fn printTest(comptime T: type, iter: *Iterator(T), ans: []T) void{
    var i: usize = 0;
    while (iter.next()) | item | {
        // warn("\r\n ans: {} item: {} ", .{ans[i], item.*});
        assertEqual(ans[i], item.*);
        i += 1;
    }
}

pub fn map(
    allocat: *std.mem.Allocator,
    comptime func: anytype, 
    iterable: []@typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?
) Iterator(@typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?) {
    const rtype = @typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?;
    var ans: []rtype  = allocat.alloc(rtype, iterable.len) catch unreachable;
    defer allocat.destroy(ans.ptr);
    
    for(iterable) | item, i | {
        ans[i] =  func(item);
    }

    return Iterator(rtype).init(allocat, ans);
}

fn addOne(a: u8) u8 {
    return a + @intCast(u8, 1);
}

pub fn filter(
    allocat: *std.mem.Allocator,
    comptime func: anytype, 
    iterable: []@typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?
) Iterator(@typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?) {
    const rtype = @typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?;
    var ans: []rtype  = allocat.alloc(rtype, iterable.len) catch unreachable;
    defer allocat.destroy(ans.ptr);
    
    var j: usize = 0;
    for (iterable) | item | {
        if (func(item) == true) {
            ans[j] = item;
            j += 1;
        }
    }

    _ = allocat.shrink(ans, j);
    ans.len = j;

    return Iterator(rtype).init(allocat, ans);
}

fn isLessThan10(a: u8) bool {
    if ( a < 10 ){
        return true;
    }
    return false;
}

pub fn accumulate(
    allocat: *std.mem.Allocator,
    comptime func: anytype, 
    iterable: []@typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?,
    comptime init: @typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?
) Iterator(@typeInfo(@TypeOf(func)).Fn.return_type.?) {
    const rtype = @typeInfo(@TypeOf(func)).Fn.return_type.?;
    var ans: []rtype  = allocat.alloc(rtype, iterable.len) catch unreachable;
    defer allocat.destroy(ans.ptr);
    
    var i: usize = 0;
    ans[0] = func(init, iterable[0]);
    i += 1;
    while (i < iterable.len) : ( i += 1 ) {
        ans[i] =  func(ans[i-1], iterable[i]);
    }

    return Iterator(rtype).init(allocat, ans);
}

fn add(a: u32, b:u32) u32 {
    return a + b;
}

fn mul(a:u32, b:u32) u32 {
    return a * b;
}

pub fn chain(
    allocat: *std.mem.Allocator,
    comptime func: anytype,
    iterables: []const []const @typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?
) Iterator(@typeInfo(@TypeOf(func)).Fn.return_type.?) {
    var totalLength: usize = 0;
    for (iterables) | iterable | { totalLength += iterable.len; }
    const rtype = @typeInfo(@TypeOf(func)).Fn.return_type.?;
    var ans: []rtype  = allocat.alloc(rtype, totalLength) catch unreachable;
    defer allocat.destroy(ans.ptr);

    var index: usize = 0;
    for (iterables) | iterable | {
        for (iterable) | item | {
            ans[index] = func(item);
            index += 1; 
        }
    }
    return Iterator(rtype).init(allocat, ans);
}

fn addOne8(a: i32) i32 {
    return a+1;
}

pub fn min(
    allocat: *std.mem.Allocator,
    comptime func: anytype,
    iterables: []const []const @typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?
) @typeInfo(@TypeOf(func)).Fn.args[0].arg_type.? {
    const rtype = @typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?;

    var min_value: rtype = iterables[0][0];
    for (iterables) | iterable | {
        for (iterable) | item | {
            if ( func(item, min_value) == true ) {
                min_value = item;
            }
        }
    }
    return min_value;
}

fn compareFnMin(a: i32, b: i32) bool {
    if (a < b) {
        return true;
    }
    return false;
}

pub fn max(
    allocat: *std.mem.Allocator,
    comptime func: anytype,
    iterables: []const []const @typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?
) @typeInfo(@TypeOf(func)).Fn.args[0].arg_type.? {
    return min(allocat, func, iterables);
}

fn compareFnMax(a: i32, b: i32) bool {
    if (a > b) {
        return true;
    }
    return false;
}

pub fn filterfalse(
    allocat: *std.mem.Allocator,
    comptime func: anytype, 
    iterable: []@typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?
) Iterator(@typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?) {
    const rtype = @typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?;
    var ans: []rtype  = allocat.alloc(rtype, iterable.len) catch unreachable;
    defer allocat.destroy(ans.ptr);
    
    var j: usize = 0;
    for (iterable) | item, i | {
        if (func(item) == false) {
            ans[j] = item;
            j += 1;
        }
    }

    _ = allocat.shrink(ans, j);
    ans.len = j;

    return Iterator(rtype).init(allocat, ans);
}

pub fn dropwhile(
    allocat: *std.mem.Allocator,
    comptime func: anytype, 
    iterable: []@typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?
) Iterator(@typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?) {
    var totalLength: usize = iterable.len;
    const rtype = @typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?;
    var ans: []rtype  = allocat.alloc(rtype, totalLength) catch unreachable;
    defer allocat.destroy(ans.ptr);

    var i: usize = 0;
    while ( func(iterable[i]) == true ) : ( i += 1 ) {}

    var j: usize = 0;
    while ( i < totalLength ) : ( j += 1 ) {
        ans[j] = iterable[i];
        i += 1;
    }

    _ = allocat.shrink(ans, j);
    ans.len = j;

    return Iterator(rtype).init(allocat, ans);
}

fn recurranceRelation(allocat: *std.mem.Allocator, N: usize) !usize {
    switch (N) {
        0 => { return 1;  },
        1 => { return 2;  },
        2 => { return 4;  },
        3 => { return 12; },
        4 => { return 32; },
        5 => { return 80; }, 
        else => {}
    }
    var T: usize = 80;
    if ( N > 5 ) {
        var i: usize = 6;
        while (i < N+1) : ( i += 1 ) {
            var term: usize = (2 * i * T) / (i-1);
            T = term;
            // warn("\r\n term: {} ", .{term});
        }
    }
    return T;
}

pub fn powerset(
    allocat: *std.mem.Allocator,
    comptime func: anytype, 
    iterable: []@typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?
) !Iterator(@typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?) {
    // Total number of sets is pow(2, iterable.len)
    // the total number of elements can be calculated by (N*1) + ((N-1)*2) + ((N-2)*3) ... + (2*(N-1)) + (1*N)
    // this is given by the recurrance relation T(N) = 2*N*T(N-1)//(N-1) => should be the allocated length
    // a func needs to be constructed to get the result of the above recurrance relation.
    // Source: the recurrance relation is mine, and the powerset algorithm is from MITx: 6.00.2x
    var totalLength: usize =  @intCast(usize, 1) << @truncate(std.math.Log2Int(usize), iterable.len);
    var allocatLength: usize = recurranceRelation(allocat, iterable.len) catch unreachable;
    // warn("\r\ntotal length: {}", .{totalLength});
    // warn("\r\nallocat length: {}", .{allocatLength});
    const rtype = @typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?;
    var ans: []rtype  = allocat.alloc(rtype, allocatLength) catch unreachable;
    defer allocat.free(ans);

    var index: usize = 0;
    var i: usize = 0;
    while( i < totalLength ) : ( i += 1 ) {
        var j: u6 = 0;
        while ( j < iterable.len ) : ( j += 1 ) {
            // Bit shift the index j of the array i bits to the left, and this makes the 
            // last bit of j become the test bit to see if it contains bit i
            if ( ( ( i >> j) % 2 ) == 1 ) {
                ans[index] = func(iterable[j]);
                index += 1;
                // warn(" {},", .{iterable[j]});
            }
        }
        // warn("\r\n =========== ", .{});
    }

    return Iterator(rtype).init(allocat, ans);

}

fn mulOne32 (a: u32) u32 {
    return a * 1;
}

fn fact(N: i64) i64 {
    var T = std.ArrayList(i64).init(allocat);
    defer T.deinit();
    try T.append(1);
    try T.append(1);


}

pub fn permutations(
    allocat: *std.mem.Allocator,
    comptime func: anytype, 
    iterable: []@typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?
) !Iterator(@typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?) {


}

pub fn combinations() void {}

pub fn compress() void {}


test "Reduce" {
    var A = [_]u8{1, 2, 4};
    assertEqual(reduce(add8, &A, 0), 7);
    assertEqual(reduce(mul8, &A, 0), 0);
    assertEqual(reduce(mul8, &A, 1), 8);
    warn("\r\n", .{});
}

test "Iterator" {

    var A: []u8 = tallocator.alloc(u8, 10) catch unreachable;
    defer tallocator.destroy(A.ptr);

    var i: u8 = 0;
    while ( i < 10 ) : ( i += 1 ) {
        A[i] = i;
    } 
    var iter = Iterator(u8).init(tallocator, A);
    defer iter.deinit();

    printTest(u8, &iter, A);

    var B = std.ArrayList(u8).init(tallocator);
    defer B.deinit();

    i =  0;
    while ( i < 10 ) : ( i += 1 ) {
        _ = try B.append(i*2);
    } 
    var iter2 = Iterator(u8).init(tallocator, B.items);
    defer iter2.deinit();

    printTest(u8, &iter2, B.items);
    warn("\r\n", .{});

}

test "Map" {
    var A = [_]u8{'a', 'b', 'c'};
    var ans = [_]u8{'b', 'c', 'd'};

    var res = map(tallocator, addOne, &A);
    defer res.deinit();

    printTest(u8, &res, &ans);
    warn("\r\n", .{});
}

test "Filter" {
    var A = [_]u8{1, 'a', 2, 'b', 3, 'c', 'd', 'e'};
    var ans = [_]u8{1, 2, 3};

    var res = filter(tallocator, isLessThan10, &A);
    defer res.deinit();

    printTest(u8, &res, &ans);
    warn("\r\n", .{});
}

test "Accumulate" {
    var A = [_]u32{1, 2, 4};
    var ans1 = [_]u32{1, 3, 7};
    var ans2 = [_]u32{0, 0, 0};
    var ans3 = [_]u32{1, 2, 8};

    var res = accumulate(tallocator, add, &A, 0);
    defer res.deinit();

    var res2 = accumulate(tallocator, mul, &A, 0);
    defer res2.deinit();

    var res3 = accumulate(tallocator, mul, &A, 1);
    defer res3.deinit();

    printTest(u32, &res, &ans1);
    printTest(u32, &res2, &ans2);
    printTest(u32, &res3, &ans3);
    warn("\r\n", .{});
}

test "Chain" {
    var A = &[_][]const i32{ 
        &[_]i32{1, 2}, 
        &[_]i32{3, 4}
    };

    var ans = [_]i32{2,3,4,5};
    var res = chain(tallocator, addOne8, A);
    defer res.deinit();

    printTest(i32, &res, &ans);

    warn("\r\n", .{});
}

test "Min" {
    var A = &[_][]const i32{ 
        &[_]i32{1, 2}, 
        &[_]i32{3, 4}
    };
    assertEqual(min(tallocator, compareFnMin, A), 1);
    warn("\r\n", .{});
}

test "Max" {
    var A = &[_][]const i32{ 
        &[_]i32{1, 2}, 
        &[_]i32{3, 4}
    };
    assertEqual(max(tallocator, compareFnMax, A), 4);
    warn("\r\n", .{});
}

test "FilterFalse" {
    var A = [_]u8{1, 'a', 2, 'b', 3, 'c', 'd', 'e'};
    var ans = [_]u8{'a', 'b', 'c', 'd', 'e'};

    var res = filterfalse(tallocator, isLessThan10, &A);
    defer res.deinit();

    printTest(u8, &res, &ans);
    warn("\r\n", .{});
}

test "Dropwhile" {
    var A = [_]u8{1, 2, 3, 5, 'a', 1, 'b', 2, 'c', 11, 'd', 'e', 1, 3, 4};
    var ans = [_]u8{'a', 1, 'b', 2, 'c', 11, 'd', 'e', 1, 3, 4};

    var res = dropwhile(tallocator, isLessThan10, &A);
    defer res.deinit();

    printTest(u8, &res, &ans);
    warn("\r\n", .{});
}

test "PowerSet" {
    var A = [_]u32{1, 2, 3, 4};
    var ans = [_]u32{1, 2, 1, 2, 3, 1, 3, 2, 3, 1, 2, 3, 4, 1, 4, 2, 4, 1, 2, 4, 3, 4, 1, 3, 4, 2, 3, 4, 1, 2, 3, 4};

    var res = powerset(tallocator, mulOne32, &A) catch unreachable;
    defer res.deinit();

    // warn("\r\n iterlen: {} ", .{res.len});
    // warn("\r\n anslen: {}", .{ans.len});

    printTest(u32, &res, &ans);

    var A1 = [_]u32{1, 2, 3};
    var ans1 = [_]u32{1, 2, 1, 2, 3, 1, 3, 2, 3, 1, 2, 3};

    var res1 = powerset(tallocator, mulOne32, &A1) catch unreachable;
    defer res1.deinit();

    // warn("\r\n iterlen: {} ", .{res1.len});
    // warn("\r\n anslen: {}", .{ans1.len});

    printTest(u32, &res1, &ans1);

    var A2 = [_]u32{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15};

    var res2 = powerset(tallocator, mulOne32, &A2) catch unreachable;
    defer res2.deinit();

    // warn("\r\n iterlen: {} ", .{res2.len});

    const allocLength: usize = recurranceRelation(tallocator, A2.len) catch unreachable;
    assertEqual(res2.len, allocLength);

    warn("\r\n", .{});
}
