async function combinePDFs(blobUrls) {
  const { PDFDocument } = PDFLib;
  const mergedPdf = await PDFDocument.create();

  for (const blobUrl of blobUrls) {
    // Descarga el contenido del blob
    const response = await fetch(blobUrl);
    const pdfBytes = await response.arrayBuffer();

    // Carga el PDF y copia las páginas
    const pdf = await PDFDocument.load(pdfBytes);
    const copiedPages = await mergedPdf.copyPages(pdf, pdf.getPageIndices());
    copiedPages.forEach((page) => mergedPdf.addPage(page));
  }

  // Genera el PDF combinado
  const mergedPdfBytes = await mergedPdf.save();

  // Crea un Blob y una URL para el PDF combinado
  const blob = new Blob([mergedPdfBytes], { type: 'application/pdf' });
  const url = URL.createObjectURL(blob);

  return url; // Retorna la URL del objeto combinado
}

window.combinePDFs = combinePDFs;