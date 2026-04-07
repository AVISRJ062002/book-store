import { Navigate, Route, Routes } from "react-router-dom";
import { SiteShell } from "./components/Layout";
import { HomePage } from "./pages/HomePage";
import { CatalogPage } from "./pages/CatalogPage";
import { CollectionsPage } from "./pages/CollectionsPage";
import { BookDetailPage } from "./pages/BookDetailPage";
import { AboutPage } from "./pages/AboutPage";

export default function App() {
  return (
    <Routes>
      <Route element={<SiteShell />}>
        <Route path="/" element={<HomePage />} />
        <Route path="/catalog" element={<CatalogPage />} />
        <Route path="/collections" element={<CollectionsPage />} />
        <Route path="/book/:workId" element={<BookDetailPage />} />
        <Route path="/about" element={<AboutPage />} />
        <Route path="*" element={<Navigate to="/" replace />} />
      </Route>
    </Routes>
  );
}
