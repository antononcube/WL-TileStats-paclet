
BeginPackage["AntonAntonov`TileStats`"];

HextileBins::usage = "HextileBins[data, binSize, {{xmin, xmax}, {ymin, ymax}}] bins data into hexagon tiles. \
Returns an association with keys that are polygon objects.
If the option \"PolygonKeys\" is set to False then the keys are hexagon centers.";

HextileHistogram::usage = "HextileHistogram[data, binSize, {{xmin, xmax}, {ymin, ymax}}] makes a hex-tile histogram.";

TileBins::usage = "TileBins[data, binSize, {{xmin, xmax}, {ymin, ymax}}] bins data into rectangular tiles. \
Returns an association with keys that are polygon objects.
If the option \"PolygonKeys\" is set to False then the keys are rectangle centers.";

TileHistogram::usage = "TileHistogram[data, binSize, {{xmin, xmax}, {ymin, ymax}}] makes a tile histogram.";

TileBinsPlot::usage = "TileBinsPlot[ tileBins_Association ] plots the polygon keys of tileBins \
and colors them according to the values.";

Begin["`Private`"];

Needs["AntonAntonov`TileStats`HextileBins`"];
Needs["AntonAntonov`TileStats`TileBins`"];


End[];
EndPackage[];