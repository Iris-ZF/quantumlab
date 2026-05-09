import 'dart:math' as math;
import '../utils/complex.dart';

/// 2x2 matrix stored as [row0col0, row0col1, row1col0, row1col1].
typedef GateMatrix = List<Complex>;

GateMatrix gateH() {
  final s = Complex(1.0 / math.sqrt(2.0));
  return [s, s, s, -s];
}

GateMatrix gateX() => [cZero, cOne, cOne, cZero];

GateMatrix gateY() => [cZero, -cI, cI, cZero];

GateMatrix gateZ() => [cOne, cZero, cZero, cNegOne];

GateMatrix gateS() => [cOne, cZero, cZero, cI];

GateMatrix gateT() {
  final eiPiOver4 = Complex.polar(1.0, math.pi / 4.0);
  return [cOne, cZero, cZero, eiPiOver4];
}

GateMatrix gateSdg() => [cOne, cZero, cZero, Complex(0, -1)];

GateMatrix gateTdg() {
  final eiNegPiOver4 = Complex.polar(1.0, -math.pi / 4.0);
  return [cOne, cZero, cZero, eiNegPiOver4];
}

GateMatrix gateRy(double theta) {
  final c = Complex(math.cos(theta / 2.0));
  final s = Complex(math.sin(theta / 2.0));
  return [c, -s, s, c];
}

GateMatrix gateRx(double theta) {
  final c = Complex(math.cos(theta / 2.0));
  final s = Complex(0, -math.sin(theta / 2.0));
  return [c, s, s, c];
}

GateMatrix gateRz(double theta) {
  final eNeg = Complex.polar(1.0, -theta / 2.0);
  final ePos = Complex.polar(1.0, theta / 2.0);
  return [eNeg, cZero, cZero, ePos];
}

/// Returns the gate matrix for a named single-qubit gate.
GateMatrix getSingleQubitGate(String name) {
  switch (name.toUpperCase()) {
    case 'H':
      return gateH();
    case 'X':
      return gateX();
    case 'Y':
      return gateY();
    case 'Z':
      return gateZ();
    case 'S':
      return gateS();
    case 'T':
      return gateT();
    case 'SDG':
      return gateSdg();
    case 'TDG':
      return gateTdg();
    default:
      throw ArgumentError('Unknown single-qubit gate: $name');
  }
}
