import 'package:flutter/material.dart';

class HandLandmark {
  const HandLandmark({
    required this.index,
    required this.name,
    required this.position,
    this.z = 0,
    this.isHighlighted = false,
  });

  final int index;
  final String name;
  final Offset position;
  final double z;
  final bool isHighlighted;
}

class HandConnection {
  const HandConnection(this.start, this.end);

  final int start;
  final int end;
}

const handLandmarkNames = <String>[
  'wrist',
  'thumb CMC',
  'thumb MCP',
  'thumb IP',
  'thumb tip',
  'index MCP',
  'index PIP',
  'index DIP',
  'index tip',
  'middle MCP',
  'middle PIP',
  'middle DIP',
  'middle tip',
  'ring MCP',
  'ring PIP',
  'ring DIP',
  'ring tip',
  'pinky MCP',
  'pinky PIP',
  'pinky DIP',
  'pinky tip',
];

const handSkeletonConnections = <HandConnection>[
  HandConnection(0, 1),
  HandConnection(1, 2),
  HandConnection(2, 3),
  HandConnection(3, 4),
  HandConnection(0, 5),
  HandConnection(5, 6),
  HandConnection(6, 7),
  HandConnection(7, 8),
  HandConnection(0, 9),
  HandConnection(9, 10),
  HandConnection(10, 11),
  HandConnection(11, 12),
  HandConnection(0, 13),
  HandConnection(13, 14),
  HandConnection(14, 15),
  HandConnection(15, 16),
  HandConnection(0, 17),
  HandConnection(17, 18),
  HandConnection(18, 19),
  HandConnection(19, 20),
  HandConnection(5, 9),
  HandConnection(9, 13),
  HandConnection(13, 17),
  HandConnection(17, 5),
];
