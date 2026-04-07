import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { BookCard } from "../components/BookCard";
import { LoadingPanel } from "../components/LoadingPanel";
import { fetchCollections } from "../lib/api";

export function CollectionsPage() {
  const [collections, setCollections] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    let active = true;

    fetchCollections()
      .then((payload) => {
        if (active) {
          setCollections(payload.collections || []);
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
  }, []);

  return (
    <div className="page-stack">
      <section className="page-hero">
        <span className="eyebrow-pill">Collections</span>
        <h1>Shelves arranged by mood, genre, and curiosity</h1>
        <p>
          Wander through visual collections designed to feel like rooms inside a beautiful bookstore, each with its own
          pace and personality.
        </p>
      </section>

      {loading ? <LoadingPanel title="Curating collections" detail="Arranging themed shelves for every kind of reader..." /> : null}
      {error ? <p className="error-banner">{error}</p> : null}

      {!loading && !error ? (
        <div className="collection-page-grid">
          {collections.map((collection) => (
            <section key={collection.slug} className={`collection-section ${collection.accent || ""}`}>
              <div className="collection-section__intro">
                <span className="eyebrow-pill subtle">{collection.slug.replace(/_/g, " ")}</span>
                <h2>{collection.title}</h2>
                <p>{collection.description}</p>
                <Link to={`/catalog?subject=${collection.slug}`} className="primary-link">
                  Browse this collection
                </Link>
              </div>

              <div className="book-grid compact-grid">
                {collection.items.map((book) => (
                  <BookCard key={book.work_id} book={book} compact />
                ))}
              </div>
            </section>
          ))}
        </div>
      ) : null}
    </div>
  );
}
