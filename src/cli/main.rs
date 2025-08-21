use clap::{Parser, Subcommand};
// Import functions from our library

use lsr::core::{hello,say_hi, };

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

    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// Runs the hello function
    Sayhi,
}

fn main() {
    let cli = Cli::parse();
    if cli.hello {
        println!("lsr  {}", hello());
    }
    match cli.name {
        Some(_) => println!("{}", hello()),
        None => println!("no"),
    }

    match cli.command {
        Commands::Sayhi => say_hi(),
    }
}
