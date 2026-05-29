"use client";

import { useState, useCallback, useRef } from "react";
import { Upload, X, FileImage, CheckCircle, AlertCircle } from "lucide-react";
import { api } from "@/lib/api";

interface FileItem {
  file: File;
  id: string;
  status: "pending" | "uploading" | "success" | "error";
  progress: number;
  error?: string;
  preview?: string;
}

export function ReceiptUpload() {
  const [files, setFiles] = useState<FileItem[]>([]);
  const [isDragging, setIsDragging] = useState(false);
  const [isUploading, setIsUploading] = useState(false);
  const inputRef = useRef<HTMLInputElement>(null);

  const handleFiles = useCallback((newFiles: FileList | File[]) => {
    const items: FileItem[] = Array.from(newFiles)
      .filter((f) => {
        const allowed = ["image/jpeg", "image/png", "image/webp", "application/pdf"];
        return allowed.includes(f.type) && f.size <= 10 * 1024 * 1024;
      })
      .map((f) => {
        const item: FileItem = {
          file: f,
          id: crypto.randomUUID(),
          status: "pending",
          progress: 0,
        };

        if (f.type.startsWith("image/")) {
          item.preview = URL.createObjectURL(f);
        }

        return item;
      });

    setFiles((prev) => [...prev, ...items]);
  }, []);

  const handleDrop = useCallback(
    (e: React.DragEvent) => {
      e.preventDefault();
      setIsDragging(false);
      if (e.dataTransfer.files) handleFiles(e.dataTransfer.files);
    },
    [handleFiles]
  );

  const handleDragOver = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(true);
  }, []);

  const handleDragLeave = useCallback(() => {
    setIsDragging(false);
  }, []);

  const removeFile = (id: string) => {
    setFiles((prev) => {
      const item = prev.find((f) => f.id === id);
      if (item?.preview) URL.revokeObjectURL(item.preview);
      return prev.filter((f) => f.id !== id);
    });
  };

  const uploadFiles = async () => {
    const pending = files.filter((f) => f.status === "pending");
    if (pending.length === 0) return;

    setIsUploading(true);

    for (const fileItem of pending) {
      setFiles((prev) =>
        prev.map((f) =>
          f.id === fileItem.id ? { ...f, status: "uploading", progress: 0 } : f
        )
      );

      const formData = new FormData();
      formData.append("file", fileItem.file);

      try {
        await api.post("/receipts/upload", formData);

        setFiles((prev) =>
          prev.map((f) =>
            f.id === fileItem.id ? { ...f, status: "success", progress: 100 } : f
          )
        );
      } catch {
        setFiles((prev) =>
          prev.map((f) =>
            f.id === fileItem.id
              ? { ...f, status: "error", error: "Upload failed" }
              : f
          )
        );
      }
    }

    setIsUploading(false);
  };

  const pendingCount = files.filter((f) => f.status === "pending").length;
  const successCount = files.filter((f) => f.status === "success").length;

  return (
    <div className="space-y-4">
      <div
        onDrop={handleDrop}
        onDragOver={handleDragOver}
        onDragLeave={handleDragLeave}
        onClick={() => inputRef.current?.click()}
        className={`
          border-2 border-dashed rounded-xl p-8 text-center cursor-pointer transition-colors
          ${isDragging
            ? "border-blue-500 bg-blue-50 dark:bg-blue-900/20"
            : "border-gray-300 dark:border-gray-600 hover:border-gray-400 dark:hover:border-gray-500"
          }
        `}
      >
        <input
          ref={inputRef}
          type="file"
          accept="image/jpeg,image/png,image/webp,application/pdf"
          multiple
          onChange={(e) => e.target.files && handleFiles(e.target.files)}
          className="hidden"
        />

        <Upload className="h-10 w-10 mx-auto mb-4 text-gray-400" />
        <p className="text-gray-700 dark:text-gray-300 font-medium">
          Drag & drop receipts here, or{" "}
          <span className="text-blue-600">browse files</span>
        </p>
        <p className="text-sm text-gray-500 mt-2">
          JPG, PNG, WebP, PDF &middot; Max 10MB
        </p>
      </div>

      {files.length > 0 && (
        <div className="space-y-2">
          <div className="flex items-center justify-between text-sm">
            <span className="text-gray-600 dark:text-gray-400">
              {successCount} / {files.length} uploaded
            </span>
            {pendingCount > 0 && (
              <button
                onClick={uploadFiles}
                disabled={isUploading}
                className="px-4 py-1.5 bg-blue-600 hover:bg-blue-700 disabled:bg-blue-400 text-white text-sm font-medium rounded-lg transition-colors"
              >
                {isUploading ? "Uploading..." : `Upload ${pendingCount} file${pendingCount > 1 ? "s" : ""}`}
              </button>
            )}
          </div>

          <div className="max-h-64 overflow-y-auto space-y-2">
            {files.map((file) => (
              <div
                key={file.id}
                className="flex items-center gap-3 p-3 bg-gray-50 dark:bg-gray-800 rounded-lg"
              >
                {file.preview ? (
                  <img
                    src={file.preview}
                    alt={file.file.name}
                    className="h-10 w-10 rounded object-cover"
                  />
                ) : (
                  <div className="h-10 w-10 rounded bg-gray-200 dark:bg-gray-700 flex items-center justify-center">
                    <FileImage className="h-5 w-5 text-gray-500" />
                  </div>
                )}

                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium text-gray-900 dark:text-white truncate">
                    {file.file.name}
                  </p>
                  <p className="text-xs text-gray-500">
                    {(file.file.size / 1024).toFixed(0)} KB
                  </p>
                </div>

                {file.status === "uploading" && (
                  <div className="w-16 h-1.5 bg-gray-200 dark:bg-gray-700 rounded-full overflow-hidden">
                    <div
                      className="h-full bg-blue-600 rounded-full transition-all"
                      style={{ width: `${file.progress}%` }}
                    />
                  </div>
                )}

                {file.status === "success" && (
                  <CheckCircle className="h-5 w-5 text-green-500" />
                )}

                {file.status === "error" && (
                  <AlertCircle className="h-5 w-5 text-red-500" />
                )}

                <button
                  onClick={() => removeFile(file.id)}
                  className="p-1 hover:bg-gray-200 dark:hover:bg-gray-700 rounded"
                >
                  <X className="h-4 w-4 text-gray-500" />
                </button>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
