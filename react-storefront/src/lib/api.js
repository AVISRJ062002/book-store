const API_BASE_URL = (
  import.meta.env.VITE_API_BASE_URL ||
  "https://a295zrp4uk.execute-api.us-east-1.amazonaws.com"
).replace(/\/$/, "");

async function request(path, params = {}) {
  const url = new URL(`${API_BASE_URL}${path}`);

  Object.entries(params).forEach(([key, value]) => {
    if (value !== undefined && value !== null && value !== "") {
      url.searchParams.set(key, String(value));
    }
  });

  const response = await fetch(url.toString());
  if (!response.ok) {
    throw new Error(`Request failed with status ${response.status}`);
  }

  return response.json();
}

export function fetchCatalog({ query, subject, page = 1, limit = 24 }) {
  return request("/books", { q: query, subject, page, limit });
}

export function fetchCollections() {
  return request("/collections");
}

export function fetchBookDetail(workId) {
  return request(`/books/${workId}`);
}

export function getApiBaseUrl() {
  return API_BASE_URL;
}
