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

async function createPdfFromImages(imageBlobs) {

  const { PDFDocument } = PDFLib;
  // Crear un nuevo documento PDF
  const pdfDoc = await PDFDocument.create();

  // Iterar sobre los blobs de imagen
  for (const blob of imageBlobs) {
        const response = await fetch(blob);
    // Leer el blob como un ArrayBuffer
        const mimeType = response.headers.get('Content-Type') || 'application/octet-stream';
        const arrayBuffer = await response.arrayBuffer();

        // Determinar el tipo de la imagen (PNG o JPG)
        let image;
        if (mimeType === 'image/png') {
          image = await pdfDoc.embedPng(arrayBuffer);
        } else if (mimeType === 'image/jpeg' || mimeType === 'image/jpg') {
          image = await pdfDoc.embedJpg(arrayBuffer);
        } else {
          throw new Error(`Formato de imagen no compatible: ${mimeType}`);
        }

        // Obtener las dimensiones de la imagen
        const { width, height } = image.scale(1);

        // Crear una nueva página con las dimensiones de la imagen
        const page = pdfDoc.addPage([width, height]);

        // Dibujar la imagen en la página
        page.drawImage(image, {
          x: 0,
          y: 0,
          width: width,
          height: height,
        });
  }

  const pdfBytes = await pdfDoc.save();
  const url = URL.createObjectURL(new Blob([pdfBytes], { type: 'application/pdf' }));
  return url;
}

async function convertPdfToImages(pdfData) {

  const { PDFDocument } = PDFLib;
  const response = await fetch(pdfData);
  const arrayBuffer = await response.arrayBuffer();
  const pdf = await PDFDocument.load(arrayBuffer);
  const pageCount = pdf.getPageCount();;
  const imageBlobs = [];

  // Configuración para renderizar la imagen de cada página
  const canvas = document.createElement("canvas");
  const context = canvas.getContext("2d");

  // Convertir cada página a imagen y agregarla a la lista
  for (let pageNum = 0; pageNum < pageCount; pageNum++) {
    const page = await pdf.getPage(pageNum);

    // Convertir el contenido del canvas a Blob
    const imgBlob = await new Promise((resolve) => canvas.toBlob(resolve, "image/png"));
    const url = URL.createObjectURL(imgBlob, { type: 'image/png' });
    imageBlobs.push(url);
  }

  return imageBlobs;
}