use colored::{ColoredString, Colorize};
use std::{fs, path::PathBuf, str::FromStr};
use tokio::{io::AsyncWriteExt, spawn};
use tracing::error;

use crate::{IS_DEV, config::LOG_DIR, error::ClewdrError};

/// Helper function to format a boolean value as "Enabled" or "Disabled"
pub fn enabled(flag: bool) -> ColoredString {
    if flag {
        "Enabled".green()
    } else {
        "Disabled".red()
    }
}

/// Sets the ClewdR directory for configuration and data files.  
/// Also creates the log directory if it doesn't exist.
/// In production, this respects environment variables for directory override
/// to support NixOS and other system service configurations.
/// 
/// In development, uses the cargo manifest directory.
/// In production, checks environment variables first, then falls back to executable directory.
/// 
/// # Environment Variables
/// * `CLEWDR_DIR` - Override the default directory location
/// * `CLEWDR_DATA_DIR` - Alternative override for data directory
/// 
/// # Returns
/// * `Result<PathBuf, ClewdrError>` - The path to the configuration directory on success, or an error
pub fn set_clewdr_dir() -> Result<PathBuf, ClewdrError> {
    let dir = if *IS_DEV {
        // In development use cargo dir
        let cargo_dir = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
        cargo_dir.canonicalize()?
    } else {
        // Check for environment variable overrides first (for NixOS/systemd services)
        if let Ok(env_dir) = std::env::var("CLEWDR_DIR") {
            PathBuf::from(env_dir)
        } else if let Ok(env_dir) = std::env::var("CLEWDR_DATA_DIR") {
            PathBuf::from(env_dir)
        } else {
            // Fallback to executable directory
            std::env::current_exe()?
                .parent()
                .ok_or_else(|| ClewdrError::PathNotFound {
                    msg: "Failed to get parent directory".to_string(),
                })?
                .canonicalize()?
                .to_path_buf()
        }
    };
    
    // Only try to change directory if it's writable, otherwise just use the dir path
    if let Err(_) = std::env::set_current_dir(&dir) {
        // If we can't change to the directory (e.g., read-only filesystem like Nix store),
        // just continue with the current working directory and log a warning
        eprintln!("Warning: Could not change to directory {}, using current directory", dir.display());
    }
    // create log dir
    #[cfg(feature = "no_fs")]
    {
        return Ok(dir);
    }

    let log_dir = dir.join(LOG_DIR);
    if !log_dir.exists() {
        fs::create_dir_all(&log_dir)?;
    }
    Ok(dir)
}

/// Helper function to print out JSON to a file in the log directory
///
/// # Arguments
/// * `json` - The JSON object to serialize and output
/// * `file_name` - The name of the file to write in the log directory
pub fn print_out_json(json: &impl serde::ser::Serialize, file_name: &str) {
    #[cfg(feature = "no_fs")]
    {
        return;
    }
    let text = serde_json::to_string_pretty(json).unwrap_or_default();
    print_out_text(text, file_name);
}

/// Helper function to print out text to a file in the log directory
///
/// # Arguments
/// * `text` - The text content to write
/// * `file_name` - The name of the file to write in the log directory
pub fn print_out_text(text: String, file_name: &str) {
    #[cfg(feature = "no_fs")]
    {
        return;
    }
    let Ok(log_dir) = PathBuf::from_str(LOG_DIR);
    let file_name = log_dir.join(file_name);
    spawn(async move {
        let Ok(mut file) = tokio::fs::File::options()
            .write(true)
            .create(true)
            .truncate(true)
            .open(&file_name)
            .await
        else {
            error!("Failed to open file: {}", file_name.display());
            return;
        };
        if let Err(e) = file.write_all(text.as_bytes()).await {
            error!("Failed to write to file: {}\n", e);
        }
    });
}

/// Timezone for the API
pub const TIME_ZONE: &str = "America/New_York";
