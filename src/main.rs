mod constants;
mod es9;
mod server;

use crate::es9::ES9;
use coreaudio::audio_unit::{
    macos_helpers::{audio_unit_from_device_id, get_audio_device_ids, get_device_name},
    render_callback::{self, data},
    AudioUnit,
};

static mut ES9: ES9 = ES9::new();

fn init_es9() -> Result<AudioUnit, coreaudio::Error> {
    let audio_unts = get_audio_device_ids().expect("Cannot get devices!");
    let es9_id = audio_unts
        .into_iter()
        .find(|device_id| {
            let name = get_device_name(*device_id);
            name.map(|s| s.trim().to_lowercase())
                .is_ok_and(|s| s.contains("es9"))
        })
        .expect("ES9 not connected!");

    let mut es9 = audio_unit_from_device_id(es9_id, false)?;

    let stream_format = es9.output_stream_format()?;
    println!("ES9 stream format: {:#?}", &stream_format);

    assert!(constants::SAMPLE_FORMAT == stream_format.sample_format);

    type Args = render_callback::Args<data::Interleaved<f32>>;

    {
        es9.set_render_callback(move |args| {
            let Args {
                num_frames, data, ..
            } = args;
            for i in 0..num_frames {
                unsafe {
                    let samples = ES9.values();
                    data.buffer[i..i + data.channels].copy_from_slice(samples)
                }
            }

            Ok(())
        })?;
    }

    Ok(es9)
}

#[tokio::main]
async fn main() -> Result<(), String> {
    let server = server::Server::new()
        .await
        .map_err(|e| format!("Cannot initialize server: {e}"))?;

    let mut es9 = init_es9().map_err(|e| format!("Cannot initialize ES9: {e}"))?;

    server
        .run()
        .await
        .map_err(|e| format!("Server error: {e}"))?;

    es9.stop().map_err(|e| format!("Cannot stop ES9: {e}"))
}
