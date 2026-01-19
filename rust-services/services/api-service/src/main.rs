use std::net::SocketAddr;
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tokio::net::TcpListener;
use tracing::{info, Level};
use tracing_subscriber::FmtSubscriber;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    // Initialize tracing
    let subscriber = FmtSubscriber::builder()
        .with_max_level(Level::INFO)
        .finish();
    tracing::subscriber::set_global_default(subscriber)?;

    let addr = SocketAddr::from(([0, 0, 0, 0], 80));
    let listener = TcpListener::bind(addr).await?;

    info!("Rust API listening on {}", addr);

    loop {
        let (mut socket, _) = listener.accept().await?;

        tokio::spawn(async move {
            let mut buffer = [0; 1024];
            if let Ok(n) = socket.read(&mut buffer).await {
                if n > 0 {
                    let request = String::from_utf8_lossy(&buffer[..n]);
                    let path = request
                        .lines()
                        .next()
                        .and_then(|line| line.split_whitespace().nth(1))
                        .unwrap_or("/");

                    let response = match path {
                        "/health" => "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n\r\nOK\n",
                        "/" => "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n\r\nHello from Rust API\n",
                        _ => "HTTP/1.1 404 Not Found\r\nContent-Type: text/plain\r\n\r\nNot Found\n",
                    };

                    let _ = socket.write_all(response.as_bytes()).await;
                }
            }
        });
    }
}
