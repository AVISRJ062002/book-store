import { Link, NavLink, Outlet } from "react-router-dom";

const links = [
  { to: "/", label: "Home" },
  { to: "/catalog", label: "Catalog" },
  { to: "/collections", label: "Collections" },
  { to: "/about", label: "About" },
];

export function SiteShell() {
  return (
    <div className="app-shell">
      <div className="ambient ambient-one" />
      <div className="ambient ambient-two" />
      <div className="ambient ambient-three" />

      <header className="site-header">
        <div className="brand-lockup">
          <Link to="/" className="brand-mark">
            <span className="brand-mark__icon">B</span>
            <span>
              <strong>Boundless Books</strong>
              <small>Curated stories for every kind of reader</small>
            </span>
          </Link>
        </div>

        <nav className="site-nav" aria-label="Primary">
          {links.map((link) => (
            <NavLink
              key={link.to}
              to={link.to}
              className={({ isActive }) => (isActive ? "nav-link active" : "nav-link")}
            >
              {link.label}
            </NavLink>
          ))}
        </nav>
      </header>

      <main className="site-main">
        <Outlet />
      </main>

      <footer className="site-footer">
        <div>
          <strong>Boundless Books</strong>
          <p>Discover fresh voices, timeless classics, and beautiful pages worth collecting.</p>
        </div>
        <div className="footer-grid">
          <span>AWS serverless frontend and API</span>
          <span>React multi-page reading experience</span>
          <span>Search-driven catalog powered by Open Library</span>
        </div>
      </footer>
    </div>
  );
}
