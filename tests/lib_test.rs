use lsrs::core::hello::{hello, say_hi};

#[test]
fn hello_test() {
    let result = hello();
    assert!(result.contains("CLI"));
}
