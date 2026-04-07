import { useEffect, useState } from "react";
import { Link, useParams } from "react-router-dom";
import { BookCard } from "../components/BookCard";
import { LoadingPanel } from "../components/LoadingPanel";
import { fetchBookDetail, fetchCatalog } from "../lib/api";

export function BookDetailPage() {
  const { workId } = useParams();
  const [detail, setDetail] = useState(null);
  const [related, setRelated] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    let active = true;

    async function load() {
      try {
        const detailPayload = await fetchBookDetail(workId);
        if (!active) {
          return;
        }

        setDetail(detailPayload.item);

        const primarySubject = (detailPayload.item?.subjects || [])[0];
        if (primarySubject) {
          const relatedPayload = await fetchCatalog({ query: primarySubject, limit: 4 });
          if (active) {
            setRelated((relatedPayload.items || []).filter((item) => item.work_id !== workId).slice(0, 4));
          }
        }
      } catch (loadError) {
        if (active) {
          setError(loadError.message);
        }
      } finally {
        if (active) {
          setLoading(false);
        }
      }
    }

    load();
    return () => {
      active = false;
    };
  }, [workId]);

  if (loading) {
    return <LoadingPanel title="Opening the book" detail="Gathering detail, editions, and subjects..." />;
  }

  if (error || !detail) {
    return <p className="error-banner">{error || "Book detail could not be loaded."}</p>;
  }

  return (
    <div className="page-stack">
      <section className="detail-hero">
        <div className="detail-cover-frame">
          {detail.cover_url ? (
            <img src={detail.cover_url} alt={detail.title} className="detail-cover" />
          ) : (
            <div className="detail-cover placeholder">{detail.title?.slice(0, 1)}</div>
          )}
        </div>

        <div className="detail-copy">
          <span className="eyebrow-pill">Book detail</span>
          <h1>{detail.title}</h1>
          <p className="detail-author">{(detail.authors || []).join(", ") || "Unknown author"}</p>
          <p className="detail-description">
            {detail.description || detail.excerpt || "A richly layered work waiting to be discovered by its next reader."}
          </p>

          <div className="detail-meta-grid">
            <div>
              <strong>First published</strong>
              <span>{detail.first_publish_date || "Unknown"}</span>
            </div>
            <div>
              <strong>Editions</strong>
              <span>{detail.edition_count || "Unknown"}</span>
            </div>
            <div>
              <strong>Subjects</strong>
              <span>{detail.subjects?.slice(0, 3).join(", ") || "General reading"}</span>
            </div>
          </div>
        </div>
      </section>

      <section className="section-frame">
        <div className="section-heading">
          <div>
            <span className="eyebrow-pill subtle">Themes</span>
            <h2>Browse what surrounds this book</h2>
          </div>
        </div>
        <div className="chip-row">
          {(detail.subjects || []).slice(0, 12).map((subject) => (
            <Link key={subject} to={`/catalog?q=${encodeURIComponent(subject)}`} className="chip-link">
              {subject}
            </Link>
          ))}
        </div>
      </section>

      <section className="section-frame">
        <div className="section-heading">
          <div>
            <span className="eyebrow-pill subtle">Editions</span>
            <h2>Available print history</h2>
          </div>
        </div>

        <div className="edition-list">
          {(detail.editions || []).map((edition, index) => (
            <article key={`${edition.title}-${index}`} className="edition-card">
              <strong>{edition.title || "Untitled edition"}</strong>
              <span>{edition.publish_date || "Date unknown"}</span>
              <small>{(edition.publishers || []).join(", ") || "Publisher unavailable"}</small>
            </article>
          ))}
        </div>
      </section>

      {related.length ? (
        <section className="section-frame">
          <div className="section-heading">
            <div>
              <span className="eyebrow-pill subtle">You may also like</span>
              <h2>Continue on the same shelf</h2>
            </div>
          </div>
          <div className="book-grid compact-grid">
            {related.map((book) => (
              <BookCard key={book.work_id} book={book} compact />
            ))}
          </div>
        </section>
      ) : null}
    </div>
  );
}
