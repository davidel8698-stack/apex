# Workflow: Add PDF Generation

## Goal
Add PDF generation capability to an existing application. Covers template-based document creation, styling, and download/email delivery.

## Prerequisites
- Existing application with data to render as PDF (invoices, reports, certificates, etc.)
- PDF library selected (Puppeteer/Playwright for HTML-to-PDF, PDFKit, ReportLab, wkhtmltopdf, or WeasyPrint)

## Phases

### Phase 1: PDF Engine & Templates
- Install PDF generation library matching project stack
- Create PDF template for primary document type (HTML template or programmatic layout)
- Implement data binding: populate template with dynamic data from application
- Configure page settings (size: A4/Letter, margins, orientation, headers/footers)
- Generate sample PDF with test data
- Verify: PDF generates successfully; data renders correctly; page layout matches design

### Phase 2: API & Delivery
- Create PDF generation endpoint (`GET /api/documents/:id/pdf`)
- Implement streaming response (don't buffer entire PDF in memory for large documents)
- Add PDF caching for frequently requested documents (generate once, serve cached)
- Add PDF attachment to email (if applicable — invoices, reports sent via email)
- Add batch PDF generation for bulk operations (export all invoices for a month)
- Verify: PDF downloads via API; cached PDFs served without regeneration; email attachment works

## Skills Required
- PDF library matching stack (puppeteer, pdfkit, reportlab, weasyprint)
- Template engine (if using HTML-to-PDF approach)

## Security Invariants
- PDF generation MUST respect access control (users can only generate PDFs for their own data)
- PDF templates MUST NOT execute user-provided scripts (if using HTML-to-PDF)
- Generated PDFs MUST NOT contain hidden metadata with sensitive system information
- Batch generation MUST be rate-limited to prevent resource exhaustion
