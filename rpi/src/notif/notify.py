'''
RILEY ANDERSON
02/17/2026
'''

# this file contains the function call that will send a notification to the flutter interface to be displayed

import json
from common_configs import COMMON_CONFIGS

# initially, we shall assume that all notifications will come in the 'base' format, containing the following data:
'''        
        {   
            we read notiftype to ensure that this is a base notification
            "notifType": "base",
            we read to see if there are any special configurations for this specific API
            "fromSource" : ""
            an internal data dictionary holds all info
            "data" : {
            timestamp
                "timestamp": "2024-01-15T10:30:00Z",
            a link to any images or media to be displayed
                "media": "",
            the text that will be displayed the largest
                "headline": "",
            smaller text below
                "info": "",
            if this is populated, a button will be displayed the the user that will prompt them if they want to see more.
            if the button is pressed, a qr code will be generated and displayed on the top screen for them to scan to see more about the notif.
                "seemore": ""
            }
        }
        
'''

# parse any special data and then pass off cleaned notif to widget builder with the proper parameters. 
def notify(notification_json):
    """
    Main notification handler that processes incoming notifications.
    Args:
        notification_json: Either a JSON string or a dictionary containing notification data
    Returns:
        bool: True if notification was processed successfully, False otherwise
    """
    try:
        # Parse the notification if it's a string
        if isinstance(notification_json, str):
            data = json.loads(notification_json)
        elif isinstance(notification_json, dict):
            data = notification_json
        else:
            print(f"Invalid notification type: {type(notification_json)}")
            return False
        
        # Validate notification structure
        if not isinstance(data, dict):
            print("Notification is not a dictionary")
            return False
            
        if data.get('notifType') != 'base':
            print(f"Unsupported notification type: {data.get('notifType')}")
            return False
        
        # Get the source and apply appropriate config
        from_source = data.get('fromSource', '')
        config = get_config_for_source(from_source)
        
        # Prepare the notification payload with config
        notification_payload = {
            'notification': data.get('data', {}),
            'config': {
                'media_size': config.media_size,
                'headline_size': config.headline_size,
                'info_size': config.info_size,
            },
            'from_source': from_source
        }
        
        # Write to file for Flutter to read
        send_to_flutter(notification_payload)
        return True
        
    except json.JSONDecodeError as e:
        print(f"JSON decode error: {e}")
        return False
    except Exception as e:
        print(f"Error processing notification: {e}")
        return False


def get_config_for_source(source):
    """
    Get the configuration for a specific notification source.
    Args:
        source: String identifier of the notification source
    Returns:
        Configuration object (either custom or default)
    """
    if source in COMMON_CONFIGS:
        if source == 'NFL':
            from common_configs import NFLConfig
            return NFLConfig()
        elif source == 'NASA':
            from common_configs import NASAConfig
            return NASAConfig()
    
    # Return default config if no custom config exists
    from common_configs import DefaultConfig
    return DefaultConfig()


def send_to_flutter(payload):
    """
    Write notification data to a JSON file that Flutter will monitor.
    Args:
        payload: Dictionary containing notification data and config
    """
    import os
    
    # Write to a file in the notif directory
    output_path = os.path.join(os.path.dirname(__file__), 'current_notification.json')
    
    with open(output_path, 'w') as f:
        json.dump(payload, f, indent=2)
    
    print(f"Notification sent to Flutter: {payload['from_source']}")