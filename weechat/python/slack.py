# This is a compiled file.
# For the original source, see https://github.com/wee-slack/wee-slack

from __future__ import annotations

import ast
import hashlib
import json
import os
import pprint
import re
import resource
import socket
import ssl
import sys
import time
import traceback
from abc import ABC, abstractmethod
from collections import OrderedDict, defaultdict
from contextlib import contextmanager
from dataclasses import dataclass, field
from datetime import date, datetime, timedelta
from enum import Enum, IntEnum
from functools import partial, wraps
from io import StringIO
from itertools import chain, islice
from typing import (
    TYPE_CHECKING,
    Any,
    Awaitable,
    Callable,
    Coroutine,
    Dict,
    Generator,
    Generic,
    Iterable,
    Iterator,
    List,
    Mapping,
    Match,
    NoReturn,
    Optional,
    Sequence,
    Set,
    Tuple,
    Type,
    TypeVar,
    Union,
    cast,
    overload,
)
from urllib.parse import quote, unquote, urlencode
from uuid import uuid4

import weechat
from websocket import (
    ABNF,
    WebSocket,
    WebSocketConnectionClosedException,
    create_connection,
)


# Copied from https://peps.python.org/pep-0616/ for support for Python < 3.9
def removeprefix(self: str, prefix: str) -> str:
    if self.startswith(prefix):
        return self[len(prefix) :]
    else:
        return self[:]


# Copied from https://peps.python.org/pep-0616/ for support for Python < 3.9
def removesuffix(self: str, suffix: str) -> str:
    if suffix and self.endswith(suffix):
        return self[: -len(suffix)]
    else:
        return self[:]


def format_exception_only(exc: BaseException) -> List[str]:
    return traceback.format_exception_only(type(exc), exc)


def format_exception(exc: BaseException) -> List[str]:
    return traceback.format_exception(type(exc), exc, exc.__traceback__)


if TYPE_CHECKING:
    pass

T = TypeVar("T")
T2 = TypeVar("T2")


def get_callback_name(callback: Callable[..., WeechatCallbackReturnType]) -> str:
    callback_id = f"{callback.__name__}-{id(callback)}"
    shared.weechat_callbacks[callback_id] = callback
    return callback_id


def get_resolved_futures(futures: Iterable[Future[T]]) -> List[T]:
    return [future.result() for future in futures if future.done_with_result()]


def with_color(color: Optional[str], string: str, reset_color: str = "default"):
    if color:
        return f"{weechat.color(color)}{string}{weechat.color(reset_color)}"
    else:
        return string


# Escape chars that have special meaning to Slack. Note that we do not
# (and should not) perform full HTML entity-encoding here.
# See https://api.slack.com/reference/surfaces/formatting#escaping for details.
def htmlescape(text: str) -> str:
    return text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def unhtmlescape(text: str) -> str:
    return text.replace("&lt;", "<").replace("&gt;", ">").replace("&amp;", "&")


def url_encode_if_not_encoded(value: str) -> str:
    is_encoded = value != unquote(value)
    if is_encoded:
        return value
    else:
        return quote(value)


def get_cookies(cookie_config: str) -> str:
    cookie_pairs = [cookie.split("=", 1) for cookie in cookie_config.split(";")]
    if len(cookie_pairs) == 1 and len(cookie_pairs[0]) == 1:
        cookie_pairs[0].insert(0, "d")
    for cookie_pair in cookie_pairs:
        cookie_pair[0] = cookie_pair[0].strip()
        cookie_pair[1] = url_encode_if_not_encoded(cookie_pair[1].strip())
    return "; ".join("=".join(cookie_pair) for cookie_pair in cookie_pairs)


# From https://github.com/more-itertools/more-itertools/blob/v10.1.0/more_itertools/recipes.py#L93-L106
def take(n: int, iterable: Iterable[T]) -> List[T]:
    """Return first *n* items of the iterable as a list.

        >>> take(3, range(10))
        [0, 1, 2]

    If there are fewer than *n* items in the iterable, all of them are
    returned.

        >>> take(10, range(3))
        [0, 1, 2]

    """
    return list(islice(iterable, n))


# Modified from https://github.com/more-itertools/more-itertools/blob/v10.1.0/more_itertools/more.py#L149-L181
def chunked(iterable: Iterable[T], n: int, strict: bool = False) -> Iterator[List[T]]:
    """Break *iterable* into lists of length *n*:

        >>> list(chunked([1, 2, 3, 4, 5, 6], 3))
        [[1, 2, 3], [4, 5, 6]]

    The last yielded list will have fewer than *n* elements
    if the length of *iterable* is not divisible by *n*:

        >>> list(chunked([1, 2, 3, 4, 5, 6, 7, 8], 3))
        [[1, 2, 3], [4, 5, 6], [7, 8]]

    To use a fill-in value instead, see the :func:`grouper` recipe.

    """
    return iter(partial(take, n, iter(iterable)), [])


# From https://stackoverflow.com/a/5921708
def intersperse(lst: Sequence[Union[T, T2]], item: T2) -> List[Union[T, T2]]:
    """Inserts item between each item in lst"""
    result: List[Union[T, T2]] = [item] * (len(lst) * 2 - 1)
    result[0::2] = lst
    return result


if TYPE_CHECKING:
    pass
    pass
    pass
    pass
    pass
    pass
    pass

WeechatCallbackReturnType = Union[int, str, Dict[str, str], None]

MESSAGE_ID_REGEX_STRING = r"(?P<msg_id>\d+|\$[0-9a-z]{3,})"
REACTION_CHANGE_REGEX_STRING = r"(?P<reaction_change>\+|-)"

EMOJI_CHAR_REGEX_STRING = "(?P<emoji_char>[\U00000080-\U0010ffff]+)"
EMOJI_NAME_REGEX_STRING = (
    ":(?P<emoji_name>[a-z0-9_+-]+(?:::skin-tone-[2-6](?:-[2-6])?)?):"
)
EMOJI_CHAR_OR_NAME_REGEX_STRING = (
    f"(?:{EMOJI_CHAR_REGEX_STRING}|{EMOJI_NAME_REGEX_STRING})"
)


class Shared:
    def __init__(self):
        self.SCRIPT_NAME = "slack"
        self.SCRIPT_VERSION = "3.0.0"

        self.weechat_version: int
        self.weechat_callbacks: Dict[str, Callable[..., WeechatCallbackReturnType]]
        self.active_tasks: Dict[str, List[Task[object]]] = defaultdict(list)
        self.active_futures: Dict[str, Future[object]] = {}
        self.buffers: Dict[str, Union[SlackWorkspace, SlackMessageBuffer]] = {}
        self.workspaces: Dict[str, SlackWorkspace] = {}
        self.current_buffer_pointer: str
        self.config: SlackConfig
        self.commands: Dict[str, Command] = {}
        self.uncaught_errors: List[UncaughtError] = []
        self.standard_emojis: Dict[str, Emoji]
        self.standard_emojis_inverse: Dict[str, Emoji]
        self.highlight_tag = "highlight"
        self.debug_buffer_pointer: Optional[str] = None
        self.script_is_unloading = False


shared = Shared()


if TYPE_CHECKING:
    pass

T = TypeVar("T")

running_tasks: Set[Task[object]] = set()
failed_tasks: List[Tuple[Task[object], BaseException]] = []


class CancelledError(Exception):
    pass


class InvalidStateError(Exception):
    pass


# Heavily inspired by https://github.com/python/cpython/blob/3.11/Lib/asyncio/futures.py
class Future(Awaitable[T]):
    def __init__(self, future_id: Optional[str] = None):
        self.id = future_id or str(uuid4())
        self._state: Literal["PENDING", "CANCELLED", "FINISHED"] = "PENDING"
        self._result: T
        self._exception: Optional[BaseException] = None
        self._cancel_message = None
        self._callbacks: List[Callable[[Self], object]] = []
        self._exception_read = False

    def __repr__(self) -> str:
        return f"{self.__class__.__name__}('{self.id}')"

    def __await__(self) -> Generator[Future[T], None, T]:
        if not self.done():
            yield self  # This tells Task to wait for completion.
        if not self.done():
            raise RuntimeError("await wasn't used with future")
        return self.result()  # May raise too.

    def _make_cancelled_error(self):
        if self._cancel_message is None:
            return CancelledError()
        else:
            return CancelledError(self._cancel_message)

    def __schedule_callbacks(self):
        callbacks = self._callbacks[:]
        if not callbacks:
            return

        self._callbacks[:] = []
        for callback in callbacks:
            callback(self)

    def result(self):
        exc = self.exception()
        if exc is not None:
            raise exc
        return self._result

    def set_result(self, result: T):
        if self.done():
            raise InvalidStateError(f"{self._state}: {self!r}")
        self._result = result
        self._state = "FINISHED"
        self.__schedule_callbacks()

    def set_exception(self, exception: BaseException):
        if self.done():
            raise InvalidStateError(f"{self._state}: {self!r}")
        if isinstance(exception, type):
            exception = exception()
        if type(exception) is StopIteration:
            raise TypeError(
                "StopIteration interacts badly with generators "
                "and cannot be raised into a Future"
            )
        self._exception = exception
        self._state = "FINISHED"
        self.__schedule_callbacks()

    def done(self):
        return self._state != "PENDING"

    def done_with_result(self):
        return self._state == "FINISHED" and self._exception is None

    def cancelled(self):
        return self._state == "CANCELLED"

    def add_done_callback(self, callback: Callable[[Self], object]) -> None:
        if self.done():
            callback(self)
        else:
            self._callbacks.append(callback)

    def remove_done_callback(self, callback: Callable[[Self], object]) -> int:
        filtered_callbacks = [cb for cb in self._callbacks if cb != callback]
        removed_count = len(self._callbacks) - len(filtered_callbacks)
        if removed_count:
            self._callbacks[:] = filtered_callbacks
        return removed_count

    def cancel(self, msg: Optional[str] = None):
        if self._state != "PENDING":
            return False
        self._state = "CANCELLED"
        self._cancel_message = msg
        self.__schedule_callbacks()
        return True

    def exception(self):
        if self.cancelled():
            raise self._make_cancelled_error()
        elif not self.done():
            raise InvalidStateError("Exception is not set.")
        self._exception_read = True
        return self._exception

    def exception_read(self):
        return self._exception_read


class FutureProcess(Future[Tuple[str, int, str, str]]):
    pass


class FutureUrl(Future[Tuple[str, Dict[str, str], Dict[str, str]]]):
    pass


class FutureTimer(Future[Tuple[int]]):
    pass


class Task(Future[T]):
    def __init__(self, coroutine: Coroutine[Future[T], None, T]):
        super().__init__()
        self.coroutine = coroutine

    def __repr__(self) -> str:
        return f"{self.__class__.__name__}('{self.id}', coroutine={self.coroutine.__qualname__})"

    def cancel(self, msg: Optional[str] = None):
        if not super().cancel(msg):
            return False
        self.coroutine.close()
        return True


def weechat_task_cb(data: str, *args: object) -> int:
    future = shared.active_futures.pop(data)
    future.set_result(args)
    tasks = shared.active_tasks.pop(data)
    for task in tasks:
        task_runner(task)
    return weechat.WEECHAT_RC_OK


def process_ended_task(task: Task[Any]):
    if task.id in shared.active_tasks:
        tasks = shared.active_tasks.pop(task.id)
        for active_task in tasks:
            task_runner(active_task)
    if task.id in shared.active_futures:
        del shared.active_futures[task.id]


def task_runner(task: Task[Any]):
    running_tasks.add(task)
    while True:
        if task.cancelled():
            break
        try:
            future = task.coroutine.send(None)
        except BaseException as e:
            if isinstance(e, StopIteration):
                task.set_result(e.value)
            else:
                task.set_exception(e)
                failed_tasks.append((task, e))
            process_ended_task(task)
            break

        if not future.done():
            shared.active_tasks[future.id].append(task)
            shared.active_futures[future.id] = future
            break

    running_tasks.remove(task)
    if not running_tasks and not shared.active_tasks:
        for task, exception in failed_tasks:
            if not task.exception_read():
                print_error(
                    f"{task} was never awaited and failed with: "
                    f"{store_and_format_exception(exception)}"
                )
        failed_tasks.clear()


def create_task(coroutine: Coroutine[Future[Any], None, T]) -> Task[T]:
    task = Task(coroutine)
    task_runner(task)
    return task


def _async_task_done(task: Task[object]):
    exception = task.exception()
    if exception:
        print_error(f"{task} failed with: {store_and_format_exception(exception)}")


def run_async(coroutine: Coroutine[Future[Any], None, Any]) -> None:
    task = Task(coroutine)
    task.add_done_callback(_async_task_done)
    task_runner(task)


@overload
async def gather(
    *requests: Union[Future[T], Coroutine[Any, None, T]],
    return_exceptions: Literal[False] = False,
) -> List[T]: ...


@overload
async def gather(
    *requests: Union[Future[T], Coroutine[Any, None, T]],
    return_exceptions: Literal[True],
) -> List[Union[T, BaseException]]: ...


async def gather(
    *requests: Union[Future[T], Coroutine[Any, None, T]],
    return_exceptions: bool = False,
) -> Sequence[Union[T, BaseException]]:
    tasks = [
        create_task(request) if isinstance(request, Coroutine) else request
        for request in requests
    ]

    results: List[Union[T, BaseException]] = []
    for task in tasks:
        if return_exceptions:
            try:
                results.append(await task)
            except BaseException as e:
                results.append(e)
        else:
            results.append(await task)

    return results


async def sleep(milliseconds: int):
    future = FutureTimer()
    sleep_ms = milliseconds if milliseconds > 0 else 1
    weechat.hook_timer(sleep_ms, 0, 1, get_callback_name(weechat_task_cb), future.id)
    return await future


if TYPE_CHECKING:
    pass
    pass
    pass
    pass
    pass

    pass
    pass
    pass

    MessageContext = Literal["conversation", "thread"]
else:
    MessageContext = str

ts_tag_prefix = "slack_ts_"


def format_date(timestamp: int, token_string: str, link: Optional[str] = None) -> str:
    ref_datetime = datetime.fromtimestamp(timestamp)
    token_to_format = {
        "date_num": "%Y-%m-%d",
        "date": "%B %d, %Y",
        "date_short": "%b %d, %Y",
        "date_long": "%A, %B %d, %Y",
        "time": "%H:%M",
        "time_secs": "%H:%M:%S",
    }

    def replace_token(match: Match[str]):
        token = match.group(1)
        if token.startswith("date_") and token.endswith("_pretty"):
            if ref_datetime.date() == date.today():
                return "today"
            elif ref_datetime.date() == date.today() - timedelta(days=1):
                return "yesterday"
            elif ref_datetime.date() == date.today() + timedelta(days=1):
                return "tomorrow"
            else:
                token = token.replace("_pretty", "")
        if token in token_to_format:
            return ref_datetime.strftime(token_to_format[token])
        else:
            return match.group(0)

    formatted_date = re.sub(r"{([^}]+)}", replace_token, token_string)
    if link is not None:
        return format_url(link, formatted_date)
    else:
        return formatted_date


def format_url(url: str, text: Optional[str] = None) -> str:
    return weechat.string_eval_expression(
        shared.config.look.render_url_as.value,
        {},
        {"url": url, "text": text or ""},
        {},
    )


def convert_int_to_letter(num: int) -> str:
    letter = ""
    while num > 0:
        num -= 1
        letter = chr((num % 26) + 97) + letter
        num //= 26
    return letter


def convert_int_to_roman(num: int) -> str:
    roman_numerals = {
        1000: "m",
        900: "cm",
        500: "d",
        400: "cd",
        100: "c",
        90: "xc",
        50: "l",
        40: "xl",
        10: "x",
        9: "ix",
        5: "v",
        4: "iv",
        1: "i",
    }
    roman_numeral = ""
    for value, symbol in roman_numerals.items():
        while num >= value:
            roman_numeral += symbol
            num -= value
    return roman_numeral


def ts_from_tag(tag: str) -> Optional[SlackTs]:
    if tag.startswith(ts_tag_prefix):
        return SlackTs(tag[len(ts_tag_prefix) :])
    return None


def is_not_found_error(e: Union[SlackApiError, SlackError]) -> bool:
    return (
        isinstance(e, SlackApiError)
        and e.response["error"]
        in ["channel_not_found", "user_not_found", "bot_not_found"]
        or isinstance(e, SlackError)
        and e.error in ["item_not_found", "usergroup_not_found"]
    )


class MessagePriority(Enum):
    NONE = "none"
    LOW = weechat.WEECHAT_HOTLIST_LOW
    MESSAGE = weechat.WEECHAT_HOTLIST_MESSAGE
    PRIVATE = weechat.WEECHAT_HOTLIST_PRIVATE
    HIGHLIGHT = weechat.WEECHAT_HOTLIST_HIGHLIGHT


class SlackTs(str):
    def __init__(self, ts: str):
        self.major, self.minor = [int(x) for x in ts.split(".", 1)]

    def __hash__(self) -> int:
        return hash((self.major, self.minor))

    def __repr__(self) -> str:
        return f"SlackTs('{self}')"

    def _cmp(self, other: object) -> int:
        if isinstance(other, str):
            other = SlackTs(other)
        if not isinstance(other, SlackTs):
            return NotImplemented
        elif self.major > other.major:
            return 1
        elif self.major < other.major:
            return -1
        elif self.minor > other.minor:
            return 1
        elif self.minor < other.minor:
            return -1
        else:
            return 0

    def __eq__(self, other: object) -> bool:
        return self._cmp(other) == 0

    def __ne__(self, other: object) -> bool:
        return self._cmp(other) != 0

    def __gt__(self, other: object) -> bool:
        return self._cmp(other) == 1

    def __ge__(self, other: object) -> bool:
        return self._cmp(other) >= 0

    def __lt__(self, other: object) -> bool:
        return self._cmp(other) == -1

    def __le__(self, other: object) -> bool:
        return self._cmp(other) <= 0


class PendingMessageItem:
    def __init__(
        self,
        message: SlackMessage,
        item_type: Literal[
            "conversation", "user", "usergroup", "broadcast", "message_nick", "file"
        ],
        item_id: str,
        display_type: Literal["mention", "chat"] = "mention",
        fallback_name: Optional[str] = None,
        file: Optional[SlackFile] = None,
    ):
        self.message = message
        self.item_type: Literal[
            "conversation", "user", "usergroup", "broadcast", "message_nick", "file"
        ] = item_type
        self.item_id = item_id
        self.display_type: Literal["mention", "chat"] = display_type
        self.fallback_name = fallback_name
        self.file = file

    def __repr__(self):
        return f"{self.__class__.__name__}({self.message}, {self.item_type}, {self.item_id}, {self.display_type})"

    async def resolve(self) -> str:
        if self.item_type == "conversation":
            try:
                conversation = await self.message.workspace.conversations[self.item_id]
                name = conversation.name_with_prefix("short_name_without_padding")
            except (SlackApiError, SlackError) as e:
                if is_not_found_error(e):
                    name = (
                        f"#{self.fallback_name}"
                        if self.fallback_name
                        else "#<private channel>"
                    )
                else:
                    raise e
            if self.display_type == "mention":
                color = shared.config.color.channel_mention.value
            elif self.display_type == "chat":
                color = "chat_channel"
            else:
                assert_never(self.display_type)
            return with_color(color, name)

        elif self.item_type == "user":
            try:
                user = await self.message.workspace.users[self.item_id]
            except (SlackApiError, SlackError) as e:
                if is_not_found_error(e):
                    name = (
                        f"@{self.fallback_name}"
                        if self.fallback_name
                        else f"@{self.item_id}"
                    )
                    return name
                else:
                    raise e

            if self.display_type == "mention":
                name = f"@{user.nick.format()}"
                return with_color(shared.config.color.user_mention.value, name)
            elif self.display_type == "chat":
                return user.nick.format(colorize=True)
            else:
                assert_never(self.display_type)

        elif self.item_type == "usergroup":
            try:
                usergroup = await self.message.workspace.usergroups[self.item_id]
                name = f"@{usergroup.handle()}"
            except (SlackApiError, SlackError) as e:
                if (
                    isinstance(e, SlackApiError)
                    and e.response["error"] == "invalid_auth"
                    or is_not_found_error(e)
                ):
                    name = (
                        self.fallback_name if self.fallback_name else f"@{self.item_id}"
                    )
                else:
                    raise e
            return with_color(shared.config.color.usergroup_mention.value, name)

        elif self.item_type == "broadcast":
            broadcast_name = self.item_id.replace("group", "channel")
            name = f"@{broadcast_name}"
            return with_color(shared.config.color.usergroup_mention.value, name)

        elif self.item_type == "message_nick":
            nick = await self.message.nick()
            return nick.format(colorize=True)

        elif self.item_type == "file":
            if self.file is None or self.file.get("file_access") == "check_file_info":
                file_response = await self.message.workspace.api.fetch_files_info(
                    self.item_id
                )
                file = file_response["file"]
            else:
                file = self.file

            if file.get("mode") == "tombstone":
                return with_color(
                    shared.config.color.deleted_message.value,
                    "(This file was deleted)",
                )
            elif file.get("mode") == "hidden_by_limit":
                return with_color(
                    shared.config.color.deleted_message.value,
                    "(This file is not available because the workspace has passed its storage limit)",
                )
            elif file.get("file_access") == "file_not_found":
                return with_color(
                    shared.config.color.deleted_message.value,
                    "(This file was not found)",
                )
            elif (
                file.get("mimetype") == "application/vnd.slack-docs"
                and "permalink" in file
            ):
                url = f"{file['permalink']}?origin_team={self.message.workspace.id}&origin_channel={self.message.conversation.id}"
                title = unhtmlescape(file.get("title", ""))
                return format_url(url, title)
            elif "url_private" in file:
                title = unhtmlescape(file.get("title", ""))
                return format_url(file["url_private"], title)
            else:
                error = SlackError(self.message.workspace, "Unsupported file", file)
                uncaught_error = UncaughtError(error)
                store_uncaught_error(uncaught_error)
                return with_color(
                    shared.config.color.render_error.value,
                    f"<Unsupported file, error id: {uncaught_error.id}>",
                )

        else:
            assert_never(self.item_type)

    def should_highlight(self, only_personal: bool) -> bool:
        if self.item_type == "conversation":
            return False
        elif self.item_type == "user":
            return self.item_id == self.message.workspace.my_user.id
        elif self.item_type == "usergroup":
            return self.item_id in self.message.workspace.usergroups_member
        elif self.item_type == "broadcast":
            # TODO: figure out how to handle here broadcast
            return not only_personal
        elif self.item_type == "message_nick":
            return False
        elif self.item_type == "file":
            return False
        else:
            assert_never(self.item_type)


class SlackMessage:
    def __init__(self, conversation: SlackConversation, message_json: SlackMessageDict):
        self._message_json = message_json
        self._rendered_prefix = None
        self._rendered_message = None
        self._parsed_message: Optional[List[Union[str, PendingMessageItem]]] = None
        self.conversation = conversation
        self.ts = SlackTs(message_json["ts"])
        self.replies_tss: List[SlackTs] = []
        self._replies = SlackMessageReplies(self)
        self.reply_history_filled = False
        self.thread_buffer: Optional[SlackThread] = None
        self._deleted = False

    def __repr__(self):
        return f"{self.__class__.__name__}({self.conversation}, {self.ts})"

    @property
    def message_json(self) -> SlackMessageDict:
        return self._message_json

    @property
    def workspace(self) -> SlackWorkspace:
        return self.conversation.workspace

    @property
    def hash(self) -> str:
        return self.conversation.message_hashes[self.ts]

    @property
    def subtype(self):
        if "subtype" in self._message_json:
            return self._message_json["subtype"]

    @property
    def thread_ts(self) -> Optional[SlackTs]:
        return (
            SlackTs(self._message_json["thread_ts"])
            if "thread_ts" in self._message_json
            else None
        )

    @property
    def is_thread_parent(self) -> bool:
        return self.thread_ts == self.ts

    @property
    def is_reply(self) -> bool:
        return self.thread_ts is not None and not self.is_thread_parent

    @property
    def is_thread_broadcast(self) -> bool:
        return self._message_json.get("subtype") == "thread_broadcast"

    @property
    def parent_message(self) -> Optional[SlackMessage]:
        if not self.is_reply or self.thread_ts is None:
            return None
        return self.conversation.messages.get(self.thread_ts)

    @property
    def subscribed(self) -> bool:
        return self._message_json.get("subscribed", False)

    @property
    def last_read(self) -> Optional[SlackTs]:
        return (
            SlackTs(self._message_json["last_read"])
            if "last_read" in self._message_json
            else None
        )

    @last_read.setter
    def last_read(self, value: SlackTs):
        self._message_json["last_read"] = value  # pyright: ignore [reportGeneralTypeIssues]
        if self.thread_buffer:
            self.thread_buffer.set_unread_and_hotlist()

    @property
    def latest_reply(self) -> Optional[SlackTs]:
        if "latest_reply" in self._message_json:
            return SlackTs(self._message_json["latest_reply"])

    @property
    def replies(self) -> Mapping[SlackTs, SlackMessage]:
        return self._replies

    @property
    def is_bot_message(self) -> bool:
        return (
            "subtype" in self._message_json
            and self._message_json["subtype"] == "bot_message"
        )

    @property
    def sender_user_id(self) -> Optional[str]:
        return self._message_json.get("user")

    @property
    def sender_bot_id(self) -> Optional[str]:
        return self._message_json.get("bot_id")

    @property
    def is_self_msg(self) -> bool:
        return self.sender_user_id == self.workspace.my_user.id

    @property
    def reactions(self) -> List[SlackMessageReaction]:
        return self._message_json.get("reactions", [])

    @property
    def muted(self) -> bool:
        parent_subscribed = (
            self.parent_message.subscribed if self.parent_message else False
        )
        return self.conversation.muted and not self.subscribed and not parent_subscribed

    @property
    def text(self) -> str:
        return self._message_json["text"]

    @property
    def deleted(self) -> bool:
        return self._deleted or self._message_json.get("subtype") == "tombstone"

    @deleted.setter
    def deleted(self, value: bool):
        self._deleted = value
        self._rendered_message = None
        self._parsed_message = None

    def update_message_json(self, message_json: SlackMessageDict):
        self._message_json.update(message_json)  # pyright: ignore [reportArgumentType, reportCallIssue]
        self._rendered_prefix = None
        self._rendered_message = None
        self._parsed_message = None

    def update_message_json_room(self, room: SlackMessageSubtypeHuddleThreadRoom):
        if "room" in self._message_json:
            self._message_json["room"] = room
        self._rendered_message = None
        self._parsed_message = None

    async def update_subscribed(
        self, subscribed: bool, subscription: SlackThreadSubscription
    ):
        self._message_json["subscribed"] = subscribed  # pyright: ignore [reportGeneralTypeIssues]
        self.last_read = SlackTs(subscription["last_read"])
        await self.conversation.rerender_message(self)

    def _get_reaction(self, reaction_name: str):
        for reaction in self._message_json.get("reactions", []):
            if reaction["name"] == reaction_name:
                return reaction

    def reaction_add(self, reaction_name: str, user_id: str):
        reaction = self._get_reaction(reaction_name)
        if reaction:
            if user_id not in reaction["users"]:
                reaction["users"].append(user_id)
                reaction["count"] += 1
        else:
            if "reactions" not in self._message_json:
                self._message_json["reactions"] = []
            self._message_json["reactions"].append(
                {"name": reaction_name, "users": [user_id], "count": 1}
            )
        self._rendered_message = None

    def reaction_remove(self, reaction_name: str, user_id: str):
        reaction = self._get_reaction(reaction_name)
        if reaction and user_id in reaction["users"]:
            reaction["users"].remove(user_id)
            reaction["count"] -= 1
            self._rendered_message = None

    def has_reacted(self, reaction_name: str) -> bool:
        reaction = self._get_reaction(reaction_name)
        return reaction is not None and self.workspace.my_user.id in reaction["users"]

    def should_highlight(self, only_personal: bool) -> bool:
        parsed_message = self.parse_message_text()

        for item in parsed_message:
            if isinstance(item, PendingMessageItem):
                if item.should_highlight(only_personal):
                    return True
            else:
                if (
                    self.workspace.global_keywords_regex is not None
                    and self.workspace.global_keywords_regex.search(item)
                ):
                    return True

        return False

    def priority(self, context: MessageContext) -> MessagePriority:
        if (
            context != "thread"
            and self.muted
            and shared.config.look.muted_conversations_notify.value == "none"
        ):
            return MessagePriority.NONE
        elif self.should_highlight(
            self.muted
            and shared.config.look.muted_conversations_notify.value
            == "personal_highlights"
        ):
            return MessagePriority.HIGHLIGHT
        elif (
            context != "thread"
            and self.muted
            and shared.config.look.muted_conversations_notify.value != "all"
        ):
            return MessagePriority.NONE
        elif self.subtype in [
            "channel_join",
            "group_join",
            "channel_leave",
            "group_leave",
        ]:
            return MessagePriority.LOW
        elif self.conversation.buffer_type == "private":
            return MessagePriority.PRIVATE
        else:
            return MessagePriority.MESSAGE

    def priority_notify_tag(self, context: MessageContext) -> Optional[str]:
        priority = self.priority(context)
        if priority == MessagePriority.HIGHLIGHT:
            return "notify_highlight"
        elif priority == MessagePriority.PRIVATE:
            return "notify_private"
        elif priority == MessagePriority.MESSAGE:
            return "notify_message"
        elif priority == MessagePriority.LOW:
            return None
        elif priority == MessagePriority.NONE:
            tags = ["notify_none"]
            if self.should_highlight(False):
                tags.append(shared.highlight_tag)
            return ",".join(tags)
        else:
            assert_never(priority)

    async def tags(self, context: MessageContext, backlog: bool) -> str:
        nick = await self.nick()
        tags = [f"{ts_tag_prefix}{self.ts}", f"nick_{nick.raw_nick}"]

        if self.sender_user_id:
            tags.append(f"slack_user_id_{self.sender_user_id}")
        if self.sender_bot_id:
            tags.append(f"slack_bot_id_{self.sender_bot_id}")

        if self._message_json.get("subtype") in ["channel_join", "group_join"]:
            tags.append("slack_join")
            log_tags = ["log4"]
        elif self._message_json.get("subtype") in ["channel_leave", "group_leave"]:
            tags.append("slack_part")
            log_tags = ["log4"]
        else:
            tags.append("slack_privmsg")
            if self.is_bot_message:
                tags.append("bot_message")

            if self._message_json.get("subtype") == "me_message":
                tags.append("slack_action")
            else:
                if shared.weechat_version >= 0x04000000:
                    tags.append(f"prefix_nick_{nick.color}")

            if self.is_self_msg:
                tags.append("self_msg")
                log_tags = ["notify_none", "no_highlight", "log1"]
            else:
                log_tags = ["log1"]
                notify_tag = self.priority_notify_tag(context)
                if notify_tag:
                    log_tags.append(notify_tag)

        if backlog:
            tags += ["no_highlight", "notify_none", "logger_backlog", "no_log"]
        else:
            tags += log_tags

        return ",".join(tags)

    async def render(
        self,
        context: MessageContext,
    ) -> str:
        prefix_coro = self.render_prefix()
        message_coro = self.render_message(context)
        prefix, message = await gather(prefix_coro, message_coro)
        self._rendered = f"{prefix}\t{message}"
        return self._rendered

    async def nick(self) -> Nick:
        if "user_profile" in self._message_json:
            # TODO: is_external
            nick = name_from_user_profile(
                self.workspace,
                self._message_json["user_profile"],
                fallback_name=self._message_json["user_profile"]["name"],
            )
            return get_user_nick(nick, is_self=self.is_self_msg)
        if "user" in self._message_json:
            try:
                user = await self.workspace.users[self._message_json["user"]]
                return user.nick
            except (SlackApiError, SlackError) as e:
                if not is_not_found_error(e):
                    raise e
        username = self._message_json.get("username")
        if username:
            return get_bot_nick(username)
        if "bot_profile" in self._message_json:
            return get_bot_nick(self._message_json["bot_profile"]["name"])
        if "bot_id" in self._message_json:
            try:
                bot = await self.workspace.bots[self._message_json["bot_id"]]
                return bot.nick
            except (SlackApiError, SlackError) as e:
                if not is_not_found_error(e):
                    raise e
        return Nick("", "Unknown", "", "unknown")

    async def _render_prefix(self) -> str:
        if self._message_json.get("subtype") in ["channel_join", "group_join"]:
            return removesuffix(weechat.prefix("join"), "\t")
        elif self._message_json.get("subtype") in ["channel_leave", "group_leave"]:
            return removesuffix(weechat.prefix("quit"), "\t")
        elif self._message_json.get("subtype") == "me_message":
            return removesuffix(weechat.prefix("action"), "\t")
        else:
            nick = await self.nick()
            return nick.format(colorize=True)

    async def render_prefix(self) -> str:
        if self._rendered_prefix is not None:
            return self._rendered_prefix
        self._rendered_prefix = await self._render_prefix()
        return self._rendered_prefix

    def parse_message_text(
        self, update: bool = False
    ) -> List[Union[str, PendingMessageItem]]:
        if self._parsed_message is not None and not update:
            return self._parsed_message

        if self.deleted:
            self._parsed_message = [
                with_color(shared.config.color.deleted_message.value, "(deleted)")
            ]

        elif self._message_json.get("subtype") in [
            "channel_join",
            "group_join",
            "channel_leave",
            "group_leave",
        ]:
            is_join = self._message_json.get("subtype") in [
                "channel_join",
                "group_join",
            ]
            text_action = (
                f"{with_color(shared.config.color.message_join.value, 'has joined')}"
                if is_join
                else f"{with_color(shared.config.color.message_quit.value, 'has left')}"
            )
            conversation_item = PendingMessageItem(
                self, "conversation", self.conversation.id, "chat"
            )

            inviter_id = self._message_json.get("inviter")
            if is_join and inviter_id:
                inviter_items = [
                    " by invitation from ",
                    PendingMessageItem(self, "user", inviter_id, "chat"),
                ]
            else:
                inviter_items = []

            self._parsed_message = [
                PendingMessageItem(self, "message_nick", ""),
                " ",
                text_action,
                " ",
                conversation_item,
            ] + inviter_items

        elif (
            "subtype" in self._message_json
            and self._message_json["subtype"] == "huddle_thread"
        ):
            room = self._message_json["room"]
            team = self._message_json.get("team", self.workspace.id)

            huddle_text = "Huddle started" if not room["has_ended"] else "Huddle ended"
            name_text = f", name: {room['name']}" if room["name"] else ""
            texts: List[Union[str, PendingMessageItem]] = [huddle_text + name_text]

            for channel_id in room["channels"]:
                texts.append(
                    f"\nhttps://app.slack.com/client/{team}/{channel_id}?open=start_huddle"
                )
            self._parsed_message = texts

        else:
            if "blocks" in self._message_json:
                texts = self._render_blocks(self._message_json["blocks"])
            else:
                items = self._unfurl_refs(self._message_json["text"])
                texts = [
                    unhtmlescape(item) if isinstance(item, str) else item
                    for item in items
                ]

            files = self._render_files(self._message_json.get("files", []), bool(texts))
            attachment_items = self._render_attachments(texts)
            self._parsed_message = texts + files + attachment_items

        return self._parsed_message

    async def _render_message(self, rerender: bool = False) -> str:
        if self._rendered_message is not None and not rerender:
            return self._rendered_message

        try:
            me_prefix = (
                f"{(await self.nick()).format(colorize=True)} "
                if self._message_json.get("subtype") == "me_message"
                else ""
            )

            parsed_message = self.parse_message_text(rerender)
            text = "".join(
                [
                    text if isinstance(text, str) else await text.resolve()
                    for text in parsed_message
                ]
            )
            text_edited = (
                f" {with_color(shared.config.color.edited_message_suffix.value, '(edited)')}"
                if self._message_json.get("edited")
                else ""
            )
            reactions = await self._create_reactions_string()
            self._rendered_message = me_prefix + text + text_edited + reactions
        except Exception as e:
            uncaught_error = UncaughtError(e)
            print_error(store_and_format_uncaught_error(uncaught_error))
            text = f"<Error rendering message {self.ts}, error id: {uncaught_error.id}>"
            self._rendered_message = with_color(
                shared.config.color.render_error.value, text
            )

        return self._rendered_message

    async def render_message(
        self,
        context: MessageContext,
        rerender: bool = False,
    ) -> str:
        text = await self._render_message(rerender=rerender)
        thread_prefix = self._create_thread_prefix(context)
        thread_info = self._create_thread_string() if context == "conversation" else ""
        return thread_prefix + text + thread_info

    def _resolve_ref(
        self, item_id: str, fallback_name: Optional[str]
    ) -> Union[str, PendingMessageItem]:
        if item_id.startswith("#"):
            return PendingMessageItem(
                self,
                "conversation",
                removeprefix(item_id, "#"),
                "mention",
                fallback_name,
            )
        elif item_id.startswith("@"):
            return PendingMessageItem(
                self, "user", removeprefix(item_id, "@"), "mention", fallback_name
            )
        elif item_id.startswith("!subteam^"):
            return PendingMessageItem(
                self,
                "usergroup",
                removeprefix(item_id, "!subteam^"),
                "mention",
                fallback_name,
            )
        elif item_id in ["!channel", "!everyone", "!group", "!here"]:
            return PendingMessageItem(
                self, "broadcast", removeprefix(item_id, "!"), "mention", fallback_name
            )
        elif item_id.startswith("!date"):
            parts = item_id.split("^")
            timestamp = int(parts[1])
            link = parts[3] if len(parts) > 3 else None
            return format_date(timestamp, parts[2], link)
        else:
            return format_url(item_id, fallback_name)

    def _unfurl_refs(
        self, message: str
    ) -> Generator[Union[str, PendingMessageItem], None, None]:
        re_ref = re.compile(r"<(?P<id>[^|>]+)(?:\|(?P<fallback_name>[^>]*))?>")

        i = 0
        for match in re_ref.finditer(message):
            if i < match.start(0):
                yield message[i : match.start(0)]
            yield self._resolve_ref(match["id"], match["fallback_name"])
            i = match.end(0)

        if i < len(message):
            yield message[i:]

    def _unfurl_and_unescape(
        self, items: Iterable[Union[str, PendingMessageItem]]
    ) -> Generator[Union[str, PendingMessageItem], None, None]:
        for item in items:
            if isinstance(item, str):
                for sub_item in self._unfurl_refs(item):
                    if isinstance(sub_item, str):
                        yield unhtmlescape(sub_item)
                    else:
                        yield sub_item
            else:
                yield item

    async def _create_reaction_string(self, reaction: SlackMessageReaction) -> str:
        if self.conversation.display_reaction_nicks():
            users = await gather(
                *(self.workspace.users[user_id] for user_id in reaction["users"])
            )
            nicks = [user.nick.format() for user in users]
            nicks_extra = (
                ["and others"] if len(reaction["users"]) < reaction["count"] else []
            )
            users_str = f"({', '.join(nicks + nicks_extra)})"
        else:
            users_str = ""

        reaction_string = f"{get_emoji(reaction['name'])}{reaction['count']}{users_str}"

        if self.workspace.my_user.id in reaction["users"]:
            return with_color(
                shared.config.color.reaction_self_suffix.value,
                reaction_string,
                reset_color=shared.config.color.reaction_suffix.value,
            )
        else:
            return reaction_string

    async def _create_reactions_string(self) -> str:
        reactions = self._message_json.get("reactions", [])
        reactions_with_users = [
            reaction for reaction in reactions if reaction["count"] > 0
        ]
        reaction_strings = await gather(
            *(
                self._create_reaction_string(reaction)
                for reaction in reactions_with_users
            )
        )
        reactions_string = " ".join(reaction_strings)
        if reactions_string:
            return " " + with_color(
                shared.config.color.reaction_suffix.value, f"[{reactions_string}]"
            )
        else:
            return ""

    def _create_thread_prefix(self, context: MessageContext) -> str:
        if not self.is_reply or self.thread_ts is None:
            return ""
        thread_hash = self.conversation.message_hashes[self.thread_ts]

        broadcast_text = (
            shared.config.look.thread_broadcast_prefix.value
            if self.is_thread_broadcast
            else None
        )
        thread_text = thread_hash if context == "conversation" else None
        text = " ".join(x for x in [broadcast_text, thread_text] if x)
        if not text:
            return ""
        return with_color(nick_color(thread_hash), f"[{text}]") + " "

    def _create_thread_string(self) -> str:
        if "reply_count" not in self._message_json:
            return ""

        reply_count = self._message_json["reply_count"]
        if not reply_count:
            return ""

        subscribed_text = " Subscribed" if self.subscribed else ""
        text = f"[ Thread: {self.hash} Replies: {reply_count}{subscribed_text} ]"
        return " " + with_color(nick_color(str(self.hash)), text)

    def _render_blocks(
        self, blocks: List[SlackMessageBlock]
    ) -> List[Union[str, PendingMessageItem]]:
        block_lines: List[List[Union[str, PendingMessageItem]]] = []

        for block in blocks:
            try:
                if block["type"] == "section":
                    fields = block.get("fields", [])
                    if "text" in block:
                        fields.insert(0, block["text"])
                    block_lines.extend(
                        self._render_block_element(field) for field in fields
                    )
                elif block["type"] == "actions":
                    items: List[Union[str, PendingMessageItem]] = []
                    for element in block["elements"]:
                        if element["type"] == "button":
                            items.extend(self._render_block_element(element["text"]))
                            if "url" in element:
                                items.append(format_url(element["url"]))
                        else:
                            text = (
                                f'<Unsupported block action type "{element["type"]}">'
                            )
                            items.append(
                                with_color(shared.config.color.render_error.value, text)
                            )
                    block_lines.append(intersperse(items, " | "))
                elif block["type"] == "call":
                    url = block["call"]["v1"]["join_url"]
                    block_lines.append(["Join via " + format_url(url)])
                elif block["type"] == "divider":
                    block_lines.append(["---"])
                elif block["type"] == "context":
                    items = [
                        item
                        for element in block["elements"]
                        for item in self._render_block_element(element)
                    ]
                    block_lines.append(intersperse(items, " | "))
                elif block["type"] == "image":
                    if "title" in block:
                        block_lines.append(self._render_block_element(block["title"]))
                    block_lines.append(self._render_block_element(block))
                elif block["type"] == "rich_text":
                    for element in block.get("elements", []):
                        if element["type"] == "rich_text_section":
                            rendered = self._render_block_rich_text_section(element)
                            if rendered:
                                block_lines.append(rendered)
                        elif element["type"] == "rich_text_list":
                            lines = [
                                [
                                    "    " * element.get("indent", 0),
                                    self._render_block_rich_text_list_prefix(
                                        element, item_index
                                    ),
                                    " ",
                                ]
                                + self._render_block_rich_text_section(item_element)
                                for item_index, item_element in enumerate(
                                    element["elements"]
                                )
                            ]
                            block_lines.extend(lines)
                        elif element["type"] == "rich_text_quote":
                            quote_str = "> "
                            items = [quote_str] + [
                                self._render_block_rich_text_element(
                                    sub_element, quote_str
                                )
                                for sub_element in element["elements"]
                            ]
                            block_lines.append(items)
                        elif element["type"] == "rich_text_preformatted":
                            texts: List[str] = [
                                sub_element["text"]
                                if "text" in sub_element
                                else sub_element["url"]
                                for sub_element in element["elements"]
                            ]
                            if texts:
                                block_lines.append([f"```\n{''.join(texts)}\n```"])
                        else:
                            text = f'<Unsupported rich text type "{element["type"]}">'
                            block_lines.append(
                                [
                                    with_color(
                                        shared.config.color.render_error.value, text
                                    )
                                ]
                            )
                else:
                    text = f'<Unsupported block type "{block["type"]}">'
                    block_lines.append(
                        [with_color(shared.config.color.render_error.value, text)]
                    )
            except Exception as e:
                uncaught_error = UncaughtError(e)
                print_error(store_and_format_uncaught_error(uncaught_error))
                text = f"<Error rendering message {self.ts}, error id: {uncaught_error.id}>"
                block_lines.append(
                    [with_color(shared.config.color.render_error.value, text)]
                )

        return [item for items in intersperse(block_lines, ["\n"]) for item in items]

    def _render_block_rich_text_section(
        self, section: SlackMessageBlockRichTextSection, lines_prepend: str = ""
    ) -> List[Union[str, PendingMessageItem]]:
        texts: List[Union[str, PendingMessageItem]] = []
        prev_element: SlackMessageBlockRichTextElement = {"type": "text", "text": ""}
        for element in section["elements"] + [prev_element.copy()]:
            colors_apply: List[str] = []
            colors_remove: List[str] = []
            characters_apply: List[str] = []
            characters_remove: List[str] = []
            prev_style = prev_element.get("style", {})
            cur_style = element.get("style", {})
            if cur_style.get("code", False) != prev_style.get("code", False):
                if cur_style.get("code"):
                    characters_apply.append("`")
                else:
                    characters_remove.append("`")
            if cur_style.get("bold", False) != prev_style.get("bold", False):
                if cur_style.get("bold"):
                    colors_apply.append(weechat.color("bold"))
                    characters_apply.append("*")
                else:
                    colors_remove.append(weechat.color("-bold"))
                    characters_remove.append("*")
            if cur_style.get("italic", False) != prev_style.get("italic", False):
                if cur_style.get("italic"):
                    colors_apply.append(weechat.color("italic"))
                    characters_apply.append("_")
                else:
                    colors_remove.append(weechat.color("-italic"))
                    characters_remove.append("_")
            if cur_style.get("strike", False) != prev_style.get("strike", False):
                if cur_style.get("strike"):
                    characters_apply.append("~")
                else:
                    characters_remove.append("~")

            prepend = "".join(
                characters_remove[::-1]
                + colors_remove[::-1]
                + colors_apply
                + characters_apply
            )
            if prepend:
                texts.append(prepend)
            text = self._render_block_rich_text_element(element, lines_prepend)
            if text:
                texts.append(text)
            prev_element = element

        if texts and isinstance(texts[-1], str) and texts[-1].endswith("\n"):
            texts[-1] = texts[-1][:-1]

        return texts

    def _render_block_rich_text_element(
        self, element: SlackMessageBlockRichTextElement, lines_prepend: str = ""
    ) -> Union[str, PendingMessageItem]:
        if element["type"] == "text":
            return element["text"].replace("\n", "\n" + lines_prepend)
        elif element["type"] == "link":
            if element.get("style", {}).get("code"):
                if "text" in element:
                    return element["text"]
                else:
                    return element["url"]
            else:
                return format_url(element["url"], element.get("text"))
        elif element["type"] == "emoji":
            return get_emoji(element["name"], element.get("skin_tone"))
        elif element["type"] == "color":
            rgb_int = int(element["value"].lstrip("#"), 16)
            weechat_color = weechat.info_get("color_rgb2term", str(rgb_int))
            return f"{element['value']} {with_color(weechat_color, '■')}"
        elif element["type"] == "date":
            return format_date(element["timestamp"], element["format"])
        elif element["type"] == "channel":
            return PendingMessageItem(self, "conversation", element["channel_id"])
        elif element["type"] == "user":
            return PendingMessageItem(self, "user", element["user_id"])
        elif element["type"] == "usergroup":
            return PendingMessageItem(self, "usergroup", element["usergroup_id"])
        elif element["type"] == "broadcast":
            return PendingMessageItem(self, "broadcast", element["range"])
        else:
            text = f'<Unsupported rich text element type "{element["type"]}">'
            return with_color(shared.config.color.render_error.value, text)

    def _render_block_element(
        self,
        element: Union[SlackMessageBlockCompositionText, SlackMessageBlockElementImage],
    ) -> List[Union[str, PendingMessageItem]]:
        if element["type"] == "plain_text" or element["type"] == "mrkdwn":
            # TODO: Support markdown, and verbatim and emoji properties
            # Looks like emoji and verbatim are only used when posting, so we don't need to care about them.
            # We do have to resolve refs (users, dates etc.) and emojis for both plain_text and mrkdwn though.
            # See a message for a poll from polly
            # Should I run unhtmlescape here?
            items = self._unfurl_refs(element["text"])
            return [
                unhtmlescape(item) if isinstance(item, str) else item for item in items
            ]
        elif element["type"] == "image":
            return [format_url(element["image_url"], element.get("alt_text"))]
        else:
            text = f'<Unsupported block element type "{element["type"]}">'
            return [with_color(shared.config.color.render_error.value, text)]

    def _render_block_rich_text_list_prefix(
        self, list_element: SlackMessageBlockRichTextList, item_index: int
    ) -> str:
        index = list_element.get("offset", 0) + item_index + 1
        if list_element["style"] == "ordered":
            if list_element["indent"] == 0 or list_element["indent"] == 3:
                return f"{index}."
            elif list_element["indent"] == 1 or list_element["indent"] == 4:
                return f"{convert_int_to_letter(index)}."
            else:
                return f"{convert_int_to_roman(index)}."
        else:
            if list_element["indent"] == 0 or list_element["indent"] == 3:
                return "•"
            elif list_element["indent"] == 1 or list_element["indent"] == 4:
                return "◦"
            else:
                return "▪︎"

    def _render_files(
        self, files: List[SlackFile], has_items_before: bool
    ) -> List[Union[str, PendingMessageItem]]:
        items = [
            PendingMessageItem(self, "file", file["id"], file=file) for file in files
        ]
        before = ["\n"] if has_items_before and items else []
        return before + intersperse(items, "\n")

    # TODO: Check if mentions in attachments should highlight
    def _render_attachments(
        self, items_before: List[Union[str, PendingMessageItem]]
    ) -> List[Union[str, PendingMessageItem]]:
        if "attachments" not in self._message_json:
            return []

        attachments: List[List[Union[str, PendingMessageItem]]] = []
        if any(items_before):
            attachments.append([])

        for attachment in self._message_json["attachments"]:
            # Attachments should be rendered roughly like:
            #
            # $pretext
            # $author: (if rest of line is non-empty) $title ($title_link) OR $from_url
            # $author: (if no $author on previous line) $text
            # $fields

            if (
                shared.config.look.display_link_previews.value != "always"
                and ("original_url" in attachment or attachment.get("is_app_unfurl"))
                and not attachment.get("is_msg_unfurl")
            ):
                continue

            if (
                shared.config.look.display_link_previews.value == "never"
                and attachment.get("is_msg_unfurl")
            ):
                continue

            lines: List[List[Union[str, PendingMessageItem]]] = []
            prepend_title_text = ""
            if "author_name" in attachment:
                prepend_title_text = attachment["author_name"] + ": "
            if "pretext" in attachment:
                lines.append([attachment["pretext"]])
            link_shown = False
            title = attachment.get("title")
            title_link = attachment.get("title_link", "")
            if title_link and any(
                isinstance(text, str) and title_link in text for text in items_before
            ):
                title_link = ""
                link_shown = True
            if title and title_link:
                lines.append(
                    [f"{prepend_title_text}{format_url(htmlescape(title_link), title)}"]
                )
                prepend_title_text = ""
            elif title and not title_link:
                lines.append([f"{prepend_title_text}{title}"])
                prepend_title_text = ""
            from_url = unhtmlescape(attachment.get("from_url", ""))
            if (
                not any(
                    isinstance(text, str) and from_url in text for text in items_before
                )
                and from_url != title_link
            ):
                lines.append([format_url(htmlescape(from_url))])
            elif from_url:
                link_shown = True

            atext = attachment.get("text")
            if atext:
                tx = re.sub(r" *\n[\n ]+", "\n", atext)
                lines.append([prepend_title_text + tx])
                prepend_title_text = ""

            image_url = attachment.get("image_url", "")
            if (
                not any(
                    isinstance(text, str) and image_url in text for text in items_before
                )
                and image_url != from_url
                and image_url != title_link
            ):
                lines.append([format_url(htmlescape(image_url))])
            elif image_url:
                link_shown = True

            for field in attachment.get("fields", []):
                if field.get("title"):
                    lines.append([f"{field['title']}: {field['value']}"])
                else:
                    lines.append([field["value"]])

            lines = [
                [item for item in self._unfurl_and_unescape(line)] for line in lines
            ]

            files = self._render_files(attachment.get("files", []), False)
            if files:
                lines.append(files)

            # TODO: Don't render both text and blocks
            blocks_items = self._render_blocks(attachment.get("blocks", []))
            if blocks_items:
                lines.append(blocks_items)

            if "is_msg_unfurl" in attachment and attachment["is_msg_unfurl"]:
                channel_name = PendingMessageItem(
                    self, "conversation", attachment["channel_id"], "chat"
                )
                if attachment.get("is_reply_unfurl"):
                    footer = ["From a thread in ", channel_name]
                else:
                    footer = ["Posted in ", channel_name]
            elif attachment.get("footer"):
                footer: List[Union[str, PendingMessageItem]] = [
                    attachment.get("footer")
                ]
            else:
                footer = []

            if footer:
                ts = attachment.get("ts")
                if ts:
                    ts_int = ts if isinstance(ts, int) else SlackTs(ts).major
                    if ts_int > 100000000000:
                        # The Slack web interface interprets very large timestamps
                        # as milliseconds after the epoch instead of regular Unix
                        # timestamps. We use the same heuristic here.
                        ts_int = ts_int // 1000
                    time_string = ""
                    if date.today() - date.fromtimestamp(ts_int) <= timedelta(days=1):
                        time_string = " at {time}"
                    timestamp_formatted = format_date(
                        ts_int, "{date_short_pretty}" + time_string
                    )
                    footer.append(f" | {timestamp_formatted.capitalize()}")

                lines.append([item for item in self._unfurl_and_unescape(footer)])

            fallback = attachment.get("fallback")
            if not any(lines) and fallback and not link_shown:
                lines.append([fallback])

            items = [item for items in intersperse(lines, ["\n"]) for item in items]

            texts_separate_newlines = [
                item_separate_newline
                for item in items
                for item_separate_newline in (
                    intersperse(item.split("\n"), "\n")
                    if isinstance(item, str)
                    else [item]
                )
            ]

            if texts_separate_newlines:
                prefix = "|"
                line_color = None
                color = attachment.get("color")
                if (
                    color
                    and shared.config.look.color_message_attachments.value != "none"
                ):
                    weechat_color = weechat.info_get(
                        "color_rgb2term", str(int(color.lstrip("#"), 16))
                    )
                    if shared.config.look.color_message_attachments.value == "prefix":
                        prefix = with_color(weechat_color, prefix)
                    elif shared.config.look.color_message_attachments.value == "all":
                        line_color = weechat_color

                texts_with_prefix = [f"{prefix} "] + [
                    f"\n{prefix} " if item == "\n" else item
                    for item in texts_separate_newlines
                ]

                attachment_texts: List[Union[str, PendingMessageItem]] = []
                if line_color:
                    attachment_texts.append(weechat.color(line_color))
                attachment_texts.extend(texts_with_prefix)
                if line_color:
                    attachment_texts.append(weechat.color("reset"))
                attachments.append(attachment_texts)

        return [item for items in intersperse(attachments, ["\n"]) for item in items]


class SlackMessageReplies(Mapping[SlackTs, SlackMessage]):
    def __init__(self, parent: SlackMessage):
        super().__init__()
        self._parent = parent

    def __getitem__(self, key: SlackTs) -> SlackMessage:
        if key == self._parent.ts:
            return self._parent
        return self._parent.conversation.messages[key]

    def __iter__(self) -> Generator[SlackTs, None, None]:
        yield self._parent.ts
        for ts in self._parent.replies_tss:
            yield ts

    def __len__(self) -> int:
        return 1 + len(self._parent.replies_tss)


if TYPE_CHECKING:
    pass

    pass
    pass
    pass


def hdata_line_ts(line_pointer: str) -> Optional[SlackTs]:
    data = weechat.hdata_pointer(weechat.hdata_get("line"), line_pointer, "data")
    for i in range(
        weechat.hdata_integer(weechat.hdata_get("line_data"), data, "tags_count")
    ):
        tag = weechat.hdata_string(
            weechat.hdata_get("line_data"), data, f"{i}|tags_array"
        )
        ts = ts_from_tag(tag)
        if ts is not None:
            return ts
    return None


def tags_set_notify_none(tags: List[str]) -> List[str]:
    notify_tags = {"notify_highlight", "notify_message", "notify_private"}
    tags = [tag for tag in tags if tag not in notify_tags]
    tags += ["no_highlight", "notify_none"]
    return tags


def modify_buffer_line(buffer_pointer: str, ts: SlackTs, new_text: str):
    if not buffer_pointer:
        return False

    own_lines = weechat.hdata_pointer(
        weechat.hdata_get("buffer"), buffer_pointer, "own_lines"
    )
    line_pointer = weechat.hdata_pointer(
        weechat.hdata_get("lines"), own_lines, "last_line"
    )

    # Find the last line with this ts
    is_last_line = True
    while line_pointer and hdata_line_ts(line_pointer) != ts:
        is_last_line = False
        line_pointer = weechat.hdata_move(weechat.hdata_get("line"), line_pointer, -1)

    if not line_pointer:
        return False

    if shared.weechat_version >= 0x04000000:
        data = weechat.hdata_pointer(weechat.hdata_get("line"), line_pointer, "data")
        weechat.hdata_update(
            weechat.hdata_get("line_data"), data, {"message": new_text}
        )
        return True

    # Find all lines for the message
    pointers: List[str] = []
    while line_pointer and hdata_line_ts(line_pointer) == ts:
        pointers.append(line_pointer)
        line_pointer = weechat.hdata_move(weechat.hdata_get("line"), line_pointer, -1)
    pointers.reverse()

    if not pointers:
        return False

    if is_last_line:
        lines = new_text.split("\n")
        extra_lines_count = len(lines) - len(pointers)
        if extra_lines_count > 0:
            line_data = weechat.hdata_pointer(
                weechat.hdata_get("line"), pointers[0], "data"
            )
            tags_count = weechat.hdata_integer(
                weechat.hdata_get("line_data"), line_data, "tags_count"
            )
            tags = [
                weechat.hdata_string(
                    weechat.hdata_get("line_data"), line_data, f"{i}|tags_array"
                )
                for i in range(tags_count)
            ]
            tags = tags_set_notify_none(tags)
            tags_str = ",".join(tags)
            last_read_line = weechat.hdata_pointer(
                weechat.hdata_get("lines"), own_lines, "last_read_line"
            )
            should_set_unread = last_read_line == pointers[-1]

            # Insert new lines to match the number of lines in the message
            weechat.buffer_set(buffer_pointer, "print_hooks_enabled", "0")
            for _ in range(extra_lines_count):
                weechat.prnt_date_tags(buffer_pointer, ts.major, tags_str, " \t ")
                pointers.append(
                    weechat.hdata_pointer(
                        weechat.hdata_get("lines"), own_lines, "last_line"
                    )
                )
            if should_set_unread:
                weechat.buffer_set(buffer_pointer, "unread", "")
            weechat.buffer_set(buffer_pointer, "print_hooks_enabled", "1")
    else:
        # Split the message into at most the number of existing lines as we can't insert new lines
        lines = new_text.split("\n", len(pointers) - 1)
        # Replace newlines to prevent garbled lines in bare display mode
        lines = [line.replace("\n", " | ") for line in lines]

    # Extend lines in case the new message is shorter than the old as we can't delete lines
    lines += [""] * (len(pointers) - len(lines))

    for pointer, line in zip(pointers, lines):
        data = weechat.hdata_pointer(weechat.hdata_get("line"), pointer, "data")
        weechat.hdata_update(weechat.hdata_get("line_data"), data, {"message": line})
    return True


class SlackMessageBuffer(ABC):
    def __init__(self):
        self._typing_self_last_sent = 0
        self._should_update_server_on_buffer_close = None
        self.buffer_pointer: Optional[str] = None
        self.is_loading = False
        self.history_pending_messages: List[SlackMessage] = []
        self.history_needs_refresh = False
        self.last_printed_ts: Optional[SlackTs] = None
        self.hotlist_tss: Set[SlackTs] = set()

        self.completion_context: Literal[
            "NO_COMPLETION",
            "PENDING_COMPLETION",
            "ACTIVE_COMPLETION",
            "IN_PROGRESS_COMPLETION",
        ] = "NO_COMPLETION"
        self.completion_values: List[str] = []
        self.completion_index = 0

    @property
    def api(self) -> SlackApi:
        return self.workspace.api

    @contextmanager
    def loading(self):
        self.is_loading = True
        weechat.bar_item_update("input_text")
        try:
            yield
        finally:
            self.is_loading = False
            weechat.bar_item_update("input_text")

    @contextmanager
    def completing(self):
        self.completion_context = "IN_PROGRESS_COMPLETION"
        try:
            yield
        finally:
            self.completion_context = "ACTIVE_COMPLETION"

    @property
    @abstractmethod
    def workspace(self) -> SlackWorkspace:
        raise NotImplementedError()

    @property
    @abstractmethod
    def conversation(self) -> SlackConversation:
        raise NotImplementedError()

    @property
    @abstractmethod
    def context(self) -> MessageContext:
        raise NotImplementedError()

    @property
    @abstractmethod
    def members(self) -> Generator[Nick, None, None]:
        raise NotImplementedError()

    @property
    @abstractmethod
    def messages(self) -> Mapping[SlackTs, SlackMessage]:
        raise NotImplementedError()

    @property
    @abstractmethod
    def last_read(self) -> Optional[SlackTs]:
        raise NotImplementedError()

    @abstractmethod
    def get_name_and_buffer_props(self) -> Tuple[str, Dict[str, str]]:
        raise NotImplementedError()

    async def buffer_switched_to(self) -> None:
        self.hotlist_tss.clear()

    def get_full_name(self, name: str) -> str:
        return f"{shared.SCRIPT_NAME}.{self.workspace.name}.{name}"

    async def open_buffer(self, switch: bool = False):
        if self.buffer_pointer:
            if switch:
                weechat.buffer_set(self.buffer_pointer, "display", "1")
            return

        name, buffer_props = self.get_name_and_buffer_props()
        full_name = self.get_full_name(name)

        buffer_props["highlight_tags"] = (
            f"{buffer_props['highlight_tags']},{shared.highlight_tag}"
            if buffer_props.get("highlight_tags")
            else shared.highlight_tag
        )

        if switch:
            buffer_props["display"] = "1"

        self.buffer_pointer = buffer_new(
            full_name,
            buffer_props,
            self._buffer_input_cb,
            self._buffer_close_cb,
        )

        shared.buffers[self.buffer_pointer] = self
        if switch:
            await self.buffer_switched_to()

    async def close_buffer(self, update_server: bool = False):
        await self._buffer_close(call_buffer_close=True, update_server=update_server)

    def update_buffer_props(self) -> None:
        if self.buffer_pointer is None:
            return

        name, buffer_props = self.get_name_and_buffer_props()
        buffer_props["name"] = self.get_full_name(name)
        for key, value in buffer_props.items():
            weechat.buffer_set(self.buffer_pointer, key, value)

    @abstractmethod
    async def set_hotlist(self) -> None:
        raise NotImplementedError()

    async def rerender_message(self, message: SlackMessage):
        if self.buffer_pointer is None:
            return

        new_text = await message.render_message(context=self.context, rerender=True)
        modify_buffer_line(self.buffer_pointer, message.ts, new_text)

    async def rerender_history(self):
        if self.buffer_pointer is None:
            return

        if shared.weechat_version >= 0x04000000:
            own_lines = weechat.hdata_pointer(
                weechat.hdata_get("buffer"), self.buffer_pointer, "own_lines"
            )
            line_pointer = weechat.hdata_pointer(
                weechat.hdata_get("lines"), own_lines, "last_line"
            )

            while line_pointer:
                ts = hdata_line_ts(line_pointer)
                if ts:
                    message = self.messages[ts]
                    new_text = await message.render_message(
                        context=self.context, rerender=True
                    )
                    data = weechat.hdata_pointer(
                        weechat.hdata_get("line"), line_pointer, "data"
                    )
                    weechat.hdata_update(
                        weechat.hdata_get("line_data"), data, {"message": new_text}
                    )
                    line_pointer = weechat.hdata_move(
                        weechat.hdata_get("line"), line_pointer, -1
                    )
        else:
            for message in self.messages.values():
                await self.rerender_message(message)

    def set_typing_self(self):
        now = time.time()
        if now - 4 > self._typing_self_last_sent:
            self._typing_self_last_sent = now
            self.workspace.send_typing(self)

    async def print_message(self, message: SlackMessage):
        if not self.buffer_pointer:
            return False

        if self.last_printed_ts is not None and message.ts <= self.last_printed_ts:
            new_text = await message.render_message(context=self.context, rerender=True)
            did_update = modify_buffer_line(self.buffer_pointer, message.ts, new_text)
            if not did_update:
                print_error(
                    f"Didn't find message with ts {message.ts} when last_printed_ts is {self.last_printed_ts}, message: {message}"
                )
            return False

        rendered = await message.render(self.context)
        backlog = self.last_read is not None and message.ts <= self.last_read
        tags = await message.tags(self.context, backlog)
        if message.ts in self.hotlist_tss:
            tags += ",notify_none"
        weechat.prnt_date_tags(self.buffer_pointer, message.ts.major, tags, rendered)
        if backlog:
            weechat.buffer_set(self.buffer_pointer, "unread", "")
        else:
            self.hotlist_tss.add(message.ts)
        self.last_printed_ts = message.ts
        return True

    def last_read_line_ts(self) -> Optional[SlackTs]:
        if self.buffer_pointer:
            own_lines = weechat.hdata_pointer(
                weechat.hdata_get("buffer"), self.buffer_pointer, "own_lines"
            )
            first_line_not_read = weechat.hdata_integer(
                weechat.hdata_get("lines"), own_lines, "first_line_not_read"
            )
            if first_line_not_read:
                return
            line = weechat.hdata_pointer(
                weechat.hdata_get("lines"), own_lines, "last_read_line"
            )
            while line:
                ts = hdata_line_ts(line)
                if ts:
                    return ts
                line = weechat.hdata_move(weechat.hdata_get("line"), line, -1)

    @abstractmethod
    async def mark_read(self) -> None:
        raise NotImplementedError()

    def set_unread_and_hotlist(self):
        if self.buffer_pointer:
            # TODO: Move unread marker to correct position according to last_read for WeeChat >= 4.0.0
            weechat.buffer_set(self.buffer_pointer, "unread", "")
            weechat.buffer_set(self.buffer_pointer, "hotlist", "-1")
            self.hotlist_tss.clear()

    def ts_from_hash(self, ts_hash: str) -> Optional[SlackTs]:
        return self.conversation.message_hashes.get_ts(ts_hash)

    def ts_from_index(
        self, index: int, message_filter: Optional[Literal["sender_self"]] = None
    ) -> Optional[SlackTs]:
        if index < 0 or self.buffer_pointer is None:
            return

        lines = weechat.hdata_pointer(
            weechat.hdata_get("buffer"), self.buffer_pointer, "lines"
        )

        line = weechat.hdata_pointer(weechat.hdata_get("lines"), lines, "last_line")
        while line and index:
            if not message_filter:
                index -= 1
            elif message_filter == "sender_self":
                ts = hdata_line_ts(line)
                if ts is not None:
                    message = self.messages[ts]
                    if (
                        message.sender_user_id == self.workspace.my_user.id
                        and message.subtype in [None, "me_message", "thread_broadcast"]
                    ):
                        index -= 1
            else:
                assert_never(message_filter)

            if index == 0:
                break

            line = weechat.hdata_move(weechat.hdata_get("line"), line, -1)

        if line:
            return hdata_line_ts(line)

    def ts_from_hash_or_index(
        self,
        hash_or_index: Union[str, int],
        message_filter: Optional[Literal["sender_self"]] = None,
    ) -> Optional[SlackTs]:
        ts_from_hash = (
            self.ts_from_hash(hash_or_index) if isinstance(hash_or_index, str) else None
        )
        if ts_from_hash is not None:
            return ts_from_hash
        elif isinstance(hash_or_index, int) or hash_or_index.isdigit():
            return self.ts_from_index(int(hash_or_index), message_filter)
        else:
            return None

    async def post_message(
        self,
        text: str,
        thread_ts: Optional[SlackTs] = None,
        broadcast: bool = False,
    ):
        linkified_text = await self.linkify_text(text)
        await self.api.chat_post_message(
            self.conversation, linkified_text, thread_ts, broadcast
        )

    async def send_change_reaction(
        self, ts: SlackTs, emoji_char: str, change_type: Literal["+", "-", "toggle"]
    ) -> None:
        emoji = shared.standard_emojis_inverse.get(emoji_char)
        emoji_name = emoji["name"] if emoji else emoji_char

        if change_type == "toggle":
            message = self.messages[ts]
            has_reacted = message.has_reacted(emoji_name)
            change_type = "-" if has_reacted else "+"

        await self.api.reactions_change(self.conversation, ts, emoji_name, change_type)

    async def edit_message(self, ts: SlackTs, old: str, new: str, flags: str):
        message = self.messages[ts]

        if new == "" and old == "":
            await self.api.chat_delete_message(self.conversation, message.ts)
        else:
            num_replace = 0 if "g" in flags else 1
            f = re.UNICODE
            f |= re.IGNORECASE if "i" in flags else 0
            f |= re.MULTILINE if "m" in flags else 0
            f |= re.DOTALL if "s" in flags else 0
            old_message_text = message.text
            new_message_text = re.sub(old, new, old_message_text, num_replace, f)
            if new_message_text != old_message_text:
                await self.api.chat_update_message(
                    self.conversation, message.ts, new_message_text
                )
            else:
                print_error("The regex didn't match any part of the message")

    async def linkify_text(self, text: str) -> str:
        escaped_text = (
            htmlescape(text)
            # Replace some WeeChat formatting chars with Slack formatting chars
            .replace("\x02", "*")
            .replace("\x1d", "_")
        )

        users = await gather(*self.workspace.users.values(), return_exceptions=True)
        nick_to_user_id = {
            user.nick.raw_nick: user.id
            for user in users
            if not isinstance(user, BaseException)
        }

        def linkify_word(match: Match[str]) -> str:
            word = match.group(0)
            nick = match.group(1)
            if nick in nick_to_user_id:
                return f"<@{nick_to_user_id[nick]}>"
            return word

        linkify_regex = r"(?:^|(?<=\s))@([\w\(\)\'.-]+)"
        return re.sub(linkify_regex, linkify_word, escaped_text, flags=re.UNICODE)

    async def process_input(self, input_data: str):
        special = re.match(
            rf"{MESSAGE_ID_REGEX_STRING}?(?:{REACTION_CHANGE_REGEX_STRING}{EMOJI_CHAR_OR_NAME_REGEX_STRING}\s*|s/)",
            input_data,
        )
        if special:
            msg_id = special.group("msg_id") or 1
            emoji = special.group("emoji_char") or special.group("emoji_name")
            reaction_change_type = special.group("reaction_change")

            message_filter = "sender_self" if not emoji else None
            ts = self.ts_from_hash_or_index(msg_id, message_filter)
            if ts is None:
                print_error(f"No slack message found for message id or index {msg_id}")
                return

            if emoji and (reaction_change_type == "+" or reaction_change_type == "-"):
                await self.send_change_reaction(ts, emoji, reaction_change_type)
            else:
                try:
                    old, new, flags = re.split(r"(?<!\\)/", input_data)[1:]
                except ValueError:
                    print_error(
                        "Incomplete regex for changing a message, "
                        "it should be in the form s/old text/new text/"
                    )
                else:
                    # Replacement string in re.sub() is a string, not a regex, so get rid of escapes
                    new = new.replace(r"\/", "/")
                    old = old.replace(r"\/", "/")
                    await self.edit_message(ts, old, new, flags)
        else:
            if input_data.startswith(("//", " ")):
                input_data = input_data[1:]
            await self.post_message(input_data)

    def _buffer_input_cb(self, data: str, buffer: str, input_data: str) -> int:
        run_async(self.process_input(input_data))
        return weechat.WEECHAT_RC_OK

    def _buffer_close_cb(self, data: str, buffer: str) -> int:
        update_server = (
            self._should_update_server_on_buffer_close
            if self._should_update_server_on_buffer_close is not None
            else shared.config.look.leave_channel_on_buffer_close.value
        )
        run_async(self._buffer_close(update_server=update_server))
        self._should_update_server_on_buffer_close = None
        return weechat.WEECHAT_RC_OK

    async def _buffer_close(
        self, call_buffer_close: bool = False, update_server: bool = False
    ):
        if shared.script_is_unloading:
            return

        self._should_update_server_on_buffer_close = update_server

        if self.buffer_pointer in shared.buffers:
            del shared.buffers[self.buffer_pointer]

        if call_buffer_close and self.buffer_pointer is not None:
            weechat.buffer_close(self.buffer_pointer)

        self.buffer_pointer = None
        self.last_printed_ts = None
        self.hotlist_tss.clear()


if TYPE_CHECKING:
    pass

    Options = Dict[str, Union[str, Literal[True]]]
    WeechatCommandCallback = Callable[[str, str], None]
    InternalCommandCallback = Callable[
        [str, List[str], Options], Optional[Coroutine[Any, None, None]]
    ]

T = TypeVar("T")

focus_events = ("auto", "message", "delete", "linkarchive", "reply", "thread")


def print_message_not_found_error(msg_id: str):
    if msg_id:
        print_error(
            "Invalid id given, must be an existing id or a number greater "
            + "than 0 and less than the number of messages in the channel"
        )
    else:
        print_error("No messages found in channel")


# def parse_help_docstring(cmd):
#     doc = textwrap.dedent(cmd.__doc__).strip().split("\n", 1)
#     cmd_line = doc[0].split(None, 1)
#     args = "".join(cmd_line[1:])
#     return cmd_line[0], args, doc[1].strip()


def parse_options(args: str):
    regex = re.compile("(?:^| )+-([^ =]+)(?:=([^ ]+))?")
    pos_args = regex.sub("", args).strip()
    options: Options = {
        match.group(1): match.group(2) or True for match in regex.finditer(args)
    }
    return pos_args, options


@dataclass
class Command:
    cmd: str
    top_level: bool
    description: str
    args: str
    args_description: str
    completion: str
    cb: WeechatCommandCallback


def weechat_command(
    completion: str = "",
    min_args: int = 0,
    max_split: Optional[int] = None,
    slack_buffer_required: bool = False,
) -> Callable[
    [InternalCommandCallback],
    WeechatCommandCallback,
]:
    def decorator(
        f: InternalCommandCallback,
    ) -> WeechatCommandCallback:
        cmd = removeprefix(f.__name__, "command_").replace("_", " ")
        top_level = " " not in cmd

        @wraps(f)
        def wrapper(buffer: str, args: str):
            pos_args, options = parse_options(args)
            re_maxsplit = (
                max_split
                if max_split is not None
                else -1
                if min_args == 1
                else min_args - 1
            )
            split_args = (
                re.split(r"\s+", pos_args, re_maxsplit)
                if re_maxsplit >= 0
                else [pos_args]
            )
            if min_args and not pos_args or len(split_args) < min_args:
                print_error(
                    f'Too few arguments for command "/{cmd}" (help on command: /help {cmd})'
                )
                return
            result = f(buffer, split_args, options)
            if result is not None:
                run_async(result)
            return

        shared.commands[cmd] = Command(cmd, top_level, "", "", "", completion, wrapper)

        return wrapper

    return decorator


def list_workspaces(workspace_name: Optional[str] = None, detailed_list: bool = False):
    weechat.prnt("", "")
    weechat.prnt("", "All workspaces:")
    for workspace in shared.workspaces.values():
        display_workspace(workspace, detailed_list)


def display_workspace(workspace: SlackWorkspace, detailed_list: bool):
    if workspace.is_connected:
        num_pvs = len(
            [
                conversation
                for conversation in workspace.open_conversations.values()
                if conversation.buffer_type == "private"
            ]
        )
        num_channels = len(workspace.open_conversations) - num_pvs
        weechat.prnt(
            "",
            f" * "
            f"{with_color('chat_server', workspace.name)} "
            f"{with_color('chat_delimiters', '[')}"
            f"connected"
            f"{with_color('chat_delimiters', ']')}"
            f", nick: {workspace.my_user.nick.format()}"
            f", {num_channels} channel(s), {num_pvs} pv",
        )
    elif workspace.is_connecting:
        weechat.prnt(
            "",
            f"   {with_color('chat_server', workspace.name)} "
            f"{with_color('chat_delimiters', '[')}"
            f"connecting"
            f"{with_color('chat_delimiters', ']')}",
        )
    else:
        weechat.prnt("", f"   {with_color('chat_server', workspace.name)}")


@weechat_command()
def command_slack(buffer: str, args: List[str], options: Options):
    """
    slack command
    """
    print("ran slack")


async def workspace_connect(workspace: SlackWorkspace):
    if workspace.is_connected:
        print_error(f'already connected to workspace "{workspace.name}"!')
        return
    elif workspace.is_connecting:
        print_error(f'already connecting to workspace "{workspace.name}"!')
        return
    await workspace.connect()


@weechat_command("%(slack_workspaces)|-all", max_split=0)
async def command_slack_connect(buffer: str, args: List[str], options: Options):
    if options.get("all"):
        for workspace in shared.workspaces.values():
            await workspace.connect()
    elif args[0]:
        for arg in args:
            workspace = shared.workspaces.get(arg)
            if workspace is None:
                print_error(f'workspace "{arg}" not found')
            else:
                await workspace_connect(workspace)
    else:
        slack_buffer = shared.buffers.get(buffer)
        if slack_buffer:
            await workspace_connect(slack_buffer.workspace)


def workspace_disconnect(workspace: SlackWorkspace):
    if not workspace.is_connected and not workspace.is_connecting:
        print_error(f'not connected to workspace "{workspace.name}"!')
        return
    workspace.disconnect()


@weechat_command("%(slack_workspaces)|-all", max_split=0)
def command_slack_disconnect(buffer: str, args: List[str], options: Options):
    if options.get("all"):
        for workspace in shared.workspaces.values():
            workspace.disconnect()
    elif args[0]:
        for arg in args:
            workspace = shared.workspaces.get(arg)
            if workspace is None:
                print_error(f'workspace "{arg}" not found')
            else:
                workspace_disconnect(workspace)
    else:
        slack_buffer = shared.buffers.get(buffer)
        if slack_buffer:
            workspace_disconnect(slack_buffer.workspace)


@weechat_command()
async def command_slack_rehistory(buffer: str, args: List[str], options: Options):
    slack_buffer = shared.buffers.get(buffer)
    if isinstance(slack_buffer, SlackMessageBuffer):
        await slack_buffer.rerender_history()


@weechat_command()
def command_slack_workspace(buffer: str, args: List[str], options: Options):
    list_workspaces()


@weechat_command("%(slack_workspaces)")
def command_slack_workspace_list(buffer: str, args: List[str], options: Options):
    list_workspaces()


@weechat_command("%(slack_workspaces)")
def command_slack_workspace_listfull(buffer: str, args: List[str], options: Options):
    list_workspaces(detailed_list=True)


@weechat_command(min_args=1)
def command_slack_workspace_add(buffer: str, args: List[str], options: Options):
    name = args[0]
    if name in shared.workspaces:
        print_error(f'workspace "{name}" already exists, can\'t add it!')
        return

    shared.workspaces[name] = SlackWorkspace(name)

    for option_name, option_value in options.items():
        if hasattr(shared.workspaces[name].config, option_name):
            config_option: WeeChatOption[WeeChatOptionTypes] = getattr(
                shared.workspaces[name].config, option_name
            )
            value = "on" if option_value is True else option_value
            config_option.value_set_as_str(value)

    weechat.prnt(
        "",
        f"{shared.SCRIPT_NAME}: workspace added: {weechat.color('chat_server')}{name}{weechat.color('reset')}",
    )


@weechat_command("%(slack_workspaces)", min_args=2)
def command_slack_workspace_rename(buffer: str, args: List[str], options: Options):
    old_name = args[0]
    new_name = args[1]
    workspace = shared.workspaces.get(old_name)
    if not workspace:
        print_error(f'workspace "{old_name}" not found for "workspace rename" command')
        return
    workspace.name = new_name
    shared.workspaces[new_name] = workspace
    del shared.workspaces[old_name]
    weechat.prnt(
        "",
        f"server {with_color('chat_server', old_name)} has been renamed to {with_color('chat_server', new_name)}",
    )
    # TODO: Rename buffers and config


@weechat_command("%(slack_workspaces)", min_args=1)
def command_slack_workspace_del(buffer: str, args: List[str], options: Options):
    name = args[0]
    workspace = shared.workspaces.get(name)
    if not workspace:
        print_error(f'workspace "{name}" not found for "workspace del" command')
        return
    if workspace.is_connected:
        print_error(
            f'you can not delete server "{name}" because you are connected to it. Try "/slack disconnect {name}" first.'
        )
        return
    # TODO: Delete config
    del shared.workspaces[name]
    weechat.prnt(
        "",
        f"server {with_color('chat_server', name)} has been deleted",
    )


@weechat_command("%(nicks)", min_args=1, max_split=0)
async def command_slack_query(buffer: str, args: List[str], options: Options):
    slack_buffer = shared.buffers.get(buffer)
    if slack_buffer is None:
        return

    nicks = [removeprefix(nick, "@") for nick in args]
    all_users = get_resolved_futures(slack_buffer.workspace.users.values())
    users = [user for user in all_users if user.nick.raw_nick in nicks]

    if len(users) != len(nicks):
        found_nicks = [user.nick.raw_nick for user in users]
        not_found_nicks = [nick for nick in nicks if nick not in found_nicks]
        print_error(
            f"No such nick{'s' if len(not_found_nicks) > 1 else ''}: {', '.join(not_found_nicks)}"
        )
        return

    if len(users) == 1:
        user = users[0]
        all_conversations = get_resolved_futures(
            slack_buffer.workspace.conversations.values()
        )
        for conversation in all_conversations:
            if conversation.im_user_id == user.id:
                await conversation.open_buffer(switch=True)
                return

    user_ids = [user.id for user in users]
    await create_conversation_for_users(slack_buffer.workspace, user_ids)


async def get_conversation_from_args(buffer: str, args: List[str], options: Options):
    slack_buffer = shared.buffers.get(buffer)

    workspace_name = options.get("workspace")
    if workspace_name is True:
        print_error("No workspace specified")
        return

    workspace = (
        shared.workspaces.get(workspace_name)
        if workspace_name
        else slack_buffer.workspace
        if slack_buffer is not None
        else None
    )

    if workspace is None:
        if workspace_name:
            print_error(f'Workspace "{workspace_name}" not found')
        else:
            print_error(
                "Must be run from a slack buffer unless a workspace is specified"
            )
        return

    if len(args) == 0 or not args[0]:
        if workspace_name is not None:
            print_error(
                "Must specify conversaton name when workspace name is specified"
            )
            return
        if isinstance(slack_buffer, SlackConversation):
            return slack_buffer
        else:
            return

    conversation_name = removeprefix(args[0].strip(), "#")
    all_conversations = get_resolved_futures(workspace.conversations.values())
    for conversation in all_conversations:
        if conversation.name() == conversation_name:
            return conversation

    if workspace.api.edgeapi.is_available:
        results = await workspace.api.edgeapi.fetch_channels_search(conversation_name)
        for channel_info in results["results"]:
            if channel_info["name"] == conversation_name:
                return await workspace.conversations[channel_info["id"]]

    print_error(f'Conversation "{conversation_name}" not found')


@weechat_command("")
async def command_slack_join(buffer: str, args: List[str], options: Options):
    conversation = await get_conversation_from_args(buffer, args, options)
    if conversation is not None:
        await conversation.api.conversations_join(conversation.id)
        await conversation.open_buffer(switch=not options.get("noswitch"))


@weechat_command("")
async def command_slack_part(buffer: str, args: List[str], options: Options):
    conversation = await get_conversation_from_args(buffer, args, options)
    if conversation is not None:
        await conversation.part()


@weechat_command("%(threads)", min_args=1)
async def command_slack_thread(buffer: str, args: List[str], options: Options):
    slack_buffer = shared.buffers.get(buffer)
    if isinstance(slack_buffer, SlackConversation):
        await slack_buffer.open_thread(args[0], switch=True)


@weechat_command("-alsochannel|%(threads)", min_args=1)
async def command_slack_reply(buffer: str, args: List[str], options: Options):
    slack_buffer = shared.buffers.get(buffer)
    broadcast = bool(options.get("alsochannel"))
    if isinstance(slack_buffer, SlackThread):
        await slack_buffer.post_message(args[0], broadcast=broadcast)
    elif isinstance(slack_buffer, SlackConversation):
        split_args = re.split(r"\s+", args[0], 1)
        if len(split_args) < 2:
            print_error(
                'Too few arguments for command "/slack reply" (help on command: /help slack reply)'
            )
            return
        thread_ts = slack_buffer.ts_from_hash_or_index(split_args[0])
        if thread_ts is None:
            print_message_not_found_error(split_args[0])
            return
        await slack_buffer.post_message(split_args[1], thread_ts, broadcast)


@weechat_command("away|active")
async def command_slack_presence(buffer: str, args: List[str], options: Options):
    slack_buffer = shared.buffers.get(buffer)
    if slack_buffer is None:
        return
    new_presence = args[0]
    if new_presence not in ("active", "away"):
        print_error(
            f'Error with command "/slack presence {args[0]}" (help on command: /help slack presence)'
        )
        return
    await slack_buffer.api.set_presence(new_presence)


@weechat_command("list")
async def command_slack_mute(buffer: str, args: List[str], options: Options):
    slack_buffer = shared.buffers.get(buffer)
    if not isinstance(slack_buffer, SlackConversation):
        return

    if args[0] == "list":
        conversations = await gather(
            *[
                slack_buffer.workspace.conversations[conversation_id]
                for conversation_id in slack_buffer.workspace.muted_channels
            ]
        )
        conversation_names = sorted(
            conversation.name_with_prefix("short_name_without_padding")
            for conversation in conversations
        )
        slack_buffer.workspace.print(
            f"Muted conversations: {', '.join(conversation_names)}"
        )
        return

    muted_channels = set(slack_buffer.workspace.muted_channels)
    muted_channels ^= {slack_buffer.id}
    await slack_buffer.api.set_muted_channels(muted_channels)
    muted_str = "Muted" if slack_buffer.id in muted_channels else "Unmuted"
    slack_buffer.workspace.print(
        f"{muted_str} channel {slack_buffer.name_with_prefix('short_name_without_padding')}",
    )


@weechat_command("channels|users", max_split=1)
async def command_slack_search(buffer: str, args: List[str], options: Options):
    if args[0] == "":
        search_buffer = next(
            (
                search_buffer
                for workspace in shared.workspaces.values()
                for search_buffer in workspace.search_buffers.values()
                if search_buffer.buffer_pointer == buffer
            ),
            None,
        )
        if search_buffer is not None:
            if options.get("up"):
                search_buffer.selected_line -= 1
            elif options.get("down"):
                search_buffer.selected_line += 1
            elif options.get("mark"):
                search_buffer.mark_line(search_buffer.selected_line)
            elif options.get("join_channel"):
                await search_buffer.join_channel()
            else:
                print_error("No search action specified")
    else:
        slack_buffer = shared.buffers.get(buffer)
        if slack_buffer is None:
            return

        if args[0] == "channels" or args[0] == "users":
            search_buffer = slack_buffer.workspace.search_buffers.get(args[0])
            query = args[1] if len(args) > 1 else None
            if search_buffer is not None:
                search_buffer.switch_to_buffer()
                if query is not None:
                    await search_buffer.search(query)
            else:
                slack_buffer.workspace.search_buffers[args[0]] = SlackSearchBuffer(
                    slack_buffer.workspace, args[0], query
                )
        else:
            print_error(f"Unknown search type: {args[0]}")


def print_uncaught_error(error: UncaughtError, detailed: bool, options: Options):
    weechat.prnt("", f"  {error.id} ({error.time}): {error.exception}")
    if detailed:
        for line in format_exception(error.exception):
            weechat.prnt("", f"  {line}")
    if options.get("data"):
        if isinstance(error.exception, SlackRtmError):
            weechat.prnt("", f"  data: {json.dumps(error.exception.message_json)}")
        elif isinstance(error.exception, SlackError):
            weechat.prnt("", f"  data: {json.dumps(error.exception.data)}")
        else:
            print_error("This error does not have any data")


@weechat_command("tasks|buffer|open_buffer|replay_events|errors|error", max_split=0)
async def command_slack_debug(buffer: str, args: List[str], options: Options):
    # TODO: Add message info (message_json)
    if args[0] == "tasks":
        weechat.prnt("", "Active tasks:")
        weechat.prnt("", pprint.pformat(shared.active_tasks))
        weechat.prnt("", "Active futures:")
        weechat.prnt("", pprint.pformat(shared.active_futures))
    elif args[0] == "buffer":
        slack_buffer = shared.buffers.get(buffer)
        if isinstance(slack_buffer, SlackConversation):
            weechat.prnt("", f"Conversation id: {slack_buffer.id}")
        elif isinstance(slack_buffer, SlackThread):
            weechat.prnt(
                "",
                f"Conversation id: {slack_buffer.parent.conversation.id}, Thread ts: {slack_buffer.parent.thread_ts}, Thread hash: {slack_buffer.parent.hash}",
            )
    elif args[0] == "open_buffer":
        open_debug_buffer()
    elif args[0] == "replay_events":
        slack_buffer = shared.buffers.get(buffer)
        if slack_buffer is None:
            print_error("Must be run from a slack buffer")
            return
        with open(args[1]) as f:
            for line in f:
                first_brace_pos = line.find("{")
                if first_brace_pos == -1:
                    continue
                event = json.loads(line[first_brace_pos:])
                await slack_buffer.workspace.ws_recv(event)
    elif args[0] == "errors":
        num_arg = int(args[1]) if len(args) > 1 and args[1].isdecimal() else 5
        num = min(num_arg, len(shared.uncaught_errors))
        weechat.prnt("", f"Last {num} errors:")
        for error in shared.uncaught_errors[-num:]:
            print_uncaught_error(error, False, options)
    elif args[0] == "error":
        if len(args) > 1:
            if args[1].isdecimal() and args[1] != "0":
                num = int(args[1])
                if num > len(shared.uncaught_errors):
                    print_error(
                        f"Only {len(shared.uncaught_errors)} error(s) have occurred"
                    )
                    return
                error = shared.uncaught_errors[-num]
            else:
                errors = [e for e in shared.uncaught_errors if e.id == args[1]]
                if not errors:
                    print_error(f"Error {args[1]} not found")
                    return
                error = errors[0]
            weechat.prnt("", f"Error {error.id}:")
        elif not shared.uncaught_errors:
            weechat.prnt("", "No errors have occurred")
            return
        else:
            error = shared.uncaught_errors[-1]
            weechat.prnt("", "Last error:")
        print_uncaught_error(error, True, options)


@weechat_command("-clear")
async def command_slack_status(buffer: str, args: List[str], options: Options):
    status = args[0]
    slack_buffer = shared.buffers.get(buffer)
    if slack_buffer is not None:
        if options.get("clear"):
            await slack_buffer.api.clear_user_status()
        elif slack_buffer and len(status) > 0:
            await slack_buffer.api.set_user_status(status)
        else:
            print_error(
                'Too few arguments for command "/slack status" (help on command: /help slack status)'
            )
    else:
        print_error("Run the command in a slack buffer")


def _get_conversation_from_buffer(
    slack_buffer: Union[SlackWorkspace, SlackMessageBuffer],
) -> Optional[SlackConversation]:
    if isinstance(slack_buffer, SlackConversation):
        return slack_buffer
    elif isinstance(slack_buffer, SlackThread):
        return slack_buffer.parent.conversation
    return None


def _get_linkarchive_url(
    slack_buffer: Union[SlackWorkspace, SlackMessageBuffer],
    message_ts: Optional[SlackTs],
) -> str:
    url = f"https://{slack_buffer.workspace.domain}.slack.com/"
    conversation = _get_conversation_from_buffer(slack_buffer)
    if conversation is not None:
        url += f"archives/{conversation.id}/"
        if message_ts is not None:
            message = conversation.messages[message_ts]
            url += f"p{message.ts.major}{message.ts.minor:0>6}"
            if message.thread_ts is not None:
                url += f"?thread_ts={message.thread_ts}&cid={conversation.id}"
    return url


@weechat_command("%(threads)")
def command_slack_linkarchive(buffer: str, args: List[str], options: Options):
    """
    /slack linkarchive [message_id]
    Place a link to the conversation or message in the input bar.
    Use cursor or mouse mode to get the id.
    """
    slack_buffer = shared.buffers.get(buffer)
    if slack_buffer is None:
        return

    if isinstance(slack_buffer, SlackMessageBuffer) and args[0]:
        ts = slack_buffer.ts_from_hash_or_index(args[0])
        if ts is None:
            print_message_not_found_error(args[0])
            return
    else:
        ts = None

    url = _get_linkarchive_url(slack_buffer, ts)
    weechat.command(buffer, f"/input insert {url}")


def find_command(start_cmd: str, args: str) -> Optional[Tuple[Command, str]]:
    args_parts = re.finditer("[^ ]+", args)
    cmd = start_cmd
    cmd_args_startpos = 0

    for part in args_parts:
        next_cmd = f"{cmd} {part.group(0)}"
        if next_cmd not in shared.commands:
            cmd_args_startpos = part.start(0)
            break
        cmd = next_cmd
    else:
        cmd_args_startpos = len(args)

    cmd_args = args[cmd_args_startpos:]
    if cmd in shared.commands:
        return shared.commands[cmd], cmd_args
    return None


def command_cb(data: str, buffer: str, args: str) -> int:
    found_cmd_with_args = find_command(data, args)
    if found_cmd_with_args:
        command = found_cmd_with_args[0]
        cmd_args = found_cmd_with_args[1]
        command.cb(buffer, cmd_args)
    else:
        print_error(
            f'Error with command "/{data} {args}" (help on command: /help {data})'
        )

    return weechat.WEECHAT_RC_OK


async def mark_read(slack_buffer: SlackMessageBuffer):
    # Sleep so the read marker is updated before we run slack_buffer.mark_read
    await sleep(1)
    await slack_buffer.mark_read()


def buffer_set_unread_cb(data: str, buffer: str, command: str) -> int:
    slack_buffer = shared.buffers.get(buffer)
    if isinstance(slack_buffer, SlackMessageBuffer):
        run_async(mark_read(slack_buffer))
    return weechat.WEECHAT_RC_OK


def focus_event_cb(data: str, signal: str, hashtable: Dict[str, str]) -> int:
    tags = hashtable["_chat_line_tags"].split(",")
    for tag in tags:
        ts = ts_from_tag(tag)
        if ts is not None:
            break
    else:
        return weechat.WEECHAT_RC_OK

    buffer_pointer = hashtable["_buffer"]
    slack_buffer = shared.buffers.get(buffer_pointer)
    if not isinstance(slack_buffer, SlackMessageBuffer):
        return weechat.WEECHAT_RC_OK

    conversation = _get_conversation_from_buffer(slack_buffer)
    if conversation is None:
        return weechat.WEECHAT_RC_OK

    message_hash = f"${conversation.message_hashes[ts]}"

    if data not in focus_events:
        print_error(f"Unknown focus event: {data}")
        return weechat.WEECHAT_RC_OK

    if data == "auto":
        emoji_match = re.match(EMOJI_CHAR_OR_NAME_REGEX_STRING, hashtable["_chat_eol"])
        if emoji_match is not None:
            emoji = emoji_match.group("emoji_char") or emoji_match.group("emoji_name")
            run_async(conversation.send_change_reaction(ts, emoji, "toggle"))
        else:
            weechat.command(buffer_pointer, f"/input insert {message_hash}")
    elif data == "message":
        weechat.command(buffer_pointer, f"/input insert {message_hash}")
    elif data == "delete":
        run_async(conversation.api.chat_delete_message(conversation, ts))
    elif data == "linkarchive":
        url = _get_linkarchive_url(slack_buffer, ts)
        weechat.command(buffer_pointer, f"/input insert {url}")
    elif data == "reply":
        weechat.command(buffer_pointer, f"/input insert /reply {message_hash}\\x20")
    elif data == "thread":
        run_async(conversation.open_thread(message_hash, switch=True))
    else:
        assert_never(data)
    return weechat.WEECHAT_RC_OK


def python_eval_slack_cb(data: str, buffer: str, command: str) -> int:
    slack_buffer = shared.buffers.get(buffer)
    if slack_buffer is None:
        print_error("Must be run from a slack buffer")
        return weechat.WEECHAT_RC_OK_EAT
    args = command.split(" ", 2)
    code = compile(
        args[2], "<string>", "exec", flags=getattr(ast, "PyCF_ALLOW_TOP_LEVEL_AWAIT", 0)
    )
    coroutine = eval(code)
    if coroutine is not None:
        run_async(coroutine)
    return weechat.WEECHAT_RC_OK_EAT


def register_commands():
    weechat.hook_command_run(
        "/buffer set unread", get_callback_name(buffer_set_unread_cb), ""
    )
    weechat.hook_command_run(
        "/buffer set unread *", get_callback_name(buffer_set_unread_cb), ""
    )
    weechat.hook_command_run(
        "/input set_unread_current_buffer", get_callback_name(buffer_set_unread_cb), ""
    )
    weechat.hook_command_run(
        "/python eval_slack *", get_callback_name(python_eval_slack_cb), ""
    )

    for cmd, command in shared.commands.items():
        if command.top_level:
            weechat.hook_command(
                command.cmd,
                command.description,
                command.args,
                command.args_description,
                "%(slack_commands)|%*",
                get_callback_name(command_cb),
                cmd,
            )

    for focus_event in focus_events:
        weechat.hook_hsignal(
            f"slack_focus_{focus_event}",
            get_callback_name(focus_event_cb),
            focus_event,
        )

    weechat.key_bind(
        "mouse",
        {
            "@chat(python.*):button2": "hsignal:slack_focus_auto",
        },
    )
    weechat.key_bind(
        "cursor",
        {
            "@chat(python.*):D": "hsignal:slack_focus_delete",
            "@chat(python.*):L": "hsignal:slack_focus_linkarchive; /cursor stop",
            "@chat(python.*):M": "hsignal:slack_focus_message; /cursor stop",
            "@chat(python.*):R": "hsignal:slack_focus_reply; /cursor stop",
            "@chat(python.*):T": "hsignal:slack_focus_thread; /cursor stop",
        },
    )


REACTION_PREFIX_REGEX_STRING = (
    rf"{MESSAGE_ID_REGEX_STRING}?{REACTION_CHANGE_REGEX_STRING}"
)


def completion_slack_workspaces_cb(
    data: str, completion_item: str, buffer: str, completion: str
) -> int:
    for workspace_name in shared.workspaces:
        weechat.completion_list_add(
            completion, workspace_name, 0, weechat.WEECHAT_LIST_POS_SORT
        )
    return weechat.WEECHAT_RC_OK


def completion_list_add_expand(
    completion: str, word: str, nick_completion: int, where: str, buffer: str
):
    if word == "%(slack_workspaces)":
        completion_slack_workspaces_cb("", "slack_workspaces", buffer, completion)
    elif word == "%(nicks)":
        completion_nicks_cb("", "nicks", buffer, completion)
    elif word == "%(threads)":
        completion_thread_hashes_cb("", "threads", buffer, completion)
    else:
        weechat.completion_list_add(completion, word, nick_completion, where)


def completion_slack_workspace_commands_cb(
    data: str, completion_item: str, buffer: str, completion: str
) -> int:
    base_command = weechat.completion_get_string(completion, "base_command")
    base_word = weechat.completion_get_string(completion, "base_word")
    args = weechat.completion_get_string(completion, "args")
    args_without_base_word = removesuffix(args, base_word)

    found_cmd_with_args = find_command(base_command, args_without_base_word)
    if found_cmd_with_args:
        command = found_cmd_with_args[0]
        matching_cmds = [
            removeprefix(cmd, command.cmd).lstrip()
            for cmd in shared.commands
            if cmd.startswith(command.cmd) and cmd != command.cmd
        ]
        if len(matching_cmds) > 1:
            for match in matching_cmds:
                cmd_arg = match.split(" ")
                completion_list_add_expand(
                    completion, cmd_arg[0], 0, weechat.WEECHAT_LIST_POS_SORT, buffer
                )
        else:
            for arg in command.completion.split("|"):
                completion_list_add_expand(
                    completion, arg, 0, weechat.WEECHAT_LIST_POS_SORT, buffer
                )

    return weechat.WEECHAT_RC_OK


def completion_slack_channels_cb(
    data: str, completion_item: str, buffer: str, completion: str
) -> int:
    slack_buffer = shared.buffers.get(buffer)
    if slack_buffer is None:
        return weechat.WEECHAT_RC_OK

    conversations = slack_buffer.workspace.open_conversations.values()
    for conversation in conversations:
        if conversation.buffer_type == "channel":
            weechat.completion_list_add(
                completion,
                conversation.name_with_prefix("short_name_without_padding"),
                0,
                weechat.WEECHAT_LIST_POS_SORT,
            )
    return weechat.WEECHAT_RC_OK


def completion_emojis_cb(
    data: str, completion_item: str, buffer: str, completion: str
) -> int:
    slack_buffer = shared.buffers.get(buffer)
    if slack_buffer is None:
        return weechat.WEECHAT_RC_OK

    base_word = weechat.completion_get_string(completion, "base_word")
    reaction = re.match(REACTION_PREFIX_REGEX_STRING + ":", base_word)
    prefix = reaction.group(0) if reaction else ":"

    emoji_names = chain(
        shared.standard_emojis.keys(), slack_buffer.workspace.custom_emojis.keys()
    )
    for emoji_name in emoji_names:
        if "::skin-tone-" not in emoji_name:
            weechat.completion_list_add(
                completion,
                f"{prefix}{emoji_name}:",
                0,
                weechat.WEECHAT_LIST_POS_SORT,
            )
    return weechat.WEECHAT_RC_OK


def completion_nicks_cb(
    data: str, completion_item: str, buffer: str, completion: str
) -> int:
    slack_buffer = shared.buffers.get(buffer)
    if slack_buffer is None:
        return weechat.WEECHAT_RC_OK

    all_users = get_resolved_futures(slack_buffer.workspace.users.values())
    all_nicks = [user.nick for user in all_users]
    all_raw_nicks = sorted([nick.raw_nick for nick in all_nicks], key=str.casefold)
    for nick in all_raw_nicks:
        weechat.completion_list_add(
            completion,
            f"@{nick}",
            1,
            weechat.WEECHAT_LIST_POS_END,
        )
        weechat.completion_list_add(
            completion,
            nick,
            1,
            weechat.WEECHAT_LIST_POS_END,
        )

    members = (
        slack_buffer.members
        if isinstance(slack_buffer, SlackMessageBuffer)
        else all_nicks
    )

    buffer_nicks = sorted(
        [nick.raw_nick for nick in members], key=str.casefold, reverse=True
    )
    for nick in buffer_nicks:
        weechat.completion_list_add(
            completion,
            nick,
            1,
            weechat.WEECHAT_LIST_POS_BEGINNING,
        )
        weechat.completion_list_add(
            completion,
            f"@{nick}",
            1,
            weechat.WEECHAT_LIST_POS_BEGINNING,
        )

    if isinstance(slack_buffer, SlackMessageBuffer):
        senders = [
            m.sender_user_id
            for m in slack_buffer.messages.values()
            if m.sender_user_id
            and m.subtype in [None, "me_message", "thread_broadcast"]
        ]
        unique_senders = list(dict.fromkeys(senders))
        sender_users = get_resolved_futures(
            [slack_buffer.workspace.users[sender] for sender in unique_senders]
        )
        nicks = [user.nick.raw_nick for user in sender_users]
        for nick in nicks:
            weechat.completion_list_add(
                completion,
                nick,
                1,
                weechat.WEECHAT_LIST_POS_BEGINNING,
            )
            weechat.completion_list_add(
                completion,
                f"@{nick}",
                1,
                weechat.WEECHAT_LIST_POS_BEGINNING,
            )

    my_user_nick = slack_buffer.workspace.my_user.nick.raw_nick
    weechat.completion_list_add(
        completion,
        f"@{my_user_nick}",
        1,
        weechat.WEECHAT_LIST_POS_END,
    )
    weechat.completion_list_add(
        completion,
        my_user_nick,
        1,
        weechat.WEECHAT_LIST_POS_END,
    )

    return weechat.WEECHAT_RC_OK


def completion_thread_hashes_cb(
    data: str, completion_item: str, buffer: str, completion: str
) -> int:
    slack_buffer = shared.buffers.get(buffer)
    if not isinstance(slack_buffer, SlackConversation):
        return weechat.WEECHAT_RC_OK

    message_tss = sorted(slack_buffer.message_hashes.keys())
    messages = [slack_buffer.messages.get(ts) for ts in message_tss]
    thread_messages = [
        message
        for message in messages
        if message is not None and message.is_thread_parent
    ]
    for message in thread_messages:
        weechat.completion_list_add(
            completion, message.hash, 0, weechat.WEECHAT_LIST_POS_BEGINNING
        )
    for message in thread_messages:
        weechat.completion_list_add(
            completion, f"${message.hash}", 0, weechat.WEECHAT_LIST_POS_BEGINNING
        )
    return weechat.WEECHAT_RC_OK


def complete_input(buffer: str, slack_buffer: SlackMessageBuffer, query: str):
    if (
        slack_buffer.completion_context == "ACTIVE_COMPLETION"
        and slack_buffer.completion_values
    ):
        input_value = weechat.buffer_get_string(buffer, "input")
        input_pos = weechat.buffer_get_integer(buffer, "input_pos")
        result = slack_buffer.completion_values[slack_buffer.completion_index]
        input_before = removesuffix(input_value[:input_pos], query)
        input_after = input_value[input_pos:]
        new_input = input_before + result + input_after
        new_pos = input_pos - len(query) + len(result)

        with slack_buffer.completing():
            weechat.buffer_set(buffer, "input", new_input)
            weechat.buffer_set(buffer, "input_pos", str(new_pos))


def nick_suffix():
    return weechat.config_string(
        weechat.config_get("weechat.completion.nick_completer")
    )


async def complete_user_next(
    buffer: str, slack_buffer: SlackMessageBuffer, query: str, is_first_word: bool
):
    if slack_buffer.completion_context == "NO_COMPLETION":
        slack_buffer.completion_context = "PENDING_COMPLETION"
        search = await slack_buffer.api.edgeapi.fetch_users_search(query)
        if slack_buffer.completion_context != "PENDING_COMPLETION":
            return
        slack_buffer.completion_context = "ACTIVE_COMPLETION"
        suffix = nick_suffix() if is_first_word else " "
        slack_buffer.completion_values = [
            get_user_nick(name_from_user_info(slack_buffer.workspace, user)).raw_nick
            + suffix
            for user in search["results"]
        ]
        slack_buffer.completion_index = 0
    elif slack_buffer.completion_context == "ACTIVE_COMPLETION":
        slack_buffer.completion_index += 1
        if slack_buffer.completion_index >= len(slack_buffer.completion_values):
            slack_buffer.completion_index = 0

    complete_input(buffer, slack_buffer, query)


def complete_previous(buffer: str, slack_buffer: SlackMessageBuffer, query: str) -> int:
    if slack_buffer.completion_context == "ACTIVE_COMPLETION":
        slack_buffer.completion_index -= 1
        if slack_buffer.completion_index < 0:
            slack_buffer.completion_index = len(slack_buffer.completion_values) - 1
        complete_input(buffer, slack_buffer, query)
        return weechat.WEECHAT_RC_OK_EAT
    return weechat.WEECHAT_RC_OK


def input_complete_cb(data: str, buffer: str, command: str) -> int:
    slack_buffer = shared.buffers.get(buffer)
    if isinstance(slack_buffer, SlackMessageBuffer):
        input_value = weechat.buffer_get_string(buffer, "input")
        input_pos = weechat.buffer_get_integer(buffer, "input_pos")
        input_before_cursor = input_value[:input_pos]

        word_index = (
            -2 if slack_buffer.completion_context == "ACTIVE_COMPLETION" else -1
        )
        word_until_cursor = " ".join(input_before_cursor.split(" ")[word_index:])

        if word_until_cursor.startswith("@"):
            query = word_until_cursor[1:]
            is_first_word = word_until_cursor == input_before_cursor

            if command == "/input complete_next":
                run_async(
                    complete_user_next(buffer, slack_buffer, query, is_first_word)
                )
                return weechat.WEECHAT_RC_OK_EAT
            else:
                return complete_previous(buffer, slack_buffer, query)
    return weechat.WEECHAT_RC_OK


def register_completions():
    if shared.weechat_version < 0x02090000:
        weechat.completion_get_string = (
            weechat.hook_completion_get_string  # pyright: ignore [reportAttributeAccessIssue, reportUnknownMemberType]
        )
        weechat.completion_list_add = (
            weechat.hook_completion_list_add  # pyright: ignore [reportAttributeAccessIssue, reportUnknownMemberType]
        )

    # Disable until working properly
    # weechat.hook_command_run(
    #     "/input complete_*", get_callback_name(input_complete_cb), ""
    # )

    weechat.hook_completion(
        "slack_workspaces",
        "Slack workspaces (internal names)",
        get_callback_name(completion_slack_workspaces_cb),
        "",
    )
    weechat.hook_completion(
        "slack_commands",
        "completions for Slack commands",
        get_callback_name(completion_slack_workspace_commands_cb),
        "",
    )
    weechat.hook_completion(
        "slack_channels",
        "conversations in the current Slack workspace",
        get_callback_name(completion_slack_channels_cb),
        "",
    )
    weechat.hook_completion(
        "slack_emojis",
        "Emoji names known to Slack",
        get_callback_name(completion_emojis_cb),
        "",
    )
    weechat.hook_completion(
        "nicks",
        "nicks in the current Slack buffer",
        get_callback_name(completion_nicks_cb),
        "",
    )
    weechat.hook_completion(
        "threads",
        "complete thread ids for slack",
        get_callback_name(completion_thread_hashes_cb),
        "",
    )


if TYPE_CHECKING:
    pass


class SlackConfigSectionColor:
    def __init__(self, weechat_config: WeeChatConfig):
        self._section = WeeChatSection(weechat_config, "color")

        self.buflist_muted_conversation = WeeChatOption(
            self._section,
            "buflist_muted_conversation",
            "text color for muted conversations in the buflist",
            WeeChatColor("darkgray"),
            callback_change=self.config_change_buflist_muted_conversation_cb,
        )

        self.channel_mention = WeeChatOption(
            self._section,
            "channel_mention",
            "text color for mentioned channel names in the chat",
            WeeChatColor("blue"),
        )

        self.deleted_message = WeeChatOption(
            self._section,
            "deleted_message",
            "text color for a deleted message",
            WeeChatColor("red"),
        )

        self.disconnected = WeeChatOption(
            self._section,
            "disconnected",
            "text color for the disconnected text",
            WeeChatColor("red"),
        )

        self.edited_message_suffix = WeeChatOption(
            self._section,
            "edited_message_suffix",
            "text color for the suffix after an edited message",
            WeeChatColor("095"),
        )

        self.loading = WeeChatOption(
            self._section,
            "loading",
            "text color for the loading text",
            WeeChatColor("yellow"),
        )

        self.message_join = WeeChatOption(
            self._section,
            "message_join",
            "color for text in join messages",
            WeeChatColor("green"),
            parent_option="irc.color.message_join",
        )

        self.message_quit = WeeChatOption(
            self._section,
            "message_quit",
            "color for text in part messages",
            WeeChatColor("red"),
            parent_option="irc.color.message_quit",
        )

        self.reaction_suffix = WeeChatOption(
            self._section,
            "reaction_suffix",
            "color for the reactions after a message",
            WeeChatColor("darkgray"),
        )

        self.reaction_self_suffix = WeeChatOption(
            self._section,
            "reaction_self_suffix",
            "color for the reactions after a message, for reactions you have added",
            WeeChatColor("blue"),
        )

        self.render_error = WeeChatOption(
            self._section,
            "render_error",
            "color for displaying rendering errors in a message",
            WeeChatColor("red"),
        )

        self.search_line_marked_bg = WeeChatOption(
            self._section,
            "search_line_marked_bg",
            "background color for a marked line in search buffers",
            WeeChatColor("17"),
        )

        self.search_line_selected_bg = WeeChatOption(
            self._section,
            "search_line_selected_bg",
            "background color for the selected line in search buffers",
            WeeChatColor("24"),
        )

        self.search_marked = WeeChatOption(
            self._section,
            "search_marked",
            "color for mark indicator in search buffers",
            WeeChatColor("brown"),
        )

        self.search_marked_selected = WeeChatOption(
            self._section,
            "search_marked_selected",
            "color for mark indicator on the selected line in search buffers",
            WeeChatColor("yellow"),
        )

        self.user_mention = WeeChatOption(
            self._section,
            "user_mention",
            "text color for mentioned user names in the chat",
            WeeChatColor("blue"),
        )

        self.usergroup_mention = WeeChatOption(
            self._section,
            "usergroup_mention",
            "text color for mentioned user group names in the chat",
            WeeChatColor("blue"),
        )

    def config_change_buflist_muted_conversation_cb(
        self, option: WeeChatOption[WeeChatOptionType], parent_changed: bool
    ):
        update_buffer_props()


class SlackConfigSectionLook:
    def __init__(self, weechat_config: WeeChatConfig):
        self._section = WeeChatSection(weechat_config, "look")

        self.bot_user_suffix = WeeChatOption(
            self._section,
            "bot_user_suffix",
            "the suffix appended to nicks to indicate a bot",
            " :]",
        )

        self.thread_broadcast_prefix = WeeChatOption(
            self._section,
            "thread_broadcast_prefix",
            "prefix to distinguish thread messages that were also sent to the channel, when display_thread_replies_in_channel is enabled",
            "+",
        )

        self.color_nicks_in_nicklist = WeeChatOption(
            self._section,
            "color_nicks_in_nicklist",
            "use nick color in nicklist",
            False,
            parent_option="irc.look.color_nicks_in_nicklist",
            callback_change=self.config_change_color_nicks_in_nicklist_cb,
        )

        self.color_message_attachments: WeeChatOption[
            Literal["prefix", "all", "none"]
        ] = WeeChatOption(
            self._section,
            "color_message_attachments",
            "colorize attachments in a message: prefix = only colorize the prefix, all = colorize the whole line, none = don't colorize",
            "prefix",
            string_values=["prefix", "all", "none"],
        )

        self.display_link_previews: WeeChatOption[
            Literal["always", "only_internal", "never"]
        ] = WeeChatOption(
            self._section,
            "display_link_previews",
            "display previews of URLs in messages: always = always display, only_internal = only display for URLs to messages in the workspace, never = never display",
            "always",
            string_values=["always", "only_internal", "never"],
        )

        self.display_reaction_nicks = WeeChatOption(
            self._section,
            "display_reaction_nicks",
            "display the name of the reacting user(s) after each reaction; can be overridden per buffer with the buffer localvar display_reaction_nicks",
            False,
        )

        self.display_thread_replies_in_channel = WeeChatOption(
            self._section,
            "display_thread_replies_in_channel",
            "display thread replies in the parent channel; can be overridden per buffer with the buffer localvar display_thread_replies_in_channel; note that it only takes effect for new messages; note that due to limitations in the Slack API, on load only thread messages for parents that are in the buffer and thread messages in subscribed threads will be displayed (but all thread messages received while connected will be displayed)",
            False,
        )

        self.external_user_suffix = WeeChatOption(
            self._section,
            "external_user_suffix",
            "the suffix appended to nicks to indicate external users",
            "*",
        )

        self.leave_channel_on_buffer_close = WeeChatOption(
            self._section,
            "leave_channel_on_buffer_close",
            "leave channel when a buffer is closed",
            True,
        )

        self.muted_conversations_notify: WeeChatOption[
            Literal["none", "personal_highlights", "all_highlights", "all"]
        ] = WeeChatOption(
            self._section,
            "muted_conversations_notify",
            "notify level to set for messages in muted conversations; none: don't notify for any messages; personal_highlights: only notify for personal highlights, i.e. not @channel and @here; all_highlights: notify for all highlights, but not other messages; all: notify for all messages, like other channels; note that this doesn't affect messages in threads you are subscribed to or in open thread buffers, those will always notify",
            "personal_highlights",
            string_values=["none", "personal_highlights", "all_highlights", "all"],
        )

        self.part_closes_buffer = WeeChatOption(
            self._section,
            "part_closes_buffer",
            "close buffer when /slack part is issued on a channel",
            False,
            parent_option="irc.look.part_closes_buffer",
        )

        self.render_emoji_as: WeeChatOption[Literal["emoji", "name", "both"]] = (
            WeeChatOption(
                self._section,
                "render_emoji_as",
                "show emojis as: emoji = the emoji unicode character, name = the emoji name, both = both the emoji name and the emoji character",
                "emoji",
                string_values=["emoji", "name", "both"],
            )
        )

        self.render_url_as = WeeChatOption(
            self._section,
            "render_url_as",
            "format to render URLs (note: content is evaluated, see /help eval; ${url} is replaced by the URL link and ${text} is replaced by the URL text); the default format renders only the URL if the text is empty or is contained in the URL, otherwise it renders the text (underlined) first and then the URL in parentheses",
            "${if: ${text} == || ${url} =- ${text} ?${url}:${color:underline}${text}${color:-underline} (${url})}",
        )

        self.replace_space_in_nicks_with = WeeChatOption(
            self._section,
            "replace_space_in_nicks_with",
            "",
            "",
        )

        self.workspace_buffer: WeeChatOption[
            Literal["merge_with_core", "merge_without_core", "independent"]
        ] = WeeChatOption(
            self._section,
            "workspace_buffer",
            "merge workspace buffers; this option has no effect if a layout is saved and is conflicting with this value (see /help layout)",
            "merge_with_core",
            string_values=["merge_with_core", "merge_without_core", "independent"],
            parent_option="irc.look.server_buffer",
            callback_change=self.config_change_workspace_buffer_cb,
        )

        self.typing_status_nicks = WeeChatOption(
            self._section,
            "typing_status_nicks",
            'display nicks typing on the channel in bar item "typing" (option typing.look.enabled_nicks must be enabled)',
            True,
        )

        self.typing_status_self = WeeChatOption(
            self._section,
            "typing_status_self",
            "send self typing status to channels so that other users see when you are typing a message (option typing.look.enabled_self must be enabled)",
            True,
        )

        weechat.hook_config(
            "weechat.look.nick_color_*",
            get_callback_name(self.config_change_nick_colors_cb),
            "",
        )
        weechat.hook_config(
            "weechat.color.chat_nick_colors",
            get_callback_name(self.config_change_nick_colors_cb),
            "",
        )

    def config_change_color_nicks_in_nicklist_cb(
        self, option: WeeChatOption[WeeChatOptionType], parent_changed: bool
    ):
        invalidate_nicklists()

    def config_change_workspace_buffer_cb(
        self, option: WeeChatOption[WeeChatOptionType], parent_changed: bool
    ):
        for workspace in shared.workspaces.values():
            if workspace.buffer_pointer:
                weechat.buffer_unmerge(workspace.buffer_pointer, -1)

        buffer_to_merge_with = workspace_get_buffer_to_merge_with()
        if buffer_to_merge_with:
            for workspace in shared.workspaces.values():
                if (
                    workspace.buffer_pointer
                    and workspace.buffer_pointer != buffer_to_merge_with
                ):
                    weechat.buffer_merge(workspace.buffer_pointer, buffer_to_merge_with)

    def config_change_nick_colors_cb(self, data: str, option: str, value: str):
        invalidate_nicklists()
        return weechat.WEECHAT_RC_OK


class SlackConfigSectionWorkspace:
    def __init__(
        self,
        section: WeeChatSection,
        workspace_name: Optional[str],
        parent_config: Optional[SlackConfigSectionWorkspace],
    ):
        self._section = section
        self._workspace_name = workspace_name
        self._parent_config = parent_config

        self.api_token = self._create_option(
            "api_token",
            "The token (note: content is evaluated, see /help eval; workspace options are evaluated with ${workspace} replaced by the workspace name)",
            "",
            evaluate_func=self._evaluate_with_workspace_name,
        )

        self.api_cookies = self._create_option(
            "api_cookies",
            "The cookies (note: content is evaluated, see /help eval; workspace options are evaluated with ${workspace} replaced by the workspace name)",
            "",
            evaluate_func=self._evaluate_with_workspace_name,
        )

        self.autoconnect = self._create_option(
            "autoconnect",
            "automatically connect to workspace when WeeChat is starting",
            False,
        )

        self.network_timeout = self._create_option(
            "network_timeout",
            "timeout (in seconds) for network requests",
            30,
        )

        self.use_real_names = self._create_option(
            "use_real_names",
            "use real names as the nicks for all users. When this is"
            " false, display names will be used if set, with a fallback"
            " to the real name if display name is not set",
            False,
        )

    def _evaluate_with_workspace_name(self, value: str) -> str:
        return weechat.string_eval_expression(
            value, {}, {"workspace": self._workspace_name or ""}, {}
        )

    def _create_option(
        self,
        name: str,
        description: str,
        default_value: WeeChatOptionType,
        min_value: Optional[int] = None,
        max_value: Optional[int] = None,
        string_values: Optional[list[WeeChatOptionType]] = None,
        evaluate_func: Optional[
            Callable[[WeeChatOptionType], WeeChatOptionType]
        ] = None,
    ) -> WeeChatOption[WeeChatOptionType]:
        if self._workspace_name:
            option_name = f"{self._workspace_name}.{name}"
        else:
            option_name = name

        if self._parent_config:
            parent_option = getattr(self._parent_config, name, None)
        else:
            parent_option = None

        return WeeChatOption(
            self._section,
            option_name,
            description,
            default_value,
            min_value,
            max_value,
            string_values,
            parent_option,
            evaluate_func=evaluate_func,
        )


def config_section_workspace_read_cb(
    data: str, config_file: str, section: str, option_name: str, value: Optional[str]
) -> int:
    option_split = option_name.split(".", 1)
    if len(option_split) < 2:
        return weechat.WEECHAT_CONFIG_OPTION_SET_ERROR
    workspace_name, name = option_split
    if not workspace_name or not name:
        return weechat.WEECHAT_CONFIG_OPTION_SET_ERROR

    if workspace_name not in shared.workspaces:
        shared.workspaces[workspace_name] = SlackWorkspace(workspace_name)

    option = getattr(shared.workspaces[workspace_name].config, name, None)
    if option is None:
        return weechat.WEECHAT_CONFIG_OPTION_SET_OPTION_NOT_FOUND
    if not isinstance(option, WeeChatOption):
        return weechat.WEECHAT_CONFIG_OPTION_SET_ERROR

    if value is None or (
        shared.weechat_version < 0x03080000
        and value == ""
        and option.weechat_type != "string"
    ):
        rc = option.value_set_null()
    else:
        rc = option.value_set_as_str(value)
    if rc == weechat.WEECHAT_CONFIG_OPTION_SET_ERROR:
        print_error(f'error creating workspace option "{option_name}"')
    return rc


def config_section_workspace_write_for_old_weechat_cb(
    data: str, config_file: str, section_name: str
) -> int:
    if not weechat.config_write_line(config_file, section_name, ""):
        return weechat.WEECHAT_CONFIG_WRITE_ERROR

    for workspace in shared.workspaces.values():
        for option in vars(workspace.config).values():
            if isinstance(option, WeeChatOption):
                if option.weechat_type != "string" or not weechat.config_option_is_null(
                    option._pointer  # pyright: ignore [reportPrivateUsage]
                ):
                    if not weechat.config_write_option(
                        config_file,
                        option._pointer,  # pyright: ignore [reportPrivateUsage]
                    ):
                        return weechat.WEECHAT_CONFIG_WRITE_ERROR

    return weechat.WEECHAT_CONFIG_WRITE_OK


class SlackConfig:
    def __init__(self):
        self.weechat_config = WeeChatConfig("slack")
        self.color = SlackConfigSectionColor(self.weechat_config)
        self.look = SlackConfigSectionLook(self.weechat_config)
        self._section_workspace_default = WeeChatSection(
            self.weechat_config, "workspace_default"
        )
        # WeeChat < 3.8 sends null as an empty string to callback_read, so in
        # order to distinguish them, don't write the null values to the config
        # See https://github.com/weechat/weechat/pull/1843
        callback_write = (
            get_callback_name(config_section_workspace_write_for_old_weechat_cb)
            if shared.weechat_version < 0x03080000
            else ""
        )
        self._section_workspace = WeeChatSection(
            self.weechat_config,
            "workspace",
            callback_read=get_callback_name(config_section_workspace_read_cb),
            callback_write=callback_write,
        )
        self._workspace_default = SlackConfigSectionWorkspace(
            self._section_workspace_default, None, None
        )

    def config_read(self):
        weechat.config_read(self.weechat_config.pointer)

    def create_workspace_config(self, workspace_name: str):
        if workspace_name in shared.workspaces:
            raise Exception(
                f"Failed to create workspace config, already exists: {workspace_name}"
            )
        return SlackConfigSectionWorkspace(
            self._section_workspace, workspace_name, self._workspace_default
        )


if TYPE_CHECKING:
    pass
    pass

    pass


class HttpError(Exception):
    def __init__(
        self,
        url: str,
        options: Dict[str, str],
        return_code: Optional[int],
        http_status_code: Optional[int],
        error: str,
    ):
        super().__init__(
            f"{self.__class__.__name__}: url='{url}', return_code={return_code}, http_status_code={http_status_code}, error='{error}'"
        )
        self.url = url
        self.options = options
        self.return_code = return_code
        self.http_status_code = http_status_code
        self.error = error


class SlackApiError(Exception):
    def __init__(
        self,
        workspace: SlackWorkspace,
        method: str,
        response: SlackErrorResponse,
        request: object = None,
    ):
        super().__init__(
            f"{self.__class__.__name__}: workspace={workspace}, method='{method}', request={request}, response={response}"
        )
        self.workspace = workspace
        self.method = method
        self.request = request
        self.response = response


class SlackRtmError(Exception):
    def __init__(
        self,
        workspace: SlackWorkspace,
        exception: BaseException,
        message_json: SlackRtmMessage,
    ):
        super().__init__(
            f"{self.__class__.__name__}: workspace={workspace}, exception=`{format_exception_only_str(exception)}`"
        )
        super().with_traceback(exception.__traceback__)
        self.workspace = workspace
        self.exception = exception
        self.message_json = message_json


class SlackError(Exception):
    def __init__(
        self, workspace: SlackWorkspace, error: str, data: Optional[object] = None
    ):
        super().__init__(
            f"{self.__class__.__name__}: workspace={workspace}, error={error}"
        )
        self.workspace = workspace
        self.error = error
        self.data = data


@dataclass
class UncaughtError:
    id: str = field(init=False)
    exception: BaseException

    def __post_init__(self):
        self.id = str(uuid4())
        self.time = datetime.now()


def format_exception_only_str(exc: BaseException) -> str:
    return format_exception_only(exc)[-1].strip()


def store_uncaught_error(uncaught_error: UncaughtError) -> None:
    shared.uncaught_errors.append(uncaught_error)


def store_and_format_uncaught_error(uncaught_error: UncaughtError) -> str:
    store_uncaught_error(uncaught_error)
    e = uncaught_error.exception
    stack_msg_command = f"/slack debug error {uncaught_error.id}"
    stack_msg = f"run `{stack_msg_command}` for the stack trace"

    if isinstance(e, HttpError):
        return (
            f"Error calling URL {e.url}: return code: {e.return_code}, "
            f"http status code: {e.http_status_code}, error: {e.error} ({stack_msg})"
        )
    elif isinstance(e, SlackApiError):
        return (
            f"Error from Slack API method {e.method} with request {e.request} for workspace "
            f"{e.workspace.name}: {e.response} ({stack_msg})"
        )
    elif isinstance(e, SlackRtmError):
        return (
            f"Error while handling Slack event of type '{e.message_json['type']}' for workspace "
            f"{e.workspace.name}: {format_exception_only_str(e.exception)} ({stack_msg}, "
            f"run `{stack_msg_command} -data` for the event data)"
        )
    elif isinstance(e, SlackError):
        return (
            f"Error occurred in workspace {e.workspace.name}: {e.error} ({stack_msg})"
        )
    else:
        return f"Unknown error occurred: {format_exception_only_str(e)} ({stack_msg})"


def store_and_format_exception(e: BaseException) -> str:
    uncaught_error = UncaughtError(e)
    return store_and_format_uncaught_error(uncaught_error)


def available_file_descriptors():
    num_current_file_descriptors = len(os.listdir("/proc/self/fd/"))
    max_file_descriptors = min(resource.getrlimit(resource.RLIMIT_NOFILE))
    return max_file_descriptors - num_current_file_descriptors


async def hook_process_hashtable(
    command: str, options: Dict[str, str], timeout: int
) -> Tuple[str, int, str, str]:
    future = FutureProcess()
    log(
        LogLevel.DEBUG,
        DebugMessageType.LOG,
        f"hook_process_hashtable calling ({future.id}): command: {command}",
    )
    while available_file_descriptors() < 10:
        await sleep(100)
    weechat.hook_process_hashtable(
        command, options, timeout, get_callback_name(weechat_task_cb), future.id
    )

    stdout = StringIO()
    stderr = StringIO()
    return_code = -1

    while return_code == -1:
        next_future = FutureProcess(future.id)
        _, return_code, out, err = await next_future
        log(
            LogLevel.TRACE,
            DebugMessageType.LOG,
            f"hook_process_hashtable intermediary response ({next_future.id}): command: {command}",
        )
        stdout.write(out)
        stderr.write(err)

    out = stdout.getvalue()
    err = stderr.getvalue().strip()
    log(
        LogLevel.DEBUG,
        DebugMessageType.LOG,
        f"hook_process_hashtable response ({future.id}): command: {command}, "
        f"return_code: {return_code}, response length: {len(out)}"
        + (f", error: {err}" if err else ""),
    )

    return command, return_code, out, err


async def hook_url(
    url: str, options: Dict[str, str], timeout: int
) -> Tuple[str, Dict[str, str], Dict[str, str]]:
    future = FutureUrl()
    weechat.hook_url(
        url, options, timeout, get_callback_name(weechat_task_cb), future.id
    )
    return await future


async def http_request_process(
    url: str, options: Dict[str, str], timeout: int
) -> Tuple[int, str, str]:
    options["header"] = "1"
    _, return_code, out, err = await hook_process_hashtable(
        f"url:{url}", options, timeout
    )

    if return_code != 0 or err:
        raise HttpError(url, options, return_code, None, err)

    parts = out.split("\r\n\r\nHTTP/")
    headers, body = parts[-1].split("\r\n\r\n", 1)
    http_status = int(headers.split(None, 2)[1])
    return http_status, headers, body


async def http_request_url(
    url: str, options: Dict[str, str], timeout: int
) -> Tuple[int, str, str]:
    _, _, output = await hook_url(url, options, timeout)

    if "error" in output:
        raise HttpError(url, options, None, None, output["error"])

    if "response_code" not in output:
        raise HttpError(
            url,
            options,
            None,
            None,
            f"Unexpectedly missing response_code, output: {output}",
        )

    http_status = int(output["response_code"])
    header_parts = output["headers"].split("\r\n\r\nHTTP/")
    return http_status, header_parts[-1], output["output"]


async def http_request(
    url: str, options: Dict[str, str], timeout: int, max_retries: int = 5
) -> str:
    log(
        LogLevel.DEBUG,
        DebugMessageType.HTTP_REQUEST,
        f"requesting: {url}, {options.get('postfields')}",
    )
    try:
        if hasattr(weechat, "hook_url"):
            http_status, headers, body = await http_request_url(url, options, timeout)
        else:
            http_status, headers, body = await http_request_process(
                url, options, timeout
            )
    except HttpError as e:
        if max_retries > 0:
            log(
                LogLevel.INFO,
                DebugMessageType.LOG,
                f"HTTP error, retrying (max {max_retries} times): "
                f"return_code: {e.return_code}, error: {e.error}, url: {url}",
            )
            await sleep(1000)
            return await http_request(url, options, timeout, max_retries - 1)
        raise

    if http_status == 429:
        header_lines = headers.split("\r\n")
        for header in header_lines[1:]:
            name, value = header.split(":", 1)
            if name.lower() == "retry-after":
                retry_after = int(value.strip())
                log(
                    LogLevel.INFO,
                    DebugMessageType.LOG,
                    f"HTTP ratelimit, retrying in {retry_after} seconds, url: {url}",
                )
                await sleep(retry_after * 1000)
                return await http_request(url, options, timeout)

    if http_status >= 400:
        raise HttpError(url, options, None, http_status, body)

    return body


class LogLevel(IntEnum):
    TRACE = 1
    DEBUG = 2
    INFO = 3
    WARN = 4
    ERROR = 5
    FATAL = 6


class DebugMessageType(IntEnum):
    WEBSOCKET_SEND = 1
    WEBSOCKET_RECV = 2
    HTTP_REQUEST = 3
    LOG = 4


@dataclass
class DebugMessage:
    time: float
    level: LogLevel
    message_type: DebugMessageType
    message: str


debug_messages: List[DebugMessage] = []
printed_exceptions: Set[BaseException] = set()


# TODO: Figure out what to do with print_error vs log
def print_error(message: str):
    weechat.prnt("", f"{weechat.prefix('error')}{shared.SCRIPT_NAME}: {message}")


def print_exception_once(e: BaseException):
    if e not in printed_exceptions:
        print_error(store_and_format_exception(e))
        printed_exceptions.add(e)


def log(level: LogLevel, message_type: DebugMessageType, message: str):
    if level >= LogLevel.INFO:
        prefix = weechat.prefix("error") if level >= LogLevel.ERROR else "\t"
        weechat.prnt("", f"{prefix}{shared.SCRIPT_NAME} {level.name}: {message}")

    debug_message = DebugMessage(time.time(), level, message_type, message)
    debug_messages.append(debug_message)
    print_debug_buffer(debug_message)


def _close_debug_buffer_cb(data: str, buffer: str):
    shared.debug_buffer_pointer = None
    return weechat.WEECHAT_RC_OK


def open_debug_buffer():
    if shared.debug_buffer_pointer:
        weechat.buffer_set(shared.debug_buffer_pointer, "display", "1")
        return

    name = f"{shared.SCRIPT_NAME}.debug"
    shared.debug_buffer_pointer = weechat.buffer_new_props(
        name,
        {"display": "1"},
        "",
        "",
        get_callback_name(_close_debug_buffer_cb),
        "",
    )
    for message in debug_messages:
        print_debug_buffer(message)


def print_debug_buffer(debug_message: DebugMessage):
    if shared.debug_buffer_pointer:
        message = f"{debug_message.level.name} - {debug_message.message_type.name}\t{debug_message.message}"
        weechat.prnt_date_tags(
            shared.debug_buffer_pointer, int(debug_message.time), "", message
        )


class Proxy:
    @property
    def name(self):
        return weechat.config_string(weechat.config_get("weechat.network.proxy_curl"))

    @property
    def enabled(self):
        return bool(self.type)

    @property
    def _proxy_option_prefix(self):
        return f"weechat.proxy.{self.name}"

    @property
    def type(self):
        return weechat.config_string(
            weechat.config_get(f"{self._proxy_option_prefix}.type")
        )

    @property
    def address(self):
        return weechat.config_string(
            weechat.config_get(f"{self._proxy_option_prefix}.address")
        )

    @property
    def port(self):
        return weechat.config_integer(
            weechat.config_get(f"{self._proxy_option_prefix}.port")
        )

    @property
    def ipv6(self):
        return weechat.config_boolean(
            weechat.config_get(f"{self._proxy_option_prefix}.ipv6")
        )

    @property
    def username(self):
        return weechat.config_string(
            weechat.config_get(f"{self._proxy_option_prefix}.username")
        )

    @property
    def password(self):
        return weechat.config_string(
            weechat.config_get(f"{self._proxy_option_prefix}.password")
        )

    @property
    def curl_option(self):
        if not self.enabled:
            return ""

        user = (
            f"{self.username}:{self.password}@"
            if self.username and self.password
            else ""
        )
        return f"-x{self.type}://{user}{self.address}:{self.port}"


SCRIPT_AUTHOR = "Trygve Aaberge <trygveaa@gmail.com>"
SCRIPT_LICENSE = "MIT"
SCRIPT_DESC = "Extends weechat for typing notification/search/etc on slack.com"


def shutdown_cb():
    shared.script_is_unloading = True
    weechat.config_write(shared.config.weechat_config.pointer)
    return weechat.WEECHAT_RC_OK


def signal_buffer_switch_cb(data: str, signal: str, buffer_pointer: str) -> int:
    prev_buffer_pointer = shared.current_buffer_pointer
    shared.current_buffer_pointer = buffer_pointer

    if prev_buffer_pointer != buffer_pointer:
        prev_slack_buffer = shared.buffers.get(prev_buffer_pointer)
        if isinstance(prev_slack_buffer, SlackMessageBuffer):
            run_async(prev_slack_buffer.mark_read())

    slack_buffer = shared.buffers.get(buffer_pointer)
    if isinstance(slack_buffer, SlackMessageBuffer):
        run_async(slack_buffer.buffer_switched_to())

    return weechat.WEECHAT_RC_OK


def input_text_changed_cb(data: str, signal: str, buffer_pointer: str) -> int:
    reset_completion_context_on_input(buffer_pointer)
    return weechat.WEECHAT_RC_OK


def input_text_cursor_moved_cb(data: str, signal: str, buffer_pointer: str) -> int:
    reset_completion_context_on_input(buffer_pointer)
    return weechat.WEECHAT_RC_OK


def reset_completion_context_on_input(buffer_pointer: str):
    slack_buffer = shared.buffers.get(buffer_pointer)
    if (
        isinstance(slack_buffer, SlackMessageBuffer)
        and slack_buffer.completion_context != "IN_PROGRESS_COMPLETION"
    ):
        slack_buffer.completion_context = "NO_COMPLETION"


def modifier_input_text_display_with_cursor_cb(
    data: str, modifier: str, buffer_pointer: str, string: str
) -> str:
    prefix = ""
    slack_buffer = shared.buffers.get(buffer_pointer)
    if slack_buffer:
        input_delim_color = weechat.config_string(
            weechat.config_get("weechat.bar.input.color_delim")
        )
        input_delim_start = with_color(input_delim_color, "[")
        input_delim_end = with_color(input_delim_color, "]")
        if (
            not slack_buffer.workspace.is_connected
            and not slack_buffer.workspace.is_connecting
        ):
            prefix += (
                f"{input_delim_start}"
                f"{with_color(shared.config.color.disconnected.value, 'disconnected')}"
                f"{input_delim_end} "
            )
        if (
            slack_buffer.workspace.is_connecting
            or isinstance(slack_buffer, SlackMessageBuffer)
            and slack_buffer.is_loading
        ):
            text = "connecting" if slack_buffer.workspace.is_connecting else "loading"
            prefix += (
                f"{input_delim_start}"
                f"{with_color(shared.config.color.loading.value, text)}"
                f"{input_delim_end} "
            )
    return prefix + string


def typing_self_cb(data: str, signal: str, signal_data: str) -> int:
    if not shared.config.look.typing_status_self or signal != "typing_self_typing":
        return weechat.WEECHAT_RC_OK

    slack_buffer = shared.buffers.get(signal_data)
    if isinstance(slack_buffer, SlackMessageBuffer):
        slack_buffer.set_typing_self()
    return weechat.WEECHAT_RC_OK


def ws_ping_cb(data: str, remaining_calls: int) -> int:
    for workspace in shared.workspaces.values():
        if workspace.is_connected:
            workspace.ping()
    return weechat.WEECHAT_RC_OK


async def init_async():
    auto_connect = weechat.info_get("auto_connect", "") == "1"
    if auto_connect:
        await sleep(1)  # Defer auto connect to ensure the logger plugin is loaded
        for workspace in shared.workspaces.values():
            if workspace.config.autoconnect:
                run_async(workspace.connect())


def register():
    if weechat.register(
        shared.SCRIPT_NAME,
        SCRIPT_AUTHOR,
        shared.SCRIPT_VERSION,
        SCRIPT_LICENSE,
        SCRIPT_DESC,
        get_callback_name(shutdown_cb),
        "",
    ):
        shared.weechat_version = int(weechat.info_get("version_number", "") or 0)
        shared.current_buffer_pointer = weechat.current_buffer()
        shared.standard_emojis = load_standard_emojis()
        shared.standard_emojis_inverse = {
            value["unicode"]: value for value in shared.standard_emojis.values()
        }
        shared.workspaces = {}
        shared.config = SlackConfig()
        shared.config.config_read()
        register_completions()
        register_commands()

        weechat.hook_signal(
            "buffer_switch", get_callback_name(signal_buffer_switch_cb), ""
        )
        weechat.hook_signal(
            "input_text_changed", get_callback_name(input_text_changed_cb), ""
        )
        weechat.hook_signal(
            "input_text_cursor_moved", get_callback_name(input_text_cursor_moved_cb), ""
        )
        weechat.hook_modifier(
            "100|input_text_display_with_cursor",
            get_callback_name(modifier_input_text_display_with_cursor_cb),
            "",
        )
        weechat.hook_signal("typing_self_*", get_callback_name(typing_self_cb), "")
        weechat.hook_timer(5000, 0, 0, get_callback_name(ws_ping_cb), "")

        run_async(init_async())


if TYPE_CHECKING:
    pass
    pass
    pass
    pass
    pass
    pass
    pass
    pass
    pass
    pass
    pass
    pass
    pass
    pass
    pass
    pass
    pass
    pass
    pass
    pass
    pass
    pass
    pass
    pass

    pass
    pass

Params = Mapping[str, Union[str, int, bool]]
EdgeParams = Mapping[
    str, Union[str, int, bool, Sequence[str], Sequence[int], Sequence[bool]]
]


class SlackApiCommon:
    def __init__(self, workspace: SlackWorkspace):
        self.workspace = workspace

    def _get_request_options(self):
        return {
            "useragent": f"wee_slack {shared.SCRIPT_VERSION}",
            "httpheader": f"Authorization: Bearer {self.workspace.config.api_token.value}",
            "cookie": get_cookies(self.workspace.config.api_cookies.value),
        }


class SlackEdgeApi(SlackApiCommon):
    @property
    def is_available(self) -> bool:
        return self.workspace.token_type == "session"

    async def _fetch_edgeapi(self, method: str, params: EdgeParams = {}):
        id_for_path = self.workspace.enterprise_id or self.workspace.id
        url = f"https://edgeapi.slack.com/cache/{id_for_path}/{method}"
        options = self._get_request_options()
        options["postfields"] = json.dumps(params)
        options["httpheader"] += "\nContent-Type: application/json"
        response = await http_request(
            url,
            options,
            self.workspace.config.network_timeout.value * 1000,
        )
        return json.loads(response)

    async def fetch_usergroups_info(self, usergroup_ids: Sequence[str]):
        method = "usergroups/info"
        params: EdgeParams = {"ids": usergroup_ids}
        response: SlackEdgeUsergroupsInfoResponse = await self._fetch_edgeapi(
            method, params
        )
        if response["ok"] is False:
            raise SlackApiError(self.workspace, method, response, params)
        return response

    async def fetch_users_search(self, query: str):
        method = "users/search"
        params: EdgeParams = {
            "include_profile_only_users": True,
            "query": query,
            "count": 25,
            "fuzz": 1,
            "uax29_tokenizer": False,
            "filter": "NOT deactivated",
        }
        response: SlackUsersSearchResponse = await self._fetch_edgeapi(method, params)
        if response["ok"] is False:
            raise SlackApiError(self.workspace, method, response, params)
        return response

    async def fetch_channels_search(self, query: str):
        method = "channels/search"
        params: EdgeParams = {
            "query": query,
            "count": 25,
            "fuzz": 1,
            "uax29_tokenizer": False,
            "filter": "xws",
            "include_record_channels": True,
            "check_membership": True,
        }
        response: SlackChannelsSearchResponse = await self._fetch_edgeapi(
            method, params
        )
        if response["ok"] is False:
            raise SlackApiError(self.workspace, method, response, params)
        return response


class SlackApi(SlackApiCommon):
    def __init__(self, workspace: SlackWorkspace):
        super().__init__(workspace)
        self.edgeapi = SlackEdgeApi(workspace)

    async def _fetch(self, method: str, params: Params = {}):
        url = f"https://api.slack.com/api/{method}"
        options = self._get_request_options()
        options["postfields"] = urlencode(params)
        response = await http_request(
            url,
            options,
            self.workspace.config.network_timeout.value * 1000,
        )
        return json.loads(response)

    async def _fetch_list(
        self,
        method: str,
        list_key: str,
        params: Params = {},
        limit: Optional[int] = None,
    ):
        cur_limit = 1000 if limit is None or limit > 1000 else limit
        response = await self._fetch(method, {**params, "limit": cur_limit})
        remaining = limit - cur_limit if limit is not None else None
        next_cursor = response.get("response_metadata", {}).get("next_cursor")
        if (remaining is None or remaining > 0) and next_cursor and response["ok"]:
            new_params = {**params, "cursor": next_cursor}
            next_pages = await self._fetch_list(method, list_key, new_params, remaining)
            response[list_key].extend(next_pages[list_key])
            return response
        return response

    async def _post(self, method: str, body: Mapping[str, object]):
        url = f"https://api.slack.com/api/{method}"
        options = self._get_request_options()
        options["httpheader"] += "\nContent-Type: application/json"
        options["postfields"] = json.dumps(body)
        response = await http_request(
            url,
            options,
            self.workspace.config.network_timeout.value * 1000,
        )
        return json.loads(response)

    async def fetch_team_info(self):
        method = "team.info"
        response: SlackTeamInfoResponse = await self._fetch(method)
        if response["ok"] is False:
            raise SlackApiError(self.workspace, method, response)
        return response

    async def fetch_rtm_connect(self):
        method = "rtm.connect"
        response: SlackRtmConnectResponse = await self._fetch(method)
        if response["ok"] is False:
            raise SlackApiError(self.workspace, method, response)
        return response

    async def fetch_users_get_prefs(self, prefs: Optional[str] = None):
        method = "users.prefs.get"
        params: Params = {"prefs": prefs} if prefs else {}
        response: SlackUsersPrefsGetResponse = await self._fetch(method, params)
        if response["ok"] is False:
            raise SlackApiError(self.workspace, method, response)
        return response

    async def fetch_conversations_history(self, conversation: SlackConversation):
        method = "conversations.history"
        params: Params = {"channel": conversation.id}
        response: SlackConversationsHistoryResponse = await self._fetch(method, params)
        if response["ok"] is False:
            raise SlackApiError(self.workspace, method, response, params)
        return response

    async def fetch_conversations_history_after(
        self, conversation: SlackConversation, after: SlackTs
    ):
        method = "conversations.history"
        params: Params = {
            "channel": conversation.id,
            "oldest": after,
            "inclusive": False,
        }
        response: SlackConversationsHistoryResponse = await self._fetch_list(
            method, "messages", params
        )
        if response["ok"] is False:
            raise SlackApiError(self.workspace, method, response, params)
        return response

    async def fetch_conversations_replies(
        self, conversation: SlackConversation, parent_message_ts: SlackTs
    ):
        method = "conversations.replies"
        params: Params = {
            "channel": conversation.id,
            "ts": parent_message_ts,
        }
        response: SlackConversationsRepliesResponse = await self._fetch_list(
            method, "messages", params
        )
        if response["ok"] is False:
            raise SlackApiError(self.workspace, method, response, params)
        return response

    async def fetch_conversations_info(self, conversation_id: str):
        method = "conversations.info"
        params: Params = {"channel": conversation_id}
        response: SlackConversationsInfoResponse = await self._fetch(method, params)
        if response["ok"] is False:
            raise SlackApiError(self.workspace, method, response, params)
        return response

    async def fetch_conversations_members(
        self,
        conversation: SlackConversation,
        limit: Optional[int] = None,
    ):
        method = "conversations.members"
        params: Params = {"channel": conversation.id}
        response: SlackConversationsMembersResponse = await self._fetch_list(
            method, "members", params, limit
        )
        if response["ok"] is False:
            raise SlackApiError(self.workspace, method, response, params)
        return response

    async def fetch_conversations_list_public(
        self,
        exclude_archived: bool = True,
        limit: Optional[int] = 1000,
    ):
        method = "conversations.list"
        params: Params = {
            "exclude_archived": exclude_archived,
            "types": "public_channel",
        }
        response: SlackConversationsListPublicResponse = await self._fetch_list(
            method, "chanels", params, limit
        )
        if response["ok"] is False:
            raise SlackApiError(self.workspace, method, response, params)
        return response

    async def fetch_users_conversations(
        self,
        types: str,
        exclude_archived: bool = True,
        limit: Optional[int] = None,
    ):
        method = "users.conversations"
        params: Params = {
            "types": types,
            "exclude_archived": exclude_archived,
        }
        response: SlackUsersConversationsResponse = await self._fetch_list(
            method,
            "channels",
            params,
            limit,
        )
        if response["ok"] is False:
            raise SlackApiError(self.workspace, method, response, params)
        return response

    async def fetch_user_info(self, user_id: str):
        method = "users.info"
        params: Params = {"user": user_id}
        response: SlackUserInfoResponse = await self._fetch(method, params)
        if response["ok"] is False:
            raise SlackApiError(self.workspace, method, response, params)
        return response

    async def _fetch_users_info_without_splitting(self, user_ids: Iterable[str]):
        method = "users.info"
        params: Params = {"users": ",".join(user_ids)}
        response: SlackUsersInfoResponse = await self._fetch(method, params)
        if response["ok"] is False:
            raise SlackApiError(self.workspace, method, response, params)
        return response

    async def fetch_users_info(
        self, user_ids: Iterable[str]
    ) -> SlackUsersInfoSuccessResponse[SlackUserInfo]:
        responses = await gather(
            *(
                self._fetch_users_info_without_splitting(user_ids_batch)
                for user_ids_batch in chunked(
                    user_ids, self.workspace.max_users_per_fetch_request
                )
            ),
            return_exceptions=True,
        )

        errors = [r for r in responses if isinstance(r, BaseException)]
        if errors:
            if (
                any(
                    # The users.info method may respond with 500 if we request too many users in one request
                    (isinstance(e, HttpError) and e.http_status_code == 500)
                    or (
                        isinstance(e, SlackApiError)
                        and e.response["error"] == "too_many_users"
                    )
                    for e in errors
                )
                and self.workspace.max_users_per_fetch_request > 1
            ):
                self.workspace.max_users_per_fetch_request //= 2
                return await self.fetch_users_info(user_ids)
            else:
                raise errors[0]

        success_responses = [r for r in responses if not isinstance(r, BaseException)]
        users = list(chain(*(response["users"] for response in success_responses)))
        response: SlackUsersInfoResponse = {"ok": True, "users": users}
        return response

    async def fetch_bot_info(self, bot_id: str):
        method = "bots.info"
        params: Params = {"bot": bot_id}
        response: SlackBotInfoResponse = await self._fetch(method, params)
        if response["ok"] is False:
            raise SlackApiError(self.workspace, method, response, params)
        return response

    async def fetch_bots_info(self, bot_ids: Iterable[str]):
        method = "bots.info"
        params: Params = {"bots": ",".join(bot_ids)}
        response: SlackBotsInfoResponse = await self._fetch(method, params)
        if response["ok"] is False:
            raise SlackApiError(self.workspace, method, response, params)
        return response

    async def fetch_usergroups_list(self, include_users: bool):
        method = "usergroups.list"
        params: Params = {"include_users": include_users}
        response: SlackUsergroupsInfoResponse = await self._fetch(method, params)
        if response["ok"] is False:
            raise SlackApiError(self.workspace, method, response)
        return response

    async def fetch_files_info(self, file_id: str):
        method = "files.info"
        params: Params = {"file": file_id}
        response: SlackFilesInfoResponse = await self._fetch(method, params)
        if response["ok"] is False:
            raise SlackApiError(self.workspace, method, response)
        return response

    async def fetch_emoji_list(self):
        method = "emoji.list"
        response: SlackEmojiListResponse = await self._fetch(method)
        if response["ok"] is False:
            raise SlackApiError(self.workspace, method, response)
        return response

    async def fetch_client_userboot(self):
        method = "client.userBoot"
        response: SlackClientUserbootResponse = await self._fetch(method)
        if response["ok"] is False:
            raise SlackApiError(self.workspace, method, response)
        return response

    async def fetch_client_counts(self):
        method = "client.counts"
        response: SlackClientCountsResponse = await self._fetch(method)
        if response["ok"] is False:
            raise SlackApiError(self.workspace, method, response)
        return response

    async def conversations_open(self, user_ids: Iterable[str]):
        method = "conversations.open"
        params: Params = {"users": ",".join(user_ids), "return_im": True}
        response: SlackConversationsOpenResponse = await self._fetch(method, params)
        if response["ok"] is False:
            raise SlackApiError(self.workspace, method, response, params)
        return response

    async def conversations_join(self, conversation_id: str):
        method = "conversations.join"
        params: Params = {"channel": conversation_id}
        response: SlackConversationsJoinResponse = await self._fetch(method, params)
        if response["ok"] is False:
            raise SlackApiError(self.workspace, method, response, params)
        return response

    async def conversations_close(self, conversation: SlackConversation):
        method = "conversations.close"
        params: Params = {"channel": conversation.id}
        response: SlackGenericResponse = await self._fetch(method, params)
        if response["ok"] is False:
            raise SlackApiError(self.workspace, method, response, params)
        return response

    async def conversations_leave(self, conversation: SlackConversation):
        method = "conversations.leave"
        params: Params = {"channel": conversation.id}
        response: SlackGenericResponse = await self._fetch(method, params)
        if response["ok"] is False:
            raise SlackApiError(self.workspace, method, response, params)
        return response

    async def conversations_mark(self, conversation: SlackConversation, ts: SlackTs):
        method = "conversations.mark"
        params: Params = {"channel": conversation.id, "ts": ts}
        response: SlackGenericResponse = await self._fetch(method, params)
        if response["ok"] is False:
            raise SlackApiError(self.workspace, method, response, params)
        return response

    async def subscriptions_thread_mark(
        self, conversation: SlackConversation, thread_ts: SlackTs, ts: SlackTs
    ):
        method = "subscriptions.thread.mark"
        params: Params = {
            "channel": conversation.id,
            "thread_ts": thread_ts,
            "ts": ts,
            "read": 1,
        }
        response: SlackGenericResponse = await self._fetch(method, params)
        if response["ok"] is False:
            raise SlackApiError(self.workspace, method, response, params)
        return response

    async def chat_post_message(
        self,
        conversation: SlackConversation,
        text: str,
        thread_ts: Optional[SlackTs] = None,
        broadcast: bool = False,
    ):
        method = "chat.postMessage"
        params: Params = {
            "channel": conversation.id,
            "text": text,
            "as_user": True,
            "link_names": True,
        }
        if thread_ts is not None:
            params["thread_ts"] = thread_ts
            params["reply_broadcast"] = broadcast
        response: SlackGenericResponse = await self._fetch(method, params)
        if response["ok"] is False:
            raise SlackApiError(self.workspace, method, response, params)
        return response

    async def chat_update_message(
        self,
        conversation: SlackConversation,
        ts: SlackTs,
        text: str,
    ):
        method = "chat.update"
        params: Params = {
            "channel": conversation.id,
            "ts": ts,
            "text": text,
            "as_user": True,
            "link_names": True,
        }
        response: SlackGenericResponse = await self._fetch(method, params)
        if response["ok"] is False:
            raise SlackApiError(self.workspace, method, response, params)
        return response

    async def chat_delete_message(self, conversation: SlackConversation, ts: SlackTs):
        method = "chat.delete"
        params: Params = {
            "channel": conversation.id,
            "ts": ts,
            "as_user": True,
        }
        response: SlackGenericResponse = await self._fetch(method, params)
        if response["ok"] is False:
            raise SlackApiError(self.workspace, method, response, params)
        return response

    async def reactions_change(
        self,
        conversation: SlackConversation,
        ts: SlackTs,
        name: str,
        change_type: Literal["+", "-"],
    ):
        method = (
            "reactions.add"
            if change_type == "+"
            else "reactions.remove"
            if change_type == "-"
            else assert_never(change_type)
        )
        params: Params = {
            "channel": conversation.id,
            "timestamp": ts,
            "name": name,
        }
        response: SlackGenericResponse = await self._fetch(method, params)
        if response["ok"] is False:
            raise SlackApiError(self.workspace, method, response, params)
        return response

    async def set_presence(self, presence: Literal["active", "away"]):
        method = "presence.set"
        params: Params = {"presence": presence}
        response: SlackGenericResponse = await self._fetch(method, params)
        if response["ok"] is False:
            raise SlackApiError(self.workspace, method, response, params)
        return response

    async def set_muted_channels(self, channel_ids: Iterable[str]):
        method = "users.prefs.set"
        params: Params = {"name": "muted_channels", "value": ",".join(channel_ids)}
        response: SlackGenericResponse = await self._fetch(method, params)
        if response["ok"] is False:
            raise SlackApiError(self.workspace, method, response, params)
        return response

    async def _set_user_profile(self, profile: SlackSetProfile):
        method = "users.profile.set"
        body = {"profile": profile}
        response: SlackUsersProfileSetResponse = await self._post(method, body)
        if response["ok"] is False:
            raise SlackApiError(self.workspace, method, response, body)
        return response

    async def set_user_status(self, status: str):
        return await self._set_user_profile({"status_text": status})

    async def clear_user_status(self):
        return await self._set_user_profile({"status_emoji": "", "status_text": ""})


if TYPE_CHECKING:
    pass
    pass
    pass
    pass
    pass

    pass

    SlackConversationsInfoInternal = Union[
        SlackConversationsInfo, SlackUsersConversationsNotIm, SlackClientUserbootIm
    ]


def update_buffer_props():
    for workspace in shared.workspaces.values():
        for conversation in workspace.open_conversations.values():
            conversation.update_buffer_props()


def invalidate_nicklists():
    for workspace in shared.workspaces.values():
        for conversation in workspace.open_conversations.values():
            conversation.nicklist_needs_refresh = True


async def create_conversation_for_users(
    workspace: SlackWorkspace, user_ids: Iterable[str]
):
    conversation_open_response = await workspace.api.conversations_open(user_ids)
    conversation_id = conversation_open_response["channel"]["id"]
    workspace.conversations.initialize_items(
        [conversation_id], {conversation_id: conversation_open_response["channel"]}
    )
    conversation = await workspace.conversations[conversation_id]
    await conversation.open_buffer(switch=True)


def sha1_hex(string: str) -> str:
    return str(hashlib.sha1(string.encode()).hexdigest())


def hash_from_ts(ts: SlackTs) -> str:
    return sha1_hex(str(ts))


class SlackConversationMessageHashes(Dict[SlackTs, str]):
    def __init__(self, conversation: SlackConversation):
        super().__init__()
        self._conversation = conversation
        self._inverse_map: Dict[str, SlackTs] = {}

    def __setitem__(self, key: SlackTs, value: str) -> NoReturn:
        raise RuntimeError("Set from outside isn't allowed")

    def __delitem__(self, key: SlackTs) -> None:
        if key in self:
            hash_key = self[key]
            del self._inverse_map[hash_key]
        super().__delitem__(key)

    def _setitem(self, key: SlackTs, value: str) -> None:
        super().__setitem__(key, value)

    def __missing__(self, key: SlackTs) -> str:
        hash_len = 3
        full_hash = hash_from_ts(key)
        short_hash = full_hash[:hash_len]

        while any(
            existing_hash.startswith(short_hash) for existing_hash in self._inverse_map
        ):
            hash_len += 1
            short_hash = full_hash[:hash_len]

        if short_hash[:-1] in self._inverse_map:
            ts_with_same_hash = self._inverse_map.pop(short_hash[:-1])
            other_full_hash = hash_from_ts(ts_with_same_hash)
            other_short_hash = other_full_hash[:hash_len]

            while short_hash == other_short_hash:
                hash_len += 1
                short_hash = full_hash[:hash_len]
                other_short_hash = other_full_hash[:hash_len]

            self._setitem(ts_with_same_hash, other_short_hash)
            self._inverse_map[other_short_hash] = ts_with_same_hash

            other_message = self._conversation.messages.get(ts_with_same_hash)
            if other_message:
                run_async(self._conversation.rerender_message(other_message))
                if other_message.thread_buffer is not None:
                    other_message.thread_buffer.update_buffer_props()
                for reply in other_message.replies.values():
                    run_async(self._conversation.rerender_message(reply))

        self._setitem(key, short_hash)
        self._inverse_map[short_hash] = key
        return self[key]

    def get_ts(self, ts_hash: str) -> Optional[SlackTs]:
        hash_without_prefix = removeprefix(ts_hash, "$")
        return self._inverse_map.get(hash_without_prefix)


class SlackConversation(SlackMessageBuffer):
    async def __new__(
        cls,
        workspace: SlackWorkspace,
        info: SlackConversationsInfoInternal,
    ):
        conversation = super().__new__(cls)
        conversation.__init__(workspace, info)
        return await conversation

    def __init__(
        self,
        workspace: SlackWorkspace,
        info: SlackConversationsInfoInternal,
    ):
        super().__init__()
        self._workspace = workspace
        self._info = info
        self._is_joined: bool = False
        self._members: Optional[List[str]] = None
        self._im_user: Optional[SlackUser] = None
        self._mpim_users: Optional[List[SlackUser]] = None
        self._messages: OrderedDict[SlackTs, SlackMessage] = OrderedDict()
        self._nicklist: Dict[Nick, str] = {}
        self.nicklist_needs_refresh = True
        self.message_hashes = SlackConversationMessageHashes(self)

        self._last_read = (
            SlackTs(self._info["last_read"])
            if "last_read" in self._info
            else SlackTs("0.0")
        )

        self._topic: SlackTopic = (
            self._info["topic"]
            if "topic" in self._info
            else {"value": "", "creator": "", "last_set": 0}
        )

    async def __init_async(self):
        if self._info["is_im"] is True:
            self._im_user = await self._workspace.users[self._info["user"]]
        elif self.type == "mpim":
            if "members" in self._info:
                members = self._info["members"]
            else:
                members = await self.load_members(load_all=True)

            self._mpim_users = await gather(
                *(
                    self._workspace.users[user_id]
                    for user_id in members
                    if user_id != self._workspace.my_user.id
                )
            )

    def __await__(self: _T) -> Generator[Task[None], None, _T]:
        yield from self.__init_async().__await__()
        return self

    @classmethod
    async def create(
        cls: Type[_T], workspace: SlackWorkspace, conversation_id: str
    ) -> _T:
        info_response = await workspace.api.fetch_conversations_info(conversation_id)
        return await cls(workspace, info_response["channel"])

    def __repr__(self):
        return f"{self.__class__.__name__}({self.workspace}, {self.id})"

    @property
    def id(self) -> str:
        return self._info["id"]

    @property
    def workspace(self) -> SlackWorkspace:
        return self._workspace

    @property
    def conversation(self) -> SlackConversation:
        return self

    @property
    def context(self) -> MessageContext:
        return "conversation"

    @property
    def is_joined(self) -> bool:
        return self._is_joined

    @property
    def members(self) -> Generator[Nick, None, None]:
        for nick in self._nicklist:
            if nick.type == "user":
                yield nick

    @property
    def messages(self) -> Mapping[SlackTs, SlackMessage]:
        return self._messages

    @property
    def type(self) -> Literal["channel", "private", "mpim", "im"]:
        if self._info["is_im"] is True:
            return "im"
        elif self._info["is_mpim"] is True:
            return "mpim"
        elif self._info["is_private"] is True:
            return "private"
        else:
            return "channel"

    @property
    def buffer_type(self) -> Literal["private", "channel"]:
        return "private" if self.type in ("im", "mpim") else "channel"

    @property
    def last_read(self) -> SlackTs:
        return self._last_read

    @last_read.setter
    def last_read(self, value: SlackTs):
        self._last_read = value
        self.set_unread_and_hotlist()

    @property
    def muted(self) -> bool:
        return self.id in self.workspace.muted_channels

    @property
    def im_user_id(self) -> Optional[str]:
        if self.type == "im":
            return self._info.get("user")

    def _add_or_update_message(self, message: SlackMessage):
        if message.ts in self._messages:
            self._messages[message.ts].update_message_json(message.message_json)
        else:
            self._messages[message.ts] = message

    def sort_key(self) -> str:
        type_sort_key = {
            "channel": 0,
            "private": 1,
            "mpim": 2,
            "im": 3,
        }[self.type]
        return f"{type_sort_key}{self.name()}".lower()

    def name(self) -> str:
        if self._im_user is not None:
            return self._im_user.nick.format()
        elif self._info["is_im"] is True:
            raise SlackError(self.workspace, "IM conversation without _im_user set")
        elif self._mpim_users is not None:
            return ",".join(sorted(user.nick.format() for user in self._mpim_users))
        else:
            return self._info["name"]

    def name_prefix(
        self,
        name_type: Literal["full_name", "short_name", "short_name_without_padding"],
    ) -> str:
        if self.type == "im":
            if name_type == "short_name":
                return " "
            else:
                return ""
        elif self.type == "mpim":
            if name_type == "short_name" or name_type == "short_name_without_padding":
                return "@"
            else:
                return ""
        elif self.type == "private":
            return "&"
        else:
            return "#"

    def name_with_prefix(
        self,
        name_type: Literal["full_name", "short_name", "short_name_without_padding"],
    ) -> str:
        return f"{self.name_prefix(name_type)}{self.name()}"

    def should_open(self):
        if "is_open" in self._info:
            if self._info["is_open"]:
                return True
        elif self._info.get("is_member"):
            return True
        return False

    def buffer_title(self) -> str:
        # TODO: unfurl and apply styles
        topic = unhtmlescape(self._topic["value"])
        if self._im_user:
            status = f"{self._im_user.status_emoji} {self._im_user.status_text}".strip()
            parts = [self._im_user.real_name, status, topic]
            return " | ".join(part for part in parts if part)
        return topic

    def set_topic(self, title: str):
        self._topic["value"] = title
        self.update_buffer_props()

    def get_name_and_buffer_props(self) -> Tuple[str, Dict[str, str]]:
        name_without_prefix = self.name()
        name = f"{self.name_prefix('full_name')}{name_without_prefix}"
        short_name = self.name_prefix("short_name") + name_without_prefix
        if self.muted:
            short_name = with_color(
                shared.config.color.buflist_muted_conversation.value, short_name
            )

        im_localvars = (
            {
                "localvar_set_user_status_emoji": self._im_user.status_emoji,
                "localvar_set_user_status_text": self._im_user.status_text,
            }
            if self._im_user
            else {}
        )

        return name, {
            "short_name": short_name,
            "title": self.buffer_title(),
            "input_prompt": self.workspace.my_user.nick.raw_nick,
            "input_multiline": "1",
            "nicklist": "0" if self.type == "im" else "1",
            "nicklist_display_groups": "0",
            "localvar_set_type": self.buffer_type,
            "localvar_set_slack_type": self.type,
            "localvar_set_nick": self.workspace.my_user.nick.raw_nick,
            "localvar_set_channel": name,
            "localvar_set_server": self.workspace.name,
            "localvar_set_workspace": self.workspace.name,
            "localvar_set_slack_muted": "1" if self.muted else "0",
            "localvar_set_completion_default_template": "${weechat.completion.default_template}|%(slack_channels)|%(slack_emojis)",
            **im_localvars,
        }

    async def buffer_switched_to(self):
        await super().buffer_switched_to()
        await gather(self.nicklist_update(), self.fill_history())

    async def open_buffer(self, switch: bool = False):
        await super().open_buffer(switch)
        self._is_joined = True
        self.workspace.open_conversations[self.id] = self

    async def rerender_message(self, message: SlackMessage):
        await super().rerender_message(message)
        parent_message = message.parent_message
        if parent_message and parent_message.thread_buffer:
            await parent_message.thread_buffer.rerender_message(message)

    async def load_members(self, load_all: bool = False):
        if self._members is None:
            members_response = await self.api.fetch_conversations_members(
                self, limit=None if load_all else 1000
            )
            self._members = members_response["members"]
        self.workspace.users.initialize_items(self._members)
        return self._members

    async def fetch_replies(self, thread_ts: SlackTs) -> List[SlackMessage]:
        replies_response = await self.api.fetch_conversations_replies(self, thread_ts)
        messages = [
            SlackMessage(self, message) for message in replies_response["messages"]
        ]

        if thread_ts != messages[0].ts:
            raise SlackError(
                self.workspace,
                f"First message in conversations.replies response did not match thread_ts {thread_ts}",
                replies_response,
            )

        self._add_or_update_message(messages[0])
        parent_message = self._messages[thread_ts]

        replies = messages[1:]
        parent_message.replies_tss = [message.ts for message in replies]
        for reply in replies:
            self._add_or_update_message(reply)

        self._messages = OrderedDict(sorted(self._messages.items()))

        parent_message.reply_history_filled = True
        return replies

    async def set_hotlist(self):
        if self.last_printed_ts is not None:
            self.history_needs_refresh = True

        if self.buffer_pointer and shared.current_buffer_pointer == self.buffer_pointer:
            await self.fill_history()
            return

        if self.last_printed_ts is not None:
            history_after_ts = (
                next(iter(self._messages))
                if self.display_thread_replies()
                else self.last_printed_ts
            )
            history = await self.api.fetch_conversations_history_after(
                self, history_after_ts
            )
        else:
            history = await self.api.fetch_conversations_history(self)

        if self.buffer_pointer and shared.current_buffer_pointer != self.buffer_pointer:
            for message_json in history["messages"]:
                message = SlackMessage(self, message_json)
                if message.ts > self.last_read and message.ts not in self.hotlist_tss:
                    priority = message.priority(self.context).value
                    weechat.buffer_set(self.buffer_pointer, "hotlist", priority)
                    self.hotlist_tss.add(message.ts)
                if (
                    self.display_thread_replies()
                    and (
                        not message.muted
                        or shared.config.look.muted_conversations_notify.value == "all"
                    )
                    and message.latest_reply
                    and message.latest_reply > self.last_read
                    and message.latest_reply not in self.hotlist_tss
                ):
                    # TODO: Load subscribed threads, so they are added to hotlist for muted channels if they have highlights
                    priority = (
                        MessagePriority.PRIVATE
                        if self.buffer_type == "private"
                        else MessagePriority.MESSAGE
                    )
                    weechat.buffer_set(self.buffer_pointer, "hotlist", priority.value)
                    self.hotlist_tss.add(message.latest_reply)

    async def fill_history(self, update: bool = False):
        if self.is_loading:
            return

        if (
            self.last_printed_ts is not None
            and not self.history_needs_refresh
            and not update
        ):
            return

        with self.loading():
            history_after_ts = (
                next(iter(self._messages), None)
                if self.history_needs_refresh
                else self.last_printed_ts
            )
            if history_after_ts:
                history = await self.api.fetch_conversations_history_after(
                    self, history_after_ts
                )
            else:
                history = await self.api.fetch_conversations_history(self)

            conversation_messages = [
                SlackMessage(self, message) for message in history["messages"]
            ]
            for message in reversed(conversation_messages):
                self._add_or_update_message(message)

            if self.display_thread_replies():
                await gather(
                    *(
                        self.fetch_replies(message.ts)
                        for message in conversation_messages
                        if message.is_thread_parent
                    )
                )

            if self.history_needs_refresh:
                await self.rerender_history()

            self._messages = OrderedDict(sorted(self._messages.items()))
            self.history_pending_messages.clear()
            messages = [
                message
                for message in self._messages.values()
                if self.should_display_message(message)
                and (self.last_printed_ts is None or message.ts > self.last_printed_ts)
            ]

            user_ids = [m.sender_user_id for m in messages if m.sender_user_id]
            if self.display_reaction_nicks():
                reaction_user_ids = [
                    user_id
                    for m in messages
                    for reaction in m.reactions
                    for user_id in reaction["users"]
                ]
                user_ids.extend(reaction_user_ids)

            parsed_messages = [
                item for m in messages for item in m.parse_message_text()
            ]
            pending_items = [
                item for item in parsed_messages if isinstance(item, PendingMessageItem)
            ]
            item_user_ids = [
                item.item_id for item in pending_items if item.item_type == "user"
            ]
            user_ids.extend(item_user_ids)

            self.workspace.users.initialize_items(user_ids)

            sender_bot_ids = [
                m.sender_bot_id
                for m in messages
                if m.sender_bot_id and not m.sender_user_id
            ]
            self.workspace.bots.initialize_items(sender_bot_ids)

            await gather(*(message.render(self.context) for message in messages))

            for message in messages:
                await self.print_message(message)

            while self.history_pending_messages:
                message = self.history_pending_messages.pop(0)
                await self.print_message(message)

            self.history_needs_refresh = False

    async def nicklist_update(self):
        if self.nicklist_needs_refresh and self.type != "im":
            self.nicklist_needs_refresh = False
            try:
                members = await self.load_members()
            except SlackApiError as e:
                if e.response["error"] == "enterprise_is_restricted":
                    return
                raise e
            else:
                users = await gather(
                    *(self.workspace.users[user_id] for user_id in members)
                )
                for user in users:
                    self.nicklist_add_nick(user.nick)

    def nicklist_add_nick(self, nick: Nick):
        if nick in self._nicklist or self.type == "im" or self.buffer_pointer is None:
            return

        # TODO: weechat.color.nicklist_away
        color = nick.color if shared.config.look.color_nicks_in_nicklist else ""
        visible = 1 if nick.type == "user" else 0

        nick_pointer = weechat.nicklist_add_nick(
            self.buffer_pointer, "", nick.raw_nick, color, nick.suffix, "", visible
        )
        self._nicklist[nick] = nick_pointer

    def nicklist_remove_nick(self, nick: Nick):
        if self.type == "im" or self.buffer_pointer is None:
            return
        if nick in self._nicklist:
            nick_pointer = self._nicklist.pop(nick)
            weechat.nicklist_remove_nick(self.buffer_pointer, nick_pointer)

    def display_thread_replies(self) -> bool:
        if self.buffer_pointer is not None:
            buffer_value = weechat.buffer_get_string(
                self.buffer_pointer, "localvar_display_thread_replies_in_channel"
            )
            if buffer_value:
                return bool(weechat.config_string_to_boolean(buffer_value))
        return shared.config.look.display_thread_replies_in_channel.value

    def display_reaction_nicks(self) -> bool:
        if self.buffer_pointer is not None:
            buffer_value = weechat.buffer_get_string(
                self.buffer_pointer, "localvar_display_reaction_nicks"
            )
            if buffer_value:
                return bool(weechat.config_string_to_boolean(buffer_value))
        return shared.config.look.display_reaction_nicks.value

    def should_display_message(self, message: SlackMessage) -> bool:
        return (
            not message.is_reply
            or message.is_thread_broadcast
            or self.display_thread_replies()
        )

    async def add_new_message(self, message: SlackMessage):
        # TODO: Remove old messages
        self._add_or_update_message(message)

        parent_message = message.parent_message
        if parent_message:
            if message.ts not in parent_message.replies_tss:
                parent_message.replies_tss.append(message.ts)
            thread_buffer = parent_message.thread_buffer
            if thread_buffer:
                if thread_buffer.is_loading:
                    thread_buffer.history_pending_messages.append(message)
                else:
                    await thread_buffer.print_message(message)
        elif message.thread_ts is not None:
            await self.fetch_replies(message.thread_ts)

        if self.should_display_message(message):
            if self.is_loading:
                self.history_pending_messages.append(message)
            elif self.last_printed_ts is not None:
                await self.print_message(message)
            elif self.buffer_pointer is not None:
                priority = message.priority(self.context).value
                weechat.buffer_set(self.buffer_pointer, "hotlist", priority)
                self.hotlist_tss.add(message.ts)
                if not message.muted:
                    await self.fill_history()

        if message.sender_user_id and message.sender_bot_id is None:
            user = await self.workspace.users[message.sender_user_id]
            if message.is_reply:
                if parent_message and parent_message.thread_buffer:
                    weechat.hook_signal_send(
                        "typing_set_nick",
                        weechat.WEECHAT_HOOK_SIGNAL_STRING,
                        f"{parent_message.thread_buffer.buffer_pointer};off;{user.nick.format()}",
                    )
            else:
                weechat.hook_signal_send(
                    "typing_set_nick",
                    weechat.WEECHAT_HOOK_SIGNAL_STRING,
                    f"{self.buffer_pointer};off;{user.nick.format()}",
                )

    async def change_message(
        self, data: Union[SlackMessageChanged, SlackMessageReplied]
    ):
        ts = SlackTs(data["ts"])
        message = self._messages.get(ts)
        if message:
            message.update_message_json(data["message"])
            await self.rerender_message(message)

    async def delete_message(self, data: SlackMessageDeleted):
        ts = SlackTs(data["deleted_ts"])
        if ts in self.message_hashes:
            del self.message_hashes[ts]
        message = self._messages.get(ts)
        if message:
            message.deleted = True
            await self.rerender_message(message)

    async def update_message_room(
        self, data: Union[SlackShRoomJoin, SlackShRoomUpdate]
    ):
        ts = SlackTs(data["room"]["thread_root_ts"])
        message = self._messages.get(ts)
        if message:
            message.update_message_json_room(data["room"])
            await self.rerender_message(message)

    async def reaction_add(self, message_ts: SlackTs, reaction: str, user_id: str):
        message = self._messages.get(message_ts)
        if message:
            message.reaction_add(reaction, user_id)
            await self.rerender_message(message)

    async def reaction_remove(self, message_ts: SlackTs, reaction: str, user_id: str):
        message = self._messages.get(message_ts)
        if message:
            message.reaction_remove(reaction, user_id)
            await self.rerender_message(message)

    async def typing_add_user(self, data: SlackUserTyping):
        if not shared.config.look.typing_status_nicks:
            return

        user = await self.workspace.users[data["user"]]
        if "thread_ts" not in data:
            weechat.hook_signal_send(
                "typing_set_nick",
                weechat.WEECHAT_HOOK_SIGNAL_STRING,
                f"{self.buffer_pointer};typing;{user.nick.format()}",
            )
        else:
            thread_ts = SlackTs(data["thread_ts"])
            parent_message = self._messages.get(thread_ts)
            if parent_message and parent_message.thread_buffer:
                weechat.hook_signal_send(
                    "typing_set_nick",
                    weechat.WEECHAT_HOOK_SIGNAL_STRING,
                    f"{parent_message.thread_buffer.buffer_pointer};typing;{user.nick.format()}",
                )

    async def open_thread(self, thread_hash: str, switch: bool = False):
        thread_ts = self.ts_from_hash(thread_hash)
        if thread_ts:
            thread_message = self.messages.get(thread_ts)
            if thread_message is None:
                # TODO: Fetch message
                return
            if thread_message.thread_buffer is None:
                thread_message.thread_buffer = SlackThread(thread_message)
            await thread_message.thread_buffer.open_buffer(switch)

    async def print_message(self, message: SlackMessage):
        did_print = await super().print_message(message)

        if did_print:
            nick = await message.nick()
            if message.subtype in ["channel_leave", "group_leave"]:
                self.nicklist_remove_nick(nick)
            else:
                self.nicklist_add_nick(nick)

        return did_print

    async def mark_read(self):
        if not self._is_joined:
            return
        last_read_line_ts = self.last_read_line_ts()
        if last_read_line_ts and last_read_line_ts != self.last_read:
            await self.api.conversations_mark(self, last_read_line_ts)

    async def part(self):
        self._is_joined = False
        await self.api.conversations_leave(self)
        if shared.config.look.part_closes_buffer.value:
            await self.close_buffer()
        else:
            # Update history to get the part message
            await self.fill_history(update=True)

    async def _buffer_close(
        self, call_buffer_close: bool = False, update_server: bool = False
    ):
        await super()._buffer_close(call_buffer_close, update_server)

        if shared.script_is_unloading:
            return

        if self.id in self.workspace.open_conversations:
            del self.workspace.open_conversations[self.id]

        if update_server:
            if self.type in ["im", "mpim"]:
                await self.api.conversations_close(self)
            else:
                await self.api.conversations_leave(self)

        self._nicklist = {}


_T = TypeVar("_T", bound=SlackConversation)


if TYPE_CHECKING:
    pass

    class EmojiSkinVariation(TypedDict):
        name: str
        unicode: str

    class Emoji(TypedDict):
        aliasOf: NotRequired[str]
        name: str
        skinVariations: NotRequired[Dict[str, EmojiSkinVariation]]
        unicode: str


def load_standard_emojis() -> Dict[str, Emoji]:
    weechat_dir = weechat.info_get("weechat_data_dir", "") or weechat.info_get(
        "weechat_dir", ""
    )
    weechat_sharedir = weechat.info_get("weechat_sharedir", "")
    local_weemoji, global_weemoji = (
        f"{path}/weemoji.json" for path in (weechat_dir, weechat_sharedir)
    )
    path = (
        global_weemoji
        if os.path.exists(global_weemoji) and not os.path.exists(local_weemoji)
        else local_weemoji
    )
    if not os.path.exists(path):
        return {}

    try:
        with open(path) as f:
            emojis: Dict[str, Emoji] = json.loads(f.read())

            emojis_skin_tones: Dict[str, Emoji] = {
                skin_tone["name"]: {
                    "name": skin_tone["name"],
                    "unicode": skin_tone["unicode"],
                }
                for emoji in emojis.values()
                if "skinVariations" in emoji
                for skin_tone in emoji["skinVariations"].values()
            }

            emojis.update(emojis_skin_tones)
            return emojis
    except Exception as e:
        print_error(f"couldn't read weemoji.json: {store_and_format_exception(e)}")
        return {}


def get_emoji(emoji_name: str, skin_tone: Optional[int] = None) -> str:
    emoji_name_with_colons = f":{emoji_name}:"
    if shared.config.look.render_emoji_as.value == "name":
        return emoji_name_with_colons

    emoji_item = shared.standard_emojis.get(emoji_name)
    if emoji_item is None:
        return emoji_name_with_colons

    skin_tone_item = (
        emoji_item.get("skinVariations", {}).get(str(skin_tone)) if skin_tone else None
    )
    emoji_unicode = (
        skin_tone_item["unicode"] if skin_tone_item else emoji_item["unicode"]
    )

    if shared.config.look.render_emoji_as.value == "emoji":
        return emoji_unicode
    elif shared.config.look.render_emoji_as.value == "both":
        return f"{emoji_unicode}({emoji_name_with_colons})"
    else:
        assert_never(shared.config.look.render_emoji_as.value)


if TYPE_CHECKING:
    pass
    pass
    pass

    SearchType = Literal["channels", "users"]


@dataclass
class BufferLine:
    type: SearchType
    content: str
    content_id: str


class SlackSearchBuffer:
    def __init__(
        self,
        workspace: SlackWorkspace,
        search_type: SearchType,
        query: Optional[str] = None,
    ):
        self.workspace = workspace
        self.search_type: SearchType = search_type
        self._query = query or ""
        self._lines: List[BufferLine] = []
        self._marked_lines: Set[int] = set()
        self._selected_line = 0

        buffer_name = f"{shared.SCRIPT_NAME}.search.{self.workspace.name}.{search_type}"
        buffer_props = {
            "type": "free",
            "display": "1",
            "key_bind_up": "/slack search -up",
            "key_bind_down": "/slack search -down",
            "key_bind_ctrl-j": "/slack search -join_channel",
            "key_bind_meta-comma": "/slack search -mark",
            "key_bind_shift-up": "/slack search -up; /slack search -mark",
            "key_bind_shift-down": "/slack search -mark; /slack search -down",
        }

        self.buffer_pointer = buffer_new(
            buffer_name,
            buffer_props,
            self._buffer_input_cb,
            self._buffer_close_cb,
        )

        run_async(self.search())

    @property
    def selected_line(self) -> int:
        return self._selected_line

    @selected_line.setter
    def selected_line(self, value: int):
        old_line = self._selected_line
        if value < 0:
            self._selected_line = len(self._lines) - 1
        elif value >= len(self._lines):
            self._selected_line = 0
        else:
            self._selected_line = value
        self.print(old_line)
        self.print(self._selected_line)

    def update_title(self, searching: bool = False):
        matches = (
            "Searching"
            if searching
            else f"First {len(self._lines)} matching {self.search_type}"
        )
        title = f"{matches} | Filter: {self._query or '*'} | Key(input): ctrl+j=join channel, ($)=refresh, (q)=close buffer"
        weechat.buffer_set(self.buffer_pointer, "title", title)

    def switch_to_buffer(self):
        weechat.buffer_set(self.buffer_pointer, "display", "1")

    def mark_line(self, y: int):
        if y < 0 or y >= len(self._lines):
            return
        if y in self._marked_lines:
            self._marked_lines.remove(y)
        else:
            self._marked_lines.add(y)
        self.print(y)

    def print(self, y: int):
        if y < 0 or y >= len(self._lines):
            return

        line_is_selected = y == self.selected_line
        line_is_marked = y in self._marked_lines
        marked_color = (
            shared.config.color.search_marked_selected.value
            if line_is_selected
            else shared.config.color.search_marked.value
        )
        selected_color_bg = (
            shared.config.color.search_line_selected_bg.value
            if line_is_selected
            else shared.config.color.search_line_marked_bg.value
            if line_is_marked
            else None
        )

        marked = with_color(marked_color, "* ") if line_is_marked else "  "
        line = with_color(
            f",{selected_color_bg}" if selected_color_bg is not None else None,
            f"{marked}{self._lines[y].content}",
        )
        weechat.prnt_y(self.buffer_pointer, y, line)

    def format_channel(
        self, channel_info: SlackConversationsInfoPublic, member_channels: List[str]
    ) -> str:
        prefix = "&" if channel_info["is_private"] else "#"
        name = f"{prefix}{channel_info['name']}"
        joined = " (joined)" if channel_info["id"] in member_channels else ""
        # TODO: Resolve refs
        purpose = channel_info["purpose"]["value"].replace("\n", " ")
        description = f" - Description: {purpose}" if purpose else ""
        return f"{name}{joined}{description}"

    def format_user(self, user_info: SlackUserInfo) -> str:
        name = name_from_user_info(self.workspace, user_info)
        real_name = user_info["profile"].get("real_name", "")
        real_name_str = f" - {real_name}" if real_name else ""

        title = user_info["profile"].get("title", "")
        title_str = f" - Title: {title}" if title else ""

        status_emoji_name = user_info["profile"].get("status_emoji", "")
        status_emoji = (
            get_emoji(status_emoji_name.strip(":")) if status_emoji_name else ""
        )
        status_text = user_info["profile"].get("status_text", "") or ""
        status = f"{status_emoji} {status_text}".strip()
        status_str = f" - Status: {status}" if status else ""

        return f"{name}{real_name_str}{title_str}{status_str}"

    async def search(self, query: Optional[str] = None):
        if query is not None:
            self._query = query

        self.update_title(searching=True)

        marked_lines = [self._lines[line] for line in self._marked_lines]
        marked_lines_ids = {line.content_id for line in marked_lines}
        weechat.buffer_clear(self.buffer_pointer)
        self._selected_line = 0
        weechat.prnt_y(self.buffer_pointer, 0, f'Searching for "{self._query}"...')

        if self.search_type == "channels":
            results = await self.workspace.api.edgeapi.fetch_channels_search(
                self._query
            )
            self._lines = marked_lines + [
                BufferLine(
                    "channels",
                    self.format_channel(channel, results.get("member_channels", [])),
                    channel["id"],
                )
                for channel in results["results"]
                if channel["id"] not in marked_lines_ids
            ]
        elif self.search_type == "users":
            results = await self.workspace.api.edgeapi.fetch_users_search(self._query)
            self._lines = marked_lines + [
                BufferLine("users", self.format_user(user), user["id"])
                for user in results["results"]
                if user["id"] not in marked_lines_ids
            ]
        else:
            assert_never(self.search_type)
        self._marked_lines = set(range(len(marked_lines)))

        self.update_title()

        if not self._lines:
            weechat.prnt_y(self.buffer_pointer, 0, "No results found.")
            return

        for i in range(len(self._lines)):
            self.print(i)

    async def join_channel(self):
        marked_lines = (
            self._marked_lines if self._marked_lines else {self.selected_line}
        )
        if self.search_type == "channels":
            for line in marked_lines:
                channel_id = self._lines[line].content_id
                conversation = await self.workspace.conversations[channel_id]
                await conversation.api.conversations_join(conversation.id)
                await conversation.open_buffer(switch=True)
        elif self.search_type == "users":
            user_ids = [self._lines[line].content_id for line in marked_lines]
            await create_conversation_for_users(self.workspace, user_ids)
        else:
            assert_never(self.search_type)

    def _buffer_input_cb(self, data: str, buffer: str, input_data: str) -> int:
        if input_data == "q":
            weechat.buffer_close(buffer)
            return weechat.WEECHAT_RC_OK
        elif input_data == "$":
            run_async(self.search())
            return weechat.WEECHAT_RC_OK

        query = "" if input_data == "*" else input_data
        run_async(self.search(query))
        return weechat.WEECHAT_RC_OK

    def _buffer_close_cb(self, data: str, buffer: str) -> int:
        del self.workspace.search_buffers[self.search_type]
        return weechat.WEECHAT_RC_OK


if TYPE_CHECKING:
    pass
    pass


class SlackThread(SlackMessageBuffer):
    def __init__(self, parent: SlackMessage) -> None:
        super().__init__()
        self.parent = parent
        self._reply_nicks: Set[Nick] = set()

    @property
    def workspace(self) -> SlackWorkspace:
        return self.parent.workspace

    @property
    def conversation(self) -> SlackConversation:
        return self.parent.conversation

    @property
    def context(self) -> MessageContext:
        return "thread"

    @property
    def members(self) -> Generator[Nick, None, None]:
        for nick in self._reply_nicks:
            if nick.type == "user":
                yield nick

    @property
    def messages(self) -> Mapping[SlackTs, SlackMessage]:
        return self.parent.replies

    @property
    def last_read(self) -> Optional[SlackTs]:
        return self.parent.last_read

    def get_name_and_buffer_props(self) -> Tuple[str, Dict[str, str]]:
        conversation_name = self.parent.conversation.name_with_prefix("full_name")
        name = f"{conversation_name}.${self.parent.hash}"
        short_name = f" ${self.parent.hash}"

        return name, {
            "short_name": short_name,
            "title": "topic",
            "input_prompt": self.workspace.my_user.nick.raw_nick,
            "input_multiline": "1",
            "localvar_set_type": self.parent.conversation.buffer_type,
            "localvar_set_slack_type": "thread",
            "localvar_set_nick": self.workspace.my_user.nick.raw_nick,
            "localvar_set_channel": name,
            "localvar_set_server": self.workspace.name,
            "localvar_set_workspace": self.workspace.name,
            "localvar_set_completion_default_template": "${weechat.completion.default_template}|%(slack_channels)|%(slack_emojis)",
        }

    async def buffer_switched_to(self):
        await super().buffer_switched_to()
        await self.fill_history()

    async def set_hotlist(self):
        self.history_needs_refresh = True
        await self.fill_history()

    async def print_history(self):
        messages = chain([self.parent], self.parent.replies.values())
        self.history_pending_messages.clear()
        for message in list(messages):
            if self.last_printed_ts is None or message.ts > self.last_printed_ts:
                await self.print_message(message)

        while self.history_pending_messages:
            message = self.history_pending_messages.pop(0)
            await self.print_message(message)

    async def fill_history(self):
        if self.is_loading:
            return

        with self.loading():
            if self.parent.reply_history_filled and not self.history_needs_refresh:
                await self.print_history()
                return

            messages = await self.parent.conversation.fetch_replies(self.parent.ts)

            if self.history_needs_refresh:
                await self.rerender_history()

            sender_user_ids = [m.sender_user_id for m in messages if m.sender_user_id]
            self.workspace.users.initialize_items(sender_user_ids)

            sender_bot_ids = [
                m.sender_bot_id
                for m in messages
                if m.sender_bot_id and not m.sender_user_id
            ]
            self.workspace.bots.initialize_items(sender_bot_ids)

            await gather(*(message.render(self.context) for message in messages))
            await self.print_history()

            self.history_needs_refresh = False

    async def print_message(self, message: SlackMessage):
        did_print = await super().print_message(message)

        if did_print:
            nick = await message.nick()
            self._reply_nicks.add(nick)

        return did_print

    async def mark_read(self):
        # subscriptions.thread.mark is only available for session tokens
        if self.workspace.token_type != "session":
            return

        # last_read can only be set if it exists (which is on threads you're subscribed to)
        if self.last_read is None:
            return

        last_read_line_ts = self.last_read_line_ts()
        if last_read_line_ts and last_read_line_ts != self.last_read:
            await self.api.subscriptions_thread_mark(
                self.parent.conversation, self.parent.ts, last_read_line_ts
            )

    async def post_message(
        self,
        text: str,
        thread_ts: Optional[SlackTs] = None,
        broadcast: bool = False,
    ):
        await super().post_message(text, thread_ts or self.parent.ts, broadcast)


if TYPE_CHECKING:
    pass
    pass
    pass
    pass
    pass
    pass
    pass

    pass


@dataclass
class Nick:
    color: str
    raw_nick: str
    suffix: str
    type: Literal["user", "bot", "unknown"]

    def __hash__(self) -> int:
        return hash(self.raw_nick)

    def format(self, colorize: bool = False) -> str:
        color = self.color if colorize else ""
        return with_color(color, self.raw_nick) + self.suffix


def nick_color(nick: str, is_self: bool = False) -> str:
    if is_self:
        return weechat.config_string(weechat.config_get("weechat.color.chat_nick_self"))

    return weechat.info_get("nick_color_name", nick)


# TODO: Probably need to do some mapping here based on the existing users, in case some has been changed to avoid duplicate names
def name_from_user_profile(
    workspace: SlackWorkspace,
    profile: Union[SlackProfile, SlackMessageUserProfile],
    fallback_name: str,
) -> str:
    display_name = profile.get("display_name")
    if display_name and not workspace.config.use_real_names:
        return display_name

    return profile.get("display_name") or profile.get("real_name") or fallback_name


def name_from_user_info(workspace: SlackWorkspace, info: SlackUserInfo) -> str:
    return name_from_user_profile(
        workspace, info["profile"], info.get("real_name") or info["name"]
    )


def get_user_nick(
    nick: str,
    is_external: bool = False,
    is_self: bool = False,
) -> Nick:
    nick = nick.replace(" ", shared.config.look.replace_space_in_nicks_with.value)
    suffix = shared.config.look.external_user_suffix.value if is_external else ""
    return Nick(
        nick_color(nick, is_self),
        nick,
        suffix,
        "user",
    )


def get_bot_nick(nick: str) -> Nick:
    nick = nick.replace(" ", shared.config.look.replace_space_in_nicks_with.value)
    return Nick(
        nick_color(nick),
        nick,
        shared.config.look.bot_user_suffix.value,
        "bot",
    )


class SlackUser:
    def __init__(self, workspace: SlackWorkspace, info: SlackUserInfo):
        self.workspace = workspace
        self._info = info

    @classmethod
    async def create(cls, workspace: SlackWorkspace, id: str):
        info_response = await workspace.api.fetch_user_info(id)
        return cls(workspace, info_response["user"])

    @property
    def id(self) -> str:
        return self._info["id"]

    @property
    def is_self(self) -> bool:
        return self.id == self.workspace.my_user.id

    @property
    def is_external(self) -> bool:
        return self._info["profile"]["team"] != self.workspace.id and (
            "enterprise_user" not in self._info
            or self._info["enterprise_user"]["enterprise_id"]
            != self.workspace.enterprise_id
        )

    @property
    def status_text(self) -> str:
        return self._info["profile"].get("status_text", "") or ""

    @property
    def status_emoji(self) -> str:
        status_emoji = self._info["profile"].get("status_emoji")
        if not status_emoji:
            return ""
        return get_emoji(status_emoji.strip(":"))

    @property
    def real_name(self) -> str:
        return self._info["profile"].get("real_name") or name_from_user_info(
            self.workspace, self._info
        )

    @property
    def nick(self) -> Nick:
        nick = name_from_user_info(self.workspace, self._info)
        return get_user_nick(nick, self.is_external, self.is_self)

    def update_info_json(self, info_json: SlackUserInfo):
        self._info.update(info_json)  # pyright: ignore [reportArgumentType, reportCallIssue]

        for conversation in self.workspace.open_conversations.values():
            if conversation.im_user_id == self.id:
                conversation.update_buffer_props()


class SlackBot:
    def __init__(self, workspace: SlackWorkspace, info: SlackBotInfo):
        self.workspace = workspace
        self._info = info

    @classmethod
    async def create(cls, workspace: SlackWorkspace, id: str):
        info_response = await workspace.api.fetch_bot_info(id)
        return cls(workspace, info_response["bot"])

    @property
    def nick(self) -> Nick:
        return get_bot_nick(self._info["name"])


class SlackUsergroup:
    def __init__(
        self, workspace: SlackWorkspace, info: Union[SlackUsergroupInfo, SlackSubteam]
    ):
        self.workspace = workspace
        self._info = info

    @classmethod
    async def create(cls, workspace: SlackWorkspace, id: str):
        info_response = await workspace.api.edgeapi.fetch_usergroups_info([id])
        if not info_response["results"] or info_response["results"][0]["id"] != id:
            raise SlackError(workspace, "usergroup_not_found")
        return cls(workspace, info_response["results"][0])

    def handle(self) -> str:
        return self._info["handle"]

    def update_info_json(self, info_json: Union[SlackUsergroupInfo, SlackSubteam]):
        self._info.update(info_json)


if TYPE_CHECKING:
    pass
    pass
    pass
    pass
    pass
    pass
    pass

    pass
    pass
else:
    SlackBotInfo = object
    SlackConversationsInfoInternal = object
    SlackUsergroupInfo = object
    SlackUserInfo = object
    SlackSubteam = object


def workspace_get_buffer_to_merge_with() -> Optional[str]:
    if shared.config.look.workspace_buffer.value == "merge_with_core":
        return weechat.buffer_search_main()
    elif shared.config.look.workspace_buffer.value == "merge_without_core":
        workspace_buffers_by_number = {
            weechat.buffer_get_integer(
                workspace.buffer_pointer, "number"
            ): workspace.buffer_pointer
            for workspace in shared.workspaces.values()
            if workspace.buffer_pointer is not None
        }
        if workspace_buffers_by_number:
            lowest_number = min(workspace_buffers_by_number.keys())
            return workspace_buffers_by_number[lowest_number]


SlackItemClass = TypeVar(
    "SlackItemClass", SlackConversation, SlackUser, SlackBot, SlackUsergroup
)
SlackItemInfo = TypeVar(
    "SlackItemInfo",
    SlackConversationsInfoInternal,
    SlackUserInfo,
    SlackBotInfo,
    Union[SlackUsergroupInfo, SlackSubteam],
)


class SlackItem(
    ABC, Generic[SlackItemClass, SlackItemInfo], Dict[str, Future[SlackItemClass]]
):
    def __init__(self, workspace: SlackWorkspace, item_class: Type[SlackItemClass]):
        super().__init__()
        self.workspace = workspace
        self._item_class = item_class

    def __missing__(self, key: str):
        self[key] = create_task(self._create_item(key))
        return self[key]

    def initialize_items(
        self,
        item_ids: Iterable[str],
        items_info_prefetched: Optional[Mapping[str, SlackItemInfo]] = None,
    ):
        item_ids_to_init = set(item_id for item_id in item_ids if item_id not in self)
        if item_ids_to_init:
            item_ids_to_fetch = (
                set(
                    item_id
                    for item_id in item_ids_to_init
                    if item_id not in items_info_prefetched
                )
                if items_info_prefetched
                else item_ids_to_init
            )
            items_info_task = create_task(self._fetch_items_info(item_ids_to_fetch))
            for item_id in item_ids_to_init:
                self[item_id] = create_task(
                    self._create_item(item_id, items_info_task, items_info_prefetched)
                )

    async def _create_item(
        self,
        item_id: str,
        items_info_task: Optional[Future[Dict[str, SlackItemInfo]]] = None,
        items_info_prefetched: Optional[Mapping[str, SlackItemInfo]] = None,
    ) -> SlackItemClass:
        if items_info_prefetched and item_id in items_info_prefetched:
            return await self._create_item_from_info(items_info_prefetched[item_id])
        elif items_info_task:
            items_info = await items_info_task
            item = items_info.get(item_id)
            if item is None:
                raise SlackError(self.workspace, "item_not_found")
            return await self._create_item_from_info(item)
        else:
            return await self._item_class.create(self.workspace, item_id)

    @abstractmethod
    async def _fetch_items_info(
        self, item_ids: Iterable[str]
    ) -> Dict[str, SlackItemInfo]:
        raise NotImplementedError()

    @abstractmethod
    async def _create_item_from_info(self, item_info: SlackItemInfo) -> SlackItemClass:
        raise NotImplementedError()


class SlackConversations(SlackItem[SlackConversation, SlackConversationsInfoInternal]):
    def __init__(self, workspace: SlackWorkspace):
        super().__init__(workspace, SlackConversation)

    async def _fetch_items_info(
        self, item_ids: Iterable[str]
    ) -> Dict[str, SlackConversationsInfoInternal]:
        responses = await gather(
            *(
                self.workspace.api.fetch_conversations_info(item_id)
                for item_id in item_ids
            )
        )
        return {
            response["channel"]["id"]: response["channel"] for response in responses
        }

    async def _create_item_from_info(
        self, item_info: SlackConversationsInfoInternal
    ) -> SlackConversation:
        return await self._item_class(self.workspace, item_info)


class SlackUsers(SlackItem[SlackUser, SlackUserInfo]):
    def __init__(self, workspace: SlackWorkspace):
        super().__init__(workspace, SlackUser)

    async def _fetch_items_info(
        self, item_ids: Iterable[str]
    ) -> Dict[str, SlackUserInfo]:
        response = await self.workspace.api.fetch_users_info(item_ids)
        return {info["id"]: info for info in response["users"]}

    async def _create_item_from_info(self, item_info: SlackUserInfo) -> SlackUser:
        return self._item_class(self.workspace, item_info)


class SlackBots(SlackItem[SlackBot, SlackBotInfo]):
    def __init__(self, workspace: SlackWorkspace):
        super().__init__(workspace, SlackBot)

    async def _fetch_items_info(
        self, item_ids: Iterable[str]
    ) -> Dict[str, SlackBotInfo]:
        response = await self.workspace.api.fetch_bots_info(item_ids)
        return {info["id"]: info for info in response["bots"]}

    async def _create_item_from_info(self, item_info: SlackBotInfo) -> SlackBot:
        return self._item_class(self.workspace, item_info)


class SlackUsergroups(
    SlackItem[SlackUsergroup, Union[SlackUsergroupInfo, SlackSubteam]]
):
    def __init__(self, workspace: SlackWorkspace):
        super().__init__(workspace, SlackUsergroup)

    async def _fetch_items_info(
        self, item_ids: Iterable[str]
    ) -> Dict[str, Union[SlackUsergroupInfo, SlackSubteam]]:
        response = await self.workspace.api.edgeapi.fetch_usergroups_info(
            list(item_ids)
        )
        return {info["id"]: info for info in response["results"]}

    async def _create_item_from_info(
        self, item_info: Union[SlackUsergroupInfo, SlackSubteam]
    ) -> SlackUsergroup:
        return self._item_class(self.workspace, item_info)


class SlackWorkspace:
    def __init__(self, name: str):
        self.name = name
        self.buffer_pointer: Optional[str] = None
        self.config = shared.config.create_workspace_config(self.name)
        self.api = SlackApi(self)
        self._initial_connect = True
        self._is_connected = False
        self._connect_task: Optional[Task[bool]] = None
        self._ws: Optional[WebSocket] = None
        self._hook_ws_fd: Optional[str] = None
        self._last_ws_received_time = time.time()
        self._debug_ws_buffer_pointer: Optional[str] = None
        self._reconnect_url: Optional[str] = None
        self.my_user: SlackUser
        self.conversations = SlackConversations(self)
        self.open_conversations: Dict[str, SlackConversation] = {}
        self.search_buffers: Dict[SearchType, SlackSearchBuffer] = {}
        self.users = SlackUsers(self)
        self.bots = SlackBots(self)
        self.usergroups = SlackUsergroups(self)
        self.usergroups_member: Set[str] = set()
        self.muted_channels: Set[str] = set()
        self.global_keywords_regex: Optional[re.Pattern[str]] = None
        self.custom_emojis: Dict[str, str] = {}
        self.max_users_per_fetch_request = 512

    def __repr__(self):
        return f"{self.__class__.__name__}({self.name})"

    @property
    def workspace(self) -> SlackWorkspace:
        return self

    @property
    def token_type(self) -> Literal["oauth", "session", "unknown"]:
        if self.config.api_token.value.startswith("xoxp-"):
            return "oauth"
        elif self.config.api_token.value.startswith("xoxc-"):
            return "session"
        else:
            return "unknown"

    @property
    def team_is_org_level(self) -> bool:
        return self.id.startswith("E")

    @property
    def is_connected(self):
        return self._is_connected

    @property
    def is_connecting(self):
        return self._connect_task is not None

    @is_connected.setter
    def is_connected(self, value: bool):
        self._is_connected = value
        weechat.bar_item_update("input_text")

    def get_full_name(self) -> str:
        return f"{shared.SCRIPT_NAME}.server.{self.name}"

    def get_buffer_props(self) -> Dict[str, str]:
        buffer_props = {
            "short_name": self.name,
            "title": "",
            "input_multiline": "1",
            "localvar_set_type": "server",
            "localvar_set_slack_type": "workspace",
            "localvar_set_channel": self.name,
            "localvar_set_server": self.name,
            "localvar_set_workspace": self.name,
            "localvar_set_completion_default_template": "${weechat.completion.default_template}|%(slack_channels)|%(slack_emojis)",
        }
        if hasattr(self, "my_user"):
            buffer_props["input_prompt"] = self.my_user.nick.raw_nick
            buffer_props["localvar_set_nick"] = self.my_user.nick.raw_nick
        return buffer_props

    def open_buffer(self, switch: bool = False):
        if self.buffer_pointer:
            if switch:
                weechat.buffer_set(self.buffer_pointer, "display", "1")
            return

        buffer_props = self.get_buffer_props()

        if switch:
            buffer_props["display"] = "1"

        self.buffer_pointer = buffer_new(
            self.get_full_name(),
            buffer_props,
            self._buffer_input_cb,
            self._buffer_close_cb,
        )

        buffer_to_merge_with = workspace_get_buffer_to_merge_with()
        if (
            buffer_to_merge_with
            and weechat.buffer_get_integer(self.buffer_pointer, "layout_number") < 1
        ):
            weechat.buffer_merge(self.buffer_pointer, buffer_to_merge_with)

        shared.buffers[self.buffer_pointer] = self

    def update_buffer_props(self) -> None:
        if self.buffer_pointer is None:
            return

        buffer_props = self.get_buffer_props()
        buffer_props["name"] = self.get_full_name()
        for key, value in buffer_props.items():
            weechat.buffer_set(self.buffer_pointer, key, value)

    def print(self, message: str) -> bool:
        if not self.buffer_pointer:
            return False
        weechat.prnt(self.buffer_pointer, message)
        return True

    async def connect(self) -> None:
        if self.is_connected:
            return
        self.open_buffer()
        self.print(f"Connecting to workspace {self.name}")
        self._connect_task = create_task(self._connect())
        self.is_connected = await self._connect_task
        self._connect_task = None

    async def _connect(self) -> bool:
        if self._reconnect_url is not None:
            try:
                await self._connect_ws(self._reconnect_url)
                return True
            except Exception:
                self._reconnect_url = None

        try:
            if self.token_type == "session":
                team_info = await self.api.fetch_team_info()
                self.id = team_info["team"]["id"]
                self.enterprise_id = (
                    self.id
                    if self.team_is_org_level
                    else team_info["team"]["enterprise_id"]
                    if "enterprise_id" in team_info["team"]
                    else None
                )
                self.domain = team_info["team"]["domain"]
                await self._connect_ws(
                    f"wss://wss-primary.slack.com/?token={self.config.api_token.value}&gateway_server={self.id}-1&slack_client=desktop&batch_presence_aware=1"
                )
            else:
                rtm_connect = await self.api.fetch_rtm_connect()
                self.id = rtm_connect["team"]["id"]
                self.enterprise_id = rtm_connect["team"].get("enterprise_id")
                self.domain = rtm_connect["team"]["domain"]
                self.my_user = await self.users[rtm_connect["self"]["id"]]
                await self._connect_ws(rtm_connect["url"])
        except Exception as e:
            print_error(
                f'Failed connecting to workspace "{self.name}": {store_and_format_exception(e)}'
            )
            return False

        return True

    def _set_global_keywords(self, all_notifications_prefs: AllNotificationsPrefs):
        global_keywords = set(
            all_notifications_prefs["global"]["global_keywords"].split(",")
        )
        regex_words = "|".join(re.escape(keyword) for keyword in global_keywords)
        if regex_words:
            self.global_keywords_regex = re.compile(
                rf"\b(?:{regex_words})\b", re.IGNORECASE
            )
        else:
            self.global_keywords_regex = None

    async def _initialize_oauth(self) -> List[SlackConversation]:
        prefs = await self.api.fetch_users_get_prefs(
            "muted_channels,all_notifications_prefs"
        )
        self.muted_channels = set(prefs["prefs"]["muted_channels"].split(","))
        all_notifications_prefs = json.loads(prefs["prefs"]["all_notifications_prefs"])
        self._set_global_keywords(all_notifications_prefs)

        usergroups = await self.api.fetch_usergroups_list(include_users=True)
        for usergroup in usergroups["usergroups"]:
            future = Future[SlackUsergroup]()
            future.set_result(SlackUsergroup(self, usergroup))
            self.usergroups[usergroup["id"]] = future
        self.usergroups_member = set(
            u["id"]
            for u in usergroups["usergroups"]
            if self.my_user.id in u.get("users", [])
        )

        users_conversations_response = await self.api.fetch_users_conversations(
            "public_channel,private_channel,mpim,im"
        )
        channels = users_conversations_response["channels"]
        self.conversations.initialize_items(channel["id"] for channel in channels)

        conversations_if_should_open = await gather(
            *(self._conversation_if_should_open(channel) for channel in channels)
        )
        conversations_to_open = [
            c for c in conversations_if_should_open if c is not None
        ]

        # Load the first 1000 chanels to be able to look them up by name, since
        # we can't look up a channel id from channel name with OAuth tokens
        first_channels = await self.api.fetch_conversations_list_public(limit=1000)
        self.conversations.initialize_items(
            [channel["id"] for channel in first_channels["channels"]],
            {channel["id"]: channel for channel in first_channels["channels"]},
        )

        return conversations_to_open

    async def _initialize_session(self) -> List[SlackConversation]:
        user_boot_task = create_task(self.api.fetch_client_userboot())
        client_counts_task = create_task(self.api.fetch_client_counts())
        user_boot = await user_boot_task
        client_counts = await client_counts_task

        my_user_id = user_boot["self"]["id"]
        # self.users.initialize_items(my_user_id, {my_user_id: user_boot["self"]})
        self.my_user = await self.users[my_user_id]
        self.muted_channels = set(user_boot["prefs"]["muted_channels"].split(","))
        all_notifications_prefs = json.loads(
            user_boot["prefs"]["all_notifications_prefs"]
        )
        self._set_global_keywords(all_notifications_prefs)

        self.usergroups_member = set(user_boot["subteams"]["self"])

        conversation_counts = (
            client_counts["channels"] + client_counts["mpims"] + client_counts["ims"]
        )

        conversation_ids = set(
            [
                channel["id"]
                for channel in user_boot["channels"]
                if not channel["is_mpim"]
                and not channel["is_archived"]
                and (
                    self.team_is_org_level
                    or "internal_team_ids" not in channel
                    or self.id in channel["internal_team_ids"]
                )
            ]
            + user_boot["is_open"]
            + [count["id"] for count in conversation_counts if count["has_unreads"]]
        )

        conversation_counts_ids = set(count["id"] for count in conversation_counts)
        if not conversation_ids.issubset(conversation_counts_ids):
            raise SlackError(
                self,
                "Unexpectedly missing some conversations in client.counts",
                {
                    "conversation_ids": list(conversation_ids),
                    "conversation_counts_ids": list(conversation_counts_ids),
                },
            )

        channel_infos: Dict[str, SlackConversationsInfoInternal] = {
            channel["id"]: channel for channel in user_boot["channels"]
        }
        self.conversations.initialize_items(conversation_ids, channel_infos)
        conversations = {
            conversation_id: await self.conversations[conversation_id]
            for conversation_id in conversation_ids
        }

        for conversation_count in conversation_counts:
            if conversation_count["id"] in conversations:
                conversation = conversations[conversation_count["id"]]
                # TODO: Update without moving unread marker to the bottom
                if conversation.last_read == SlackTs("0.0"):
                    conversation.last_read = SlackTs(conversation_count["last_read"])

        return list(conversations.values())

    async def _initialize(self):
        try:
            if self.token_type == "session":
                conversations_to_open = await self._initialize_session()
            else:
                conversations_to_open = await self._initialize_oauth()
        except Exception as e:
            print_error(
                f'Failed connecting to workspace "{self.name}": {store_and_format_exception(e)}'
            )
            self.disconnect()
            return

        self.update_buffer_props()

        custom_emojis_response = await self.api.fetch_emoji_list()
        self.custom_emojis = custom_emojis_response["emoji"]

        for conversation in sorted(
            conversations_to_open, key=lambda conversation: conversation.sort_key()
        ):
            await conversation.open_buffer()

        await gather(
            *(
                slack_buffer.set_hotlist()
                for slack_buffer in shared.buffers.values()
                if isinstance(slack_buffer, SlackMessageBuffer)
            )
        )

    async def _conversation_if_should_open(self, info: SlackUsersConversations):
        conversation = await self.conversations[info["id"]]
        if not conversation.should_open():
            if conversation.type != "im" and conversation.type != "mpim":
                return

            if conversation.last_read == SlackTs("0.0"):
                history = await self.api.fetch_conversations_history(conversation)
            else:
                history = await self.api.fetch_conversations_history_after(
                    conversation, conversation.last_read
                )
            if not history["messages"]:
                return

        return conversation

    async def _load_unread_conversations(self):
        open_conversations = list(self.open_conversations.values())
        for conversation in open_conversations:
            if (
                conversation.hotlist_tss
                and not conversation.muted
                and self.is_connected
            ):
                await conversation.fill_history()
                # TODO: Better sleep heuristic
                sleep_duration = (
                    20000 if conversation.display_thread_replies() else 1000
                )
                await sleep(sleep_duration)

    async def _connect_ws(self, url: str):
        proxy = Proxy()
        # TODO: Handle errors
        self._ws = create_connection(
            url,
            self.config.network_timeout.value,
            cookie=get_cookies(self.config.api_cookies.value),
            proxy_type=proxy.type,
            http_proxy_host=proxy.address,
            http_proxy_port=proxy.port,
            http_proxy_auth=(proxy.username, proxy.password),
            http_proxy_timeout=self.config.network_timeout.value,
        )

        self._hook_ws_fd = weechat.hook_fd(
            self._ws.sock.fileno(),
            1,
            0,
            0,
            get_callback_name(self._ws_read_cb),
            "",
        )
        self._ws.sock.setblocking(False)
        self._last_ws_received_time = time.time()

    def _ws_read_cb(self, data: str, fd: int) -> int:
        if self._ws is None:
            raise SlackError(self, "ws_read_cb called while _ws is None")
        while True:
            try:
                opcode, recv_data = self._ws.recv_data(control_frame=True)
            except ssl.SSLWantReadError:
                # No more data to read at this time.
                return weechat.WEECHAT_RC_OK
            except (WebSocketConnectionClosedException, socket.error) as e:
                print("lost connection on receive, reconnecting", e)
                run_async(self.reconnect())
                return weechat.WEECHAT_RC_OK

            self._last_ws_received_time = time.time()

            if opcode == ABNF.OPCODE_PONG:
                return weechat.WEECHAT_RC_OK
            elif opcode != ABNF.OPCODE_TEXT:
                return weechat.WEECHAT_RC_OK

            run_async(self.ws_recv(json.loads(recv_data.decode())))

    async def ws_recv(self, data: SlackRtmMessage):
        # TODO: Remove old messages
        log(LogLevel.DEBUG, DebugMessageType.WEBSOCKET_RECV, json.dumps(data))

        try:
            if data["type"] == "hello":
                if self._initial_connect or not data["fast_reconnect"]:
                    await self._initialize()
                if self.is_connected:
                    self.print(f"Connected to workspace {self.name}")
                if self._initial_connect or not data["fast_reconnect"]:
                    await self._load_unread_conversations()
                self._initial_connect = False
                return
            elif data["type"] == "error":
                if data["error"]["code"] == 1:  # Socket URL has expired
                    self._reconnect_url = None
                return
            elif data["type"] == "reconnect_url":
                self._reconnect_url = data["url"]
                return
            elif data["type"] == "pref_change":
                if data["name"] == "muted_channels":
                    new_muted_channels = set(data["value"].split(","))
                    self._set_muted_channels(new_muted_channels)
                elif data["name"] == "all_notifications_prefs":
                    new_prefs = json.loads(data["value"])
                    new_muted_channels = set(
                        channel_id
                        for channel_id, prefs in new_prefs["channels"].items()
                        if prefs["muted"]
                    )
                    self._set_muted_channels(new_muted_channels)
                    self._set_global_keywords(new_prefs)
                return
            elif data["type"] == "user_status_changed":
                user_id = data["user"]["id"]
                if user_id in self.users:
                    user = await self.users[user_id]
                    user.update_info_json(data["user"])
                return
            elif data["type"] == "user_invalidated":
                user_id = data["user"]["id"]
                if user_id in self.users:
                    has_dm_conversation = any(
                        conversation.im_user_id == user_id
                        for conversation in self.open_conversations.values()
                    )
                    if has_dm_conversation:
                        user = await self.users[user_id]
                        user_info = await self.api.fetch_user_info(user_id)
                        user.update_info_json(user_info["user"])
                return
            elif data["type"] == "subteam_created":
                subteam_id = data["subteam"]["id"]
                self.usergroups.initialize_items(
                    [subteam_id], {subteam_id: data["subteam"]}
                )
                return
            elif data["type"] == "subteam_updated":
                subteam_id = data["subteam"]["id"]
                if subteam_id in self.usergroups:
                    usergroup = await self.usergroups[subteam_id]
                    usergroup.update_info_json(data["subteam"])
                return
            elif data["type"] == "subteam_members_changed":
                # Handling subteam_updated should be enough
                return
            elif data["type"] == "subteam_self_added":
                self.usergroups_member.add(data["subteam_id"])
                return
            elif data["type"] == "subteam_self_removed":
                self.usergroups_member.remove(data["subteam_id"])
                return
            elif data["type"] == "channel_joined" or data["type"] == "group_joined":
                channel_id = data["channel"]["id"]
            elif data["type"] == "reaction_added" or data["type"] == "reaction_removed":
                channel_id = data["item"]["channel"]
            elif (
                data["type"] == "thread_marked"
                or data["type"] == "thread_subscribed"
                or data["type"] == "thread_unsubscribed"
            ) and data["subscription"]["type"] == "thread":
                channel_id = data["subscription"]["channel"]
            elif data["type"] == "sh_room_join" or data["type"] == "sh_room_update":
                channel_id = data["huddle"]["channel_id"]
            elif "channel" in data and isinstance(data["channel"], str):
                channel_id = data["channel"]
            else:
                if data["type"] not in [
                    "file_public",
                    "file_shared",
                    "file_deleted",
                    "dnd_updated_user",
                ]:
                    log(
                        LogLevel.DEBUG,
                        DebugMessageType.LOG,
                        f"unknown websocket message type (without channel): {data.get('type')}",
                    )
                return

            channel = self.open_conversations.get(channel_id)
            if channel is None:
                if (
                    data["type"] == "message"
                    or data["type"] == "im_open"
                    or data["type"] == "mpim_open"
                    or data["type"] == "group_open"
                    or data["type"] == "channel_joined"
                    or data["type"] == "group_joined"
                ):
                    channel = await self.conversations[channel_id]
                    if channel.type in ["im", "mpim"] or data["type"] in [
                        "channel_joined",
                        "group_joined",
                    ]:
                        await channel.open_buffer()
                        await channel.set_hotlist()
                else:
                    log(
                        LogLevel.DEBUG,
                        DebugMessageType.LOG,
                        "received websocket message for not open conversation, discarding",
                    )
                return

            if data["type"] == "message":
                if "subtype" in data and data["subtype"] == "message_changed":
                    await channel.change_message(data)
                elif "subtype" in data and data["subtype"] == "message_deleted":
                    await channel.delete_message(data)
                elif "subtype" in data and data["subtype"] == "message_replied":
                    await channel.change_message(data)
                else:
                    if "subtype" in data and data["subtype"] == "channel_topic":
                        channel.set_topic(data["topic"])

                    message = SlackMessage(channel, data)
                    await channel.add_new_message(message)
            elif (
                data["type"] == "im_close"
                or data["type"] == "mpim_close"
                or data["type"] == "group_close"
                or data["type"] == "channel_left"
                or data["type"] == "group_left"
            ):
                if channel.buffer_pointer is not None and channel.is_joined:
                    await channel.close_buffer()
            elif data["type"] == "reaction_added" and data["item"]["type"] == "message":
                await channel.reaction_add(
                    SlackTs(data["item"]["ts"]), data["reaction"], data["user"]
                )
            elif (
                data["type"] == "reaction_removed" and data["item"]["type"] == "message"
            ):
                await channel.reaction_remove(
                    SlackTs(data["item"]["ts"]), data["reaction"], data["user"]
                )
            elif (
                data["type"] == "channel_marked"
                or data["type"] == "group_marked"
                or data["type"] == "mpim_marked"
                or data["type"] == "im_marked"
            ):
                channel.last_read = SlackTs(data["ts"])
            elif (
                data["type"] == "thread_marked"
                and data["subscription"]["type"] == "thread"
            ):
                message = channel.messages.get(
                    SlackTs(data["subscription"]["thread_ts"])
                )
                if message:
                    message.last_read = SlackTs(data["subscription"]["last_read"])
            elif (
                data["type"] == "thread_subscribed"
                or data["type"] == "thread_unsubscribed"
            ) and data["subscription"]["type"] == "thread":
                message = channel.messages.get(
                    SlackTs(data["subscription"]["thread_ts"])
                )
                if message:
                    subscribed = data["type"] == "thread_subscribed"
                    await message.update_subscribed(subscribed, data["subscription"])
            elif data["type"] == "sh_room_join" or data["type"] == "sh_room_update":
                await channel.update_message_room(data)
            elif data["type"] == "user_typing":
                await channel.typing_add_user(data)
            else:
                log(
                    LogLevel.DEBUG,
                    DebugMessageType.LOG,
                    f"unknown websocket message type (with channel): {data.get('type')}",
                )
        except Exception as e:
            slack_error = SlackRtmError(self, e, data)
            print_error(store_and_format_exception(slack_error))

    def _set_muted_channels(self, muted_channels: Set[str]):
        changed_channels = self.muted_channels ^ muted_channels
        self.muted_channels = muted_channels
        for channel_id in changed_channels:
            channel = self.open_conversations.get(channel_id)
            if channel:
                channel.update_buffer_props()

    def ping(self):
        if not self.is_connected:
            raise SlackError(self, "Can't ping when not connected")
        if self._ws is None:
            raise SlackError(self, "is_connected is True while _ws is None")

        time_since_last_msg = time.time() - self._last_ws_received_time
        if time_since_last_msg > self.config.network_timeout.value:
            run_async(self.reconnect())
            return

        try:
            self._ws.ping()
            # workspace.last_ping_time = time.time()
        except (WebSocketConnectionClosedException, socket.error):
            print("lost connection on ping, reconnecting")
            run_async(self.reconnect())

    def send_typing(self, buffer: SlackMessageBuffer):
        if not self.is_connected:
            raise SlackError(self, "Can't send typing when not connected")
        if self._ws is None:
            raise SlackError(self, "is_connected is True while _ws is None")

        msg = {
            "type": "user_typing",
            "channel": buffer.conversation.id,
        }
        if isinstance(buffer, SlackThread):
            msg["thread_ts"] = buffer.parent.ts
        self._ws.send(json.dumps(msg))

    async def reconnect(self):
        self.disconnect()
        await self.connect()

    def disconnect(self):
        self.is_connected = False
        self.print(f"Disconnected from workspace {self.name}")

        if self._connect_task:
            self._connect_task.cancel()
            self._connect_task = None

        if self._hook_ws_fd:
            weechat.unhook(self._hook_ws_fd)
            self._hook_ws_fd = None

        if self._ws:
            self._ws.close()
            self._ws = None

    def _buffer_input_cb(self, data: str, buffer: str, input_data: str) -> int:
        self.print(
            f"{weechat.prefix('error')}{shared.SCRIPT_NAME}: this buffer is not a channel!"
        )
        return weechat.WEECHAT_RC_OK

    def _buffer_close_cb(self, data: str, buffer: str) -> int:
        run_async(self._buffer_close())
        return weechat.WEECHAT_RC_OK

    async def _buffer_close(self):
        if shared.script_is_unloading:
            return

        if self.is_connected:
            self.disconnect()

        conversations = list(shared.buffers.values())
        for conversation in conversations:
            if (
                isinstance(conversation, SlackMessageBuffer)
                and conversation.workspace == self
            ):
                await conversation.close_buffer()

        if self.buffer_pointer in shared.buffers:
            del shared.buffers[self.buffer_pointer]

        self.buffer_pointer = None
        self._initial_connect = True


def buffer_new(
    name: str,
    properties: Dict[str, str],
    input_callback: Callable[[str, str, str], int],
    close_callback: Callable[[str, str], int],
) -> str:
    input_callback_name = get_callback_name(input_callback)
    close_callback_name = get_callback_name(close_callback)
    if shared.weechat_version >= 0x03050000:
        buffer_pointer = weechat.buffer_new_props(
            name,
            properties,
            input_callback_name,
            "",
            close_callback_name,
            "",
        )
    else:
        buffer_pointer = weechat.buffer_new(
            name,
            input_callback_name,
            "",
            close_callback_name,
            "",
        )
        for prop_name, value in properties.items():
            weechat.buffer_set(buffer_pointer, prop_name, value)
    return buffer_pointer


if TYPE_CHECKING:
    pass


class WeeChatColor(str):
    pass


@dataclass
class WeeChatConfig:
    name: str

    def __post_init__(self):
        self.pointer = weechat.config_new(self.name, "", "")


@dataclass
class WeeChatSection:
    weechat_config: WeeChatConfig
    name: str
    user_can_add_options: bool = False
    user_can_delete_options: bool = False
    callback_read: str = ""
    callback_write: str = ""

    def __post_init__(self):
        self.pointer = weechat.config_new_section(
            self.weechat_config.pointer,
            self.name,
            self.user_can_add_options,
            self.user_can_delete_options,
            self.callback_read,
            "",
            self.callback_write,
            "",
            "",
            "",
            "",
            "",
            "",
            "",
        )


WeeChatOptionTypes = Union[int, str]
WeeChatOptionType = TypeVar("WeeChatOptionType", bound=WeeChatOptionTypes)


def option_get_value(
    option_pointer: str, option_type: WeeChatOptionType
) -> WeeChatOptionType:
    if isinstance(option_type, bool):
        return cast(WeeChatOptionType, weechat.config_boolean(option_pointer) == 1)
    if isinstance(option_type, int):
        return cast(WeeChatOptionType, weechat.config_integer(option_pointer))
    if isinstance(option_type, WeeChatColor):
        color = weechat.config_color(option_pointer)
        return cast(WeeChatOptionType, WeeChatColor(color))
    return cast(WeeChatOptionType, weechat.config_string(option_pointer))


@dataclass
class WeeChatOption(Generic[WeeChatOptionType]):
    section: WeeChatSection
    name: str
    description: str
    default_value: WeeChatOptionType
    min_value: Optional[int] = None
    max_value: Optional[int] = None
    string_values: Optional[list[WeeChatOptionType]] = None
    parent_option: Union[WeeChatOption[WeeChatOptionType], str, None] = None
    callback_change: Optional[
        Callable[[WeeChatOption[WeeChatOptionType], bool], None]
    ] = None
    evaluate_func: Optional[Callable[[WeeChatOptionType], WeeChatOptionType]] = None

    def __post_init__(self):
        self._pointer = self._create_weechat_option()

    def __bool__(self) -> bool:
        return bool(self.value)

    def _raw_value(self) -> WeeChatOptionType:
        if weechat.config_option_is_null(self._pointer):
            if isinstance(self.parent_option, str):
                parent_option_pointer = weechat.config_get(self.parent_option)
                return option_get_value(parent_option_pointer, self.default_value)
            elif self.parent_option is not None:
                return self.parent_option._raw_value()
            return self.default_value
        return option_get_value(self._pointer, self.default_value)

    @property
    def value(self) -> WeeChatOptionType:
        value = self._raw_value()
        if self.evaluate_func is not None:
            return self.evaluate_func(value)
        return value

    @value.setter
    def value(self, value: WeeChatOptionType):
        value_str = (
            str(value).lower() if isinstance(self.default_value, bool) else str(value)
        )
        rc = self.value_set_as_str(value_str)
        if rc == weechat.WEECHAT_CONFIG_OPTION_SET_ERROR:
            raise Exception(f"Failed to set value for option: {self.name}")

    def value_set_as_str(self, value: str) -> int:
        return weechat.config_option_set(self._pointer, value, 1)

    def value_set_null(self) -> int:
        if self.parent_option is None:
            raise Exception(
                f"Can't set null value for option without parent: {self.name}"
            )
        return weechat.config_option_set_null(self._pointer, 1)

    @property
    def weechat_type(
        self,
    ) -> Literal["integer", "boolean", "color", "string"]:
        if self.string_values:
            return "integer"
        if isinstance(self.default_value, bool):
            return "boolean"
        if isinstance(self.default_value, int):
            return "integer"
        if isinstance(self.default_value, WeeChatColor):
            return "color"
        return "string"

    def _changed_cb(self, data: str, option: str, value: Optional[str] = None):
        if self.callback_change:
            parent_changed = data == "parent_changed"
            if not parent_changed or weechat.config_option_is_null(self._pointer):
                self.callback_change(self, parent_changed)
        return weechat.WEECHAT_RC_OK

    def _create_weechat_option(self) -> str:
        if self.parent_option is not None:
            if isinstance(self.parent_option, str):
                parent_option_name = self.parent_option
                name = f"{self.name} << {parent_option_name}"
            else:
                parent_option_name = (
                    f"{self.parent_option.section.weechat_config.name}"
                    f".{self.parent_option.section.name}"
                    f".{self.parent_option.name}"
                )
                name = f"{self.name} << {parent_option_name}"
            default_value = None
            null_value_allowed = True
            weechat.hook_config(
                parent_option_name,
                get_callback_name(self._changed_cb),
                "parent_changed",
            )
        else:
            name = self.name
            default_value = (
                str(self.default_value).lower()
                if self.weechat_type == "boolean"
                else str(self.default_value)
            )
            null_value_allowed = False

        value = None

        if shared.weechat_version < 0x03050000:
            default_value = str(default_value)
            value = default_value

        return weechat.config_new_option(
            self.section.weechat_config.pointer,
            self.section.pointer,
            name,
            self.weechat_type,
            self.description,
            "|".join(str(x) for x in self.string_values or []),
            self.min_value or -(2**31),
            self.max_value or 2**31 - 1,
            default_value,
            value,
            null_value_allowed,
            "",
            "",
            get_callback_name(self._changed_cb),
            "",
            "",
            "",
        )


sys.path.append(os.path.dirname(os.path.realpath(__file__)))

shared.weechat_callbacks = globals()

if __name__ == "__main__":
    register()
