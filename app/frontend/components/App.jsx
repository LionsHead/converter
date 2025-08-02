import React, { useState } from 'react';

function App() {
  const [file, setFile] = useState(null);
  const [downloadUrl, setDownloadUrl] = useState(null);
  const [error, setError] = useState(null);
  const [isLoading, setIsLoading] = useState(false);

  const handleFileChange = (event) => {
    setFile(event.target.files[0]);
    setDownloadUrl(null);
    setError(null);
  };

  const handleSubmit = async (event) => {
    event.preventDefault();
    if (!file) {
      setError('Выберите файл!');
      return;
    }

    setIsLoading(true);
    setError(null);
    setDownloadUrl(null);

    const formData = new FormData();
    formData.append('file', file);

    try {
      const response = await fetch('api/upload', {
        method: 'POST',
        body: formData,
      });

      if (!response.ok) {
        throw new Error('Server error: ' + response.statusText);
      }

      const data = await response.json();
      if (data.success && data.url) {
        setDownloadUrl(data.url);
      } else {
        setError(data.error || 'Unexpected error occurred');
      }
    } catch (err) {
      setError(err.message || 'Upload failed');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="hero">
      <h1 className="hero-title">Generate PDF from SVG </h1>
      <form onSubmit={handleSubmit} className="upload-form">
        <input
          type="file"
          onChange={handleFileChange}
          className="file-input"
          disabled={isLoading}
        />
        <button
          type="submit"
          className="btn btn-primary"
          disabled={isLoading || !file}
        >
          {isLoading ? 'Upload...' : 'Upload SVG'}
        </button>
      </form>
      {file && !downloadUrl && <p className="file-info">File: {file.name}</p>}
      {error && <p className="error-message">{error}</p>}
      {downloadUrl && (
        <a
          href={downloadUrl}
          download
          className="btn btn-primary download-btn"
        >
          Export PDF
        </a>
      )}
    </div>
  );
}

export default App;
