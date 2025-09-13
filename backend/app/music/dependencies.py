from .service import MusicService


def get_music_service() -> MusicService:
    return MusicService()
