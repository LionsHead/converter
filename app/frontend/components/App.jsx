import React, { useState, useEffect } from 'react';

function App() {
  const [file, setFile] = useState(null);
  const [documentId, setDocumentId] = useState(null);
  const [documentData, setDocumentData] = useState(null);
  const [error, setError] = useState(null);
  const [isUploading, setIsUploading] = useState(false);
  const [isPolling, setIsPolling] = useState(false);

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
      case 'validation':
        return 'Validating...';
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
      case 'validation':
        return 'status-validation';
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

  return (
    <div className="hero">
      <h1 className="hero-title">Generate PDF from SVG</h1>

      <div className="upload-form">
        <input
          type="file"
          accept=".svg"
          onChange={handleFileChange}
          className="file-input"
          disabled={isUploading || isPolling}
        />
        <button
          onClick={handleSubmit}
          className="btn btn-primary"
          disabled={isUploading || !file || isPolling}
        >
          <i class="fa-solid fa-upload"></i>
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

        </div>
      )}


      {documentData && documentData.pdf_file_url && (
        <div className="upload-form">
          <a
            href={documentData.pdf_file_url}
            download
            className="btn btn-primary download-btn"
          >
            <i class="fa-solid fa-download"></i>
            {' Download PDF'}
            </a>
        </div>
      )}
    </div>
  );
}

export default App;
