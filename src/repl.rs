use crate::ES9;

use rustyline::{DefaultEditor, Result};

pub fn repl() -> Result<()> {
    let mut rl = DefaultEditor::new()?;
    while let Ok(line) = rl.readline(">> ") {
        let _ = rl.add_history_entry(line.as_str());
        let mut iter = line.split('/').skip(1);
        if let (Some(output), Some(value)) = (iter.next(), iter.next()) {
            if let (Ok(output), Ok(value)) = (str::parse::<usize>(output), str::parse::<f32>(value))
            {
                println!("RECEIVED: {{ output: {output}, value: {value} }}");
                ES9::set(output, value)
            }
        }
    }

    Ok(())
}
