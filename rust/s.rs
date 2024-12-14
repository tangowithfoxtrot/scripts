#!/usr/bin/env cargo +nightly -Zscript -q
---cargo
[dependencies]
ansible-vault = "0.2.1"
clap = { version = "4.5.23", features = ["derive"] }
rpassword = "7.3.1"
serde = { version = "1.0.216", features = ["derive"] }
serde_yaml = "0.9.34"
---

use ansible_vault::decrypt_vault;
use clap::Parser;
use serde::Deserialize;
use std::collections::HashMap;
use std::io::Read;
use std::path::PathBuf;

#[derive(Parser)]
#[command(version, about, long_about = None)]
struct Cli {
    /// Command to run with secrets injected
    #[arg(required = true)]
    command: Vec<String>,

    /// Sets a custom secrets file
    #[arg(
        short = 'f',
        long = "secrets-file",
        value_name = "FILE",
        default_value = "secrets.yml"
    )]
    secrets_file: Option<PathBuf>,

    /// Password for decrypting the secrets file
    #[arg(
        short = 'p',
        long = "password",
        value_name = "PASSWORD",
    )]
    password: Option<String>,

    /// Ignore existing environment variables
    #[arg(
        short = 'i',
        long = "ignore-env",
    )]
    ignore_env: bool,
}

#[derive(Debug, Deserialize)]
struct Secrets {
    #[serde(flatten)]
    data: HashMap<String, String>,
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let cli = Cli::parse();

    let mut environment: HashMap<String, String> = HashMap::new();

    if let Some(secrets_path) = cli.secrets_file.as_deref() {
        let mut file = std::fs::File::open(secrets_path)?;
        let mut encrypted_contents = String::new();
        file.read_to_string(&mut encrypted_contents)?;

        let decryption_password = cli
            .password
            .unwrap_or_else(|| rpassword::prompt_password("Enter decryption password: ")
            .expect("Failed to read password"));

        let decrypted_contents =
            decrypt_vault(encrypted_contents.as_bytes(), &decryption_password)?;

        let secrets: Secrets = serde_yaml::from_str(&String::from_utf8(decrypted_contents)?)?;
        environment.extend(secrets.data);
    }

    let mut command = std::process::Command::new("/bin/sh");
    command.arg("-c").arg(&cli.command.join(" "));

    if cli.ignore_env {
        command.env_clear();
    }

    command.envs(environment)
        .stdout(std::process::Stdio::inherit())
        .stderr(std::process::Stdio::inherit());

    let status = command.spawn()?.wait();

    match status {
        Ok(_) => Ok(()),
        Err(e) => Err(e.into()),
    }
}
