import { Link } from "react-router-dom";

export function AboutPage() {
  return (
    <div className="page-stack">
      <section className="page-hero">
        <span className="eyebrow-pill">About</span>
        <h1>A bookstore built like a reading room, not a spreadsheet</h1>
        <p>
          Boundless Books pairs a visual React storefront with AWS serverless delivery so the experience feels rich
          while the infrastructure stays fast, scalable, and cost-aware.
        </p>
      </section>

      <section className="about-grid">
        <article className="about-card">
          <h2>What changed</h2>
          <p>
            The original one-page sample is now a true multi-page React application with a richer catalog, themed
            collections, book detail views, a dedicated cart page, and a more polished editorial look.
          </p>
        </article>
        <article className="about-card">
          <h2>How it works</h2>
          <p>
            CloudFront serves the React app from S3, API Gateway fronts Lambda, and the Lambda API fetches live catalog
            data from Open Library for search, collections, and book detail pages.
          </p>
        </article>
        <article className="about-card">
          <h2>Why it scales</h2>
          <p>
            The frontend is static, the API is event-driven, and the database and background worker stay available for
            future account and order features without introducing EC2.
          </p>
        </article>
      </section>

      <section className="section-frame story-panel">
        <div>
          <span className="eyebrow-pill subtle">Next chapter</span>
          <h2>Ready for more features</h2>
          <p>
            The storefront now supports a persistent local cart and is ready for customer authentication, wishlists,
            checkout, admin inventory, and richer book metadata whenever you want to keep growing the store.
          </p>
        </div>
        <Link to="/cart" className="primary-link">
          Visit your cart
        </Link>
      </section>
    </div>
  );
}
