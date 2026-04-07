import { Link } from "react-router-dom";
import { useCart } from "../context/CartContext";
import { formatCurrency, getBookListPriceCents, getBookPriceCents } from "../lib/pricing";

function CoverArt({ book }) {
  if (book.cover_url) {
    return <img src={book.cover_url} alt={book.title} loading="lazy" className="book-card__cover" />;
  }

  return (
    <div className="book-card__placeholder">
      <span>{book.title?.slice(0, 1) || "B"}</span>
    </div>
  );
}

export function BookCard({ book, compact = false }) {
  const { addItem, getQuantity } = useCart();
  const quantityInCart = getQuantity(book.work_id);
  const priceCents = getBookPriceCents(book);
  const listPriceCents = getBookListPriceCents(book);

  return (
    <article className={`book-card ${compact ? "compact" : ""}`}>
      <Link to={`/book/${book.work_id}`} className="book-card__link">
        <div className="book-card__visual">
          <CoverArt book={book} />
          {book.first_publish_year ? <span className="book-card__badge">{book.first_publish_year}</span> : null}
        </div>

        <div className="book-card__content">
          <p className="book-card__eyebrow">{book.author_line || "Unknown author"}</p>
          <h3>{book.title}</h3>
          {book.subtitle ? <p className="book-card__subtitle">{book.subtitle}</p> : null}
          <div className="book-card__meta">
            <span>{book.edition_count ? `${book.edition_count} editions` : "Reader favorite"}</span>
            <span>{book.subjects?.[0] || "General reading"}</span>
          </div>
        </div>
      </Link>

      <div className="book-card__footer">
        <div className="book-card__pricing">
          <strong>{formatCurrency(priceCents)}</strong>
          <small>List {formatCurrency(listPriceCents)}</small>
        </div>

        <div className="book-card__actions">
          {quantityInCart ? <span className="book-card__cart-state">{quantityInCart} in cart</span> : null}
          <button type="button" className="book-card__action" onClick={() => addItem(book)}>
            {quantityInCart ? "Add another" : "Add to cart"}
          </button>
        </div>
      </div>
    </article>
  );
}
