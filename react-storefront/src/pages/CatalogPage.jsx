import { useEffect, useMemo, useState } from "react";
import { useSearchParams } from "react-router-dom";
import { BookCard } from "../components/BookCard";
import { LoadingPanel } from "../components/LoadingPanel";
import { fetchCatalog } from "../lib/api";

const quickSubjects = ["fiction", "fantasy", "romance", "history", "science_fiction", "business"];

export function CatalogPage() {
  const [params, setParams] = useSearchParams();
  const [draftQuery, setDraftQuery] = useState(params.get("q") || "");
  const [payload, setPayload] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  const query = params.get("q") || "";
  const subject = params.get("subject") || "";
  const page = Number(params.get("page") || 1);

  const heading = useMemo(() => {
    if (query) {
      return `Results for "${query}"`;
    }

    if (subject) {
      return `${subject.replace(/_/g, " ")} shelf`;
    }

    return "All books";
  }, [query, subject]);

  useEffect(() => {
    setDraftQuery(query);
  }, [query]);

  useEffect(() => {
    let active = true;
    setLoading(true);
    setError("");

    fetchCatalog({ query, subject, page, limit: 24 })
      .then((nextPayload) => {
        if (active) {
          setPayload(nextPayload);
        }
      })
      .catch((loadError) => {
        if (active) {
          setError(loadError.message);
        }
      })
      .finally(() => {
        if (active) {
          setLoading(false);
        }
      });

    return () => {
      active = false;
    };
  }, [page, query, subject]);

  function updateSearch(nextValues) {
    const merged = {
      q: query,
      subject,
      page: 1,
      ...nextValues,
    };

    if (!merged.q) {
      delete merged.q;
    }

    if (!merged.subject) {
      delete merged.subject;
    }

    if (!merged.page || merged.page === 1) {
      delete merged.page;
    }

    setParams(merged);
  }

  function handleSubmit(event) {
    event.preventDefault();
    updateSearch({ q: draftQuery.trim(), subject: "" });
  }

  return (
    <div className="page-stack">
      <section className="page-hero">
        <span className="eyebrow-pill">Catalog</span>
        <h1>{heading}</h1>
        <p>Search by title, author, subject, or follow one of the visual shelves below to discover something new.</p>
      </section>

      <section className="catalog-toolbar">
        <form className="search-bar catalog" onSubmit={handleSubmit}>
          <input
            value={draftQuery}
            onChange={(event) => setDraftQuery(event.target.value)}
            placeholder="Try fantasy, Murakami, business, poetry..."
            aria-label="Search catalog"
          />
          <button type="submit">Update search</button>
        </form>

        <div className="chip-row">
          {quickSubjects.map((item) => (
            <button key={item} type="button" className="chip-button" onClick={() => updateSearch({ subject: item, q: "" })}>
              {item.replace(/_/g, " ")}
            </button>
          ))}
        </div>
      </section>

      {loading ? <LoadingPanel title="Loading catalog" detail="Turning the page to your next favorite read..." /> : null}
      {error ? <p className="error-banner">{error}</p> : null}

      {!loading && !error && payload ? (
        <>
          <section className="section-frame">
            <div className="section-heading">
              <div>
                <span className="eyebrow-pill subtle">Results</span>
                <h2>{payload.total || 0} titles found</h2>
              </div>
              <span className="result-meta">
                Page {payload.page} of {Math.max(payload.page_count || 1, 1)}
              </span>
            </div>

            <div className="book-grid">
              {(payload.items || []).map((book) => (
                <BookCard key={book.work_id} book={book} />
              ))}
            </div>
          </section>

          <section className="pager-row">
            <button
              type="button"
              className="secondary-link buttonish"
              disabled={page <= 1}
              onClick={() => updateSearch({ page: page - 1 })}
            >
              Previous page
            </button>

            <button
              type="button"
              className="primary-link buttonish"
              disabled={page >= Math.max(payload.page_count || 1, 1)}
              onClick={() => updateSearch({ page: page + 1 })}
            >
              Next page
            </button>
          </section>
        </>
      ) : null}
    </div>
  );
}
