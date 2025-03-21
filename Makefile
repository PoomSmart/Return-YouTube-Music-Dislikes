ifeq ($(THEOS_PACKAGE_SCHEME),rootless)
TARGET = iphone:clang:latest:15.0
else
TARGET = iphone:clang:latest:11.0
endif
ARCHS = arm64
INSTALL_TARGET_PROCESSES = YouTubeMusic

API_URL = "https://returnyoutubedislikeapi.com"
TWEAK_DISPLAY_NAME = "Return\ YouTube\ Music\ Dislike"
TWEAK_SHORT_DISPLAY_NAME = "RYMD"

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ReturnYouTubeMusicDislikes

$(TWEAK_NAME)_FILES = Settings.x ../Return-YouTube-Dislikes/API.x ../Return-YouTube-Dislikes/Vote.x ../Return-YouTube-Dislikes/TweakSettings.x Tweak.x
$(TWEAK_NAME)_CFLAGS = -fobjc-arc -DAPI_URL="\"${API_URL}\"" -DTWEAK_NAME="\"${TWEAK_DISPLAY_NAME}\"" -DSHORT_TWEAK_NAME="\"${TWEAK_SHORT_DISPLAY_NAME}\""

include $(THEOS_MAKE_PATH)/tweak.mk
