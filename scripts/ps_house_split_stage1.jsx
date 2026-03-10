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
  var tmp = sourceDoc.duplicate("codex_stage1_tmp", false);
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
  { name: "hilltop_temple_block", rect: [420, 220, 2250, 1880] },
  { name: "hill_stair_shop", rect: [820, 1180, 1860, 2500] },
  { name: "closed_market_block", rect: [560, 1960, 1980, 3640] },
  { name: "general_store_block", rect: [900, 2960, 2280, 4360] },
  { name: "fish_market_block", rect: [0, 3440, 1460, 5040] },
  { name: "subway_station", rect: [120, 4540, 2700, 5463] },
  { name: "exchange_row_left", rect: [3100, 120, 4560, 1020] },
  { name: "exchange_row_mid", rect: [4460, 100, 5660, 1040] },
  { name: "stock_exchange", rect: [5360, 80, 7820, 1200] },
  { name: "clocktower_building", rect: [7440, 20, 8192, 1040] },
  { name: "exchange_row_right", rect: [6940, 300, 8192, 1240] },
  { name: "bank_hall", rect: [2900, 1080, 4880, 2260] },
  { name: "bank_side_shop", rect: [4580, 1140, 5520, 2260] },
  { name: "lower_exchange_stalls", rect: [3120, 2000, 5060, 3040] },
  { name: "memorial_row", rect: [6600, 760, 8192, 1700] },
  { name: "fountain_right_row", rect: [6420, 1320, 8192, 2300] },
  { name: "warehouse_small", rect: [5080, 2720, 6240, 3980] },
  { name: "iron_claw_factory", rect: [5640, 2460, 7880, 3880] },
  { name: "factory_right_row", rect: [7320, 2100, 8192, 3820] },
  { name: "seal_flour", rect: [4940, 3760, 6480, 4860] },
  { name: "warehouse_24", rect: [6340, 4140, 8192, 5120] },
  { name: "harbor_office", rect: [7240, 4480, 8192, 5360] },
  { name: "lighthouse", rect: [5840, 4340, 7080, 5463] },
  { name: "container_yard", rect: [6420, 4680, 8192, 5463] }
];

var workingDoc = ensureWorkingDocument(sourceDoc, "codex_house_split_stage1_complete");
clearTopLevelGroups(workingDoc);
var baseLayer = ensureBaseLayer(workingDoc);
var group = workingDoc.layerSets.add();
group.name = "stage1_complete";

for (var i = 0; i < items.length; i++) {
  pasteAtOriginalPosition(sourceDoc, workingDoc, group, items[i]);
}

baseLayer.visible = false;
app.activeDocument = workingDoc;

var psdFile = new File("E:/Desktop/gamexu/assets/generated/ditu_8k_house_layers_stage1_complete.psd");
var psdOptions = new PhotoshopSaveOptions();
psdOptions.layers = true;
psdOptions.embedColorProfile = true;
psdOptions.alphaChannels = true;
workingDoc.saveAs(psdFile, psdOptions, true, Extension.LOWERCASE);

exportGroupLayers(workingDoc, group, "E:/Desktop/gamexu/assets/generated/ditu_8k_house_layers_stage1_complete");

var previewFile = new File("E:/Desktop/gamexu/tmp_stage1_complete_preview.png");
var previewOptions = new ExportOptionsSaveForWeb();
previewOptions.format = SaveDocumentType.PNG;
previewOptions.PNG8 = false;
previewOptions.transparency = true;
workingDoc.exportDocument(previewFile, ExportType.SAVEFORWEB, previewOptions);
