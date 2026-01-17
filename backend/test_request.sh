#!/bin/bash

URL=${1:-"https://www.instagram.com/reel/DTlXG3pDANa/?utm_source=ig_web_copy_link&igsh=NTc4MTIwNjQ2YQ=="} # Default to "Me at the zoo" (reliable)

echo "Testing download with URL: $URL"

curl -X POST http://localhost:8080/api/process \
  -H "Content-Type: application/json" \
  -d "{\"url\":\"$URL\"}"
