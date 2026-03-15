#!/bin/bash
# wav2sipp.sh - Convert WAV files to SIPp-compatible format for rtp_stream
#
# SIPp 3.7.0+ supports WAV files directly in rtp_stream, but the WAV must be
# pre-encoded in a supported codec: PCMA (G.711a), PCMU (G.711u), G.722, G.729
#
# Usage:
#   ./wav2sipp.sh input.wav [codec] [output.wav]
#
# Codecs:
#   pcma  - G.711 A-law  (8kHz, mono) - payload type 8  [default]
#   pcmu  - G.711 U-law  (8kHz, mono) - payload type 0
#   g722  - G.722        (16kHz, mono) - payload type 9
#
# Examples:
#   ./wav2sipp.sh audio.wav                    # Convert to PCMA (default)
#   ./wav2sipp.sh audio.wav pcmu               # Convert to PCMU
#   ./wav2sipp.sh audio.wav g722 output.wav    # Convert to G.722 with custom output name

set -e

INPUT="$1"
CODEC="${2:-pcma}"
OUTPUT="${3}"

if [[ -z "$INPUT" ]]; then
    echo "Usage: $0 input.wav [pcma|pcmu|g722] [output.wav]"
    echo ""
    echo "Supported codecs:"
    echo "  pcma  - G.711 A-law  8kHz mono (SIPp payload type 8) [default]"
    echo "  pcmu  - G.711 U-law  8kHz mono (SIPp payload type 0)"
    echo "  g722  - G.722       16kHz mono (SIPp payload type 9)"
    exit 1
fi

if [[ ! -f "$INPUT" ]]; then
    echo "Error: Input file not found: $INPUT"
    exit 1
fi

BASENAME=$(basename "$INPUT" .wav)

case "$CODEC" in
    pcma)
        [[ -z "$OUTPUT" ]] && OUTPUT="${BASENAME}_pcma.wav"
        echo "Converting to G.711 A-law (PCMA) 8kHz mono..."
        sox "$INPUT" -r 8000 -c 1 -e a-law "$OUTPUT"
        PAYLOAD=8
        ;;
    pcmu)
        [[ -z "$OUTPUT" ]] && OUTPUT="${BASENAME}_pcmu.wav"
        echo "Converting to G.711 U-law (PCMU) 8kHz mono..."
        sox "$INPUT" -r 8000 -c 1 -e u-law "$OUTPUT"
        PAYLOAD=0
        ;;
    g722)
        [[ -z "$OUTPUT" ]] && OUTPUT="${BASENAME}_g722.wav"
        echo "Converting to G.722 16kHz mono..."
        sox "$INPUT" -r 16000 -c 1 "$OUTPUT"
        PAYLOAD=9
        ;;
    *)
        echo "Error: Unknown codec '$CODEC'. Use: pcma, pcmu, or g722"
        exit 1
        ;;
esac

echo ""
echo "Done: $OUTPUT"
echo ""
echo "Use in SIPp scenario:"
echo "  <exec rtp_stream=\"$OUTPUT\" />"
echo "  <exec rtp_stream=\"$OUTPUT,1,$PAYLOAD\" />   (explicit payload type)"
echo ""
echo "File info:"
sox --i "$OUTPUT"
