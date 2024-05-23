use crate::ES9;
use std::io;

use tokio::net::UdpSocket;

pub struct Server {
    socket: UdpSocket,
    buf: Vec<u8>,
}

impl Server {
    pub async fn new() -> std::io::Result<Self> {
        println!("Initializating UDP server . . .");
        Ok(Self {
            socket: UdpSocket::bind("127.0.0.1:8080").await?,
            buf: Vec::with_capacity(8),
        })
    }
    pub async fn run(self) -> Result<(), io::Error> {
        let Server { socket, mut buf } = self;

        loop {
            // Check if there's a message
            let (size, _) = socket.recv_from(&mut buf).await?;
            let recv = &buf[..size];
            println!("RECEIVED: {recv:?}");
            let mut command = recv.split(|c| *c == b'/').skip(1);

            match (command.next(), command.next()) {
                (Some(channel), Some(value)) => unsafe {
                    match (
                        std::str::from_utf8_unchecked(channel).parse::<usize>(),
                        std::str::from_utf8_unchecked(value).parse::<f32>(),
                    ) {
                        (Ok(channel), Ok(value)) => {
                            ES9::set(channel, value);
                        }
                        _ => {
                            println!("RECEIVED MALFORMED MESSAGE!");
                            continue;
                        }
                    }
                },
                (a, b) => {
                    println!("RECEIVED MALFORMED MESSAGE: {a:?} <> {b:?}")
                }
            }
        }
    }
}
