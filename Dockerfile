# source: https://alexbrand.dev/post/how-to-package-rust-applications-into-minimal-docker-containers/

# Dockerfile for creating a statically-linked Rust application using docker's
# multi-stage build feature. This also leverages the docker build cache to avoid
# re-downloading dependencies if they have not changed.
FROM rust:latest AS build-{{project-name}}
WORKDIR /usr/src

# Download the target for static linking.
RUN rustup target add x86_64-unknown-linux-musl

# Create a dummy project and build the app's dependencies.
# If the Cargo.toml or Cargo.lock files have not changed,
# we can use the docker build cache and skip these (typically slow) steps.
RUN USER=root cargo new {{project-name}}
WORKDIR /usr/src/{{project-name}}
COPY Cargo.toml Cargo.lock ./
RUN cargo test --release --target x86_64-unknown-linux-musl

# Copy the source and build the application.
COPY . .
RUN cargo install --target x86_64-unknown-linux-musl --path .
# uncomment to remove unneeded symbols from executable (this will break stack traces!)
#RUN strip /usr/local/cargo/bin/{{project-name}}

# Copy the statically-linked binary into a scratch container.
FROM scratch
COPY --from=build-{{project-name}} /usr/local/cargo/bin/{{project-name}} .
USER 1000
ENV RUST_LOG info
ENV RUST_BACKTRACE 1
CMD ["./{{project-name}}"]