import React, { useState, useEffect } from 'react';
function App() {
  const [file, setFile] = useState(null);
  const [documentId, setDocumentId] = useState(null);
  const [documentData, setDocumentData] = useState(null);
  const [error, setError] = useState(null);
  const [isUploading, setIsUploading] = useState(false);
  const [isPolling, setIsPolling] = useState(false);
  const [checkForAI, setCheckForAI] = useState(false);

  const handleFileChange = (event) => {
    setFile(event.target.files[0]);
    setDocumentId(null);
    setDocumentData(null);
    setError(null);
  };
  const handleSubmit = async () => {
    if (!file) {
      setError('Please select a file!');
      return;
    }
    setIsUploading(true);
    setError(null);
    setDocumentId(null);
    setDocumentData(null);
    const formData = new FormData();
    formData.append('svg_file', file);
    formData.append('check_with_ai', checkForAI);
    try {
      const response = await fetch('/api/v1/documents', {
        method: 'POST',
        body: formData,
      });
      if (!response.ok) {
        throw new Error('Server error: ' + response.statusText);
      }
      const data = await response.json();
      if (data.id) {
        setDocumentId(data.id);
        setDocumentData(data);
        setIsPolling(true);
      } else {
        setError('Unexpected error occurred');
      }
    } catch (err) {
      setError(err.message || 'Upload failed');
    } finally {
      setIsUploading(false);
    }
  };
  const checkDocumentStatus = async (id) => {
    try {
      const response = await fetch(`/api/v1/documents/${id}`);
      if (!response.ok) {
        throw new Error('Failed to check document status');
      }
      const data = await response.json();
      setDocumentData(data);
      if (data.status === 'completed' || data.status === 'failed' || data.status === 'validation_failed') {
        setIsPolling(false);
      }
    } catch (err) {
      setError(err.message || 'Failed to check status');
      setIsPolling(false);
    }
  };
  useEffect(() => {
    let interval;
    if (isPolling && documentId) {
      interval = setInterval(() => {
        checkDocumentStatus(documentId);
      }, 1000);
    }
    return () => clearInterval(interval);
  }, [isPolling, documentId]);
  const getStatusText = (status) => {
    switch (status) {
      case 'pending':
        return 'Waiting...';
      case 'processing':
        return 'Processing...';
      case 'validating':
        return checkForAI ? 'Validating with LLM improvements...' : 'Validating...';
      case 'validation_failed':
        return 'Validation failed';
      case 'completed':
        return 'Completed!';
      case 'failed':
        return 'Failed';
      default:
        return status;
    }
  };
  const getStatusClass = (status) => {
    switch (status) {
      case 'pending':
        return 'status-pending';
      case 'processing':
        return 'status-processing';
      case 'validating':
        return 'status-validating';
      case 'validation_failed':
        return 'status-validation-failed';
      case 'completed':
        return 'status-completed';
      case 'failed':
        return 'status-failed';
      default:
        return 'status-pending';
    }
  };
  const isFormDisabled = isUploading || isPolling;
  return (
    <div className="hero">
      <div className="docs-links">
        <a
          href="/api-docs/index.html"
          target="_blank"
          rel="noopener noreferrer"
          className="btn btn-docs"
        >
          <i className="fa-solid fa-book"></i> API Docs
        </a>
        <a
          href="https://github.com/LionsHead/converter"
          target="_blank"
          rel="noopener noreferrer"
          className="btn btn-docs"
        >
          <i className="fa-brands fa-github"></i> GitHub
        </a>
      </div>
      <h1 className="hero-title">Generate PDF from SVG</h1>
      <div className="upload-form">
        <input
          type="file"
          accept=".svg"
          onChange={handleFileChange}
          className="file-input"
          disabled={isFormDisabled}
        />
        <div className="checkbox-container">
          <input
            type="checkbox"
            id="checkForAI"
            checked={checkForAI}
            onChange={(e) => setCheckForAI(e.target.checked)}
            disabled={isFormDisabled}
          />
          <label htmlFor="checkForAI" className="checkbox-label">Check with AI</label>
        </div>
        <button
          onClick={handleSubmit}
          className="btn btn-primary"
          disabled={isFormDisabled || !file}
        >
          <i className="fa-solid fa-upload"></i>
          {isUploading ? ' Uploading...' : ' Upload SVG'}
        </button>
      </div>
      {file && !documentData && (
        <p className="file-info">File: {file.name}</p>
      )}
      {error && (
        <p className="error-message">{error}</p>
      )}
      {documentData && (
        <div className="document-status">
          <p className="file-info">
            File: {documentData.original_file_name}
          </p>
          <div className={`status ${getStatusClass(documentData.status)}`}>
            <span className="status-text">
              {getStatusText(documentData.status)}
            </span>
            {isPolling && (
              <div className="spinner"></div>
            )}
          </div>
          {['completed', 'failed', 'validation_failed'].includes(documentData.status) &&
            documentData.issues_found?.length > 0 && (
              <div className="issues-section">
                <h3>
                  <i className="fa-solid fa-check-circle"></i> Issues Fixed
                </h3>
                <ul className="issues-list">
                  {documentData.issues_found.map((issue, index) => (
                    <li key={index}>{issue}</li>
                  ))}
                </ul>
              </div>
            )}
          {['completed', 'failed', 'validation_failed'].includes(documentData.status) &&
            documentData.warnings?.length > 0 && (
              <div className="warnings-section">
                <h3>
                  <i className="fa-solid fa-exclamation-triangle"></i> Warnings
                </h3>
                <ul className="warnings-list">
                  {documentData.warnings.map((warning, index) => (
                    <li key={index}>{warning}</li>
                  ))}
                </ul>
              </div>
            )}
        </div>
      )}
      {documentData && documentData.pdf_file_url && (
        <div className="upload-form">
          <a
            href={documentData.pdf_file_url}
            target="_blank"
            rel="noopener noreferrer"
            className="btn btn-primary download-btn"
          >
            <i className="fa-solid fa-download"></i>
            {' Download PDF'}
          </a>
        </div>
      )}
    </div>
  );
}
export default App;
