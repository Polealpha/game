#target photoshop

app.displayDialogs = DialogModes.NO;

function findDocumentByPrefix(prefix) {
  for (var i = 0; i < app.documents.length; i++) {
    if (app.documents[i].name.indexOf(prefix) === 0) {
      return app.documents[i];
    }
  }
  return null;
}

function ensureWorkingDocument(sourceDoc, workingName) {
  var doc = findDocumentByPrefix(workingName);
  if (doc) {
    app.activeDocument = doc;
    try {
      doc.close(SaveOptions.DONOTSAVECHANGES);
    } catch (e) {}
  }

  app.activeDocument = sourceDoc;
  doc = sourceDoc.duplicate(workingName, false);
  app.activeDocument = doc;
  return doc;
}

function ensureBaseLayer(doc) {
  var layer = doc.activeLayer;
  if (layer.isBackgroundLayer) {
    layer.isBackgroundLayer = false;
  }
  layer.name = "_source";
  return layer;
}

function clearTopLevelGroups(doc) {
  while (doc.layerSets.length > 0) {
    doc.layerSets[0].remove();
  }
}

function cropAndCopy(sourceDoc, item) {
  app.activeDocument = sourceDoc;
  var tmp = sourceDoc.duplicate("codex_stage2_tmp", false);
  app.activeDocument = tmp;
  tmp.crop(item.rect);
  tmp.selection.selectAll();
  tmp.selection.copy();
  return tmp;
}

function pasteAtOriginalPosition(sourceDoc, workingDoc, group, item) {
  var tmp = cropAndCopy(sourceDoc, item);

  app.activeDocument = workingDoc;
  workingDoc.paste();
  var layer = workingDoc.activeLayer;
  layer.name = item.name;
  layer.move(group, ElementPlacement.INSIDE);
  layer.translate(
    item.rect[0] - ((workingDoc.width.as("px") - tmp.width.as("px")) / 2),
    item.rect[1] - ((workingDoc.height.as("px") - tmp.height.as("px")) / 2)
  );

  app.activeDocument = tmp;
  tmp.close(SaveOptions.DONOTSAVECHANGES);
}

function exportGroupLayers(doc, group, folderPath) {
  var folder = new Folder(folderPath);
  if (!folder.exists) {
    folder.create();
  }

  for (var i = 0; i < group.artLayers.length; i++) {
    var sourceLayer = group.artLayers[i];
    var exportDoc = app.documents.add(
      doc.width,
      doc.height,
      doc.resolution,
      sourceLayer.name,
      NewDocumentMode.RGB,
      DocumentFill.TRANSPARENT
    );

    app.activeDocument = doc;
    sourceLayer.duplicate(exportDoc, ElementPlacement.PLACEATBEGINNING);

    app.activeDocument = exportDoc;
    exportDoc.trim(TrimType.TRANSPARENT, true, true, true, true);

    var pngFile = new File(folder.fsName + "/" + sourceLayer.name + ".png");
    var opts = new ExportOptionsSaveForWeb();
    opts.format = SaveDocumentType.PNG;
    opts.PNG8 = false;
    opts.transparency = true;
    exportDoc.exportDocument(pngFile, ExportType.SAVEFORWEB, opts);
    exportDoc.close(SaveOptions.DONOTSAVECHANGES);
  }
}

var sourceDoc = findDocumentByPrefix("ditu_8k_realesrgan.png");
if (!sourceDoc) {
  throw new Error("Source document ditu_8k_realesrgan.png is not open.");
}

var items = [
  { name: "hilltop_temple_block", rect: [500, 220, 2140, 1020] },
  { name: "hill_stair_shop", rect: [860, 1180, 1760, 1960] },
  { name: "closed_market_block", rect: [620, 1980, 1920, 2780] },
  { name: "general_store_block", rect: [980, 3000, 2220, 3720] },
  { name: "fish_market_block", rect: [0, 3460, 1320, 4180] },
  { name: "subway_station", rect: [160, 4560, 2520, 5060] },
  { name: "exchange_row_left", rect: [3140, 120, 4520, 680] },
  { name: "exchange_row_mid", rect: [4440, 100, 5640, 680] },
  { name: "stock_exchange", rect: [5380, 80, 7800, 660] },
  { name: "clocktower_building", rect: [7440, 20, 8192, 740] },
  { name: "exchange_row_right", rect: [6940, 300, 8192, 820] },
  { name: "bank_hall", rect: [2940, 1100, 4860, 1520] },
  { name: "bank_side_shop", rect: [4600, 1160, 5520, 1720] },
  { name: "lower_exchange_stalls", rect: [3160, 2020, 5040, 2260] },
  { name: "memorial_row", rect: [6620, 780, 8192, 1260] },
  { name: "fountain_right_row", rect: [6440, 1340, 8192, 1760] },
  { name: "warehouse_small", rect: [5100, 2760, 6220, 3340] },
  { name: "iron_claw_factory", rect: [5660, 2480, 7860, 3080] },
  { name: "factory_right_row", rect: [7340, 2120, 8192, 3260] },
  { name: "seal_flour", rect: [4960, 3780, 6460, 4300] },
  { name: "warehouse_24", rect: [6360, 4160, 8192, 4580] },
  { name: "harbor_office", rect: [7240, 4480, 8192, 5040] },
  { name: "lighthouse", rect: [5900, 4380, 7000, 5463] },
  { name: "container_yard", rect: [6420, 4720, 8192, 5463] }
];

var workingDoc = ensureWorkingDocument(sourceDoc, "codex_house_split_stage2_no_road");
clearTopLevelGroups(workingDoc);
var baseLayer = ensureBaseLayer(workingDoc);
var group = workingDoc.layerSets.add();
group.name = "stage2_no_road";

for (var i = 0; i < items.length; i++) {
  pasteAtOriginalPosition(sourceDoc, workingDoc, group, items[i]);
}

baseLayer.visible = false;
app.activeDocument = workingDoc;

var psdFile = new File("E:/Desktop/gamexu/assets/generated/ditu_8k_house_layers_stage2_no_road.psd");
var psdOptions = new PhotoshopSaveOptions();
psdOptions.layers = true;
psdOptions.embedColorProfile = true;
psdOptions.alphaChannels = true;
workingDoc.saveAs(psdFile, psdOptions, true, Extension.LOWERCASE);

exportGroupLayers(workingDoc, group, "E:/Desktop/gamexu/assets/generated/ditu_8k_house_layers_stage2_no_road");

var previewFile = new File("E:/Desktop/gamexu/tmp_stage2_no_road_preview.png");
var previewOptions = new ExportOptionsSaveForWeb();
previewOptions.format = SaveDocumentType.PNG;
previewOptions.PNG8 = false;
previewOptions.transparency = true;
workingDoc.exportDocument(previewFile, ExportType.SAVEFORWEB, previewOptions);
