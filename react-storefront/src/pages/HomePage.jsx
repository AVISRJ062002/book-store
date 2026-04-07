import { useEffect, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { BookCard } from "../components/BookCard";
import { LoadingPanel } from "../components/LoadingPanel";
import { fetchCatalog, fetchCollections, getApiBaseUrl } from "../lib/api";

export function HomePage() {
  const [query, setQuery] = useState("magical realism");
  const [featured, setFeatured] = useState([]);
  const [editorChoice, setEditorChoice] = useState([]);
  const [collections, setCollections] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const navigate = useNavigate();

  useEffect(() => {
    let active = true;

    async function load() {
      try {
        const [featuredPayload, editorPayload, collectionsPayload] = await Promise.all([
          fetchCatalog({ subject: "fiction", limit: 8 }),
          fetchCatalog({ query: "award winning novels", limit: 4 }),
          fetchCollections(),
        ]);

        if (!active) {
          return;
        }

        setFeatured(featuredPayload.items || []);
        setEditorChoice(editorPayload.items || []);
        setCollections((collectionsPayload.collections || []).slice(0, 3));
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
  }, []);

  function handleSubmit(event) {
    event.preventDefault();
    navigate(`/catalog?q=${encodeURIComponent(query.trim() || "fiction")}`);
  }

  return (
    <div className="page-stack">
      <section className="hero-panel">
        <div className="hero-copy">
          <span className="eyebrow-pill">React bookstore experience</span>
          <h1>
            One storefront,
            <br />
            thousands of worlds.
          </h1>
          <p className="hero-lead">
            Browse every genre, search live catalog results, explore themed collections, and slip into richly
            designed reading spaces powered by AWS serverless infrastructure.
          </p>

          <form className="search-bar" onSubmit={handleSubmit}>
            <input
              value={query}
              onChange={(event) => setQuery(event.target.value)}
              placeholder="Search books, authors, or moods"
              aria-label="Search books"
            />
            <button type="submit">Search catalog</button>
          </form>

          <div className="hero-actions">
            <Link to="/catalog?subject=fiction" className="primary-link">
              Browse fiction
            </Link>
            <Link to="/collections" className="secondary-link">
              Explore collections
            </Link>
          </div>
        </div>

        <div className="hero-aside">
          <div className="stat-card">
            <strong>Live API</strong>
            <span>{getApiBaseUrl()}</span>
          </div>
          <div className="stat-card accent">
            <strong>Reading moods</strong>
            <span>Fantasy, romance, business, history, classics, and more.</span>
          </div>
          <div className="quote-card">
            <p>
              "A bookstore should feel like an invitation. Warm light. Wide choice. A story waiting in every corner."
            </p>
          </div>
        </div>
      </section>

      <section className="section-frame">
        <div className="section-heading">
          <div>
            <span className="eyebrow-pill subtle">Featured shelf</span>
            <h2>Popular picks for curious readers</h2>
          </div>
          <Link to="/catalog" className="inline-link">
            See full catalog
          </Link>
        </div>

        {loading ? <LoadingPanel /> : null}
        {error ? <p className="error-banner">{error}</p> : null}

        {!loading && !error ? (
          <div className="book-grid">
            {featured.map((book) => (
              <BookCard key={book.work_id} book={book} />
            ))}
          </div>
        ) : null}
      </section>

      <section className="section-frame editorial-band">
        <div className="section-heading">
          <div>
            <span className="eyebrow-pill subtle">Editor's note</span>
            <h2>Fresh arrivals with lasting charm</h2>
          </div>
        </div>

        <div className="editorial-grid">
          {editorChoice.map((book) => (
            <BookCard key={book.work_id} book={book} compact />
          ))}
        </div>
      </section>

      <section className="section-frame">
        <div className="section-heading">
          <div>
            <span className="eyebrow-pill subtle">Curated paths</span>
            <h2>Shop by collection</h2>
          </div>
          <Link to="/collections" className="inline-link">
            View every collection
          </Link>
        </div>

        <div className="collection-grid">
          {collections.map((collection) => (
            <article key={collection.slug} className={`collection-card ${collection.accent || ""}`}>
              <div>
                <span className="collection-card__label">{collection.slug.replace(/_/g, " ")}</span>
                <h3>{collection.title}</h3>
                <p>{collection.description}</p>
              </div>
              <div className="collection-card__stack">
                {collection.items.slice(0, 3).map((book) => (
                  <Link key={book.work_id} to={`/book/${book.work_id}`} className="mini-book">
                    <span>{book.title}</span>
                    <small>{book.author_line}</small>
                  </Link>
                ))}
              </div>
              <Link to={`/catalog?subject=${collection.slug}`} className="inline-link">
                Open this shelf
              </Link>
            </article>
          ))}
        </div>
      </section>
    </div>
  );
}
