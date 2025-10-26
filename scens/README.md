# SIPp Scenario Catalog

This directory contains 74+ comprehensive SIPp test scenarios for SIP/VoIP testing.

## Table of Contents

- [Quick Reference](#quick-reference)
- [UAC Scenarios (User Agent Client)](#uac-scenarios)
- [UAS Scenarios (User Agent Server)](#uas-scenarios)
- [Media Files (PCAP)](#media-files)
- [CSV Data Files](#csv-data-files)
- [Usage Examples](#usage-examples)

---

## Quick Reference

### Most Common Scenarios

| Scenario | Type | Purpose | Typical Usage |
|----------|------|---------|---------------|
| `sipp_uac_basic.xml` | UAC | Basic INVITE/200/ACK/BYE flow | Initial connectivity testing |
| `sipp_uas_basic.xml` | UAS | Basic responder | Server-side testing |
| `sipp_uac_pcap_g711a.xml` | UAC | G.711 alaw with RTP | Codec testing |
| `sipp_uac_register.xml` | UAC | Registration with auth | Registration load |
| `17minutes_G711.xml` | UAC | Long duration calls | Stability testing |

---

## UAC Scenarios

### Basic Call Flows

| Scenario | Description | Media | Use Case |
|----------|-------------|-------|----------|
| `sipp_uac_basic.xml` | Standard INVITE/200/ACK/BYE | No | Basic connectivity |
| `uac.xml` | Simple UAC implementation | No | Quick testing |

### Codec-Specific Scenarios

#### G.711 (Alaw/Ulaw)

| Scenario | Codec | Duration | PCAP File | Notes |
|----------|-------|----------|-----------|-------|
| `sipp_uac_pcap_g711a.xml` | G.711 alaw | Variable | `g711a.pcap` | Standard quality |
| `sipp_uac_pcap_g711a_csv.xml` | G.711 alaw | Variable | `g711a.pcap` | With CSV data injection |
| `uac_g711_34sec.xml` | G.711 | 34 sec | `G711a_34.pcap` | Medium duration |
| `uac_g711_34sec-PCMU.xml` | G.711 μlaw | 34 sec | N/A | Ulaw variant |
| `17minutes_G711.xml` | G.711 alaw | 17 min | `17Minutes_g711ALAW.pcap` | Long duration stability test |
| `17March2013_Tele.xml` | G.711 | 17 min | N/A | Telecom test variant |

#### G.722 (Wideband Audio)

| Scenario | Codec | PCAP File | Notes |
|----------|-------|-----------|-------|
| `sipp_uac_pcap_g722.xml` | G.722 | `g722.pcap` | 16 kHz wideband audio |

#### G.729 (Compressed Audio)

| Scenario | Codec | PCAP File | Duration | Notes |
|----------|-------|-----------|----------|-------|
| `uac_g711_34sec-G729.xml` | G.729 | `G729-1Minute30Seconds.pcap` | 90 sec | Compressed codec |
| N/A | G.729 | `G729-2minute-call-flow.pcap` | 120 sec | Long duration G.729 |

#### Video

| Scenario | Codec | PCAP File | Notes |
|----------|-------|-----------|-------|
| `sipp_uac_pcap_h264.xml` | H.264 | `h264.pcap` | Video calls |
| `sipp_uac_audio_video.xml` | Multi-media | Multiple | Combined audio + video |

### SDP (Session Description Protocol) Testing

| Scenario | Test Type | Purpose |
|----------|-----------|---------|
| `sipp_uac_no_c_line.xml` | Missing SDP c= line | SDP parsing robustness |
| `sipp_uac_no_c_line_multiple_streams.xml` | Missing c= line, multiple streams | Multi-stream SDP handling |
| `sipp_uac_no_session_c_line.xml` | Missing session-level c= line | SDP validation |
| `sipp_uac_no_rtpmap.xml` | Missing rtpmap attributes | Codec negotiation without rtpmap |
| `sipp_uac_invite_without_sdp.xml` | No SDP in INVITE | Late offer scenario |
| `sipp_uac_invite_no_sdp.xml` | INVITE without SDP | SDP-less call setup |
| `sipp_uac_bogus_sdp.xml` | Invalid SDP body | Error handling |
| `sipp_uac_bogus_codec.xml` | Invalid codec parameters | Codec mismatch testing |
| `sipp_uac_late_offer.xml` | SDP in ACK (late offer) | Delayed SDP negotiation |

### Call Hold/Resume

| Scenario | Method | Description |
|----------|--------|-------------|
| `sipp_uac_hold.xml` | sendonly/inactive | Standard call hold (RFC 3264) |
| `sipp_uac_deprecated_hold.xml` | Legacy method | Deprecated hold implementation |
| `sipp_uac_dir_sendonly.xml` | sendonly attribute | Directional attribute testing |
| `sipp_uac_dir_recvonly.xml` | recvonly attribute | Receive-only media |
| `sipp_uac_dir_inactive.xml` | inactive attribute | Media on hold |

### Re-INVITE Testing

| Scenario | Purpose |
|----------|---------|
| `sipp_uac_empty_reinvite.xml` | Empty re-INVITE body testing |
| `advanced-call-flow-uas.xml` | Advanced re-INVITE scenarios |

### Registration

| Scenario | Authentication | Features |
|----------|----------------|----------|
| `sipp_uac_register.xml` | Yes (Digest) | Standard REGISTER with challenge/response |
| `sipp_uac_register_quick.xml` | Optional | Fast registration without delays |
| `sipp_uac_register_broken_contact.xml` | Yes | Malformed Contact header testing |

### Subscription/Presence

| Scenario | Event Type | Purpose |
|----------|------------|---------|
| `sipp_uac_subscribe_presence.xml` | presence | Basic presence subscription |
| `sipp_uac_subscribe_presence_poll.xml` | presence | Polling-based presence |
| `sipp_uac_subscribe_presence_refresh.xml` | presence | Subscription refresh testing |
| `sipp_uac_subscribe_presence_expire.xml` | presence | Expiration handling |
| `sipp_uac_subscribe_mwi_bogus_from.xml` | message-summary | MWI with invalid From header |

### Call Transfer (REFER)

| Scenario | Method | Notes |
|----------|--------|-------|
| `sipp_uac_oob_refer.xml` | Out-of-band REFER | Call transfer testing |
| `sipp_uac_oob_refer_norefsub.xml` | REFER without subscription | No NOTIFY expected |

### Error Injection & Edge Cases

| Scenario | Error Type | SBC Test Purpose |
|----------|------------|------------------|
| `sipp_uac_bad_message.xml` | Malformed SIP message | Message parsing robustness |
| `sipp_uac_wrong_cseq_in_ack.xml` | Invalid CSeq in ACK | CSeq validation |
| `sipp_uac_wrong_format_type.xml` | Invalid Content-Type | Header validation |
| `sipp_uac_empty_subject.xml` | Missing Subject header | Optional header handling |
| `sipp_uac_test_inv.xml` | INVITE variations | Protocol compliance |

### Advanced Features

| Scenario | Feature | Purpose |
|----------|---------|---------|
| `sipp_uac_anonymous.xml` | Privacy headers | Anonymous calling |
| `sipp_uac_diversions.xml` | Diversion headers | Call forwarding info |
| `sipp_uac_ice_without_rtcp.xml` | ICE without RTCP | NAT traversal edge case |
| `OPTIONS.xml` | OPTIONS method | SIP OPTIONS requests |
| `uac-asterisk-tt-monkeys.xml` | Asterisk-specific | Asterisk PBX testing |
| `sip_tele_test.xml` | Telecom testing | Carrier-grade scenarios |

### SBC-Specific Testing

| Scenario | Purpose |
|----------|---------|
| `INVITE-large.xml` | Large SIP message with SBC headers |
| `INVITE-lrt.xml` | SBC routing test with custom tags |

### Advanced Test Suites

| Directory/File | Purpose | Features |
|----------------|---------|----------|
| `Advanced-SIPp-Albert-UAC` | Comprehensive UAC | PCAP playback, PRACK, G.729, DTMF (RFC 2833) |

---

## UAS Scenarios

### Basic Responders

| Scenario | Response | Media | Notes |
|----------|----------|-------|-------|
| `sipp_uas_basic.xml` | 180 + 200 OK | None | Simple answering |
| `uas.xml` | 200 OK | None | Minimal responder |
| `sipp_uas_pcap_g711a.xml` | 200 OK | G.711 RTP | With media playback |

### Advanced UAS

| Scenario | Features | Purpose |
|----------|----------|---------|
| `sipp_uas_pcap_g711a_multi_183.xml` | Multiple 183 Session Progress | Early media testing |
| `sipp_uas_200_multiple_streams.xml` | Multiple media streams | Multi-stream SDP |
| `sipp_uas_multiple_codecs.xml` | Multiple codec negotiation | Codec selection testing |
| `Advanced-SIPp-Albert-UAS` | UPDATE support, complex scenarios | Advanced testing |

### SDP Handling

| Scenario | SDP Feature | Purpose |
|----------|-------------|---------|
| `sipp_uas_200_no_sdp.xml` | No SDP in 200 OK | Late SDP answer |

### Re-INVITE Handling

| Scenario | Response | Purpose |
|----------|----------|---------|
| `sipp_uas_reinvite_481.xml` | 481 Call/Transaction Does Not Exist | Error response testing |

### Registration Handling

| Scenario | Response | Purpose |
|----------|----------|---------|
| `sipp_uas_register_ignore.xml` | Ignore REGISTER | Server-side REGISTER testing |

### Error Responses

| Scenario | Error Code | Purpose |
|----------|------------|---------|
| `sipp_uas_491.xml` | 491 Request Pending | Simultaneous request handling |
| `sipp_uas_malformed_400.xml` | 400 Bad Request | Malformed message response |
| `sipp_uas_double_bye.xml` | Handle double BYE | Duplicate request handling |
| `sipp_uas_message_no_answer.xml` | No answer to MESSAGE | MESSAGE method testing |

### Timing Variations

| Scenario | Timing | Purpose |
|----------|--------|---------|
| `sipp_uas_delayed_answer.xml` | Delayed 200 OK | Timeout testing |
| `sipp_uas_big_start_time.xml` | Large timestamp values | Edge case testing |
| `sipp_uas_no_180.xml` | Skip 180 Ringing | Missing provisional response |

---

## Media Files (PCAP)

### Audio Codecs

| File | Codec | Duration | Sample Rate | Purpose |
|------|-------|----------|-------------|---------|
| `g711a.pcap` | G.711 alaw | Short | 8 kHz | Basic audio testing |
| `G711a_34.pcap` | G.711 alaw | 34 sec | 8 kHz | Medium duration |
| `G711-alaw-2-minutes.pcap` | G.711 alaw | 120 sec | 8 kHz | Long duration |
| `17Minutes_g711ALAW.pcap` | G.711 alaw | 1020 sec | 8 kHz | Stability testing |
| `G711alaw_Early-media-ringing-rtp-only.pcap` | G.711 alaw | Variable | 8 kHz | Early media |
| `g722.pcap` | G.722 | Variable | 16 kHz | Wideband audio |
| `G729-1Minute30Seconds.pcap` | G.729 | 90 sec | 8 kHz | Compressed audio |
| `G729-2minute-call-flow.pcap` | G.729 | 120 sec | 8 kHz | Long G.729 |

### Video Codecs

| File | Codec | Purpose |
|------|-------|---------|
| `h264.pcap` | H.264 | Video call testing |

### Special Media

| File | Type | Purpose |
|------|------|---------|
| `dtmf/dtmf_2833_1.pcap` | RFC 2833 DTMF | DTMF tone testing (payload type 101) |
| `fax/sendfax-wjdtest20150505.pcap` | T.38 FAX | FAX transmission testing |

---

## CSV Data Files

| File | Records | Format | Purpose |
|------|---------|--------|---------|
| `2numbers.csv` | 2000 | calling_number;called_number | Call injection with variable numbers |
| `test50.csv` | 50 | Variable | Small test dataset |
| `test100.csv` | 100 | Variable | Medium test dataset |
| `register_data.csv` | Variable | Username/password | Registration testing |
| `subscribe_mwi_data.csv` | Variable | Subscription data | MWI subscription testing |

### CSV Format Examples

**2numbers.csv:**
```
SEQUENTIAL
1111100001;0119990001
1111100002;0119990002
...
```

---

## Special Scenarios

### DTMF Testing

| Directory/File | Purpose |
|----------------|---------|
| `dtmf/playdtmf.xml` | DTMF tone playback scenario |
| `dtmf/dtmf_2833_1.pcap` | RFC 2833 DTMF tones (telephone-event) |

### FAX Testing

| Directory/File | Purpose |
|----------------|---------|
| `fax/sendfax.xml` | FAX transmission scenario |
| `fax/sendfax-wjdtest20150505.pcap` | T.38 FAX media |

---

## Usage Examples

### Basic UAC Call

```bash
docker run --rm --network host \
  -v $(pwd)/scens:/scens:ro \
  -e "ARGS=-sf /scens/sipp_uac_basic.xml -r 10 -m 100 192.168.1.100:5060" \
  sipp:3.4.1
```

### UAC with G.711 Media

```bash
docker run --rm --network host \
  -v $(pwd)/scens:/scens:ro \
  -e "ARGS=-i 192.168.1.50 -mi 192.168.1.50 -mp 16384 \
             -sf /scens/sipp_uac_pcap_g711a.xml \
             -r 10 -m 100 192.168.1.100:5060" \
  sipp:3.4.1
```

### UAC with CSV Data Injection

```bash
docker run --rm --network host \
  -v $(pwd)/scens:/scens:ro \
  -e "ARGS=-sf /scens/sipp_uac_pcap_g711a_csv.xml \
             -inf /scens/2numbers.csv \
             -r 20 -m 500 192.168.1.100:5060" \
  sipp:3.4.1
```

### UAS with RTP Echo

```bash
docker run --rm --network host \
  -v $(pwd)/scens:/scens:ro \
  -e "ARGS=-i 192.168.1.60 -mi 192.168.1.60 -mp 28384 \
             -sf /scens/sipp_uas_pcap_g711a.xml \
             -rtp_echo" \
  sipp:3.4.1
```

### Long Duration Stability Test

```bash
docker run --rm --network host \
  -v $(pwd)/scens:/scens:ro \
  -v $(pwd)/logs:/logs \
  -e "ARGS=-sf /scens/17minutes_G711.xml \
             -inf /scens/2numbers.csv \
             -r 5 -m 50 -l 500 \
             -trace_stat -stf /logs/stats.csv \
             192.168.1.100:5060" \
  sipp:3.4.1
```

### Registration Load Test

```bash
docker run --rm --network host \
  -v $(pwd)/scens:/scens:ro \
  -e "ARGS=-sf /scens/sipp_uac_register.xml \
             -inf /scens/register_data.csv \
             -r 100 -m 1000 \
             192.168.1.100:5060" \
  sipp:3.4.1
```

---

## Scenario Selection Guide

### By Use Case

**Initial Setup & Connectivity:**
- `sipp_uac_basic.xml` + `sipp_uas_basic.xml`

**Codec Validation:**
- G.711: `sipp_uac_pcap_g711a.xml`
- G.722: `sipp_uac_pcap_g722.xml`
- G.729: `uac_g711_34sec-G729.xml`
- Video: `sipp_uac_pcap_h264.xml`

**SBC Functional Testing:**
- Basic routing: `sipp_uac_basic.xml`
- Header manipulation: `INVITE-large.xml`
- Codec transcoding: Use different codecs on UAC/UAS
- Media relay: Any PCAP scenario with RTP echo on UAS

**SBC Load Testing:**
- Moderate: `sipp_uac_pcap_g711a.xml` (-r 50 -m 500)
- High: `sipp_uac_basic.xml` (-r 200 -m 2000)
- Stability: `17minutes_G711.xml` (-r 10 -m 100)

**SBC Error Handling:**
- `sipp_uac_bad_message.xml`
- `sipp_uac_bogus_sdp.xml`
- `sipp_uac_wrong_cseq_in_ack.xml`

**Registration Load:**
- `sipp_uac_register.xml` with `register_data.csv`

**Feature Testing:**
- Call hold: `sipp_uac_hold.xml`
- Transfer: `sipp_uac_oob_refer.xml`
- Presence: `sipp_uac_subscribe_presence.xml`
- DTMF: `dtmf/playdtmf.xml`
- FAX: `fax/sendfax.xml`

---

## Tips & Best Practices

1. **Start Simple**: Use `sipp_uac_basic.xml` and `sipp_uas_basic.xml` first
2. **Add Media Gradually**: Move to PCAP scenarios after basic connectivity works
3. **Use CSV for Scale**: Inject variable phone numbers with CSV files
4. **Monitor Logs**: Always use `-trace_err` for error logging
5. **Collect Stats**: Use `-trace_stat -stf stats.csv` for metrics
6. **Long Duration**: Use 17-minute scenarios for stability testing
7. **Error Testing**: Run malformed message scenarios to validate robustness

---

## Related Documentation

- Main README: `/README.md`
- Docker Compose configs: `/docker-compose*.yml`
- Control script: `/sipp-control.sh`
- Environment config: `/.env.example`

---

**Last Updated:** 2025-10-26
**Total Scenarios:** 74+ XML files
**Total Media Files:** 11 PCAP files
**Total CSV Files:** 6 data files
