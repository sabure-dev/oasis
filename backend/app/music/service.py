import os
from pathlib import Path

import yt_dlp

current_dir = Path(__file__).parent
app_dir = current_dir.parent.parent
cookies_file = os.path.join(app_dir, "youtube_cookies.txt")


class MusicService:

    @staticmethod
    def search_youtube(query: str, limit: int = 2):
        ydl_opts = {
            "format": "bestaudio/best",
            "quiet": True,
            "cookiefile": cookies_file
        }
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            results = ydl.extract_info(f"ytsearch{limit}:{query} audio", download=False)["entries"]
            tracks = [
                {"title": t["title"], "url": t["url"]}
                for t in results
                if 60 <= t.get("duration", 0) <= 600
            ]
            return tracks
