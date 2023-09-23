pub export fn _start() noreturn {
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    print();
    exit();
}

fn print() void {
    asm volatile ("svc #0"
        :
        : [number] "{x8}" (64),
          [arg1] "{x0}" (1),
          [arg2] "{x1}" (@intFromPtr("Hello, World!\n")),
          [arg3] "{x2}" ("Hello, World!\n".len),
        : "memory", "cc"
    );
}

fn exit() noreturn {
    asm volatile ("svc #0"
        :
        : [number] "{x8}" (93),
          [arg1] "{x0}" (0),
        : "memory", "cc"
    );
    unreachable;
}
