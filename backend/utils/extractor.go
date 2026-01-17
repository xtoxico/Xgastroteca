package utils

import (
	"errors"
	"regexp"
	"strings"
)

// ExtractVideoInfo parses a video URL to identify the platform (source) and the unique video ID (externalID).
// Supported sources: youtube, instagram, tiktok.
func ExtractVideoInfo(url string) (source string, externalID string, err error) {
	// YouTube
	// Supports: youtube.com/watch?v=ID, youtube.com/shorts/ID, youtu.be/ID
	if strings.Contains(url, "youtube.com") || strings.Contains(url, "youtu.be") {
		// Try Shorts
		reShorts := regexp.MustCompile(`youtube\.com/shorts/([a-zA-Z0-9_-]+)`)
		match := reShorts.FindStringSubmatch(url)
		if len(match) > 1 {
			return "youtube", match[1], nil
		}

		// Try Watch ?v=
		reWatch := regexp.MustCompile(`[?&]v=([a-zA-Z0-9_-]+)`)
		match = reWatch.FindStringSubmatch(url)
		if len(match) > 1 {
			return "youtube", match[1], nil
		}

		// Try youtu.be/ID
		reShortened := regexp.MustCompile(`youtu\.be/([a-zA-Z0-9_-]+)`)
		match = reShortened.FindStringSubmatch(url)
		if len(match) > 1 {
			return "youtube", match[1], nil
		}

		return "", "", errors.New("could not extract youtube ID")
	}

	// Instagram
	// Supports: instagram.com/reel/ID, instagram.com/p/ID
	if strings.Contains(url, "instagram.com") {
		reInsta := regexp.MustCompile(`instagram\.com/(?:p|reel)/([a-zA-Z0-9_-]+)`)
		match := reInsta.FindStringSubmatch(url)
		if len(match) > 1 {
			return "instagram", match[1], nil
		}
		return "", "", errors.New("could not extract instagram ID")
	}

	// TikTok
	// Supports: tiktok.com/@user/video/ID
	if strings.Contains(url, "tiktok.com") {
		reTikTok := regexp.MustCompile(`tiktok\.com/.*/video/(\d+)`)
		match := reTikTok.FindStringSubmatch(url)
		if len(match) > 1 {
			return "tiktok", match[1], nil
		}
		return "", "", errors.New("could not extract tiktok ID")
	}

	return "", "", errors.New("platform not supported")
}
