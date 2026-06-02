declare module "pdfkit" {
  import { EventEmitter } from "events";

  interface PDFDocumentOptions {
    size?: string;
    margin?: number;
    info?: Record<string, string | Date>;
    bufferPages?: boolean;
  }

  class PDFDocument extends EventEmitter {
    constructor(options?: PDFDocumentOptions);
    fontSize(size: number): this;
    font(font: string): this;
    text(text: string, options?: Record<string, unknown>): this;
    text(text: string, x: number, y: number, options?: Record<string, unknown>): this;
    moveTo(x: number, y: number): this;
    lineTo(x: number, y: number): this;
    stroke(color?: string): this;
    moveDown(lines?: number): this;
    addPage(options?: Record<string, unknown>): this;
    end(): void;
    pipe(dest: NodeJS.WritableStream): this;
  }

  export default PDFDocument;
}
