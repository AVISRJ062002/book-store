const formatter = new Intl.NumberFormat("en-US", {
  style: "currency",
  currency: "USD",
});

function hashSeed(seed) {
  return [...seed].reduce((total, character) => total * 31 + character.charCodeAt(0), 7);
}

export function getAuthorLine(book) {
  if (book.author_line) {
    return book.author_line;
  }

  if (Array.isArray(book.authors) && book.authors.length) {
    return book.authors.slice(0, 3).join(", ");
  }

  return "Unknown author";
}

export function getBookPriceCents(book) {
  const seed = book?.work_id || book?.title || "boundless-books";
  const hash = Math.abs(hashSeed(seed));
  return 1299 + (hash % 2200);
}

export function getBookListPriceCents(book) {
  const priceCents = getBookPriceCents(book);
  return priceCents + 500 + (priceCents % 350);
}

export function formatCurrency(amountCents) {
  return formatter.format((amountCents || 0) / 100);
}

export function buildCartItem(book) {
  return {
    work_id: book.work_id,
    title: book.title || "Untitled book",
    subtitle: book.subtitle || "",
    author_line: getAuthorLine(book),
    cover_url: book.cover_url || book.cover_thumbnail_url || null,
    price_cents: getBookPriceCents(book),
  };
}
