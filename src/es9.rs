pub const INPUTS: usize = 14;
pub const OUTPUTS: usize = 8;

pub struct ES9 {
    outs: [f32; OUTPUTS],
}

impl ES9 {
    pub const fn new() -> Self {
        Self {
            outs: [0.0; OUTPUTS],
        }
    }

    pub fn values(&self) -> &[f32] {
        &self.outs[..]
    }

    pub fn update(&mut self, channel: usize, value: f32) {
        self.outs[channel] = value
    }
}
