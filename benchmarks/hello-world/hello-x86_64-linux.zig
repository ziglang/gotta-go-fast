pub fn main() void {
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
}

fn print() void {
    asm volatile ("syscall"
        :
        : [number] "{rax}" (1),
          [arg1] "{rdi}" (1),
          [arg2] "{rsi}" (@ptrToInt("Hello, World!\n")),
          [arg3] "{rdx}" (14),
        : "rcx", "r11", "memory"
    );
    return;
}
