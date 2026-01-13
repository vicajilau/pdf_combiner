async function combinePDFs(blobUrls) {
  const { PDFDocument } = PDFLib;
  const mergedPdf = await PDFDocument.create();

  for (const blobUrl of blobUrls) {
    try {
      // Download blob content
      const response = await fetch(blobUrl);
      if (!response.ok) {
        throw new Error(`Error downloading the blob from the URL: ${blobUrl}`);
      }
      const pdfBytes = await response.arrayBuffer();

      // load pdf and copy pages
      const pdf = await PDFDocument.load(pdfBytes);
      const copiedPages = await mergedPdf.copyPages(pdf, pdf.getPageIndices());
      copiedPages.forEach((page) => mergedPdf.addPage(page));
    } catch (error) {
      console.error(`Error processing blob ${blobUrl}:`, error);
    }
  }

  // Generate combined pdfs
  const mergedPdfBytes = await mergedPdf.save();

  // build a blob to combined pdf
  const blob = new Blob([mergedPdfBytes], { type: 'application/pdf' });
  const url = URL.createObjectURL(blob);

  return url; // Return url from combined object
}

async function createPdfFromImages(imageBlobs, config) {
  const { PDFDocument } = PDFLib;
  // Create a new pdf document
  const pdfDoc = await PDFDocument.create();

  // iterate into image blobs
  for (const blob of imageBlobs) {
    const response = await fetch(blob);
    // read blob like an arraybuffer
    const mimeType = response.headers.get('Content-Type') || 'application/octet-stream';
    let image;
    const arrayBuffer = await response.arrayBuffer();

    if (mimeType !== 'image/heic') {
      if (mimeType === 'image/png') {
        image = await pdfDoc.embedPng(arrayBuffer);
      } else if (mimeType === 'image/jpeg' || mimeType === 'image/jpg') {
        image = await pdfDoc.embedJpg(arrayBuffer);
      }
    } else {
      if (mimeType === 'image/heic') {
        const convertedBlob = await heic2any({
          blob: new Blob([arrayBuffer], { type: 'image/heic' }),
          toType: 'image/jpeg'
        });
        const convertedArrayBuffer = await convertedBlob.arrayBuffer();
        image = await pdfDoc.embedJpg(convertedArrayBuffer);
      } else {
        throw new Error(`Image format not supported: ${mimeType}`);
      }
    }

    // Get image dimensions
    let imageScaled = image;
    let page;

    if (config.rescale.width !== 0 && config.rescale.height !== 0) {
      const dimensions = scaleImage(image, config.rescale.width);
      imageScaled = {
        scaledWidth: dimensions.scaledWidth,
        scaledHeight: dimensions.scaledHeight
      };
      page = pdfDoc.addPage([imageScaled.scaledWidth, imageScaled.scaledHeight]);
    } else {
      imageScaled = {
        scaledWidth: image.width,
        scaledHeight: image.height
      };
      page = pdfDoc.addPage([image.width, image.height]);
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

async function convertPdfToImages(pdfData, config) {
  const pdfjsLib = window['pdfjs-dist/build/pdf'];

  // Configure url from the pdf library
  pdfjsLib.GlobalWorkerOptions.workerSrc = '//cdnjs.cloudflare.com/ajax/libs/pdf.js/2.16.105/pdf.worker.min.js';

  const pdf = await pdfjsLib.getDocument(pdfData).promise;
  const pageCount = pdf.numPages;
  const imageUrls = [];

  // Convert each page into image
  for (let pageNum = 1; pageNum <= pageCount; pageNum++) {
    const page = await pdf.getPage(pageNum);

    // Canvas configuration
    const viewport = page.getViewport({ scale: 2 }); // Adjust the scaling if necessary
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

async function pdfToImage(pdfFile, config) {
  const pdfjsLib = window['pdfjs-dist/build/pdf'];
  const pdf = await pdfjsLib.getDocument(pdfFile).promise;
  const numPages = pdf.numPages;

  const pageImages = [];
  let totalWidth = 0;
  let totalHeight = 0;

  // Render each page on a temporary canvas
  for (let i = 1; i <= numPages; i++) {
    const page = await pdf.getPage(i);
    const scale = 2; // Adjust the quality
    const viewport = page.getViewport({ scale });

    const canvas = document.createElement('canvas');
    const context = canvas.getContext('2d');
    canvas.width = viewport.width;
    canvas.height = viewport.height;

    await page.render({ canvasContext: context, viewport }).promise;

    pageImages.push(canvas);
    totalWidth = Math.max(totalWidth, viewport.width); // We used the largest width
    totalHeight += viewport.height; // Add up the heights
  }

  // Create a new canvas to join all the pages.
  const finalCanvas = document.createElement('canvas');
  finalCanvas.width = totalWidth;
  finalCanvas.height = totalHeight;
  const finalContext = finalCanvas.getContext('2d');

  // Draw each image in the correct position
  let yOffset = 0;
  for (const img of pageImages) {
    finalContext.drawImage(img, 0, yOffset);
    yOffset += img.height;
  }

  // Convert the final canvas into a Blob
  const imgBlob = await new Promise((resolve) => {
    finalCanvas.toBlob((blob) => resolve(blob), 'image/png');
  });
  const imgUrl = URL.createObjectURL(imgBlob);
  return [imgUrl];
}