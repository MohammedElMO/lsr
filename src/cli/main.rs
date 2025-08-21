use std::process::exit;
use clap::Parser;
// Import functions from our library

use lsr::core::hello::*;

#[derive(Parser)]
#[command(name = "lsr")]
#[command(about = "A simple hello world CLI")]
// #[command(version = get_version())]
struct Cli {
    hello: bool,
    name: Option<String>,

    /// Show version
    #[arg(short, long)]
    version: bool,
}

fn main() {
    let cli = Cli::parse();
    if cli.hello {
        println!("lsr  {}", hello());

    }
    match cli.name {
        Some(_) => println!("{}", hello()),
        None => exit(0)
    }

}
