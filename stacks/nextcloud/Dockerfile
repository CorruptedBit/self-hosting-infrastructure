FROM nextcloud:latest

# Install ffmpeg for video previews (required by Photos or Memories apps)
RUN apt-get update && \
    apt-get install -y ffmpeg && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
