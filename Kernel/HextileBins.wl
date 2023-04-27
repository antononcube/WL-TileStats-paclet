(* :Title: HextileBins *)
(* :Context: HextileBins` *)
(* :Author: Anton Antonov *)
(* :Date: 2020-03-29 *)

(* :Package Version: 0.4 *)
(* :Mathematica Version: 12.0 *)
(* :Copyright: (c) 2020 Anton Antonov *)
(* :Keywords: Hextile, Hexagon, Binning, Histogram, Polygon, Mathematica, Wolfram Language, WL *)
(* :Discussion:

   # In brief

   This package provides a few functions for hex-tile binning of 2D data.

   The package functions can have a specified aggregation function applied to binned values.

   # Usage examples

     SeedRandom[2129];
     data = RandomVariate[MultinormalDistribution[{10, 10}, 7 IdentityMatrix[2]], 100];

     HextileBins[data, 2, "PolygonKeys" -> False]

     data2 = Map[# -> RandomInteger[{1, 10}] &, data];

     HextileBins[data2, 2, "PolygonKeys" -> False]

     HextileBins[data2, 6]

     Show[{HextileHistogram[data, 2, "AggregationFunction" -> Mean, ColorFunction -> (Opacity[#, Blue] &), PlotRange -> All],
           Graphics[{Red, PointSize[0.01], Point[data], PointSize[0.02], Green,Point[Keys@HextileBins[data, 2, "PolygonKeys" -> False]]}]}]

     Show[{HextileHistogram[data, 3, "HistogramType" -> 3, ColorFunction -> ColorData["TemperatureMap"], PlotRange -> All],
           Graphics[{Red, PointSize[0.01], Point[data], PointSize[0.02], Green, Point[Keys@HextileBins[data, 3, "PolygonKeys" -> False]]}]}]


   # References

     Initial ideas / versions of the code in this package can be found in Mathematica Stack Exchange:

       https://mathematica.stackexchange.com/q/28149


*)

BeginPackage["AntonAntonov`TileStats`HextileBins`"];
(* Exported symbols added here with SymbolName::usage *)

(*HextileBins::usage = "HextileBins[data, binSize, {{xmin, xmax}, {ymin, ymax}}] bins data into hexagon tiles. \*)
(*Returns an association with keys that are polygon objects.*)
(*If the option \"PolygonKeys\" is set to False then the keys are hexagon centers.";*)

(*HextileHistogram::usage = "HextileHistogram[data, binSize, {{xmin, xmax}, {ymin, ymax}}] makes a hex-tile histogram.";*)

Begin["`Private`"];

Needs["AntonAntonov`TileStats`"];

(*********************************************************)
(* Support functions                                     *)
(*********************************************************)

Clear[ReferenceHexagon];
ReferenceHexagon[] := {{1 / 2, Sqrt[3] / 2}, {-(1 / 2), Sqrt[3] / 2}, {-1, 0}, {-(1 / 2), -(Sqrt[3] / 2)}, {1 / 2, -(Sqrt[3] / 2)}, {1, 0}};

Clear[NearestWithinTile];
NearestWithinTile = Nearest[{{0, 0}, {1, 0}, {1 / 2, Sqrt[3] / 2}, {0, Sqrt[3]}, {1, Sqrt[3]}}];

Clear[TileContaining];
TileContaining[{x_, y_}] := {Floor[x], Sqrt[3] Floor[y / Sqrt[3]]};

Clear[NearestHexagon];
NearestHexagon[point : {_?NumericQ, _?NumericQ}] :=
    Module[{tile, relative},
      tile = TileContaining[point];
      relative = point - tile;
      tile + First@NearestWithinTile[relative]
    ];

Clear[TransformByVector];
TransformByVector[v_, tr_] := Polygon[TranslationTransform[tr][RotationTransform[Pi / 2][v]]];

Clear[HexagonVertexDistance];
HexagonVertexDistance[binSize_?NumericQ, factor_?NumericQ ] :=
    binSize * factor * ReferenceHexagon[] / Sqrt[3];

Clear[HextileBinDataRulesQ];
HextileBinDataRulesQ[d_] :=
    MatchQ[d, (List | Association)[({_?NumericQ, _?NumericQ} -> _?NumericQ) ..]] ||
        MatchQ[d, (List | Association)[({_?NumericQ, _?NumericQ} -> _) ..]];

Clear[HextileBinDataQ];
HextileBinDataQ[d_] := (MatrixQ[d] && Dimensions[d][[2]] == 2) || HextileBinDataRulesQ[d];


(*********************************************************)
(* HextileCenterBins                                     *)
(*********************************************************)

Clear[HextileCenterBins];

SyntaxInformation[HextileCenterBins] = { "ArgumentsPattern" -> { _, _, _., OptionsPattern[] } };

Options[HextileCenterBins] = { "AggregationFunction" -> Total };

HextileCenterBins[data_?HextileBinDataQ, binSize_?NumericQ, opts : OptionsPattern[] ] :=
    HextileCenterBins[ data, binSize, Automatic, opts ];

HextileCenterBins[data_?MatrixQ, binSize_?NumericQ, Automatic, opts : OptionsPattern[] ] :=
    HextileCenterBins[data, binSize, MinMax /@ Transpose[data], opts] /; Dimensions[data][[2]] == 2;

HextileCenterBins[data_?MatrixQ, binSize_?NumericQ, {{xmin_, xmax_}, {ymin_, ymax_}}, opts : OptionsPattern[] ] :=
    Block[{},
      Association[Rule @@@ Tally[binSize * (NearestHexagon /@ (data / binSize))]]
    ] /; Dimensions[data][[2]] == 2;

HextileCenterBins[data_?HextileBinDataRulesQ, binSize_?NumericQ, Automatic, opts : OptionsPattern[] ] :=
    HextileCenterBins[ data, binSize, MinMax /@ Transpose[Keys[data]], opts ];

HextileCenterBins[data_?HextileBinDataRulesQ, binSize_?NumericQ, {{xmin_, xmax_}, {ymin_, ymax_}}, opts : OptionsPattern[] ] :=
    Block[{aggrFunc},

      aggrFunc = OptionValue[HextileCenterBins, "AggregationFunction"];

      GroupBy[Map[(binSize * NearestHexagon[#[[1]] / binSize]) -> #[[2]] &, Normal[data]], #[[1]] &, aggrFunc[#[[All, 2]]] &]
    ];


(*********************************************************)
(* HextilePolygonBins                                    *)
(*********************************************************)

Clear[HextilePolygonBins];

SyntaxInformation[HextilePolygonBins] = { "ArgumentsPattern" -> { _, _, _., OptionsPattern[] } };

Options[HextilePolygonBins] = Join[ {"OverlapFactor" -> 1}, Options[HextileCenterBins] ];

HextilePolygonBins[data_?HextileBinDataQ, binSize_?NumericQ, opts : OptionsPattern[] ] :=
    HextilePolygonBins[data, binSize, Automatic, opts ];

HextilePolygonBins[data_?HextileBinDataQ, binSize_?NumericQ, Automatic, opts : OptionsPattern[] ] :=
    HextilePolygonBins[
      data,
      binSize,
      If[MatrixQ[data], MinMax /@ Transpose[data], MinMax /@ Transpose[Keys[data]]],
      opts
    ];

HextilePolygonBins[data_?HextileBinDataQ, binSize_?NumericQ, {{xmin_, xmax_}, {ymin_, ymax_}}, opts : OptionsPattern[] ] :=
    Block[{overlapFactor, vh},

      overlapFactor = OptionValue[HextilePolygonBins, "OverlapFactor"];

      vh = HexagonVertexDistance[binSize, overlapFactor];

      KeyMap[ TransformByVector[vh, #] &, HextileCenterBins[data, binSize, {{xmin, xmax}, {ymin, ymax}}, FilterRules[{opts}, Options[HextileCenterBins]]] ]
    ];


(*********************************************************)
(* HextileBins                                           *)
(*********************************************************)

Clear[HextileBins];

SyntaxInformation[HextileBins] = { "ArgumentsPattern" -> { _, _, _., OptionsPattern[] } };

HextileBins::"nargs" = "The first argument is expected to be a numerical matrix or \
an association of 2D coordinates to numeric values. \
The second argument is expected to be a positive number. \
The third argument is expected to be a range specification, two pairs of numbers, or Automatic.";

HextileBins::"nof" = "The value of the option \"OverlapFactor\" is expected to be a positive number.";

Options[HextileBins] = { "AggregationFunction" -> Total, "PolygonKeys" -> True, "OverlapFactor" -> 1 };

HextileBins[data_?HextileBinDataQ, binSize_?NumericQ, opts : OptionsPattern[] ] :=
    HextileBins[data, binSize, Automatic, opts ];

HextileBins[data_?HextileBinDataQ, binSize_?NumericQ, Automatic, opts : OptionsPattern[] ] :=
    HextileBins[
      data,
      binSize,
      If[MatrixQ[data], MinMax /@ Transpose[data], MinMax /@ Transpose[Keys[data]]],
      opts
    ];

HextileBins[data_?HextileBinDataQ, binSize_?NumericQ, {{xmin_, xmax_}, {ymin_, ymax_}}, opts : OptionsPattern[] ] :=
    Block[{overlapFactor, polygonKeys},

      overlapFactor = OptionValue[HextileBins, "OverlapFactor"];
      If[ ! ( NumberQ[overlapFactor] && overlapFactor > 0 ),
        Message[HextileBins::"nof"];
        Return[$Failed]
      ];

      polygonKeys = OptionValue[HextileBins, "PolygonKeys"];

      If[ BooleanQ[polygonKeys] && !polygonKeys,
        HextileCenterBins[data, binSize, {{xmin, xmax}, {ymin, ymax}}, FilterRules[{opts}, Options[HextileCenterBins]]],
        (*ELSE*)
        HextilePolygonBins[data, binSize, {{xmin, xmax}, {ymin, ymax}}, FilterRules[{opts}, Options[HextilePolygonBins]]]
      ]
    ] /; binSize > 0;

HextileBins[___] :=
    Block[{},
      Message[HextileBins::"nargs"];
      $Failed
    ];


(*********************************************************)
(* HextileHistogram                                      *)
(*********************************************************)

Clear[HextileHistogram];

SyntaxInformation[HextileHistogram] = { "ArgumentsPattern" -> { _, _, _., OptionsPattern[] } };

HextileHistogram::"nargs" = "The first argument is expected to be a numerical matrix or \
an association of 2D coordinates to numeric values. \
The second argument is expected to be a positive number. \
The third argument is expected to be a range specification, two pairs of numbers, or Automatic.";

HextileHistogram::"nof" = "The value of the option \"OverlapFactor\" is expected to be a positive number.";

HextileHistogram::"nmt" = "The value of the option \"`1`\" is expected to be a number or Automatic.";

HextileHistogram::"npl" = "The value of the option PlotLegends is expected to be Automatic or None.";

Options[HextileHistogram] =
    Join[
      {
        "AggregationFunction" -> Total,
        "HistogramType" -> "ColoredPolygons",
        "MaxTally" -> Automatic,
        "MinTally" -> Automatic,
        "OverlapFactor" -> 1,
        ColorFunction -> (Blend[{Lighter[Blue, 0.99], Darker[Blue, 0.6]}, Sqrt[#]] &),
        PlotLegends -> None
      },
      Options[Graphics]
    ];

HextileHistogram[data_?HextileBinDataQ, binSize_?NumericQ, opts : OptionsPattern[]] :=
    HextileHistogram[data, binSize, Automatic, opts];

HextileHistogram[data_?HextileBinDataQ, binSize_?NumericQ, Automatic, opts : OptionsPattern[]] :=
    HextileHistogram[data, binSize, If[MatrixQ[data], MinMax /@ Transpose[data], MinMax /@ Transpose[Keys[data]]], opts];

(*
Using Module instead of Block because the second argument Legended depends on the module's variables.
I.e. for Block we have explicitly evaluate the functions and numbers of the second argument.
*)
HextileHistogram[data_?HextileBinDataQ, binSize_?NumericQ, {{xmin_, xmax_}, {ymin_, ymax_}}, opts : OptionsPattern[]] :=
    Module[{cFunc, ptype, overlapFactor, maxTally, minTally, plotLegends, tally, vh, rFunc, grRes},

      cFunc = OptionValue[HextileHistogram, ColorFunction];
      If[ StringQ[cFunc], cFunc = ColorData[cFunc]];
      If[ TrueQ[cFunc === Automatic], cFunc = (Blend[{Lighter[Blue, 0.99], Darker[Blue, 0.6]}, Sqrt[#]] &) ];

      plotLegends = OptionValue[HextileHistogram, PlotLegends];
      If[ ! ( TrueQ[plotLegends === Automatic] || TrueQ[plotLegends === None] ),
        Message[HextileHistogram::"npl"];
        plotLegends = None;
      ];

      ptype = OptionValue[HextileHistogram, "HistogramType"];

      maxTally = OptionValue[HextileHistogram, "MaxTally"];
      If[ ! ( TrueQ[maxTally === Automatic] || NumericQ[maxTally] ),
        Message[HextileHistogram::"nmt", "MaxTally"];
        Return[$Failed]
      ];

      minTally = OptionValue[HextileHistogram, "MinTally"];
      If[ ! ( TrueQ[minTally === Automatic] || NumericQ[minTally] ),
        Message[HextileHistogram::"nmt", "MinTally"];
        Return[$Failed]
      ];

      overlapFactor = OptionValue[HextileHistogram, "OverlapFactor"];
      If[ ! ( NumberQ[overlapFactor] && overlapFactor > 0 ),
        Message[HextileHistogram::"nof"];
        Return[$Failed]
      ];

      vh = HexagonVertexDistance[binSize, overlapFactor];

      tally = HextileCenterBins[ data, binSize, {{xmin, xmax}, {ymin, ymax}}, FilterRules[{opts}, Options[HextileCenterBins]] ];
      tally = List @@@ Normal[tally];

      If[ TrueQ[maxTally === Automatic], maxTally = Max[Last /@ tally] ];
      If[ TrueQ[minTally === Automatic], minTally = Min[Last /@ tally] ];

      rFunc = Rescale[#, {minTally, maxTally}]&;

      grRes =
          Graphics[
            Table[
              Which[
                ptype == 1 || ptype == "ColoredPolygons",
                Tooltip[
                  {cFunc[Last @ rFunc @ tally[[n]]], TransformByVector[vh, First@tally[[n]]]},
                  Last@tally[[n]]
                ],

                ptype == 2 || ptype == "ProportionalSideSize",
                Tooltip[
                  TransformByVector[Last @ rFunc @ tally[[n]] * vh, First@tally[[n]]],
                  Last@tally[[n]]
                ],

                ptype == 3 || ptype == "ProportionalArea",
                Tooltip[
                  TransformByVector[Sqrt[Last @ rFunc @ tally[[n]]] * vh, First@tally[[n]]],
                  Last@tally[[n]]
                ]

              ],
              {n, Length@tally}
            ],
            FilterRules[{opts}, Options[Graphics]],
            Frame -> True, PlotRange -> {{xmin, xmax}, {ymin, ymax}},
            PlotRangeClipping -> True
          ];

      If[ TrueQ[plotLegends === Automatic],
        Legended[ grRes, BarLegend[ {cFunc[Rescale[#, {minTally, maxTally}]] &, {minTally, maxTally}} ] ],
        (* ELSE *)
        grRes
      ]
    ];


HextileHistogram[___] :=
    Block[{},
      Message[HextileHistogram::"nargs"];
      $Failed
    ];

End[]; (* `Private` *)

EndPackage[]