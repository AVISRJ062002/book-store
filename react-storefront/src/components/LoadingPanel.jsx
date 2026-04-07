export function LoadingPanel({ title = "Loading shelf", detail = "Gathering fresh titles for you..." }) {
  return (
    <div className="loading-panel">
      <div className="loading-panel__spinner" />
      <div>
        <strong>{title}</strong>
        <p>{detail}</p>
      </div>
    </div>
  );
}
