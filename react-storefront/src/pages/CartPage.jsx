import { Link } from "react-router-dom";
import { useCart } from "../context/CartContext";
import { formatCurrency } from "../lib/pricing";

function CartCover({ item }) {
  if (item.cover_url) {
    return (
      <div className="cart-item__visual">
        <img src={item.cover_url} alt={item.title} loading="lazy" />
      </div>
    );
  }

  return <div className="cart-item__placeholder">{item.title?.slice(0, 1) || "B"}</div>;
}

export function CartPage() {
  const { items, itemCount, subtotalCents, updateQuantity, removeItem, clearCart } = useCart();

  const estimatedTaxCents = Math.round(subtotalCents * 0.08);
  const totalCents = subtotalCents + estimatedTaxCents;

  if (!items.length) {
    return (
      <div className="page-stack">
        <section className="page-hero">
          <span className="eyebrow-pill">Cart</span>
          <h1>Your reading stack is empty for now</h1>
          <p>
            Add books from the catalog, collections, or detail pages and they will stay in this browser so you can
            return to them later.
          </p>
        </section>

        <section className="empty-cart">
          <h2>Build a shelf worth taking home</h2>
          <p className="cart-note">
            Start with a genre collection, a new release, or a timeless classic and your cart will begin to fill up
            right away.
          </p>
          <div className="cart-actions">
            <Link to="/catalog" className="primary-link">
              Browse the catalog
            </Link>
            <Link to="/collections" className="secondary-link">
              Explore collections
            </Link>
          </div>
        </section>
      </div>
    );
  }

  return (
    <div className="page-stack">
      <section className="page-hero">
        <span className="eyebrow-pill">Cart</span>
        <h1>Your curated reading cart</h1>
        <p>
          Review every title, adjust quantities, and keep building your order. This cart is saved locally in your
          browser for a smooth storefront demo flow.
        </p>
      </section>

      <section className="cart-layout">
        <div className="cart-panel">
          <div className="section-heading">
            <div>
              <span className="eyebrow-pill subtle">Selections</span>
              <h2>{itemCount} {itemCount === 1 ? "book" : "books"} ready</h2>
            </div>
            <button type="button" className="text-link-button" onClick={clearCart}>
              Clear cart
            </button>
          </div>

          <div className="cart-items">
            {items.map((item) => (
              <article key={item.work_id} className="cart-item">
                <CartCover item={item} />

                <div className="cart-item__line">
                  <span className="cart-item__meta">{item.author_line}</span>
                  <Link to={`/book/${item.work_id}`}>
                    <h3>{item.title}</h3>
                  </Link>
                  {item.subtitle ? <small>{item.subtitle}</small> : null}

                  <div className="cart-item__controls">
                    <button
                      type="button"
                      className="qty-button"
                      onClick={() => updateQuantity(item.work_id, item.quantity - 1)}
                    >
                      -
                    </button>
                    <span className="qty-display">{item.quantity}</span>
                    <button
                      type="button"
                      className="qty-button"
                      onClick={() => updateQuantity(item.work_id, item.quantity + 1)}
                    >
                      +
                    </button>
                    <button type="button" className="text-link-button" onClick={() => removeItem(item.work_id)}>
                      Remove
                    </button>
                  </div>
                </div>

                <div className="cart-item__amount">
                  <small>{formatCurrency(item.price_cents)} each</small>
                  <strong>{formatCurrency(item.price_cents * item.quantity)}</strong>
                </div>
              </article>
            ))}
          </div>
        </div>

        <aside className="cart-summary">
          <div>
            <span className="eyebrow-pill subtle">Order summary</span>
            <h2>Cart total</h2>
          </div>

          <div className="cart-summary__rows">
            <div className="cart-summary__row">
              <span className="cart-summary__label">Subtotal</span>
              <span>{formatCurrency(subtotalCents)}</span>
            </div>
            <div className="cart-summary__row">
              <span className="cart-summary__label">Estimated tax</span>
              <span>{formatCurrency(estimatedTaxCents)}</span>
            </div>
            <div className="summary-total">
              <strong>Estimated total</strong>
              <strong>{formatCurrency(totalCents)}</strong>
            </div>
          </div>

          <p className="cart-note">
            This is a storefront-ready cart experience. The next natural step would be checkout, customer sign-in, and
            order persistence in the database.
          </p>

          <div className="cart-actions">
            <Link to="/catalog" className="primary-link">
              Keep shopping
            </Link>
            <Link to="/collections" className="secondary-link">
              Browse shelves
            </Link>
          </div>
        </aside>
      </section>
    </div>
  );
}
