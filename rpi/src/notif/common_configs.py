'''
RILEY ANDERSON
02/17/2026
'''

# this file lists common API's custom configurations, and which APIs have such configurations

COMMON_CONFIGS = ['NFL', 'NASA']

#classes for spec options

class MEDIA_SIZES():
    # desired max media size in pixels
    # x, y
    none = (0, 0)
    small = (64.0, 48.0)
    medium = (128.0, 96.0)
    large = (256.0, 192.0)
    full = (640.0, 480.0)

class TEXT_SIZES():
    small = 12.0
    medium = 24.0
    large = 36.0

class DefaultConfig():
    media_size = MEDIA_SIZES.medium
    headline_size = TEXT_SIZES.large
    info_size = TEXT_SIZES.medium

# NFL-specific configuration - small media for team logos on score
class NFLConfig():
    media_size = MEDIA_SIZES.medium
    headline_size = TEXT_SIZES.large
    info_size = TEXT_SIZES.medium

# NASA-specific configuration - assumes pic of the day
class NASAConfig():
    media_size = MEDIA_SIZES.full  # Space image fills
    headline_size = TEXT_SIZES.large
    info_size = TEXT_SIZES.small  # more detailed scientific info in smaller text