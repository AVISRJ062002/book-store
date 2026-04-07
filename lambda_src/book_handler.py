import concurrent.futures
import json
import math
import os
import urllib.parse
import urllib.request


SEARCH_API_BASE_URL = os.getenv("EXTERNAL_API_BASE_URL", "https://openlibrary.org/search.json")
WORKS_API_BASE_URL = "https://openlibrary.org/works"
SUBJECTS_API_BASE_URL = "https://openlibrary.org/subjects"

DEFAULT_COLLECTIONS = [
    {
        "slug": "fiction",
        "title": "Fiction Favorites",
        "description": "Page-turners, literary fiction, and modern classics for every mood.",
        "query": "fiction bestsellers",
        "accent": "sunset",
    },
    {
        "slug": "fantasy",
        "title": "Fantasy Worlds",
        "description": "Epic quests, magical cities, and unforgettable mythical worlds.",
        "query": "fantasy adventures",
        "accent": "violet",
    },
    {
        "slug": "romance",
        "title": "Romance Reads",
        "description": "Slow burns, sweeping love stories, and reader favorites.",
        "query": "romance novels",
        "accent": "rose",
    },
    {
        "slug": "science_fiction",
        "title": "Science Fiction",
        "description": "Futures, space travel, and daring speculative fiction.",
        "query": "science fiction",
        "accent": "aurora",
    },
    {
        "slug": "history",
        "title": "History & Culture",
        "description": "Biographies, world history, and cultural storytelling.",
        "query": "history books",
        "accent": "bronze",
    },
    {
        "slug": "business",
        "title": "Business & Growth",
        "description": "Leadership, strategy, startups, and practical career reads.",
        "query": "business strategy",
        "accent": "evergreen",
    },
]

FALLBACK_SEARCH_ITEMS = [
    {
        "work_id": "OL27448W",
        "title": "Designing Data-Intensive Applications",
        "subtitle": None,
        "authors": ["Martin Kleppmann"],
        "author_line": "Martin Kleppmann",
        "first_publish_year": 2017,
        "edition_count": 1,
        "languages": ["eng"],
        "subjects": ["systems", "distributed systems", "data"],
        "cover_url": None,
        "cover_thumbnail_url": None,
        "ratings_average": None,
        "ratings_count": None,
    },
    {
        "work_id": "OL17930368W",
        "title": "Clean Architecture",
        "subtitle": None,
        "authors": ["Robert C. Martin"],
        "author_line": "Robert C. Martin",
        "first_publish_year": 2017,
        "edition_count": 1,
        "languages": ["eng"],
        "subjects": ["architecture", "software engineering"],
        "cover_url": None,
        "cover_thumbnail_url": None,
        "ratings_average": None,
        "ratings_count": None,
    },
]


def _response(status_code: int, payload: dict) -> dict:
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET,OPTIONS",
            "Access-Control-Allow-Headers": "Content-Type",
            "Cache-Control": "public, max-age=120",
        },
        "body": json.dumps(payload),
    }


def _json_request(url: str, timeout: int = 6) -> dict:
    request = urllib.request.Request(
        url,
        headers={"User-Agent": "bookstore-public-api/2.0"},
    )

    with urllib.request.urlopen(request, timeout=timeout) as response:
        return json.loads(response.read().decode("utf-8"))


def _normalize_work_id(key: str | None) -> str | None:
    if not key:
        return None

    return key.rsplit("/", 1)[-1]


def _cover_url(cover_id: int | None, size: str = "L") -> str | None:
    if not cover_id:
        return None

    return f"https://covers.openlibrary.org/b/id/{cover_id}-{size}.jpg"


def _description_text(raw_description) -> str:
    if isinstance(raw_description, str):
        return raw_description

    if isinstance(raw_description, dict):
        return raw_description.get("value", "")

    return ""


def _get_int(query_params: dict, key: str, default: int, minimum: int, maximum: int) -> int:
    try:
        value = int(query_params.get(key, default))
    except (TypeError, ValueError):
        value = default

    return max(minimum, min(maximum, value))


def _book_from_search_doc(book: dict) -> dict:
    work_id = _normalize_work_id(book.get("key"))
    authors = book.get("author_name") or []
    cover_id = book.get("cover_i")

    return {
        "work_id": work_id,
        "title": book.get("title"),
        "subtitle": book.get("subtitle"),
        "authors": authors,
        "author_line": ", ".join(authors[:3]) if authors else "Unknown author",
        "first_publish_year": book.get("first_publish_year"),
        "edition_count": book.get("edition_count"),
        "languages": sorted(set(book.get("language", [])[:5])),
        "subjects": book.get("subject", [])[:8],
        "cover_url": _cover_url(cover_id),
        "cover_thumbnail_url": _cover_url(cover_id, "M"),
        "ratings_average": book.get("ratings_average"),
        "ratings_count": book.get("ratings_count"),
    }


def _book_from_subject_work(book: dict) -> dict:
    work_id = _normalize_work_id(book.get("key"))
    authors = [author.get("name") for author in book.get("authors", []) if author.get("name")]
    cover_id = book.get("cover_id")

    return {
        "work_id": work_id,
        "title": book.get("title"),
        "subtitle": None,
        "authors": authors,
        "author_line": ", ".join(authors[:3]) if authors else "Unknown author",
        "first_publish_year": book.get("first_publish_year"),
        "edition_count": book.get("edition_count"),
        "languages": [],
        "subjects": book.get("subject", [])[:8],
        "cover_url": _cover_url(cover_id),
        "cover_thumbnail_url": _cover_url(cover_id, "M"),
        "ratings_average": None,
        "ratings_count": None,
    }


def _search_books(query_params: dict) -> dict:
    query = (query_params.get("q") or "").strip()
    subject = (query_params.get("subject") or "").strip()
    page = _get_int(query_params, "page", 1, 1, 50)
    limit = _get_int(query_params, "limit", 20, 1, 40)

    if not query and subject:
        query = f"subject:{subject}"

    if not query:
        query = "bestsellers"

    request_url = f"{SEARCH_API_BASE_URL}?{urllib.parse.urlencode({'q': query, 'page': page, 'limit': limit})}"
    payload = _json_request(request_url)

    total = payload.get("numFound", 0)
    items = [_book_from_search_doc(book) for book in payload.get("docs", [])[:limit]]

    return {
        "source": "openlibrary",
        "query": query,
        "subject": subject or None,
        "page": page,
        "limit": limit,
        "count": len(items),
        "total": total,
        "page_count": math.ceil(total / limit) if total else 0,
        "items": items,
    }


def _fetch_authors(author_entries: list[dict]) -> list[str]:
    author_keys = []

    for author_entry in author_entries[:4]:
        author_key = ((author_entry or {}).get("author") or {}).get("key")
        if author_key:
            author_keys.append(author_key)

    if not author_keys:
        return []

    def load_author(author_key: str) -> str | None:
        try:
            author_payload = _json_request(f"https://openlibrary.org{author_key}.json", timeout=5)
            return author_payload.get("name")
        except Exception:
            return None

    with concurrent.futures.ThreadPoolExecutor(max_workers=len(author_keys)) as executor:
        names = list(executor.map(load_author, author_keys))

    return [name for name in names if name]


def _book_detail(work_id: str) -> dict:
    work_payload = _json_request(f"{WORKS_API_BASE_URL}/{work_id}.json")
    editions_payload = _json_request(f"{WORKS_API_BASE_URL}/{work_id}/editions.json?limit=6")

    authors = _fetch_authors(work_payload.get("authors", []))
    cover_ids = work_payload.get("covers", [])
    excerpts = work_payload.get("excerpts", [])

    editions = []
    for edition in editions_payload.get("entries", [])[:6]:
        editions.append(
            {
                "title": edition.get("title"),
                "publish_date": edition.get("publish_date"),
                "publishers": edition.get("publishers", [])[:2],
                "cover_url": _cover_url((edition.get("covers") or [None])[0], "M"),
            }
        )

    return {
        "source": "openlibrary",
        "item": {
            "work_id": work_id,
            "title": work_payload.get("title"),
            "description": _description_text(work_payload.get("description")),
            "authors": authors,
            "subjects": work_payload.get("subjects", [])[:16],
            "subject_places": work_payload.get("subject_places", [])[:8],
            "subject_people": work_payload.get("subject_people", [])[:8],
            "first_publish_date": work_payload.get("first_publish_date"),
            "first_sentence": _description_text(work_payload.get("first_sentence")),
            "excerpt": _description_text(excerpts[0]) if excerpts else "",
            "links": work_payload.get("links", [])[:4],
            "cover_url": _cover_url(cover_ids[0]) if cover_ids else None,
            "cover_thumbnail_url": _cover_url(cover_ids[0], "M") if cover_ids else None,
            "edition_count": editions_payload.get("size", len(editions)),
            "editions": editions,
        },
    }


def _collections() -> dict:
    def load_collection(collection: dict) -> dict:
        try:
            payload = _json_request(f"{SUBJECTS_API_BASE_URL}/{collection['slug']}.json?limit=6", timeout=5)
            items = [_book_from_subject_work(book) for book in payload.get("works", [])[:6]]
        except Exception:
            items = []

        return {
            **collection,
            "items": items,
        }

    with concurrent.futures.ThreadPoolExecutor(max_workers=len(DEFAULT_COLLECTIONS)) as executor:
        collections = list(executor.map(load_collection, DEFAULT_COLLECTIONS))

    return {
        "source": "openlibrary",
        "collections": collections,
    }


def _fallback_book_detail(work_id: str, warning: str) -> dict:
    fallback_lookup = {item["work_id"]: item for item in FALLBACK_SEARCH_ITEMS}
    search_item = fallback_lookup.get(
        work_id,
        {
            "work_id": work_id,
            "title": "Book details are temporarily unavailable",
            "authors": ["Bookstore API"],
            "first_publish_year": None,
            "edition_count": 0,
            "subjects": ["books", "reading"],
        },
    )

    return {
        "source": "fallback",
        "warning": warning,
        "item": {
            "work_id": work_id,
            "title": search_item.get("title"),
            "description": "Live book details are temporarily unavailable, so this page is showing a graceful fallback.",
            "authors": search_item.get("authors", []),
            "subjects": search_item.get("subjects", []),
            "subject_places": [],
            "subject_people": [],
            "first_publish_date": search_item.get("first_publish_year"),
            "first_sentence": "",
            "excerpt": "",
            "links": [],
            "cover_url": search_item.get("cover_url"),
            "cover_thumbnail_url": search_item.get("cover_thumbnail_url"),
            "edition_count": search_item.get("edition_count"),
            "editions": [],
        },
    }


def lambda_handler(event, _context):
    request_context = event.get("requestContext") or {}
    http_context = request_context.get("http") or {}
    method = (http_context.get("method") or "GET").upper()
    path = event.get("rawPath") or http_context.get("path") or "/books"
    query_params = event.get("queryStringParameters") or {}

    try:
        if method == "OPTIONS":
            return _response(200, {"ok": True})

        if path == "/health":
            return _response(200, {"status": "ok", "service": "bookstore-api"})

        if path == "/collections":
            return _response(200, _collections())

        if path == "/books":
            return _response(200, _search_books(query_params))

        if path.startswith("/books/"):
            work_id = path.rsplit("/", 1)[-1].strip()
            if not work_id:
                return _response(400, {"error": "work_id is required"})
            return _response(200, _book_detail(work_id))

        return _response(404, {"error": "Route not found", "path": path})
    except Exception as exc:
        warning = f"OpenLibrary request failed: {exc}"

        if path == "/collections":
            return _response(
                200,
                {
                    "source": "fallback",
                    "warning": warning,
                    "collections": [{**collection, "items": []} for collection in DEFAULT_COLLECTIONS],
                },
            )

        if path.startswith("/books/"):
            return _response(200, _fallback_book_detail(path.rsplit("/", 1)[-1].strip() or "unknown", warning))

        return _response(
            200,
            {
                "source": "fallback",
                "warning": warning,
                "page": 1,
                "limit": len(FALLBACK_SEARCH_ITEMS),
                "count": len(FALLBACK_SEARCH_ITEMS),
                "total": len(FALLBACK_SEARCH_ITEMS),
                "page_count": 1,
                "items": FALLBACK_SEARCH_ITEMS,
            },
        )
