#!/bin/bash
echo "=== Nextcloud Video Previews & Memories Setup ==="

# Check if ffmpeg is installed
echo "Checking ffmpeg installation..."
if ! docker exec nextcloud-app which ffmpeg >/dev/null 2>&1; then
    echo "❌ ERROR: ffmpeg is not installed in the container!"
    echo "Make sure you've built the image with the Dockerfile that includes ffmpeg."
    exit 1
fi
echo "✓ ffmpeg found: $(docker exec nextcloud-app ffmpeg -version | head -n1)"

# Check if ffprobe is installed
echo "Checking ffprobe installation..."
if ! docker exec nextcloud-app which ffprobe >/dev/null 2>&1; then
    echo "❌ ERROR: ffprobe is not installed in the container!"
    echo "Make sure you've built the image with the Dockerfile that includes ffmpeg."
    exit 1
fi
echo "✓ ffprobe found: $(docker exec nextcloud-app ffprobe -version | head -n1)"

# Check if previews are already configured
echo ""
echo "Checking preview configuration..."
if docker exec nextcloud-app php occ config:system:get enable_previews 2>/dev/null | grep -q "true"; then
    echo "✓ Previews are already configured."
    echo ""
    echo "Current configuration:"
    docker exec nextcloud-app php occ config:system:get enabledPreviewProviders
else
    # Configure previews
    echo ""
    echo "Configuring previews..."
    docker exec nextcloud-app php occ config:system:set enable_previews --value=true --type=boolean
    docker exec nextcloud-app php occ config:system:set enabledPreviewProviders 0 --value="OC\\Preview\\Image"
    docker exec nextcloud-app php occ config:system:set enabledPreviewProviders 1 --value="OC\\Preview\\Movie"
    docker exec nextcloud-app php occ config:system:set enabledPreviewProviders 2 --value="OC\\Preview\\TXT"
    docker exec nextcloud-app php occ config:system:set enabledPreviewProviders 3 --value="OC\\Preview\\MP3"
    docker exec nextcloud-app php occ config:system:set enabledPreviewProviders 4 --value="OC\\Preview\\MKV"
    docker exec nextcloud-app php occ config:system:set enabledPreviewProviders 5 --value="OC\\Preview\\MP4"
    docker exec nextcloud-app php occ config:system:set enabledPreviewProviders 6 --value="OC\\Preview\\AVI"
    docker exec nextcloud-app php occ config:system:set enabledPreviewProviders 7 --value="OC\\Preview\\MOV"
    docker exec nextcloud-app php occ config:system:set enabledPreviewProviders 8 --value="OC\\Preview\\PNG"
    docker exec nextcloud-app php occ config:system:set enabledPreviewProviders 9 --value="OC\\Preview\\MarkDown"
    echo "✓ Preview configuration completed!"
fi

# Check if Memories app is installed and enabled
echo ""
echo "Checking Memories app..."
if ! docker exec nextcloud-app php occ app:list | grep -A 100 "Enabled:" | grep -q "memories"; then
    echo "⚠️  WARNING: Memories app is not installed or not enabled!"
    echo ""
    echo "To install Memories:"
    echo "  1. Go to Nextcloud → Apps → Multimedia"
    echo "  2. Search for 'Memories' and click Install"
    echo ""
    echo "Or install via command line:"
    echo "  docker exec nextcloud-app php occ app:install memories"
    echo "  docker exec nextcloud-app php occ app:enable memories"
    echo ""
    echo "Skipping Memories configuration..."
else
    echo "✓ Memories app is installed and enabled"
    
    # Configure Memories ffmpeg paths
    echo ""
    echo "Configuring Memories ffmpeg/ffprobe paths..."
    FFMPEG_PATH=$(docker exec nextcloud-app which ffmpeg)
    FFPROBE_PATH=$(docker exec nextcloud-app which ffprobe)

    docker exec nextcloud-app php occ config:system:set memories.ffmpeg --value="$FFMPEG_PATH"
    docker exec nextcloud-app php occ config:system:set memories.ffprobe --value="$FFPROBE_PATH"

    echo "✓ Memories paths configured:"
    echo "  ffmpeg:  $FFMPEG_PATH"
    echo "  ffprobe: $FFPROBE_PATH"
    
    # Set video quality to Direct (no transcoding)
    echo ""
    echo "Setting default video quality to 'Direct' (no transcoding)..."
    docker exec nextcloud-app php occ config:app:set memories video_default_quality --value="-1"
    echo "✓ Default video quality set to Direct"
    echo ""
    echo "ℹ️  This means videos will be streamed in original quality without transcoding."
    echo "   This is optimal for Raspberry Pi 5 to avoid CPU overhead."
    echo "   Users can still manually select transcoding for individual videos if needed."
fi

echo ""
echo "=== Setup completed successfully! ==="
echo ""
echo "Next steps:"
if docker exec nextcloud-app php occ app:list | grep -A 100 "Enabled:" | grep -q "memories"; then
    echo "1. Regenerate the Memories index:"
    echo "   docker exec nextcloud-app php occ memories:index --user YOUR_CONTAINER_USER_NAME  --force"
    echo ""
    echo "2. Verify settings in the web interface:"
    echo "   Settings → Administration → Memories → Video Streaming"
    echo "   (Should show 'Direct' as default quality)"
else
    echo "1. Install and enable Memories app first"
    echo "2. Then run this script again to configure video paths"
fi
