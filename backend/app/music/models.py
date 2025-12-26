from sqlalchemy import Integer, String, ForeignKey
from sqlalchemy.orm import relationship, Mapped, mapped_column

from database import Base


class PlaylistTrackAssociation(Base):
    __tablename__ = "playlist_tracks"

    playlist_id: Mapped[int] = mapped_column(ForeignKey("playlists.id", ondelete="CASCADE"), primary_key=True)
    track_id: Mapped[int] = mapped_column(ForeignKey("tracks.id", ondelete="CASCADE"), primary_key=True)


class Track(Base):
    __tablename__ = "tracks"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    source_id: Mapped[str] = mapped_column(String, index=True, unique=True)  # ID трека из внешнего API (DAB)
    title: Mapped[str] = mapped_column(String)
    artist: Mapped[str] = mapped_column(String)
    album: Mapped[str] = mapped_column(String, nullable=True)
    album_cover: Mapped[str] = mapped_column(String, nullable=True)
    duration: Mapped[int] = mapped_column(Integer, default=0)

    playlists = relationship("Playlist", secondary="playlist_tracks", back_populates="tracks")


class Playlist(Base):
    __tablename__ = "playlists"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"))
    name: Mapped[str] = mapped_column(String, unique=True)
    cover_image: Mapped[str] = mapped_column(String, nullable=True)

    tracks = relationship("Track", secondary="playlist_tracks", back_populates="playlists", lazy="selectin")
