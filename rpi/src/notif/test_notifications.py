#!/usr/bin/env python3
'''
RILEY ANDERSON
02/17/2026
Test script to send notifications to the Flutter interface
'''

import json
import sys
import os

# Add the notif directory to the path
sys.path.insert(0, os.path.dirname(__file__))

from notify import notify

def send_test_notification(source='', headline='Test Notification', 
                          info='This is a test notification', 
                          media='', seemore=''):
    """
    Send a test notification to the Flutter app
    """
    notification = {
        "notifType": "base",
        "fromSource": source,
        "data": {
            "timestamp": "2026-02-17T10:30:00Z",
            "media": media,
            "headline": headline,
            "info": info,
            "seemore": seemore
        }
    }
    
    print(f"Sending notification from: {source or 'Local Machine'}")
    print(f"Headline: {headline}")
    
    success = notify(notification)
    
    if success:
        print("✓ Notification sent successfully!")
    else:
        print("✗ Failed to send notification")
    
    return success


def main():
    """Run various test notifications"""
    print("=" * 60)
    print("NOTIFICATION SYSTEM TEST")
    print("=" * 60)
    print()
    
    # Test 1: Default notification (no specific source)
    print("Test 1: Default Notification")
    print("-" * 60)
    send_test_notification(
        source='',
        headline='System Ready',
        info='All systems operational. Ready to receive notifications.',
    )
    print()
    
    import time
    time.sleep(15)
    
    # Test 2: NFL notification (custom config - large media)
    print("Test 2: NFL Notification")
    print("-" * 60)
    send_test_notification(
        source='NFL',
        media='https://a.espncdn.com/i/teamlogos/nfl/500/kc.png',
        headline='Chiefs Win Super Bowl!',
        info='Kansas City Chiefs defeat the Eagles 31-28 in overtime.',
        seemore='https://example.com/nfl/superbowl'
    )
    print()
    
    time.sleep(15)
    
    # Test 3: NASA notification (custom config - smaller text)
    print("Test 3: NASA Notification")
    print("-" * 60)
    send_test_notification(
        source='NASA',
        media='https://www.nasa.gov/wp-content/uploads/2026/02/nycicy-oli-20260128-lrg.jpg',
        headline='New Exoplanet Discovered',
        info='Astronomers have discovered a potentially habitable exoplanet 100 light-years away.',
        seemore='https://example.com/nasa/exoplanet'
    )
    print()
    
    time.sleep(15)
    
    # Test 4: Custom API notification (uses default config)
    print("Test 4: Weather Alert")
    print("-" * 60)
    send_test_notification(
        source='WeatherAPI',
        headline='Severe Weather Warning',
        info='Heavy snowfall expected tonight. Road conditions may be hazardous.',
    )
    print()
    
    print("=" * 60)
    print("All tests completed!")
    print("Check the Flutter app top screen for notifications.")
    print("=" * 60)


if __name__ == '__main__':
    main()
