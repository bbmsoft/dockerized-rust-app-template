FROM rust:latest AS build-{{project-name}}

WORKDIR /usr/src
RUN USER=root cargo new {{project-name}}
WORKDIR /usr/src/{{project-name}}
RUN rustup target add x86_64-unknown-linux-musl
COPY Cargo.* ./
RUN cargo build --release --target x86_64-unknown-linux-musl

COPY . .
RUN cargo install --target x86_64-unknown-linux-musl --path .

FROM scratch
COPY --from=build-{{project-name}} /usr/local/cargo/bin/{{project-name}} .
USER 1000
CMD ["./{{project-name}}"]