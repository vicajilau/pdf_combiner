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
  const pdfjsLib = window['pdfjs-dist/build/pdf'];

  // Configura la URL de tu archivo PDF.js Worker
  pdfjsLib.GlobalWorkerOptions.workerSrc = '//cdnjs.cloudflare.com/ajax/libs/pdf.js/2.16.105/pdf.worker.min.js';

  const pdf = await pdfjsLib.getDocument(pdfData).promise;
  const pageCount = pdf.numPages;
  const imageUrls = [];

  // Convertir cada página a imagen
  for (let pageNum = 1; pageNum <= pageCount; pageNum++) {
    const page = await pdf.getPage(pageNum);

    // Configuración del canvas
    const viewport = page.getViewport({ scale: 2 }); // Ajusta el escalado si es necesario
    const canvas = document.createElement('canvas');
    const context = canvas.getContext('2d');
    canvas.width = viewport.width;
    canvas.height = viewport.height;

    // Renderizar página en el canvas
    await page.render({
      canvasContext: context,
      viewport: viewport
    }).promise;

    // Convertir canvas a Blob y luego a URL
    const imgBlob = await new Promise((resolve) =>
      canvas.toBlob(resolve, 'image/png')
    );
    const imgUrl = URL.createObjectURL(imgBlob);
    imageUrls.push(imgUrl);
  }

  return imageUrls;
}