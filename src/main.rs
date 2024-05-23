mod constants;
mod es9;
mod repl;
mod server;

use crate::es9::ES9;

use clap::{Parser, ValueEnum};

#[derive(Clone, Copy, Debug, ValueEnum)]
enum AppMode {
    Server,
    TestRepl,
}

impl AppMode {
    fn parse(input: &str) -> Result<Self, String> {
        match input {
            "s" | "server" => Ok(Self::Server),
            "r" | "repl" => Ok(Self::TestRepl),
            _ => Err(String::from("Invalid arg")),
        }
    }
}

#[derive(Parser)]
pub struct AppArgs {
    #[arg(value_enum, value_parser = AppMode::parse)]
    mode: AppMode,
}

#[tokio::main]
async fn main() -> Result<(), String> {
    let args = AppArgs::parse();

    match args.mode {
        AppMode::Server => {
            let server = server::Server::new()
                .await
                .map_err(|e| format!("Cannot initialize server: {e}"))?;
            server
                .run()
                .await
                .map_err(|e| format!("Server error: {e}"))?;
        }
        AppMode::TestRepl => repl::repl().map_err(|e| format!("Repl failure: {e}"))?,
    }

    Ok(())
}
