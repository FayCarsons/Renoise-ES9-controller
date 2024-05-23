use cpal::{
    traits::{DeviceTrait, HostTrait},
    OutputCallbackInfo, StreamConfig,
};

use crate::constants;

pub const INPUTS: usize = 14;
pub const OUTPUTS: usize = 8;

pub struct ES9 {
    stream: cpal::Stream,
}

impl ES9 {
    pub fn new() -> Result<Self, anyhow::Error> {
        let host = cpal::default_host();

        let device = host
            .devices()?
            .find(|device| device.name().is_ok_and(|name| name == "ES-9"))
            .expect("ES-9 not found!");

        let config = device.default_output_config()?;

        println!("ES-9 config: {config:#?}");

        let num_channels = config.channels() as usize;
        println!("Num Channels: {num_channels}");
        let err_fn = |err| eprintln!("Error building outtput sond stream: {err}");
        let callback = move |buffer: &mut [f32], _: &OutputCallbackInfo| unsafe {
            for frame in buffer.chunks_mut(num_channels) {
                for (channel, sample) in frame.iter_mut().enumerate() {
                    if channel >= 8 {
                        *sample = constants::CHANNELS[channel - 8];
                    } else {
                        *sample = 1.0;
                    }
                }
            }
        };

        let stream =
            device.build_output_stream(&StreamConfig::from(config), callback, err_fn, None)?;
        Ok(Self { stream })
    }

    pub fn set(channel: usize, value: f32) {
        unsafe { constants::CHANNELS[channel - 1] = value }
    }
}
