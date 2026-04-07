import { createContext, useContext, useEffect, useState } from "react";
import { buildCartItem, getBookPriceCents } from "../lib/pricing";

const STORAGE_KEY = "boundless-books-cart";
const CartContext = createContext(null);

function normalizeStoredItem(item) {
  if (!item || !item.work_id) {
    return null;
  }

  const quantity = Math.max(1, Number(item.quantity) || 1);
  const priceCents = Math.max(0, Number(item.price_cents) || getBookPriceCents(item));

  return {
    work_id: item.work_id,
    title: item.title || "Untitled book",
    subtitle: item.subtitle || "",
    author_line: item.author_line || "Unknown author",
    cover_url: item.cover_url || item.cover_thumbnail_url || null,
    price_cents: priceCents,
    quantity,
  };
}

function readInitialCart() {
  if (typeof window === "undefined") {
    return [];
  }

  try {
    const raw = window.localStorage.getItem(STORAGE_KEY);
    if (!raw) {
      return [];
    }

    const parsed = JSON.parse(raw);
    if (!Array.isArray(parsed)) {
      return [];
    }

    return parsed.map(normalizeStoredItem).filter(Boolean);
  } catch {
    return [];
  }
}

export function CartProvider({ children }) {
  const [items, setItems] = useState(readInitialCart);

  useEffect(() => {
    window.localStorage.setItem(STORAGE_KEY, JSON.stringify(items));
  }, [items]);

  function addItem(book, quantity = 1) {
    const nextItem = buildCartItem(book);

    setItems((currentItems) => {
      const existingItem = currentItems.find((item) => item.work_id === nextItem.work_id);

      if (existingItem) {
        return currentItems.map((item) =>
          item.work_id === nextItem.work_id
            ? { ...item, quantity: item.quantity + quantity }
            : item,
        );
      }

      return [...currentItems, { ...nextItem, quantity }];
    });
  }

  function updateQuantity(workId, quantity) {
    if (quantity <= 0) {
      removeItem(workId);
      return;
    }

    setItems((currentItems) =>
      currentItems.map((item) =>
        item.work_id === workId
          ? { ...item, quantity }
          : item,
      ),
    );
  }

  function removeItem(workId) {
    setItems((currentItems) => currentItems.filter((item) => item.work_id !== workId));
  }

  function clearCart() {
    setItems([]);
  }

  function getQuantity(workId) {
    return items.find((item) => item.work_id === workId)?.quantity || 0;
  }

  const itemCount = items.reduce((sum, item) => sum + item.quantity, 0);
  const subtotalCents = items.reduce((sum, item) => sum + item.price_cents * item.quantity, 0);

  return (
    <CartContext.Provider
      value={{
        items,
        itemCount,
        subtotalCents,
        addItem,
        updateQuantity,
        removeItem,
        clearCart,
        getQuantity,
      }}
    >
      {children}
    </CartContext.Provider>
  );
}

export function useCart() {
  const context = useContext(CartContext);

  if (!context) {
    throw new Error("useCart must be used inside CartProvider");
  }

  return context;
}
