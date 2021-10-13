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
RUN cargo build --release --target x86_64-unknown-linux-musl
# make sure the executable gets rebuilt after copying the sources
RUN rm target/x86_64-unknown-linux-musl/release/{{project-name}}*

# Copy the source and build the application.
COPY . .
RUN cargo build --release --target x86_64-unknown-linux-musl
# remove unneeded symbols from executable
RUN strip target/x86_64-unknown-linux-musl/release/{{project-name}}

# Copy the statically-linked binary into a scratch container.
FROM scratch
COPY --from=build-{{project-name}} target/x86_64-unknown-linux-musl/release/{{project-name}} .
USER 1000
ENV RUST_LOG info
CMD ["./{{project-name}}"]