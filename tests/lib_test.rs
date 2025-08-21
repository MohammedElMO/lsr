use lsr::core::hello::hello;

#[test]
fn hello_test() {
    let result = hello();
    assert!(result.contains("CLI"));
}
