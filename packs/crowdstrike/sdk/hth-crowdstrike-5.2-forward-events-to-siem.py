#!/usr/bin/env python3
# HTH CrowdStrike Control 5.2: Forward Events to SIEM
# Profile: L1 | NIST: AU-6
# https://howtoharden.com/guides/crowdstrike/#52-forward-events-to-siem

import os
from falconpy import EventStreams

# HTH Guide Excerpt: begin stream-to-siem
def stream_to_siem():
    falcon = EventStreams(
        client_id=os.environ['CS_CLIENT_ID'],
        client_secret=os.environ['CS_CLIENT_SECRET']
    )

    # List available streams
    streams = falcon.list_available_streams()

    # Connect to event stream
    for event in falcon.stream_events(stream_name='main'):
        forward_to_siem(event)
# HTH Guide Excerpt: end stream-to-siem
