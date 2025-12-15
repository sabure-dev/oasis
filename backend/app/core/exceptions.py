class OasisException(Exception):
    pass


class UserAlreadyExists(OasisException):
    pass


class UserNotFound(OasisException):
    pass


class InvalidCredentials(OasisException):
    pass


class TokenExpired(OasisException):
    pass


class InvalidToken(OasisException):
    pass


class UpstreamServiceError(OasisException):
    pass
