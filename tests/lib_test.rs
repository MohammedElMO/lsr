use lsr::core::hello::{hello, say_hi};

#[test]
fn hello_test() {
    let result = hello();
    assert!(result.contains("CLI"));
}

// #[test]
// fn say_hi_test() {
//     let result = say_hi();
//     assert!(result.)
