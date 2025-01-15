async function combinePDFs(blobUrls) {

  const { PDFDocument } = PDFLib;
  const mergedPdf = await PDFDocument.create();

  for (const blobUrl of blobUrls) {
    try {
      // Descarga el contenido del blob
      const response = await fetch(blobUrl);
      if (!response.ok) {
        throw new Error(`Error al descargar el blob desde la URL: ${blobUrl}`);
      }
      const pdfBytes = await response.arrayBuffer();

      // Carga el PDF y copia las páginas
      const pdf = await PDFDocument.load(pdfBytes);
      const copiedPages = await mergedPdf.copyPages(pdf, pdf.getPageIndices());
      copiedPages.forEach((page) => mergedPdf.addPage(page));
    } catch (error) {
      console.error(`Error procesando el blob ${blobUrl}:`, error);
    }
  }

  // Genera el PDF combinado
  const mergedPdfBytes = await mergedPdf.save();

  // Crea un Blob y una URL para el PDF combinado
  const blob = new Blob([mergedPdfBytes], { type: 'application/pdf' });
  const url = URL.createObjectURL(blob);

  return url // Retorna la URL del objeto combinado
}