async function combinePDFs(blobUrls) {

  const { PDFDocument } = PDFLib;
  const mergedPdf = await PDFDocument.create();

  for (const blobUrl of blobUrls) {
    try {
      // Download blob content
      const response = await fetch(blobUrl);
      if (!response.ok) {
        throw new Error(`Error al descargar el blob desde la URL: ${blobUrl}`);
      }
      const pdfBytes = await response.arrayBuffer();

      // load pdf and copy pages
      const pdf = await PDFDocument.load(pdfBytes);
      const copiedPages = await mergedPdf.copyPages(pdf, pdf.getPageIndices());
      copiedPages.forEach((page) => mergedPdf.addPage(page));
    } catch (error) {
      console.error(`Error procesando el blob ${blobUrl}:`, error);
    }
  }

  // Generate combinated pdfs
  const mergedPdfBytes = await mergedPdf.save();


  // build a blob to combinated pdf
  const blob = new Blob([mergedPdfBytes], { type: 'application/pdf' });
  const url = URL.createObjectURL(blob);

  return url // Returl url from combinated object
}

async function createPdfFromImages(imageBlobs,config) {

  const { PDFDocument } = PDFLib;
  // Create a new pdf document
  const pdfDoc = await PDFDocument.create();

  // iterate into image blobs
  for (const blob of imageBlobs) {
        const response = await fetch(blob);
    // read blob like an arraybuffer
        const mimeType = response.headers.get('Content-Type') || 'application/octet-stream';
        const arrayBuffer = await response.arrayBuffer();

        // get type img
        let image;
        if (mimeType === 'image/png') {
          image = await pdfDoc.embedPng(arrayBuffer);
        } else if (mimeType === 'image/jpeg' || mimeType === 'image/jpg') {
          image = await pdfDoc.embedJpg(arrayBuffer);
        } else {
          throw new Error(`Formato de imagen no compatible: ${mimeType}`);
        }

        // Get image dimensions
        const { scaledWidth, scaledHeight } = image.scale(1);
        let imageScaled = image
        let page
        if(config.rescale.width != 0 && config.rescale.height != 0){
         imageScaled = scaleImage(image,config.rescale.width);
         page = pdfDoc.addPage([imageScaled.scaledWidth, imageScaled.scaledHeight]);
        }else{
          page = pdfDoc.addPage([imageScaled.width, imageScaled.height]);
        }

        // draw image into page
        page.drawImage(image, {
          x: 0,
          y: 0,
          width: imageScaled.scaledWidth,
          height: imageScaled.scaledHeight,
        });
  }

  const pdfBytes = await pdfDoc.save();
  const url = URL.createObjectURL(new Blob([pdfBytes], { type: 'application/pdf' }));
  return url;
}

function scaleImage(img, targetWidth) {
    const scaleFactor = targetWidth / img.width;
    const scaledWidth = targetWidth;
    const scaledHeight = img.height * scaleFactor;

    return { scaledWidth, scaledHeight };
}

async function convertPdfToImages(pdfData,config) {
  const pdfjsLib = window['pdfjs-dist/build/pdf'];

  // Configure url from the pdf library
  pdfjsLib.GlobalWorkerOptions.workerSrc = '//cdnjs.cloudflare.com/ajax/libs/pdf.js/2.16.105/pdf.worker.min.js';

  const pdf = await pdfjsLib.getDocument(pdfData).promise;
  const pageCount = pdf.numPages;
  const imageUrls = [];

  // Convert each image into image
  for (let pageNum = 1; pageNum <= pageCount; pageNum++) {
    const page = await pdf.getPage(pageNum);

    // Cavnas configuration
    const viewport = page.getViewport({ scale: 2 }); // Ajusta el escalado si es necesario
    const canvas = document.createElement('canvas');
    const context = canvas.getContext('2d');
    canvas.width = viewport.width;
    canvas.height = viewport.height;

    // render page into canvas
    await page.render({
      canvasContext: context,
      viewport: viewport
    }).promise;

    // Convert canvas to blob and later to url
    const imgBlob = await new Promise((resolve) =>
      canvas.toBlob(resolve, 'image/png')
    );
    const imgUrl = URL.createObjectURL(imgBlob);
    imageUrls.push(imgUrl);
  }

  return imageUrls;
}
async function pdfToImage(pdfFile,config) {
    const { PDFDocument } = PDFLib;
    const pdf = await pdfjsLib.getDocument(pdfFile).promise;
    const numPages = pdf.numPages;

    const pageImages = [];
    let totalWidth = 0;
    let totalHeight = 0;

    // Renderizar cada página en un canvas temporal
    for (let i = 1; i <= numPages; i++) {
        const page = await pdf.getPage(i);
        const scale = 2; // Ajusta la calidad
        const viewport = page.getViewport({ scale });

        const canvas = document.createElement('canvas');
        const context = canvas.getContext('2d');
        canvas.width = viewport.width;
        canvas.height = viewport.height;

        await page.render({ canvasContext: context, viewport }).promise;

        pageImages.push(canvas);
        totalWidth = Math.max(totalWidth, viewport.width); // Usamos el ancho más grande
        totalHeight += viewport.height; // Suma las alturas
    }

    // Crear un nuevo canvas para unir todas las páginas
    const finalCanvas = document.createElement('canvas');
    finalCanvas.width = totalWidth;
    finalCanvas.height = totalHeight;
    const finalContext = finalCanvas.getContext('2d');

    // Dibujar cada imagen en la posición correcta
    let yOffset = 0;
    for (const img of pageImages) {
        finalContext.drawImage(img, 0, yOffset);
        yOffset += img.height;
    }

    // Convertir el canvas final en Blob
   const imgBlob = await new Promise((resolve) => {
        finalCanvas.toBlob((blob) => resolve(blob), 'image/png');
    });
    const imgUrl = URL.createObjectURL(imgBlob);
    return [imgUrl];
}